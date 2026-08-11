import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../models/goal_plan_model.dart';
import '../../../services/goal_planner_service.dart';
import '../../report_preview_screen.dart';

class GoalCompletionView extends StatelessWidget {
  final GoalPlanModel plan;
  final VoidCallback onSetNewGoal;

  const GoalCompletionView({
    super.key,
    required this.plan,
    required this.onSetNewGoal,
  });

  @override
  Widget build(BuildContext context) {
    final weightDiff = plan.currentWeight - plan.startingWeight;
    final bmiDiff = plan.currentBmi - plan.startingBmi;

    return Container(
      color: const Color(0xFF0D0F17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          const SizedBox(height: 10),
          // Congratulations Animated Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.25),
                  const Color(0xFF76FF03).withValues(alpha: 0.20),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF76FF03).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                // Celebration Badge Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFAB00),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFAB00).withValues(alpha: 0.6),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CONGRATULATIONS! 🎉',
                  style: TextStyle(
                    color: Color(0xFF76FF03),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal Completed: $plan.goalTitle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You successfully achieved your target over $plan.durationLabel!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transformation Summary Cards
          const Text(
            'Transformation Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock('Starting Weight', '${plan.startingWeight} kg'),
                    _statBlock('Current Weight', '${plan.currentWeight} kg'),
                    _statBlock(
                      'Weight ${weightDiff <= 0 ? "Lost" : "Gained"}',
                      '${weightDiff.abs().toStringAsFixed(1)} kg',
                      color: const Color(0xFF76FF03),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock('BMI Improvement', '${bmiDiff >= 0 ? "+" : ""}${bmiDiff.toStringAsFixed(1)}'),
                    _statBlock('Workout Comp.', '${(plan.workoutConsistency * 100).toInt()}%'),
                    _statBlock('Diet Comp.', '${(plan.dietConsistency * 100).toInt()}%'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statBlock('Total Calories Burned', '18,450 kcal', color: const Color(0xFFFF5252)),
                    _statBlock('Workout Streak', '🔥 $plan.workoutStreak Days', color: const Color(0xFFFFAB00)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Unlocked Achievement Badge
          const Text(
            'Unlocked Achievement Badge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141724),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF00E5FF),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOAL CRUSHER 🏆',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completed 100% of your AI Goal Plan timeline with top consistency!',
                        style: TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Download PDF Report Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportPreviewScreen(
                      pdfFuture: GoalPlannerService().generateProgressReportPdf(plan),
                      reportName: 'GymMate_AI_Progress_Report_${plan.goalTitle.replaceAll(' ', '_')}.pdf',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.black),
              label: const Text(
                'Download Progress Report (PDF)',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Share Achievement Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                Fluttertoast.showToast(
                  msg: 'Achievement copied to clipboard! Share with friends.',
                );
              },
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: const Text(
                'Share Achievement',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Set New Goal Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: onSetNewGoal,
              icon: const Icon(Icons.autorenew_rounded, color: Colors.black),
              label: const Text(
                'Set New Goal',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF76FF03),
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

  Widget _statBlock(String label, String val, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
