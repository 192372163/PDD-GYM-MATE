import 'package:flutter/material.dart';

/// Celebration Dialog shown when all exercises for the day are completed.
/// Displays:
/// - 🎉 Daily Workout Completed header
/// - Workout Completion %
/// - Calories Burned
/// - Workout Duration (Mins)
/// - Current Streak (e.g. 🔥 5 Days)
/// - Today's Achievement Badge (e.g. 🏆 Core Crusher)
/// - Button to automatically unlock the next day's workout!
class DailyCompletionModal extends StatelessWidget {
  final String dayName;
  final int caloriesBurned;
  final int durationMins;
  final int currentStreak;
  final String achievementBadge;
  final VoidCallback onUnlockNextDay;

  const DailyCompletionModal({
    super.key,
    required this.dayName,
    required this.caloriesBurned,
    required this.durationMins,
    required this.currentStreak,
    this.achievementBadge = 'Workout Master',
    required this.onUnlockNextDay,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF141724),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: const Color(0xFF76FF03).withValues(alpha: 0.4), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration Badge Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF76FF03).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF76FF03), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF76FF03).withValues(alpha: 0.4),
                    blurRadius: 20,
                  )
                ],
              ),
              child: const Text(
                '🎉',
                style: TextStyle(fontSize: 44),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Daily Workout Completed!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Great effort on completing $dayName routine!',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Performance Metrics Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F17),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF76FF03),
                        label: 'Completion',
                        value: '100%',
                      ),
                      _buildMetric(
                        icon: Icons.local_fire_department_rounded,
                        color: const Color(0xFFFFAB00),
                        label: 'Burned',
                        value: '$caloriesBurned kcal',
                      ),
                      _buildMetric(
                        icon: Icons.timer_rounded,
                        color: const Color(0xFF00E5FF),
                        label: 'Duration',
                        value: '$durationMins mins',
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        icon: Icons.local_fire_department_outlined,
                        color: const Color(0xFFFF5252),
                        label: 'Current Streak',
                        value: '🔥 $currentStreak Days',
                      ),
                      _buildMetric(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFFFD700),
                        label: 'Today\'s Badge',
                        value: '🏆 $achievementBadge',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Unlock Next Day Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onUnlockNextDay();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF76FF03),
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: const Color(0xFF76FF03).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Finish & View Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
