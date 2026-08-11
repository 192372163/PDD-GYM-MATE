import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseDateNullable(dynamic val) {
  if (val == null) return null;
  if (val is Timestamp) return val.toDate();
  if (val is String) return DateTime.tryParse(val);
  return null;
}

DateTime _parseDate(dynamic val, {required DateTime fallback}) {
  return _parseDateNullable(val) ?? fallback;
}

/// Represents a single exercise in the dynamic workout schedule
class WorkoutExercise {
  final String id;
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final int caloriesBurned;
  final String difficulty;
  final String category;
  final bool isCompleted;
  final String? hdThumbnailUrl;
  final String? videoUrl;
  final int durationMins;
  final List<String> instructions;
  final List<String> commonMistakes;
  final List<String> safetyTips;
  final String targetMuscle;

  WorkoutExercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.caloriesBurned,
    required this.difficulty,
    required this.category,
    this.isCompleted = false,
    this.hdThumbnailUrl,
    this.videoUrl,
    this.durationMins = 5,
    this.instructions = const [],
    this.commonMistakes = const [],
    this.safetyTips = const [],
    this.targetMuscle = 'Full Body',
  });

  WorkoutExercise copyWith({
    String? id,
    String? name,
    int? sets,
    String? reps,
    int? restSeconds,
    int? caloriesBurned,
    String? difficulty,
    String? category,
    bool? isCompleted,
    String? hdThumbnailUrl,
    String? videoUrl,
    int? durationMins,
    List<String>? instructions,
    List<String>? commonMistakes,
    List<String>? safetyTips,
    String? targetMuscle,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restSeconds: restSeconds ?? this.restSeconds,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      hdThumbnailUrl: hdThumbnailUrl ?? this.hdThumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMins: durationMins ?? this.durationMins,
      instructions: instructions ?? this.instructions,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      safetyTips: safetyTips ?? this.safetyTips,
      targetMuscle: targetMuscle ?? this.targetMuscle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      'caloriesBurned': caloriesBurned,
      'difficulty': difficulty,
      'category': category,
      'isCompleted': isCompleted,
      'hdThumbnailUrl': hdThumbnailUrl,
      'videoUrl': videoUrl,
      'durationMins': durationMins,
      'instructions': instructions,
      'commonMistakes': commonMistakes,
      'safetyTips': safetyTips,
      'targetMuscle': targetMuscle,
    };
  }

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    return WorkoutExercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sets: map['sets']?.toInt() ?? 3,
      reps: map['reps'] ?? '12 Reps',
      restSeconds: map['restSeconds']?.toInt() ?? 60,
      caloriesBurned: map['caloriesBurned']?.toInt() ?? 100,
      difficulty: map['difficulty'] ?? 'Intermediate',
      category: map['category'] ?? 'General',
      isCompleted: map['isCompleted'] ?? false,
      hdThumbnailUrl: map['hdThumbnailUrl'],
      videoUrl: map['videoUrl'],
      durationMins: map['durationMins']?.toInt() ?? 5,
      instructions: List<String>.from(map['instructions'] ?? []),
      commonMistakes: List<String>.from(map['commonMistakes'] ?? []),
      safetyTips: List<String>.from(map['safetyTips'] ?? []),
      targetMuscle: map['targetMuscle'] ?? 'Full Body',
    );
  }
}

/// Daily schedule holding workouts for a day (e.g. Day 1, Day 2)
class DailyWorkoutSchedule {
  final int dayNumber;
  final String dayName;
  final String focusArea;
  final bool isRestDay;
  final List<WorkoutExercise> warmupExercises;
  final List<WorkoutExercise> workoutExercises;
  final List<WorkoutExercise> cooldownExercises;
  final bool isCompleted;
  final DateTime? completionDate;
  /// True when user started but did not finish this day's workout
  final bool isInProgress;
  /// Index of the last exercise the user was on (for resume)
  final int lastCompletedExerciseIndex;
  /// Actual duration in seconds tracked during the session
  final int workoutDurationSecs;

  DailyWorkoutSchedule({
    required this.dayNumber,
    required this.dayName,
    required this.focusArea,
    this.isRestDay = false,
    this.warmupExercises = const [],
    required this.workoutExercises,
    this.cooldownExercises = const [],
    this.isCompleted = false,
    this.completionDate,
    this.isInProgress = false,
    this.lastCompletedExerciseIndex = 0,
    this.workoutDurationSecs = 0,
  });

  /// Combined getter returning all exercises for this day in sequence
  List<WorkoutExercise> get exercises {
    if (warmupExercises.isNotEmpty || cooldownExercises.isNotEmpty) {
      return [...warmupExercises, ...workoutExercises, ...cooldownExercises];
    }
    return workoutExercises;
  }

  int get totalCalories {
    return exercises.fold(0, (total, ex) => total + ex.caloriesBurned);
  }

  int get totalDurationMins {
    return exercises.fold(0, (total, ex) => total + ex.durationMins);
  }

  DailyWorkoutSchedule copyWith({
    int? dayNumber,
    String? dayName,
    String? focusArea,
    bool? isRestDay,
    List<WorkoutExercise>? warmupExercises,
    List<WorkoutExercise>? workoutExercises,
    List<WorkoutExercise>? cooldownExercises,
    bool? isCompleted,
    DateTime? completionDate,
    bool? isInProgress,
    int? lastCompletedExerciseIndex,
    int? workoutDurationSecs,
  }) {
    return DailyWorkoutSchedule(
      dayNumber: dayNumber ?? this.dayNumber,
      dayName: dayName ?? this.dayName,
      focusArea: focusArea ?? this.focusArea,
      isRestDay: isRestDay ?? this.isRestDay,
      warmupExercises: warmupExercises ?? this.warmupExercises,
      workoutExercises: workoutExercises ?? this.workoutExercises,
      cooldownExercises: cooldownExercises ?? this.cooldownExercises,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
      isInProgress: isInProgress ?? this.isInProgress,
      lastCompletedExerciseIndex: lastCompletedExerciseIndex ?? this.lastCompletedExerciseIndex,
      workoutDurationSecs: workoutDurationSecs ?? this.workoutDurationSecs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'dayName': dayName,
      'focusArea': focusArea,
      'isRestDay': isRestDay,
      'warmupExercises': warmupExercises.map((x) => x.toMap()).toList(),
      'workoutExercises': workoutExercises.map((x) => x.toMap()).toList(),
      'cooldownExercises': cooldownExercises.map((x) => x.toMap()).toList(),
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
      'isInProgress': isInProgress,
      'lastCompletedExerciseIndex': lastCompletedExerciseIndex,
      'workoutDurationSecs': workoutDurationSecs,
    };
  }

  factory DailyWorkoutSchedule.fromMap(Map<String, dynamic> map) {
    List<WorkoutExercise> workouts = List<WorkoutExercise>.from(
      (map['workoutExercises'] ?? map['exercises'] ?? [])
          .map((x) => WorkoutExercise.fromMap(x)),
    );
    List<WorkoutExercise> warmups = List<WorkoutExercise>.from(
      (map['warmupExercises'] ?? []).map((x) => WorkoutExercise.fromMap(x)),
    );
    List<WorkoutExercise> cooldowns = List<WorkoutExercise>.from(
      (map['cooldownExercises'] ?? []).map((x) => WorkoutExercise.fromMap(x)),
    );

    return DailyWorkoutSchedule(
      dayNumber: map['dayNumber']?.toInt() ?? 1,
      dayName: map['dayName'] ?? 'Day 1',
      focusArea: map['focusArea'] ?? 'Full Body',
      isRestDay: map['isRestDay'] ?? false,
      warmupExercises: warmups,
      workoutExercises: workouts,
      cooldownExercises: cooldowns,
      isCompleted: map['isCompleted'] ?? false,
      completionDate: _parseDateNullable(map['completionDate']),
      isInProgress: map['isInProgress'] ?? false,
      lastCompletedExerciseIndex: map['lastCompletedExerciseIndex']?.toInt() ?? 0,
      workoutDurationSecs: map['workoutDurationSecs']?.toInt() ?? 0,
    );
  }
}

/// Nutrition meal item with macronutrient details
class MealPlanItem {
  final String id;
  final String mealType; // "Breakfast", "Lunch", "Evening Snack", "Dinner"
  final String foodName;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double waterRecommendationLiters;
  final bool isCompleted;

  MealPlanItem({
    required this.id,
    required this.mealType,
    required this.foodName,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.waterRecommendationLiters,
    this.isCompleted = false,
  });

  MealPlanItem copyWith({
    String? id,
    String? mealType,
    String? foodName,
    int? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? waterRecommendationLiters,
    bool? isCompleted,
  }) {
    return MealPlanItem(
      id: id ?? this.id,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      waterRecommendationLiters:
          waterRecommendationLiters ?? this.waterRecommendationLiters,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealType': mealType,
      'foodName': foodName,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'waterRecommendationLiters': waterRecommendationLiters,
      'isCompleted': isCompleted,
    };
  }

  factory MealPlanItem.fromMap(Map<String, dynamic> map) {
    return MealPlanItem(
      id: map['id'] ?? '',
      mealType: map['mealType'] ?? 'Breakfast',
      foodName: map['foodName'] ?? 'Healthy Meal',
      calories: map['calories']?.toInt() ?? 400,
      proteinGrams: (map['proteinGrams'] as num?)?.toDouble() ?? 25.0,
      carbsGrams: (map['carbsGrams'] as num?)?.toDouble() ?? 45.0,
      fatGrams: (map['fatGrams'] as num?)?.toDouble() ?? 12.0,
      waterRecommendationLiters:
          (map['waterRecommendationLiters'] as num?)?.toDouble() ?? 0.5,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}

/// Tracks daily activities & logs
class DailyTrackerLog {
  final String dateString;
  final List<String> completedExerciseIds;
  final List<String> completedMealIds;
  final double waterIntakeLiters;
  final double sleepHours;
  final int stepsWalked;

  DailyTrackerLog({
    required this.dateString,
    this.completedExerciseIds = const [],
    this.completedMealIds = const [],
    this.waterIntakeLiters = 0.0,
    this.sleepHours = 7.0,
    this.stepsWalked = 0,
  });

  DailyTrackerLog copyWith({
    String? dateString,
    List<String>? completedExerciseIds,
    List<String>? completedMealIds,
    double? waterIntakeLiters,
    double? sleepHours,
    int? stepsWalked,
  }) {
    return DailyTrackerLog(
      dateString: dateString ?? this.dateString,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      completedMealIds: completedMealIds ?? this.completedMealIds,
      waterIntakeLiters: waterIntakeLiters ?? this.waterIntakeLiters,
      sleepHours: sleepHours ?? this.sleepHours,
      stepsWalked: stepsWalked ?? this.stepsWalked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateString': dateString,
      'completedExerciseIds': completedExerciseIds,
      'completedMealIds': completedMealIds,
      'waterIntakeLiters': waterIntakeLiters,
      'sleepHours': sleepHours,
      'stepsWalked': stepsWalked,
    };
  }

  factory DailyTrackerLog.fromMap(Map<String, dynamic> map) {
    return DailyTrackerLog(
      dateString: map['dateString'] ?? DateTime.now().toIso8601String().split('T').first,
      completedExerciseIds: List<String>.from(map['completedExerciseIds'] ?? []),
      completedMealIds: List<String>.from(map['completedMealIds'] ?? []),
      waterIntakeLiters: (map['waterIntakeLiters'] as num?)?.toDouble() ?? 0.0,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 7.0,
      stepsWalked: map['stepsWalked']?.toInt() ?? 0,
    );
  }
}

/// Core model for the active Goal-Based AI Fitness Plan
class GoalPlanModel {
  final String id;
  final String userId;
  final String goalTitle;
  final String durationLabel;
  final int durationDays;
  final DateTime startDate;
  final DateTime targetCompletionDate;
  final double startingWeight;
  final double currentWeight;
  final double targetWeight;
  final double startingBmi;
  final double currentBmi;
  final int dailyCalorieTarget;
  final double dailyProteinTarget;
  final double dailyCarbsTarget;
  final double dailyFatTarget;
  final double dailyWaterTargetLiters;
  final double dailySleepTargetHours;
  final int dailyStepsTarget;
  final List<DailyWorkoutSchedule> workoutDays;
  final List<MealPlanItem> meals;
  final DailyTrackerLog tracker;
  final int workoutStreak;
  final double workoutConsistency;
  final double dietConsistency;
  final List<String> unlockedBadges;
  final bool isCompleted;
  final DateTime? completedDate;
  final List<double> weeklyProgressHistory;
  final List<double> weightProgressHistory;
  final List<double> bmiTrendHistory;
  final int userAge;
  final String userGender;
  final double userHeightCm;
  final String userFitnessLevel;
  final List<String> medicalConditions;
  final int availableWorkoutTimeMins;
  final int currentActiveDayIndex;
  final int totalWorkoutDaysCompleted;
  final int totalCaloriesBurned;

  GoalPlanModel({
    required this.id,
    required this.userId,
    required this.goalTitle,
    required this.durationLabel,
    required this.durationDays,
    required this.startDate,
    required this.targetCompletionDate,
    required this.startingWeight,
    required this.currentWeight,
    required this.targetWeight,
    required this.startingBmi,
    required this.currentBmi,
    required this.dailyCalorieTarget,
    required this.dailyProteinTarget,
    required this.dailyCarbsTarget,
    required this.dailyFatTarget,
    required this.dailyWaterTargetLiters,
    this.dailySleepTargetHours = 8.0,
    this.dailyStepsTarget = 8000,
    required this.workoutDays,
    required this.meals,
    required this.tracker,
    this.workoutStreak = 0,
    this.workoutConsistency = 0.85,
    this.dietConsistency = 0.90,
    this.unlockedBadges = const [],
    this.isCompleted = false,
    this.completedDate,
    this.weeklyProgressHistory = const [60, 75, 80, 85, 90, 95, 92],
    this.weightProgressHistory = const [],
    this.bmiTrendHistory = const [],
    this.userAge = 25,
    this.userGender = 'Male',
    this.userHeightCm = 175.0,
    this.userFitnessLevel = 'Intermediate',
    this.medicalConditions = const [],
    this.availableWorkoutTimeMins = 45,
    this.currentActiveDayIndex = 0,
    this.totalWorkoutDaysCompleted = 0,
    this.totalCaloriesBurned = 0,
  });

  /// Calculate days completed so far
  int get completedDays {
    return totalWorkoutDaysCompleted > 0
        ? totalWorkoutDaysCompleted
        : workoutDays.where((d) => d.isCompleted).length;
  }

  /// Calculate days remaining
  int get remainingDays {
    final rem = durationDays - completedDays;
    return rem < 0 ? 0 : rem;
  }

  /// Overall goal completion percentage (0.0 to 100.0)
  double get overallGoalCompletionPercentage {
    if (durationDays == 0) return 0.0;
    return ((completedDays / durationDays) * 100).clamp(0.0, 100.0);
  }

  /// Calculates overall completion percentage for today's tasks
  double get todayCompletionPercentage {
    final activeDay = (currentActiveDayIndex >= 0 && currentActiveDayIndex < workoutDays.length)
        ? workoutDays[currentActiveDayIndex]
        : (workoutDays.isNotEmpty ? workoutDays.first : null);

    final totalWorkoutTasks = activeDay != null ? activeDay.exercises.length : 1;
    final completedWorkouts = tracker.completedExerciseIds.length;
    final totalMealTasks = meals.isNotEmpty ? meals.length : 1;
    final completedMeals = tracker.completedMealIds.length;
    
    final workoutScore = totalWorkoutTasks > 0 ? (completedWorkouts / totalWorkoutTasks).clamp(0.0, 1.0) : 1.0;
    final mealScore = totalMealTasks > 0 ? (completedMeals / totalMealTasks).clamp(0.0, 1.0) : 1.0;
    final waterScore = (tracker.waterIntakeLiters / dailyWaterTargetLiters).clamp(0.0, 1.0);
    final sleepScore = (tracker.sleepHours / dailySleepTargetHours).clamp(0.0, 1.0);
    final stepsScore = (tracker.stepsWalked / dailyStepsTarget).clamp(0.0, 1.0);

    return ((workoutScore * 0.35) +
            (mealScore * 0.30) +
            (waterScore * 0.15) +
            (sleepScore * 0.10) +
            (stepsScore * 0.10)) *
        100;
  }

  GoalPlanModel copyWith({
    String? id,
    String? userId,
    String? goalTitle,
    String? durationLabel,
    int? durationDays,
    DateTime? startDate,
    DateTime? targetCompletionDate,
    double? startingWeight,
    double? currentWeight,
    double? targetWeight,
    double? startingBmi,
    double? currentBmi,
    int? dailyCalorieTarget,
    double? dailyProteinTarget,
    double? dailyCarbsTarget,
    double? dailyFatTarget,
    double? dailyWaterTargetLiters,
    double? dailySleepTargetHours,
    int? dailyStepsTarget,
    List<DailyWorkoutSchedule>? workoutDays,
    List<MealPlanItem>? meals,
    DailyTrackerLog? tracker,
    int? workoutStreak,
    double? workoutConsistency,
    double? dietConsistency,
    List<String>? unlockedBadges,
    bool? isCompleted,
    DateTime? completedDate,
    List<double>? weeklyProgressHistory,
    List<double>? weightProgressHistory,
    List<double>? bmiTrendHistory,
    int? userAge,
    String? userGender,
    double? userHeightCm,
    String? userFitnessLevel,
    List<String>? medicalConditions,
    int? availableWorkoutTimeMins,
    int? currentActiveDayIndex,
    int? totalWorkoutDaysCompleted,
    int? totalCaloriesBurned,
  }) {
    return GoalPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalTitle: goalTitle ?? this.goalTitle,
      durationLabel: durationLabel ?? this.durationLabel,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      targetCompletionDate: targetCompletionDate ?? this.targetCompletionDate,
      startingWeight: startingWeight ?? this.startingWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      targetWeight: targetWeight ?? this.targetWeight,
      startingBmi: startingBmi ?? this.startingBmi,
      currentBmi: currentBmi ?? this.currentBmi,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyProteinTarget: dailyProteinTarget ?? this.dailyProteinTarget,
      dailyCarbsTarget: dailyCarbsTarget ?? this.dailyCarbsTarget,
      dailyFatTarget: dailyFatTarget ?? this.dailyFatTarget,
      dailyWaterTargetLiters:
          dailyWaterTargetLiters ?? this.dailyWaterTargetLiters,
      dailySleepTargetHours:
          dailySleepTargetHours ?? this.dailySleepTargetHours,
      dailyStepsTarget: dailyStepsTarget ?? this.dailyStepsTarget,
      workoutDays: workoutDays ?? this.workoutDays,
      meals: meals ?? this.meals,
      tracker: tracker ?? this.tracker,
      workoutStreak: workoutStreak ?? this.workoutStreak,
      workoutConsistency: workoutConsistency ?? this.workoutConsistency,
      dietConsistency: dietConsistency ?? this.dietConsistency,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      isCompleted: isCompleted ?? this.isCompleted,
      completedDate: completedDate ?? this.completedDate,
      weeklyProgressHistory:
          weeklyProgressHistory ?? this.weeklyProgressHistory,
      weightProgressHistory:
          weightProgressHistory ?? this.weightProgressHistory,
      bmiTrendHistory: bmiTrendHistory ?? this.bmiTrendHistory,
      userAge: userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
      userHeightCm: userHeightCm ?? this.userHeightCm,
      userFitnessLevel: userFitnessLevel ?? this.userFitnessLevel,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      availableWorkoutTimeMins:
          availableWorkoutTimeMins ?? this.availableWorkoutTimeMins,
      currentActiveDayIndex:
          currentActiveDayIndex ?? this.currentActiveDayIndex,
      totalWorkoutDaysCompleted:
          totalWorkoutDaysCompleted ?? this.totalWorkoutDaysCompleted,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'goalTitle': goalTitle,
      'durationLabel': durationLabel,
      'durationDays': durationDays,
      'startDate': startDate.toIso8601String(),
      'targetCompletionDate': targetCompletionDate.toIso8601String(),
      'startingWeight': startingWeight,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'startingBmi': startingBmi,
      'currentBmi': currentBmi,
      'dailyCalorieTarget': dailyCalorieTarget,
      'dailyProteinTarget': dailyProteinTarget,
      'dailyCarbsTarget': dailyCarbsTarget,
      'dailyFatTarget': dailyFatTarget,
      'dailyWaterTargetLiters': dailyWaterTargetLiters,
      'dailySleepTargetHours': dailySleepTargetHours,
      'dailyStepsTarget': dailyStepsTarget,
      'workoutDays': workoutDays.map((x) => x.toMap()).toList(),
      'meals': meals.map((x) => x.toMap()).toList(),
      'tracker': tracker.toMap(),
      'workoutStreak': workoutStreak,
      'workoutConsistency': workoutConsistency,
      'dietConsistency': dietConsistency,
      'unlockedBadges': unlockedBadges,
      'isCompleted': isCompleted,
      'completedDate': completedDate?.toIso8601String(),
      'weeklyProgressHistory': weeklyProgressHistory,
      'weightProgressHistory': weightProgressHistory,
      'bmiTrendHistory': bmiTrendHistory,
      'userAge': userAge,
      'userGender': userGender,
      'userHeightCm': userHeightCm,
      'userFitnessLevel': userFitnessLevel,
      'medicalConditions': medicalConditions,
      'availableWorkoutTimeMins': availableWorkoutTimeMins,
      'currentActiveDayIndex': currentActiveDayIndex,
      'totalWorkoutDaysCompleted': totalWorkoutDaysCompleted,
      'totalCaloriesBurned': totalCaloriesBurned,
    };
  }

  factory GoalPlanModel.fromMap(Map<String, dynamic> map) {
    return GoalPlanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      goalTitle: map['goalTitle'] ?? 'Fitness Goal',
      durationLabel: map['durationLabel'] ?? '1 Month',
      durationDays: map['durationDays']?.toInt() ?? 30,
      startDate: _parseDate(map['startDate'], fallback: DateTime.now()),
      targetCompletionDate: _parseDate(map['targetCompletionDate'], fallback: DateTime.now().add(const Duration(days: 30))),
      startingWeight: (map['startingWeight'] as num?)?.toDouble() ?? 70.0,
      currentWeight: (map['currentWeight'] as num?)?.toDouble() ?? 70.0,
      targetWeight: (map['targetWeight'] as num?)?.toDouble() ?? 65.0,
      startingBmi: (map['startingBmi'] as num?)?.toDouble() ?? 24.0,
      currentBmi: (map['currentBmi'] as num?)?.toDouble() ?? 24.0,
      dailyCalorieTarget: map['dailyCalorieTarget']?.toInt() ?? 2200,
      dailyProteinTarget: (map['dailyProteinTarget'] as num?)?.toDouble() ?? 140.0,
      dailyCarbsTarget: (map['dailyCarbsTarget'] as num?)?.toDouble() ?? 220.0,
      dailyFatTarget: (map['dailyFatTarget'] as num?)?.toDouble() ?? 60.0,
      dailyWaterTargetLiters:
          (map['dailyWaterTargetLiters'] as num?)?.toDouble() ?? 3.5,
      dailySleepTargetHours:
          (map['dailySleepTargetHours'] as num?)?.toDouble() ?? 8.0,
      dailyStepsTarget: map['dailyStepsTarget']?.toInt() ?? 8000,
      workoutDays: List<DailyWorkoutSchedule>.from(
        (map['workoutDays'] ?? []).map((x) => DailyWorkoutSchedule.fromMap(x)),
      ),
      meals: List<MealPlanItem>.from(
        (map['meals'] ?? []).map((x) => MealPlanItem.fromMap(x)),
      ),
      tracker: map['tracker'] != null
          ? DailyTrackerLog.fromMap(map['tracker'])
          : DailyTrackerLog(
              dateString: DateTime.now().toIso8601String().split('T').first),
      workoutStreak: map['workoutStreak']?.toInt() ?? 5,
      workoutConsistency:
          (map['workoutConsistency'] as num?)?.toDouble() ?? 0.88,
      dietConsistency: (map['dietConsistency'] as num?)?.toDouble() ?? 0.92,
      unlockedBadges: List<String>.from(map['unlockedBadges'] ?? []),
      isCompleted: map['isCompleted'] ?? false,
      completedDate: _parseDateNullable(map['completedDate']),
      weeklyProgressHistory: List<double>.from(
        (map['weeklyProgressHistory'] ?? [60, 75, 80, 85, 90, 95, 92])
            .map((x) => (x as num).toDouble()),
      ),
      weightProgressHistory: List<double>.from(
        (map['weightProgressHistory'] ?? [75.0, 74.2, 73.8, 73.1, 72.5, 71.8, 71.0])
            .map((x) => (x as num).toDouble()),
      ),
      bmiTrendHistory: List<double>.from(
        (map['bmiTrendHistory'] ?? [25.1, 24.8, 24.6, 24.4, 24.2, 24.0, 23.8])
            .map((x) => (x as num).toDouble()),
      ),
      userAge: map['userAge']?.toInt() ?? 25,
      userGender: map['userGender'] ?? 'Male',
      userHeightCm: (map['userHeightCm'] as num?)?.toDouble() ?? 175.0,
      userFitnessLevel: map['userFitnessLevel'] ?? 'Intermediate',
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      availableWorkoutTimeMins: map['availableWorkoutTimeMins']?.toInt() ?? 45,
      currentActiveDayIndex: map['currentActiveDayIndex']?.toInt() ?? 0,
      totalWorkoutDaysCompleted: map['totalWorkoutDaysCompleted']?.toInt() ?? 0,
      totalCaloriesBurned: map['totalCaloriesBurned']?.toInt() ?? 0,
    );
  }
}
