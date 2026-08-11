import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/exercise_model.dart';

class CompletedWorkout {
  final String id;
  final String title;
  final DateTime date;
  final int durationMins;
  final int caloriesBurned;
  final List<String> exercisesCompleted;

  CompletedWorkout({
    required this.id,
    required this.title,
    required this.date,
    required this.durationMins,
    required this.caloriesBurned,
    required this.exercisesCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'durationMins': durationMins,
      'caloriesBurned': caloriesBurned,
      'exercisesCompleted': exercisesCompleted,
    };
  }

  factory CompletedWorkout.fromMap(Map<String, dynamic> map) {
    return CompletedWorkout(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date']),
      durationMins: map['durationMins'] ?? 0,
      caloriesBurned: map['caloriesBurned'] ?? 0,
      exercisesCompleted: List<String>.from(map['exercisesCompleted'] ?? []),
    );
  }
}

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal() {
    loadCompletedWorkouts();
  }

  // Map keyed by date string "YYYY-MM-DD"
  final Map<String, CompletedWorkout> _completedWorkouts = {};

  Future<void> loadCompletedWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = AuthService().currentUser?.uid ?? 'guest';
      
      // Load local cache first
      final String? data = prefs.getString('completedWorkouts_$uid');
      if (data != null) {
        final Map<String, dynamic> decoded = jsonDecode(data);
        _completedWorkouts.clear();
        decoded.forEach((key, value) {
          _completedWorkouts[key] = CompletedWorkout.fromMap(value);
        });
        notifyListeners();
      }

      // Fetch from Firestore if logged in
      if (uid != 'guest') {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('completedWorkouts')
            .get();
        
        for (var doc in snapshot.docs) {
          if (doc.exists && doc.data().isNotEmpty) {
            _completedWorkouts[doc.id] = CompletedWorkout.fromMap(doc.data());
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading completed workouts: $e');
    }
  }

  Future<void> _saveCompletedWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = AuthService().currentUser?.uid ?? 'guest';
      final encoded = _completedWorkouts.map((key, value) => MapEntry(key, value.toMap()));
      await prefs.setString('completedWorkouts_$uid', jsonEncode(encoded));

      // Also persist to Cloud Firestore for signed-in user
      if (uid != 'guest') {
        final db = FirebaseFirestore.instance;
        final batch = db.batch();
        _completedWorkouts.forEach((key, workout) {
          final docRef = db.collection('users').doc(uid).collection('completedWorkouts').doc(key);
          batch.set(docRef, workout.toMap(), SetOptions(merge: true));
        });
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error saving completed workouts: $e');
    }
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Check if a workout has been completed on the given date
  bool isWorkoutCompleted(DateTime date) {
    final key = _dateKey(date);
    return _completedWorkouts.containsKey(key);
  }

  /// Get completed workout details for a date
  CompletedWorkout? getCompletedWorkout(DateTime date) {
    final key = _dateKey(date);
    return _completedWorkouts[key];
  }

  /// Record a completed workout for a date (defaults to today)
  void completeWorkout({
    required String title,
    DateTime? date,
    required int durationMins,
    required int caloriesBurned,
    required List<String> exercises,
  }) {
    final workoutDate = date ?? DateTime.now();
    final key = _dateKey(workoutDate);
    
    if (_completedWorkouts.containsKey(key)) {
      final existing = _completedWorkouts[key]!;
      // Append unique exercises
      final updatedExercises = List<String>.from(existing.exercisesCompleted);
      for (var ex in exercises) {
        if (!updatedExercises.contains(ex)) {
          updatedExercises.add(ex);
        }
      }
      _completedWorkouts[key] = CompletedWorkout(
        id: existing.id,
        title: existing.title == 'Single Exercise Session' ? title : existing.title,
        date: existing.date,
        durationMins: existing.durationMins + durationMins,
        caloriesBurned: existing.caloriesBurned + caloriesBurned,
        exercisesCompleted: updatedExercises,
      );
    } else {
      _completedWorkouts[key] = CompletedWorkout(
        id: 'cw_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        date: workoutDate,
        durationMins: durationMins,
        caloriesBurned: caloriesBurned,
        exercisesCompleted: exercises,
      );
    }

    _saveCompletedWorkouts();
    notifyListeners();
  }

  /// Total count of completed workouts
  int get completedWorkoutCount => _completedWorkouts.length;

  /// Generates a personalized 7-day workout split based on user profile
  Map<String, String> generateRecommendedSplit(UserModel user) {
    final exp = user.experienceLevel?.toLowerCase() ?? 'beginner';
    final days = user.workoutDaysPerWeek ?? 3;

    // Beginner 3-day full body
    if (days <= 3 || exp == 'beginner') {
      return {
        'Monday': 'Full Body',
        'Tuesday': 'Rest',
        'Wednesday': 'Full Body',
        'Thursday': 'Rest',
        'Friday': 'Full Body / Cardio',
        'Saturday': 'Rest',
        'Sunday': 'Rest',
      };
    }

    // Intermediate/Advanced Push/Pull/Legs
    if (days >= 5) {
      return {
        'Monday': 'Push Workout',
        'Tuesday': 'Pull Workout',
        'Wednesday': 'Legs',
        'Thursday': 'Cardio & Core',
        'Friday': 'Upper Body',
        'Saturday': 'Full Body',
        'Sunday': 'Rest',
      };
    }

    // Default 4-day split
    return {
      'Monday': 'Upper Body',
      'Tuesday': 'Lower Body',
      'Wednesday': 'Rest',
      'Thursday': 'Upper Body',
      'Friday': 'Lower Body',
      'Saturday': 'Cardio',
      'Sunday': 'Rest',
    };
  }

  /// Generates a list of exercises for a given workout type
  List<ExerciseModel> getExercisesForWorkout(String workoutName, [UserModel? user]) {
    final lowerName = workoutName.toLowerCase();
    
    List<ExerciseModel> baseExercises;

    if (lowerName.contains('full body')) {
      baseExercises = [
        ExerciseModel(id: '1', name: 'Squats', description: 'Stand with feet shoulder-width apart, lower hips back and down.', targetMuscle: 'Legs', sets: 3, reps: 12),
        ExerciseModel(id: '2', name: 'Push-ups', description: 'Start in a plank position, lower body until chest touches the floor.', targetMuscle: 'Chest', sets: 3, reps: 15),
        ExerciseModel(id: '3', name: 'Dumbbell Rows', description: 'Bend forward, pull dumbbell up to your waist.', targetMuscle: 'Back', sets: 3, reps: 10),
      ];
    } else if (lowerName.contains('upper body') || lowerName.contains('push')) {
      baseExercises = [
        ExerciseModel(id: '4', name: 'Bench Press', description: 'Lie on bench, press weight straight up.', targetMuscle: 'Chest', sets: 4, reps: 10),
        ExerciseModel(id: '5', name: 'Shoulder Press', description: 'Press dumbbells overhead from shoulders.', targetMuscle: 'Shoulders', sets: 3, reps: 12),
        ExerciseModel(id: '6', name: 'Tricep Extensions', description: 'Extend arms overhead with dumbbell.', targetMuscle: 'Triceps', sets: 3, reps: 15),
      ];
    } else if (lowerName.contains('lower body') || lowerName.contains('legs')) {
      baseExercises = [
        ExerciseModel(id: '7', name: 'Squats', description: 'Stand with feet shoulder-width apart, lower hips back and down.', targetMuscle: 'Legs', sets: 4, reps: 10),
        ExerciseModel(id: '8', name: 'Romanian Deadlifts', description: 'Hinge at hips, keep legs slightly bent.', targetMuscle: 'Hamstrings', sets: 3, reps: 12),
        ExerciseModel(id: '9', name: 'Calf Raises', description: 'Push up on toes, hold, lower down.', targetMuscle: 'Calves', sets: 4, reps: 15),
      ];
    } else if (lowerName.contains('pull')) {
      baseExercises = [
        ExerciseModel(id: '10', name: 'Pull-ups', description: 'Pull body up until chin is over the bar.', targetMuscle: 'Back', sets: 3, reps: 8),
        ExerciseModel(id: '11', name: 'Barbell Rows', description: 'Bend forward, pull barbell to waist.', targetMuscle: 'Back', sets: 3, reps: 10),
        ExerciseModel(id: '12', name: 'Bicep Curls', description: 'Curl dumbbells up to shoulders.', targetMuscle: 'Biceps', sets: 3, reps: 12),
      ];
    } else if (lowerName.contains('cardio')) {
      baseExercises = [
        ExerciseModel(id: '13', name: 'Jumping Jacks', description: 'Jump up spreading legs and arms.', targetMuscle: 'Full Body', sets: 3, reps: 30),
        ExerciseModel(id: '14', name: 'Burpees', description: 'Drop to plank, do a push-up, jump up.', targetMuscle: 'Full Body', sets: 3, reps: 15),
        ExerciseModel(id: '15', name: 'High Knees', description: 'Run in place bringing knees up high.', targetMuscle: 'Legs', sets: 3, reps: 40),
      ];
    } else {
      baseExercises = [
        ExerciseModel(id: '16', name: 'General Warm-up', description: 'Light stretching and mobility work.', targetMuscle: 'Full Body', sets: 1, reps: 1),
      ];
    }

    if (user == null || user.fitnessGoal == null || user.goalDurationMonths == null) {
      return baseExercises;
    }

    final goal = user.fitnessGoal!.toLowerCase();
    final int duration = user.goalDurationMonths!;
    final bool isShortTerm = duration <= 3;

    return baseExercises.map((ex) {
      if (ex.name == 'General Warm-up') return ex; // Keep warm-up as is

      int newSets = ex.sets;
      int newReps = ex.reps;

      if (goal.contains('loss') || goal.contains('fat')) {
        // High intensity, high volume for weight loss
        newReps = isShortTerm ? 18 : 15;
        newSets = isShortTerm ? newSets + 1 : newSets;
      } else if (goal.contains('gain') || goal.contains('muscle')) {
        // Heavy weight, lower reps for mass
        newReps = isShortTerm ? 8 : 10;
        newSets = isShortTerm ? newSets + 1 : newSets;
      }

      return ExerciseModel(
        id: ex.id,
        name: ex.name,
        description: ex.description,
        targetMuscle: ex.targetMuscle,
        sets: newSets,
        reps: newReps,
      );
    }).toList();
  }
}
