/// Represents a GymMate AI user profile stored in Firestore
/// under the `users/{uid}` document.
///
/// This intentionally includes the fields the AI Fitness Assessment
/// and Workout Recommendation modules will need later (age, height,
/// weight, goal, experience, etc.) so the schema doesn't need to
/// change when you build those modules.
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phoneNumber;

  // Fitness profile fields
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? fitnessGoal; // e.g. "Weight Loss", "Muscle Gain"
  final String? experienceLevel; // "Beginner" | "Intermediate" | "Advanced"
  final int? workoutDaysPerWeek;
  final String? foodPreference; // "Vegetarian" | "Non Vegetarian" etc.
  final List<String> medicalConditions;
  final String? dailyActivity; // "Sedentary", "Light", "Moderate", "Active"
  final String? country;
  final String? budget; // "Low", "Medium", "High"
  final int? goalDurationMonths; // E.g., 3 for 3 months (90 days)
  final int? goalDurationDays;

  // Onboarding & Progress Tracking
  final bool hasCompletedProfileSetup;
  final int currentWorkoutDay;
  final int streakCount;
  final int totalXp;
  final int completedDaysCount;
  final int totalCaloriesBurned;
  final List<String> unlockedBadges;

  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phoneNumber,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.fitnessGoal,
    this.experienceLevel,
    this.workoutDaysPerWeek,
    this.foodPreference,
    this.medicalConditions = const [],
    this.dailyActivity,
    this.country,
    this.budget,
    this.goalDurationMonths,
    this.goalDurationDays,
    this.hasCompletedProfileSetup = false,
    this.currentWorkoutDay = 1,
    this.streakCount = 1,
    this.totalXp = 150,
    this.completedDaysCount = 0,
    this.totalCaloriesBurned = 0,
    this.unlockedBadges = const ['Early Bird', 'First Step'],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Computed BMI, or null if height/weight aren't set yet.
  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final heightM = heightCm! / 100;
    return weightKg! / (heightM * heightM);
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? phoneNumber,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? fitnessGoal,
    String? experienceLevel,
    int? workoutDaysPerWeek,
    String? foodPreference,
    List<String>? medicalConditions,
    String? dailyActivity,
    String? country,
    String? budget,
    int? goalDurationMonths,
    int? goalDurationDays,
    bool? hasCompletedProfileSetup,
    int? currentWorkoutDay,
    int? streakCount,
    int? totalXp,
    int? completedDaysCount,
    int? totalCaloriesBurned,
    List<String>? unlockedBadges,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workoutDaysPerWeek: workoutDaysPerWeek ?? this.workoutDaysPerWeek,
      foodPreference: foodPreference ?? this.foodPreference,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      dailyActivity: dailyActivity ?? this.dailyActivity,
      country: country ?? this.country,
      budget: budget ?? this.budget,
      goalDurationMonths: goalDurationMonths ?? this.goalDurationMonths,
      goalDurationDays: goalDurationDays ?? this.goalDurationDays,
      hasCompletedProfileSetup: hasCompletedProfileSetup ?? this.hasCompletedProfileSetup,
      currentWorkoutDay: currentWorkoutDay ?? this.currentWorkoutDay,
      streakCount: streakCount ?? this.streakCount,
      totalXp: totalXp ?? this.totalXp,
      completedDaysCount: completedDaysCount ?? this.completedDaysCount,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'fitnessGoal': fitnessGoal,
      'experienceLevel': experienceLevel,
      'workoutDaysPerWeek': workoutDaysPerWeek,
      'foodPreference': foodPreference,
      'medicalConditions': medicalConditions,
      'dailyActivity': dailyActivity,
      'country': country,
      'budget': budget,
      'goalDurationMonths': goalDurationMonths,
      'goalDurationDays': goalDurationDays,
      'hasCompletedProfileSetup': hasCompletedProfileSetup,
      'currentWorkoutDay': currentWorkoutDay,
      'streakCount': streakCount,
      'totalXp': totalXp,
      'completedDaysCount': completedDaysCount,
      'totalCaloriesBurned': totalCaloriesBurned,
      'unlockedBadges': unlockedBadges,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      phoneNumber: map['phoneNumber'],
      age: map['age'],
      gender: map['gender'],
      heightCm: (map['heightCm'] as num?)?.toDouble(),
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      fitnessGoal: map['fitnessGoal'],
      experienceLevel: map['experienceLevel'],
      workoutDaysPerWeek: map['workoutDaysPerWeek'],
      foodPreference: map['foodPreference'],
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      dailyActivity: map['dailyActivity'],
      country: map['country'],
      budget: map['budget'],
      goalDurationMonths: map['goalDurationMonths'],
      goalDurationDays: map['goalDurationDays'],
      hasCompletedProfileSetup: map['hasCompletedProfileSetup'] ?? (map['fitnessGoal'] != null && map['age'] != null),
      currentWorkoutDay: map['currentWorkoutDay'] ?? 1,
      streakCount: map['streakCount'] ?? 1,
      totalXp: map['totalXp'] ?? 150,
      completedDaysCount: map['completedDaysCount'] ?? 0,
      totalCaloriesBurned: map['totalCaloriesBurned'] ?? 0,
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? ['Early Bird', 'First Step']),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
