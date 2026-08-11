import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../models/goal_plan_model.dart';

class DailyProgressDashboardView extends StatelessWidget {
  final GoalPlanModel plan;

  const DailyProgressDashboardView({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final tracker = plan.tracker;
    final totalWorkoutTasks = plan.workoutDays.isNotEmpty
        ? plan.workoutDays.first.exercises.length
        : 1;
    final completedWorkouts = tracker.completedExerciseIds.length;
    final workoutPct = (completedWorkouts / totalWorkoutTasks * 100).clamp(0.0, 100.0);

    final totalMealTasks = plan.meals.isNotEmpty ? plan.meals.length : 1;
    final completedMeals = tracker.completedMealIds.length;
    final dietPct = (completedMeals / totalMealTasks * 100).clamp(0.0, 100.0);

    // Calories Burned from completed exercises
    int caloriesBurned = 0;
    if (plan.workoutDays.isNotEmpty) {
      for (var ex in plan.workoutDays.first.exercises) {
        if (tracker.completedExerciseIds.contains(ex.id)) {
          caloriesBurned += ex.caloriesBurned;
        }
      }
    }

    // Calories Consumed from completed meals
    int caloriesConsumed = 0;
    for (var m in plan.meals) {
      if (tracker.completedMealIds.contains(m.id)) {
        caloriesConsumed += m.calories;
      }
    }

    final overallPct = plan.todayCompletionPercentage;

    return Container(
      color: const Color(0xFF0D0F17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF76FF03).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Color(0xFF76FF03),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Progress Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Real-time metrics for today\'s performance',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Overall Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF192338),
                  Color(0xFF141724),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                CircularPercentIndicator(
                  radius: 50.0,
                  lineWidth: 10.0,
                  animation: true,
                  percent: (overallPct / 100).clamp(0.0, 1.0),
                  center: Text(
                    '${overallPct.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  circularStrokeCap: CircularStrokeCap.round,
                  progressColor: const Color(0xFF76FF03),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Daily Progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$completedWorkouts/$totalWorkoutTasks Workouts • $completedMeals/$totalMealTasks Meals Logged',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2x2 Grid for Workouts & Diet Completion
          Row(
            children: [
              Expanded(
                child: _dashboardStatCard(
                  title: 'Workout Completion',
                  value: '${workoutPct.toInt()}%',
                  subtitle: '$completedWorkouts / $totalWorkoutTasks done',
                  percent: workoutPct / 100,
                  color: const Color(0xFF00E5FF),
                  icon: Icons.fitness_center_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dashboardStatCard(
                  title: 'Diet Completion',
                  value: '${dietPct.toInt()}%',
                  subtitle: '$completedMeals / $totalMealTasks meals',
                  percent: dietPct / 100,
                  color: const Color(0xFF76FF03),
                  icon: Icons.restaurant_menu_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Calories Burned vs Consumed
          Row(
            children: [
              Expanded(
                child: _statMetricTile(
                  label: 'Calories Burned',
                  value: '$caloriesBurned kcal',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statMetricTile(
                  label: 'Calories Consumed',
                  value: '$caloriesConsumed kcal',
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFFFFAB00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Water, Sleep, Steps Metrics Cards
          Row(
            children: [
              Expanded(
                child: _statMetricTile(
                  label: 'Water Intake',
                  value: '${tracker.waterIntakeLiters} L',
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFF40C4FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statMetricTile(
                  label: 'Sleep Hours',
                  value: '${tracker.sleepHours} hrs',
                  icon: Icons.bedtime_rounded,
                  color: const Color(0xFFE040FB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _statMetricTile(
            label: 'Steps Walked',
            value: '${tracker.stepsWalked} / $plan.dailyStepsTarget Steps',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF76FF03),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _dashboardStatCard({
    required String title,
    required String value,
    required String subtitle,
    required double percent,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              CircularPercentIndicator(
                radius: 20.0,
                lineWidth: 4.0,
                percent: percent.clamp(0.0, 1.0),
                progressColor: color,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _statMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
