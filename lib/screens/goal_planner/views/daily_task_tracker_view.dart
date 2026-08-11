import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../../models/goal_plan_model.dart';

class DailyTaskTrackerView extends StatelessWidget {
  final GoalPlanModel plan;
  final Function(GoalPlanModel updatedPlan) onPlanUpdated;

  const DailyTaskTrackerView({
    super.key,
    required this.plan,
    required this.onPlanUpdated,
  });

  void _toggleExercise(WorkoutExercise ex) {
    final currentIds = List<String>.from(plan.tracker.completedExerciseIds);
    if (currentIds.contains(ex.id)) {
      currentIds.remove(ex.id);
    } else {
      currentIds.add(ex.id);
    }

    final newTracker = plan.tracker.copyWith(completedExerciseIds: currentIds);
    
    final days = List<DailyWorkoutSchedule>.from(plan.workoutDays);
    final activeIndex = plan.currentActiveDayIndex.clamp(0, days.length - 1);
    
    // Check if the current active day is now fully completed
    final currentDaySchedule = days[activeIndex];
    final isAllDayExercisesDone = currentDaySchedule.exercises.every((e) => currentIds.contains(e.id));
    
    if (isAllDayExercisesDone) {
      days[activeIndex] = days[activeIndex].copyWith(
        isCompleted: true,
        isInProgress: false,
        completionDate: DateTime.now(),
      );
    } else {
      final someDone = currentDaySchedule.exercises.any((e) => currentIds.contains(e.id));
      if (someDone && !days[activeIndex].isCompleted) {
        days[activeIndex] = days[activeIndex].copyWith(isInProgress: true);
      } else if (!someDone) {
        days[activeIndex] = days[activeIndex].copyWith(isInProgress: false);
      }
    }

    int nextActiveDay = plan.currentActiveDayIndex;
    int completedCount = plan.totalWorkoutDaysCompleted;
    int streak = plan.workoutStreak;
    int calories = plan.totalCaloriesBurned;

    if (isAllDayExercisesDone && !plan.workoutDays[activeIndex].isCompleted) {
      completedCount++;
      streak++;
      calories += currentDaySchedule.totalCalories;
      Fluttertoast.showToast(
        msg: "🎉 Today's workout complete!",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.black,
      );
      if (activeIndex + 1 < days.length) {
        nextActiveDay = activeIndex + 1;
      }
    }

    final updated = plan.copyWith(
      tracker: newTracker,
      workoutDays: days,
      currentActiveDayIndex: nextActiveDay,
      totalWorkoutDaysCompleted: completedCount,
      workoutStreak: streak,
      totalCaloriesBurned: calories,
    );
    onPlanUpdated(updated);
  }

  void _toggleMeal(MealPlanItem meal) {
    final currentIds = List<String>.from(plan.tracker.completedMealIds);
    if (currentIds.contains(meal.id)) {
      currentIds.remove(meal.id);
    } else {
      currentIds.add(meal.id);
    }

    final newTracker = plan.tracker.copyWith(completedMealIds: currentIds);
    final updated = plan.copyWith(tracker: newTracker);
    onPlanUpdated(updated);
  }

  void _updateWater(double delta) {
    double newWater = (plan.tracker.waterIntakeLiters + delta).clamp(0.0, 10.0);
    newWater = double.parse(newWater.toStringAsFixed(1));

    final newTracker = plan.tracker.copyWith(waterIntakeLiters: newWater);
    final updated = plan.copyWith(tracker: newTracker);
    onPlanUpdated(updated);
  }

  void _updateSleep(double delta) {
    double newSleep = (plan.tracker.sleepHours + delta).clamp(0.0, 16.0);
    newSleep = double.parse(newSleep.toStringAsFixed(1));

    final newTracker = plan.tracker.copyWith(sleepHours: newSleep);
    final updated = plan.copyWith(tracker: newTracker);
    onPlanUpdated(updated);
  }

  void _updateSteps(int delta) {
    int newSteps = (plan.tracker.stepsWalked + delta).clamp(0, 50000);

    final newTracker = plan.tracker.copyWith(stepsWalked: newSteps);
    final updated = plan.copyWith(tracker: newTracker);
    onPlanUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final todayCompletion = plan.todayCompletionPercentage;
    final activeIndex = plan.currentActiveDayIndex.clamp(0, plan.workoutDays.length - 1);
    final currentWorkouts = plan.workoutDays.isNotEmpty
        ? plan.workoutDays[activeIndex].exercises
        : <WorkoutExercise>[];

    return Container(
      color: const Color(0xFF0D0F17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          // Header Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF00E5FF),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Task Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Check off activities to track your live completion %',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Live Progress Bar Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF192338),
                  Color(0xFF141724),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${todayCompletion.toInt()}% Completed',
                      style: const TextStyle(
                        color: Color(0xFF76FF03),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearPercentIndicator(
                  lineHeight: 12.0,
                  percent: (todayCompletion / 100).clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 400,
                  barRadius: const Radius.circular(8),
                  progressColor: const Color(0xFF76FF03),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Workout Checklist Section
          const Text(
            'Workout Checklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...currentWorkouts.map((ex) {
            final isDone = plan.tracker.completedExerciseIds.contains(ex.id);
            return _checkTile(
              title: ex.name,
              subtitle: '${ex.sets} Sets • $ex.reps • $ex.caloriesBurned kcal',
              icon: Icons.fitness_center_rounded,
              isCompleted: isDone,
              onTap: () => _toggleExercise(ex),
            );
          }),
          const SizedBox(height: 20),

          // Meal Checklist Section
          const Text(
            'Meal Checklist',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...plan.meals.map((meal) {
            final isDone = plan.tracker.completedMealIds.contains(meal.id);
            return _checkTile(
              title: '${meal.mealType}: $meal.foodName',
              subtitle: '${meal.calories} kcal • P: ${meal.proteinGrams.toInt()}g, C: ${meal.carbsGrams.toInt()}g, F: ${meal.fatGrams.toInt()}g',
              icon: Icons.restaurant_rounded,
              isCompleted: isDone,
              onTap: () => _toggleMeal(meal),
            );
          }),
          const SizedBox(height: 20),

          // Trackers Section: Water, Sleep, Steps
          const Text(
            'Daily Trackers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Water Intake Counter
          _trackerCard(
            title: 'Water Intake',
            valueText: '${plan.tracker.waterIntakeLiters} / $plan.dailyWaterTargetLiters L',
            percent: (plan.tracker.waterIntakeLiters / plan.dailyWaterTargetLiters).clamp(0.0, 1.0),
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF40C4FF),
            onDecrement: () => _updateWater(-0.25),
            onIncrement: () => _updateWater(0.25),
          ),
          const SizedBox(height: 12),

          // Sleep Tracker Counter
          _trackerCard(
            title: 'Sleep Tracker',
            valueText: '${plan.tracker.sleepHours} / $plan.dailySleepTargetHours Hours',
            percent: (plan.tracker.sleepHours / plan.dailySleepTargetHours).clamp(0.0, 1.0),
            icon: Icons.bedtime_rounded,
            color: const Color(0xFFE040FB),
            onDecrement: () => _updateSleep(-0.5),
            onIncrement: () => _updateSleep(0.5),
          ),
          const SizedBox(height: 12),

          // Step Counter
          _trackerCard(
            title: 'Step Counter',
            valueText: '${plan.tracker.stepsWalked} / $plan.dailyStepsTarget Steps',
            percent: (plan.tracker.stepsWalked / plan.dailyStepsTarget).clamp(0.0, 1.0),
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF76FF03),
            onDecrement: () => _updateSteps(-500),
            onIncrement: () => _updateSteps(500),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _checkTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF192434) : const Color(0xFF141724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? const Color(0xFF76FF03) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF76FF03) : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF76FF03) : Colors.grey.shade500,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isCompleted ? Colors.white : Colors.grey.shade200,
                        fontSize: 15,
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.w600,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                icon,
                color: isCompleted ? const Color(0xFF76FF03) : Colors.grey.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trackerCard({
    required String title,
    required String valueText,
    required double percent,
    required IconData icon,
    required Color color,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              Text(
                valueText,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percent,
            barRadius: const Radius.circular(6),
            progressColor: color,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_circle_outline, color: Colors.grey, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: Icon(Icons.add_circle_outline, color: color, size: 22),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
