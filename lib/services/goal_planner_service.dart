import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


import '../models/goal_plan_model.dart';
import '../models/user_model.dart';

/// Core AI Service for GymMate AI generating multi-day daily workout schedules
/// with embedded video metadata, biometric customization, medical filtering,
/// and PDF progress report export.
class GoalPlannerService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  static const String _spKeyActivePlan = 'gymmate_active_goal_plan';

  /// Generates a complete AI Goal Plan tailored to the user profile,
  /// selected goal (8 options), duration (14 to 180 days), level, and time constraint.
  GoalPlanModel generateAIPlan({
    required UserModel user,
    required String goalTitle,
    required String durationLabel,
    required int durationDays,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? fitnessLevel,
    List<String>? medicalConditions,
    int? availableWorkoutTimeMins,
  }) {
    final double weight = weightKg ?? user.weightKg ?? 70.0;
    final double height = heightCm ?? user.heightCm ?? 175.0;
    final int userAge = age ?? user.age ?? 25;
    final String userGender = gender ?? user.gender ?? 'Male';
    final String level = fitnessLevel ?? user.experienceLevel ?? 'Intermediate';
    final List<String> conditions = medicalConditions ?? user.medicalConditions;
    final int availableTime = availableWorkoutTimeMins ?? 45;

    final double bmi = weight / ((height / 100) * (height / 100));

    // Calculate Target Weight based on goal
    double targetWeight = weight;
    final lowerGoal = goalTitle.toLowerCase();
    if (lowerGoal.contains('loss') || lowerGoal.contains('fat')) {
      targetWeight = (weight - (durationDays * 0.10)).clamp(40.0, weight);
    } else if (lowerGoal.contains('gain') || lowerGoal.contains('muscle')) {
      targetWeight = (weight + (durationDays * 0.07)).clamp(weight, 120.0);
    } else if (lowerGoal.contains('six-pack')) {
      targetWeight = (weight - (durationDays * 0.06)).clamp(45.0, weight);
    }

    // Calculate Calorie & Macro Targets
    int calories = 2200;
    double protein = weight * 2.0;
    double carbs = weight * 3.0;
    double fat = weight * 0.9;
    double water = (weight * 35) / 1000 + 0.5;

    if (lowerGoal.contains('loss') || lowerGoal.contains('six-pack')) {
      calories = ((weight * 22) + 350).toInt();
      protein = weight * 2.2;
      carbs = weight * 2.0;
      fat = weight * 0.7;
      water += 0.5;
    } else if (lowerGoal.contains('gain') || lowerGoal.contains('muscle')) {
      calories = ((weight * 32) + 500).toInt();
      protein = weight * 2.4;
      carbs = weight * 4.5;
      fat = weight * 1.1;
    } else if (lowerGoal.contains('strength')) {
      calories = ((weight * 28) + 400).toInt();
      protein = weight * 2.3;
      carbs = weight * 3.5;
      fat = weight * 1.0;
    } else if (lowerGoal.contains('endurance')) {
      calories = ((weight * 30) + 400).toInt();
      protein = weight * 1.8;
      carbs = weight * 5.0;
      fat = weight * 0.8;
      water += 1.0;
    } else if (lowerGoal.contains('flexibility')) {
      calories = (weight * 24).toInt();
      protein = weight * 1.6;
      carbs = weight * 3.0;
      fat = weight * 0.8;
    }

    // Generate procedural Day 1 to Day N schedules (14, 30, 60, 90, 180 days)
    final List<DailyWorkoutSchedule> workoutDays = _generateMultiDayWorkouts(
      goalTitle: goalTitle,
      durationDays: durationDays,
      level: level,
      conditions: conditions,
      availableTimeMins: availableTime,
    );

    // Build AI Meals
    final List<MealPlanItem> meals = _generateMealPlan(goalTitle, calories, protein, carbs, fat);

    final now = DateTime.now();
    final endDate = now.add(Duration(days: durationDays));

    // Generate historical trends for graphs
    List<double> weightHist = [];
    List<double> bmiHist = [];
    double stepW = (weight - targetWeight) / 7;
    for (int i = 7; i >= 0; i--) {
      double w = weight + (stepW * i);
      weightHist.add(double.parse(w.toStringAsFixed(1)));
      double b = w / ((height / 100) * (height / 100));
      bmiHist.add(double.parse(b.toStringAsFixed(1)));
    }

    return GoalPlanModel(
      id: 'plan_$now.millisecondsSinceEpoch',
      userId: user.uid,
      goalTitle: goalTitle,
      durationLabel: durationLabel,
      durationDays: durationDays,
      startDate: now,
      targetCompletionDate: endDate,
      startingWeight: weight,
      currentWeight: weight,
      targetWeight: double.parse(targetWeight.toStringAsFixed(1)),
      startingBmi: double.parse(bmi.toStringAsFixed(1)),
      currentBmi: double.parse(bmi.toStringAsFixed(1)),
      dailyCalorieTarget: calories,
      dailyProteinTarget: double.parse(protein.toStringAsFixed(1)),
      dailyCarbsTarget: double.parse(carbs.toStringAsFixed(1)),
      dailyFatTarget: double.parse(fat.toStringAsFixed(1)),
      dailyWaterTargetLiters: double.parse(water.toStringAsFixed(1)),
      dailySleepTargetHours: 8.0,
      dailyStepsTarget: lowerGoal.contains('endurance') || lowerGoal.contains('loss') ? 10000 : 8000,
      workoutDays: workoutDays,
      meals: meals,
      tracker: DailyTrackerLog(
        dateString: now.toIso8601String().split('T').first,
        waterIntakeLiters: 1.5,
        sleepHours: 7.5,
        stepsWalked: 4500,
      ),
      workoutStreak: 1,
      workoutConsistency: 0.90,
      dietConsistency: 0.88,
      unlockedBadges: ['Goal Starter', 'Day 1 Champion'],
      weeklyProgressHistory: [65.0, 72.0, 78.0, 85.0, 90.0, 94.0, 92.0],
      weightProgressHistory: weightHist,
      bmiTrendHistory: bmiHist,
      userAge: userAge,
      userGender: userGender,
      userHeightCm: height,
      userFitnessLevel: level,
      medicalConditions: conditions,
      availableWorkoutTimeMins: availableTime,
      currentActiveDayIndex: 0,
      totalWorkoutDaysCompleted: 0,
      totalCaloriesBurned: 0,
    );
  }

  /// Master AI exercise library with demo video links, thumbnails, instructions, common mistakes, and safety tips
  static final List<WorkoutExercise> _exerciseMasterDatabase = [
    // Warm-up Exercises
    WorkoutExercise(
      id: 'ex_warm_jacks',
      name: 'Jumping Jacks',
      sets: 2,
      reps: '2 Minutes',
      restSeconds: 30,
      caloriesBurned: 45,
      difficulty: 'Beginner',
      category: 'Warm-up',
      targetMuscle: 'Full Body',
      durationMins: 2,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=iSSAk4Xo83c',
      instructions: [
        'Stand upright with legs together and arms at sides.',
        'Bend knees slightly and jump into the air.',
        'Spread legs shoulder-width apart and extend arms overhead.',
        'Land softly and jump back to starting position.'
      ],
      commonMistakes: ['Landing heavily on heels', 'Bending elbows excessively', 'Holding breath'],
      safetyTips: ['Keep core engaged and land softly on the balls of your feet to protect knees.'],
    ),
    WorkoutExercise(
      id: 'ex_warm_knees',
      name: 'High Knees',
      sets: 2,
      reps: '60 Seconds',
      restSeconds: 30,
      caloriesBurned: 50,
      difficulty: 'Beginner',
      category: 'Warm-up',
      targetMuscle: 'Legs & Core',
      durationMins: 2,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=oDdkytliOqE',
      instructions: [
        'Stand tall with feet hip-width apart.',
        'Lift right knee up toward chest as high as possible while driving left arm forward.',
        'Switch quickly to raise left knee up while driving right arm forward.',
        'Maintain a quick, continuous cadence.'
      ],
      commonMistakes: ['Leaning backward during movement', 'Not raising knees to waist level'],
      safetyTips: ['Maintain upright posture and land softly.'],
    ),
    WorkoutExercise(
      id: 'ex_warm_arm_curls',
      name: 'Arm Circles & Shoulder Rolls',
      sets: 2,
      reps: '45 Seconds',
      restSeconds: 20,
      caloriesBurned: 25,
      difficulty: 'Beginner',
      category: 'Warm-up',
      targetMuscle: 'Shoulders',
      durationMins: 2,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=L9x_NkWYf6w',
      instructions: [
        'Extend arms out to sides at shoulder height.',
        'Make small clockwise circles with arms for 20 seconds.',
        'Reverse direction for counter-clockwise circles for 20 seconds.'
      ],
      commonMistakes: ['Shrugging shoulders up to ears'],
      safetyTips: ['Keep movement smooth and controlled.'],
    ),

    // Main Workout Exercises
    WorkoutExercise(
      id: 'ex_pushups',
      name: 'Standard Push-ups',
      sets: 3,
      reps: '12 Reps',
      restSeconds: 60,
      caloriesBurned: 90,
      difficulty: 'Intermediate',
      category: 'Chest',
      targetMuscle: 'Chest & Triceps',
      durationMins: 4,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=IODxDxX7oi4',
      instructions: [
        'Place hands slightly wider than shoulder-width apart on the floor.',
        'Lower body until chest almost touches the floor.',
        'Pause, then push back up to starting position while squeezing chest.'
      ],
      commonMistakes: ['Sagging lower back', 'Flaring elbows out to 90 degrees'],
      safetyTips: ['Keep core and glutes tight to maintain a straight spine.'],
    ),
    WorkoutExercise(
      id: 'ex_squats',
      name: 'Bodyweight Squats',
      sets: 3,
      reps: '15 Reps',
      restSeconds: 60,
      caloriesBurned: 105,
      difficulty: 'Beginner',
      category: 'Legs',
      targetMuscle: 'Quads & Glutes',
      durationMins: 5,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=aclHkVaku9U',
      instructions: [
        'Stand with feet shoulder-width apart, toes pointing slightly outward.',
        'Inhale and hinge hips back while bending knees to lower into a squat.',
        'Lower until thighs are parallel to the floor.',
        'Press through heels to stand back up.'
      ],
      commonMistakes: ['Knees caving inward', 'Lifting heels off the floor'],
      safetyTips: ['Keep chest up and weight distributed across entire foot.'],
    ),
    WorkoutExercise(
      id: 'ex_climbers',
      name: 'Mountain Climbers',
      sets: 3,
      reps: '20 Reps',
      restSeconds: 45,
      caloriesBurned: 110,
      difficulty: 'Intermediate',
      category: 'HIIT',
      targetMuscle: 'Core & Cardio',
      durationMins: 4,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=nmwgirgXLYM',
      instructions: [
        'Start in a high plank position with shoulders directly above wrists.',
        'Drive right knee forward toward chest without letting hips bounce.',
        'Switch quickly, driving left knee in while extending right leg back.',
        'Continue alternating at a fast pace.'
      ],
      commonMistakes: ['Hiking hips up high', 'Resting on back foot'],
      safetyTips: ['Keep hips level with shoulders and gaze focused slightly ahead of hands.'],
    ),
    WorkoutExercise(
      id: 'ex_plank',
      name: 'Plank Hold',
      sets: 3,
      reps: '60 Seconds',
      restSeconds: 45,
      caloriesBurned: 80,
      difficulty: 'Beginner',
      category: 'Core',
      targetMuscle: 'Abs & Lumbar',
      durationMins: 3,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=pSHjTRCQxIw',
      instructions: [
        'Place forearms on the floor with elbows directly under shoulders.',
        'Extend legs back, standing on toes with feet hip-width apart.',
        'Contract abs, glutes, and quads to keep body in a straight line.',
        'Hold position without letting hips sag or pike.'
      ],
      commonMistakes: ['Sinking lower back', 'Tilting head up'],
      safetyTips: ['Breathe steadily throughout the hold and maintain neutral neck alignment.'],
    ),
    WorkoutExercise(
      id: 'ex_burpees',
      name: 'Burpees',
      sets: 3,
      reps: '12 Reps',
      restSeconds: 60,
      caloriesBurned: 140,
      difficulty: 'Advanced',
      category: 'HIIT',
      targetMuscle: 'Full Body Cardio',
      durationMins: 5,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=dZgVxmf6jkA',
      instructions: [
        'Stand tall, then drop into a squat and place hands on the floor.',
        'Kick feet back into a plank position.',
        'Perform a push-up, then jump feet back toward hands.',
        'Explode upward into a jump with hands overhead.'
      ],
      commonMistakes: ['Arching spine during plank drop', 'Landing heavily'],
      safetyTips: ['Land softly on feet with knees slightly bent.'],
    ),
    WorkoutExercise(
      id: 'ex_crunches',
      name: 'Abdominal Crunches',
      sets: 3,
      reps: '20 Reps',
      restSeconds: 45,
      caloriesBurned: 75,
      difficulty: 'Beginner',
      category: 'Core',
      targetMuscle: 'Upper Abs',
      durationMins: 4,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=Xyd_fa5zoEU',
      instructions: [
        'Lie on back with knees bent and feet flat on the floor.',
        'Place fingertips gently behind head or cross hands over chest.',
        'Contract abs to lift shoulder blades 2-3 inches off floor.',
        'Exhale at peak squeeze, then lower slowly.'
      ],
      commonMistakes: ['Pulling neck forward with hands', 'Using momentum'],
      safetyTips: ['Focus on flexing upper abs rather than pulling the head.'],
    ),
    WorkoutExercise(
      id: 'ex_russian_twist',
      name: 'Russian Twists',
      sets: 3,
      reps: '25 Reps',
      restSeconds: 45,
      caloriesBurned: 95,
      difficulty: 'Intermediate',
      category: 'Core',
      targetMuscle: 'Obliques',
      durationMins: 4,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=wkD8rjkodUI',
      instructions: [
        'Sit on floor with knees bent and feet lifted slightly off ground.',
        'Lean torso back slightly at a 45-degree angle.',
        'Clasp hands together and rotate torso from side to side.',
        'Touch hands to floor on each side.'
      ],
      commonMistakes: ['Rounding back excessively', 'Moving arms without rotating torso'],
      safetyTips: ['Keep spine long and twist from ribcage.'],
    ),
    WorkoutExercise(
      id: 'ex_lunges',
      name: 'Walking Lunges',
      sets: 3,
      reps: '16 Reps',
      restSeconds: 60,
      caloriesBurned: 110,
      difficulty: 'Intermediate',
      category: 'Legs',
      targetMuscle: 'Quads & Glutes',
      durationMins: 5,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1434682881908-b43d0467b798?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=L8fvypPrzzs',
      instructions: [
        'Step forward with right foot and lower hips until both knees are bent at 90 degrees.',
        'Ensure front knee is directly above ankle.',
        'Push off right foot to step forward into next lunge with left foot.'
      ],
      commonMistakes: ['Front knee extending past toes', 'Torso leaning forward'],
      safetyTips: ['Keep torso upright and core engaged throughout step.'],
    ),

    // Cooldown Exercises
    WorkoutExercise(
      id: 'ex_cool_stretch',
      name: 'Full Body Stretching & Cobra Pose',
      sets: 2,
      reps: '60 Seconds Hold',
      restSeconds: 30,
      caloriesBurned: 30,
      difficulty: 'Beginner',
      category: 'Cooldown',
      targetMuscle: 'Abs, Lower Back & Hamstrings',
      durationMins: 3,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=g_tea8ZNk5A',
      instructions: [
        'Lie face down on mat with hands under shoulders.',
        'Gently press palms down to lift chest off floor while keeping hips grounded.',
        'Hold stretch for 30 seconds while breathing deeply.',
        'Release and transition into Child Pose stretch.'
      ],
      commonMistakes: ['Forcing spine into uncomfortable arch', 'Holding breath'],
      safetyTips: ['Keep shoulders away from ears and breathe into abdomen.'],
    ),
    WorkoutExercise(
      id: 'ex_cool_childpose',
      name: 'Child Pose Stretch',
      sets: 1,
      reps: '90 Seconds Hold',
      restSeconds: 0,
      caloriesBurned: 20,
      difficulty: 'Beginner',
      category: 'Cooldown',
      targetMuscle: 'Back & Hips',
      durationMins: 3,
      hdThumbnailUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=600&q=80',
      videoUrl: 'https://www.youtube.com/watch?v=2MJGgKtpxZk',
      instructions: [
        'Kneel on mat with big toes touching and knees wide apart.',
        'Sit hips back onto heels while folding torso forward over thighs.',
        'Extend arms forward on mat and rest forehead on ground.'
      ],
      commonMistakes: ['Tensing shoulders'],
      safetyTips: ['Relax all muscle tension and focus on slow diaphragm breathing.'],
    ),
  ];

  /// Dynamically generates day-by-day workout routines for Day 1 to Day N (14, 30, 60, 90, 180 days).
  List<DailyWorkoutSchedule> _generateMultiDayWorkouts({
    required String goalTitle,
    required int durationDays,
    required String level,
    required List<String> conditions,
    required int availableTimeMins,
  }) {
    final lowerGoal = goalTitle.toLowerCase();
    final List<DailyWorkoutSchedule> schedules = [];

    // Focus rotation cycles
    final List<String> focusAreas = lowerGoal.contains('six-pack')
        ? ['Core & Upper Abs', 'Obliques & Lower Abs', 'Cardio Core Blast', 'Active Recovery', 'Full Core Shred', 'Plank & Stability']
        : lowerGoal.contains('muscle') || lowerGoal.contains('gain')
            ? ['Chest & Triceps', 'Back & Biceps', 'Legs & Calves', 'Shoulders & Abs', 'Active Recovery', 'Full Body Power']
            : lowerGoal.contains('loss') || lowerGoal.contains('endurance')
                ? ['HIIT & Fat Burn', 'Cardio & Abs', 'Lower Body Sculpt', 'Active Recovery', 'Upper Body Shred', 'Total Body Conditioning']
                : ['Full Body Conditioning', 'Core & Mobility', 'Strength & Resistance', 'Active Recovery', 'Cardio Blast', 'Flexibility Flow'];

    for (int dayNum = 1; dayNum <= durationDays; dayNum++) {
      final isRest = (dayNum % 5 == 0) || (dayNum % 7 == 0);
      final focusIndex = (dayNum - 1) % focusAreas.length;
      final focus = isRest ? 'Active Recovery & Stretching' : focusAreas[focusIndex];

      // Select exercises filtered by medical conditions & available time
      final warmups = _selectWarmups(availableTimeMins, dayNum);
      final workouts = isRest
          ? _selectRestExercises(dayNum)
          : _selectWorkoutsForDay(dayNum, goalTitle, level, conditions, availableTimeMins);
      final cooldowns = _selectCooldowns(dayNum);

      schedules.add(DailyWorkoutSchedule(
        dayNumber: dayNum,
        dayName: 'Day $dayNum',
        focusArea: focus,
        isRestDay: isRest,
        warmupExercises: warmups,
        workoutExercises: workouts,
        cooldownExercises: cooldowns,
        isCompleted: false,
      ));
    }

    return schedules;
  }

  List<WorkoutExercise> _selectWarmups(int availableTimeMins, int dayNum) {
    if (availableTimeMins <= 15) {
      return [_exerciseMasterDatabase[0].copyWith(id: 'day_${dayNum}_warmup_0')]; // Jumping Jacks
    }
    return [
      _exerciseMasterDatabase[0].copyWith(id: 'day_${dayNum}_warmup_0'), 
      _exerciseMasterDatabase[1].copyWith(id: 'day_${dayNum}_warmup_1')
    ]; // Jacks + High Knees
  }

  List<WorkoutExercise> _selectWorkoutsForDay(
    int dayNum,
    String goalTitle,
    String level,
    List<String> conditions,
    int timeMins,
  ) {
    List<WorkoutExercise> pool = [
      _exerciseMasterDatabase[3], // Pushups
      _exerciseMasterDatabase[4], // Squats
      _exerciseMasterDatabase[5], // Climbers
      _exerciseMasterDatabase[6], // Plank
      _exerciseMasterDatabase[7], // Burpees
      _exerciseMasterDatabase[8], // Crunches
      _exerciseMasterDatabase[9], // Russian Twist
      _exerciseMasterDatabase[10], // Lunges
    ];

    // Medical safety filtering
    if (conditions.contains('Joint Pain')) {
      pool.removeWhere((e) => e.name == 'Burpees' || e.name == 'Mountain Climbers');
    }
    if (conditions.contains('Lower Back Pain')) {
      pool.removeWhere((e) => e.name == 'Russian Twists');
    }

    // Progression scaling: boost sets/reps as dayNum increases
    int extraSets = (dayNum / 10).floor().clamp(0, 2);

    int maxExercises = 3;
    if (timeMins >= 30) maxExercises = 4;
    if (timeMins >= 45) maxExercises = 5;
    if (timeMins >= 60) maxExercises = 6;
    if (timeMins >= 90) maxExercises = 8;

    // Rotate exercise selection based on dayNum so every day is distinct
    List<WorkoutExercise> result = [];
    for (int i = 0; i < maxExercises; i++) {
      final index = (dayNum + i) % pool.length;
      final baseEx = pool[index];
      result.add(baseEx.copyWith(
        id: 'day_${dayNum}_ex_$i',
        sets: baseEx.sets + extraSets,
      ));
    }

    return result;
  }

  List<WorkoutExercise> _selectRestExercises(int dayNum) {
    return [
      _exerciseMasterDatabase[6].copyWith(id: 'day_${dayNum}_rest_0'), // Plank
      _exerciseMasterDatabase[11].copyWith(id: 'day_${dayNum}_rest_1'), // Stretch
    ];
  }

  List<WorkoutExercise> _selectCooldowns(int dayNum) {
    return [
      _exerciseMasterDatabase[11].copyWith(id: 'day_${dayNum}_cool_0'), 
      _exerciseMasterDatabase[12].copyWith(id: 'day_${dayNum}_cool_1')
    ];
  }

  /// Generates dynamic meal plan with macronutrients
  List<MealPlanItem> _generateMealPlan(String goalTitle, int targetCalories, double protein, double carbs, double fat) {
    final lowerGoal = goalTitle.toLowerCase();

    if (lowerGoal.contains('loss') || lowerGoal.contains('six-pack')) {
      return [
        MealPlanItem(
          id: 'meal_b',
          mealType: 'Breakfast',
          foodName: 'Egg White Omelet with Spinach & Oats',
          calories: (targetCalories * 0.25).round(),
          proteinGrams: (protein * 0.30),
          carbsGrams: (carbs * 0.25),
          fatGrams: (fat * 0.20),
          waterRecommendationLiters: 0.8,
        ),
        MealPlanItem(
          id: 'meal_l',
          mealType: 'Lunch',
          foodName: 'Grilled Chicken Breast with Quinoa & Steamed Broccoli',
          calories: (targetCalories * 0.35).round(),
          proteinGrams: (protein * 0.35),
          carbsGrams: (carbs * 0.35),
          fatGrams: (fat * 0.35),
          waterRecommendationLiters: 1.0,
        ),
        MealPlanItem(
          id: 'meal_s',
          mealType: 'Evening Snack',
          foodName: 'Greek Yogurt with Almonds & Berries',
          calories: (targetCalories * 0.15).round(),
          proteinGrams: (protein * 0.15),
          carbsGrams: (carbs * 0.15),
          fatGrams: (fat * 0.20),
          waterRecommendationLiters: 0.5,
        ),
        MealPlanItem(
          id: 'meal_d',
          mealType: 'Dinner',
          foodName: 'Baked Salmon Fillet with Asparagus & Garden Salad',
          calories: (targetCalories * 0.25).round(),
          proteinGrams: (protein * 0.20),
          carbsGrams: (carbs * 0.25),
          fatGrams: (fat * 0.25),
          waterRecommendationLiters: 0.7,
        ),
      ];
    } else {
      return [
        MealPlanItem(
          id: 'meal_b',
          mealType: 'Breakfast',
          foodName: 'Protein Oatmeal with Banana, Peanut Butter & Chia Seeds',
          calories: (targetCalories * 0.28).round(),
          proteinGrams: (protein * 0.25),
          carbsGrams: (carbs * 0.30),
          fatGrams: (fat * 0.25),
          waterRecommendationLiters: 0.8,
        ),
        MealPlanItem(
          id: 'meal_l',
          mealType: 'Lunch',
          foodName: 'Lean Beef / Tofu Bowl with Brown Rice & Avocado',
          calories: (targetCalories * 0.36).round(),
          proteinGrams: (protein * 0.35),
          carbsGrams: (carbs * 0.35),
          fatGrams: (fat * 0.35),
          waterRecommendationLiters: 1.0,
        ),
        MealPlanItem(
          id: 'meal_s',
          mealType: 'Evening Snack',
          foodName: 'Whey Protein Shake & Rice Cakes with Honey',
          calories: (targetCalories * 0.14).round(),
          proteinGrams: (protein * 0.20),
          carbsGrams: (carbs * 0.15),
          fatGrams: (fat * 0.15),
          waterRecommendationLiters: 0.6,
        ),
        MealPlanItem(
          id: 'meal_d',
          mealType: 'Dinner',
          foodName: 'Grilled Turkey / Cottage Cheese Steak with Sweet Potato',
          calories: (targetCalories * 0.22).round(),
          proteinGrams: (protein * 0.20),
          carbsGrams: (carbs * 0.20),
          fatGrams: (fat * 0.25),
          waterRecommendationLiters: 0.8,
        ),
      ];
    }
  }

  Future<void> saveGoalPlan(GoalPlanModel plan) async {
    try {
      final jsonMap = plan.toMap();
      final prefs = await SharedPreferences.getInstance();
      final spKey = plan.userId.isNotEmpty ? '${_spKeyActivePlan}_${plan.userId}' : _spKeyActivePlan;
      await prefs.setString(spKey, jsonEncode(jsonMap));

      if (plan.userId.isNotEmpty) {
        await _db
            .collection('users')
            .doc(plan.userId)
            .collection('goal_plans')
            .doc('active_plan')
            .set(jsonMap, SetOptions(merge: true));

        // Also update the main user document to reflect progress
        await _db.collection('users').doc(plan.userId).set({
          'completedDaysCount': plan.totalWorkoutDaysCompleted,
          'currentWorkoutDay': plan.currentActiveDayIndex + 1,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      // Fallback silently if offline or unauthenticated Firestore
    }
  }

  /// Alias for saving active plan with optional uid parameter override
  Future<void> saveActiveGoalPlan(GoalPlanModel plan, {String? uid}) async {
    final updatedPlan = uid != null && uid.isNotEmpty ? plan.copyWith(userId: uid) : plan;
    await saveGoalPlan(updatedPlan);
  }

  /// Loads active plan from SharedPreferences or Firestore
  Future<GoalPlanModel?> getActiveGoalPlan(String userId) async {
    final spKey = userId.isNotEmpty ? '${_spKeyActivePlan}_$userId' : _spKeyActivePlan;
    
    try {
      if (userId.isNotEmpty) {
        final doc = await _db
            .collection('users')
            .doc(userId)
            .collection('goal_plans')
            .doc('active_plan')
            .get();
        if (doc.exists && doc.data() != null) {
          final plan = GoalPlanModel.fromMap(doc.data()!);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(spKey, jsonEncode(plan.toMap()));
          return plan;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(spKey);
      if (localJson != null) {
        return GoalPlanModel.fromMap(jsonDecode(localJson));
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString(spKey);
      if (localJson != null) {
        return GoalPlanModel.fromMap(jsonDecode(localJson));
      }
    }
    return null;
  }

  /// Alias for loading active goal plan with optional uid
  Future<GoalPlanModel?> loadActiveGoalPlan({String? uid}) async {
    return getActiveGoalPlan(uid ?? '');
  }

  /// Synchronously load local active plan fallback
  GoalPlanModel? loadLocalActiveGoalPlan() {
    return null; // Will trigger async load in UI
  }

  /// Streams active plan live from Firestore
  Stream<GoalPlanModel?> streamActiveGoalPlan(String userId) {
    if (userId.isEmpty) {
      return Stream.value(null);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('goal_plans')
        .doc('active_plan')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GoalPlanModel.fromMap(doc.data()!);
    });
  }

  /// Generates and exports a PDF Progress Report for Goal Completion
  Future<Uint8List> generateProgressReportPdf(GoalPlanModel plan) async {
    final pdf = pw.Document();

    final fontBold = pw.Font.helveticaBold();
    final fontNormal = pw.Font.helvetica();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey900,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'GYMMATE AI - GOAL PROGRESS REPORT',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColors.cyan300,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Goal: ${plan.goalTitle.toUpperCase()} ($plan.durationLabel)',
                            style: pw.TextStyle(
                              font: fontNormal,
                              fontSize: 12,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                      pw.Text(
                        'STATUS: ${plan.isCompleted ? "COMPLETED" : "IN PROGRESS"}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 12,
                          color: plan.isCompleted ? PdfColors.green300 : PdfColors.amber300,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Transformation Summary
                pw.Text(
                  'Transformation & Biometric Summary',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.black),
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfMetricItem('Starting Weight', '${plan.startingWeight} kg', fontNormal, fontBold),
                    _pdfMetricItem('Current Weight', '${plan.currentWeight} kg', fontNormal, fontBold),
                    _pdfMetricItem('Target Weight', '${plan.targetWeight} kg', fontNormal, fontBold),
                    _pdfMetricItem('Weight Change', '${(plan.currentWeight - plan.startingWeight).toStringAsFixed(1)} kg', fontNormal, fontBold),
                  ],
                ),
                pw.SizedBox(height: 16),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfMetricItem('Starting BMI', '${plan.startingBmi}', fontNormal, fontBold),
                    _pdfMetricItem('Current BMI', '${plan.currentBmi}', fontNormal, fontBold),
                    _pdfMetricItem('Workout Days', '${plan.completedDays} / $plan.durationDays', fontNormal, fontBold),
                    _pdfMetricItem('Workout Streak', '${plan.workoutStreak} Days', fontNormal, fontBold),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Unlocked Badges
                pw.Text(
                  'Unlocked Badges & Milestones',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.black),
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: plan.unlockedBadges.map((badge) {
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.cyan100,
                        borderRadius: pw.BorderRadius.circular(16),
                      ),
                      child: pw.Text(
                        '🏆 $badge',
                        style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.blueGrey900),
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 24),

                // Daily Blueprint
                pw.Text(
                  'Daily Nutritional & Activity Blueprint',
                  style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.black),
                ),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfMetricItem('Daily Calories', '${plan.dailyCalorieTarget} kcal', fontNormal, fontBold),
                    _pdfMetricItem('Protein', '${plan.dailyProteinTarget} g', fontNormal, fontBold),
                    _pdfMetricItem('Carbohydrates', '${plan.dailyCarbsTarget} g', fontNormal, fontBold),
                    _pdfMetricItem('Healthy Fat', '${plan.dailyFatTarget} g', fontNormal, fontBold),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Footer
                pw.Spacer(),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Generated by GymMate AI - Personalized Goal Planner with Demo Videos',
                    style: pw.TextStyle(font: fontNormal, fontSize: 9, color: PdfColors.grey600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfMetricItem(String title, String value, pw.Font fontNormal, pw.Font fontBold) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontNormal, fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.blueGrey900)),
        ],
      ),
    );
  }
}
