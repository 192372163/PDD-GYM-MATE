import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles all Firestore reads/writes for the `users` collection.
/// Extended with workout progress, nutrition logs, and real-time streams for Web <-> Mobile Sync.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  // ─── User Profile Real-Time Sync ──────────────────────────────────────────

  /// Creates the initial user profile document right after signup.
  Future<void> createUserProfile(UserModel user) async {
    await _usersRef.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  /// Fetches a user's profile document (one-time).
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }

  /// Streams the user profile so Web <-> Mobile updates reflect live instantly.
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  /// Alias for streamUserProfile for naming consistency.
  Stream<UserModel?> getUserProfileStream(String uid) => streamUserProfile(uid);

  /// Updates specific fields on the profile (propagated instantly across Web & Mobile).
  Future<void> updateUserProfile(String uid, Map<String, dynamic> fields) async {
    await _usersRef.doc(uid).update(fields);
  }

  Future<void> deleteUserProfile(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  // ─── Workout Progress Real-Time Sync ──────────────────────────────────────

  /// Saves entire workout plan state (including day completion flags, streak, calories).
  Future<void> saveWorkoutProgress(String uid, Map<String, dynamic> planMap) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('workoutPlans')
        .doc('activePlan')
        .set(planMap, SetOptions(merge: false));
  }

  /// Loads the active workout plan from Firestore.
  Future<Map<String, dynamic>?> loadWorkoutProgress(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('workoutPlans')
        .doc('activePlan')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }

  /// Real-time stream for active workout plan (Web edits instantly update Mobile).
  Stream<Map<String, dynamic>?> streamWorkoutProgress(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('workoutPlans')
        .doc('activePlan')
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // ─── Nutrition Logs Real-Time Sync ────────────────────────────────────────

  /// Saves today's meal completion status.
  Future<void> saveNutritionLog(String uid, String dateKey, Map<String, dynamic> logData) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('nutritionLogs')
        .doc(dateKey)
        .set(logData, SetOptions(merge: true));
  }

  /// Loads today's nutrition log.
  Future<Map<String, dynamic>?> getNutritionLog(String uid, String dateKey) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('nutritionLogs')
        .doc(dateKey)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return doc.data();
  }

  /// Real-time stream for nutrition logs (Web meal edits sync live to Mobile).
  Stream<Map<String, dynamic>?> streamNutritionLog(String uid, String dateKey) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('nutritionLogs')
        .doc(dateKey)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  // ─── Water Intake Real-Time Sync ──────────────────────────────────────────

  /// Saves water intake for today.
  Future<void> saveWaterIntake(String uid, double liters) async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    await _db
        .collection('users')
        .doc(uid)
        .collection('waterLogs')
        .doc(key)
        .set({'liters': liters, 'date': key}, SetOptions(merge: true));

    // Also update user profile with today's water intake
    await _usersRef.doc(uid).update({'lastWaterIntake': liters});
  }

  /// Loads water intake for today.
  Future<double> getWaterIntake(String uid) async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('waterLogs')
        .doc(key)
        .get();
    if (!doc.exists || doc.data() == null) return 0.0;
    return (doc.data()!['liters'] as num?)?.toDouble() ?? 0.0;
  }

  /// Real-time stream for water intake logs.
  Stream<double> streamWaterIntake(String uid) {
    final today = DateTime.now();
    final key = '${today.year}-${today.month}-${today.day}';
    return _db
        .collection('users')
        .doc(uid)
        .collection('waterLogs')
        .doc(key)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return 0.0;
          return (doc.data()!['liters'] as num?)?.toDouble() ?? 0.0;
        });
  }

  // ─── Weight History Real-Time Sync ────────────────────────────────────────

  /// Appends a weight entry for progress tracking.
  Future<void> saveWeightEntry(String uid, double weight, DateTime date) async {
    final key = '${date.year}-${date.month}-${date.day}';
    await _db
        .collection('users')
        .doc(uid)
        .collection('weightHistory')
        .doc(key)
        .set({'weight': weight, 'date': date.toIso8601String()});
  }

  /// Real-time stream for weight history.
  Stream<List<Map<String, dynamic>>> streamWeightHistory(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('weightHistory')
        .orderBy('date', descending: false)
        .snapshots()
        .map((query) => query.docs.map((d) => d.data()).toList());
  }

  // ─── Streak & Stats ────────────────────────────────────────────────────────

  /// Updates user stats: streak, completed days, calories burned.
  Future<void> updateUserStats(String uid, {
    int? streakCount,
    int? completedDaysCount,
    int? totalCaloriesBurned,
    int? totalXp,
  }) async {
    final data = <String, dynamic>{};
    if (streakCount != null) data['streakCount'] = streakCount;
    if (completedDaysCount != null) data['completedDaysCount'] = completedDaysCount;
    if (totalCaloriesBurned != null) data['totalCaloriesBurned'] = totalCaloriesBurned;
    if (totalXp != null) data['totalXp'] = totalXp;
    if (data.isNotEmpty) await _usersRef.doc(uid).update(data);
  }
}
