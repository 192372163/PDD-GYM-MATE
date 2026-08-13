import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/goal_plan_model.dart';

/// Screen 7: Goal Progress Dashboard featuring multi-chart visualizations:
/// - Weight Progress (Line Chart)
/// - BMI Progress (Line Chart)
/// - Calories Burned (Bar Chart)
/// - Workout Consistency (Line Chart)
/// - Daily Workout History, Weekly/Monthly metrics, Streak, Completion Rate %
class GoalProgressDashboardView extends StatelessWidget {
  final GoalPlanModel plan;
  final VoidCallback onCompleteGoalTrigger;

  const GoalProgressDashboardView({
    super.key,
    required this.plan,
    required this.onCompleteGoalTrigger,
  });

  @override
  Widget build(BuildContext context) {
    final double completionRate = plan.overallGoalCompletionPercentage;

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
                  Icons.trending_up_rounded,
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
                      'Goal Progress & Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Long-term trends, history & bodyRecomp tracking',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // AI Motivational Coaching Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.18),
                  const Color(0xFF76FF03).withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Color(0xFF00E5FF),
                  size: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI MOTIVATIONAL COACHING',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Awesome job! You completed ${completionRate.toStringAsFixed(1)}% of your overall $plan.durationLabel goal. Current streak is 🔥 $plan.workoutStreak Days. Keep pushing for peak performance!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Core Metrics Summary Grid
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBlock('Current Goal', plan.goalTitle, Icons.flag_rounded, const Color(0xFF00E5FF)),
                    _metricBlock('Goal Duration', plan.durationLabel, Icons.timer_rounded, const Color(0xFF76FF03)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBlock('Completed Days', '${plan.completedDays} / $plan.durationDays', Icons.check_circle_outline, const Color(0xFF40C4FF)),
                    _metricBlock('Remaining Days', '${plan.remainingDays} Days', Icons.hourglass_empty_rounded, const Color(0xFFFFAB00)),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBlock('Starting Weight', '${plan.startingWeight} kg', Icons.monitor_weight_outlined, Colors.grey),
                    _metricBlock('Current Weight', '${plan.currentWeight} kg', Icons.fitness_center_rounded, Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricBlock('Current BMI', '${plan.currentBmi}', Icons.speed_rounded, const Color(0xFFE040FB)),
                    _metricBlock('Workout Streak', '🔥 $plan.workoutStreak Days', Icons.local_fire_department_rounded, const Color(0xFFFF5252)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. Weight Progress Chart (Line Chart)
          const Text(
            'Weight Progress (kg)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 210,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text('Wk ${v.toInt() + 1}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      (plan.totalWorkoutDaysCompleted / 7).ceil().clamp(1, plan.weightProgressHistory.length),
                      (i) => FlSpot(i.toDouble(), plan.weightProgressHistory[i]),
                    ),
                    isCurved: true,
                    color: const Color(0xFF76FF03),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF76FF03).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. BMI Progress Chart (Line Chart)
          const Text(
            'BMI Progress Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 210,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text('Wk ${v.toInt() + 1}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      (plan.totalWorkoutDaysCompleted / 7).ceil().clamp(1, plan.bmiTrendHistory.length),
                      (i) => FlSpot(i.toDouble(), plan.bmiTrendHistory[i]),
                    ),
                    isCurved: true,
                    color: const Color(0xFF00E5FF),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Calories Burned Chart (Bar Chart)
          const Text(
            'Calories Burned History (kcal)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 210,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10)),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (v.toInt() >= 0 && v.toInt() < days.length) {
                          return Text(days[v.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 11));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  final cals = [320.0, 450.0, 380.0, 520.0, 410.0, 600.0, 490.0];
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: cals[i],
                        color: const Color(0xFFFFAB00),
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Workout Consistency Chart (Line Chart)
          const Text(
            'Workout Consistency Rate (%)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 210,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10)),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, m) => Text('${v.toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) => Text('Wk ${v.toInt() + 1}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(plan.dynamicWeeklyProgress.length, (i) => FlSpot(i.toDouble(), plan.dynamicWeeklyProgress[i])),
                    isCurved: true,
                    color: const Color(0xFFE040FB),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFE040FB).withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Simulate Goal Completion Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onCompleteGoalTrigger,
              icon: const Icon(Icons.emoji_events_rounded, color: Colors.black),
              label: const Text(
                'Complete Goal & View Final Report',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAB00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _metricBlock(String title, String val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
          ],
        ),
      ],
    );
  }
}
