import 'package:flutter/material.dart';
import '../models/goal_plan_model.dart';

class NotificationsModal extends StatelessWidget {
  final GoalPlanModel? plan;

  const NotificationsModal({super.key, this.plan});

  static void show(BuildContext context, {GoalPlanModel? plan}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => NotificationsModal(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {
        'title': '💧 Water Intake Reminder',
        'subtitle': 'You are 1.4L away from your 3.5L daily target. Keep sipping!',
        'time': '1 hour ago',
        'icon': Icons.local_drink,
        'color': const Color(0xFF06B6D4),
      },
      {
        'title': '🥗 Meal Log Alert',
        'subtitle': 'Don\'t forget to track your High-Protein Lunch!',
        'time': '3 hours ago',
        'icon': Icons.restaurant,
        'color': Colors.amber,
      },
      {
        'title': '🔥 15-Day Streak Maintained!',
        'subtitle': 'Awesome consistency! You earned +50 Bonus XP.',
        'time': 'Yesterday',
        'icon': Icons.local_fire_department,
        'color': Colors.orangeAccent,
      },
      {
        'title': '😴 Sleep & Recovery Reminder',
        'subtitle': 'Target 8 hours of sleep tonight for optimal muscle repair.',
        'time': 'Yesterday',
        'icon': Icons.nightlight_round,
        'color': Colors.purpleAccent,
      },
    ];

    if (plan != null) {
      final activeIndex = plan!.currentActiveDayIndex.clamp(0, plan!.workoutDays.length - 1);
      final currentDay = plan!.workoutDays[activeIndex];
      final exerciseListStr = currentDay.exercises.map((e) => e.name).join(', ');
      
      if (!currentDay.isCompleted) {
        final completedIds = plan!.tracker.completedExerciseIds;
        final incompleteExercises = currentDay.exercises.where((e) => !completedIds.contains(e.id)).toList();
        final incompleteCount = incompleteExercises.length;
        
        if (incompleteCount > 0 && incompleteCount < currentDay.exercises.length) {
          final remainingStr = incompleteExercises.map((e) => e.name).join(', ');
          notifications.insert(0, {
            'title': '🏋️ Today\'s Exercises (In Progress)',
            'subtitle': '$incompleteCount remaining for Day ${currentDay.dayNumber}: $remainingStr',
            'time': 'Just now',
            'icon': Icons.fitness_center,
            'color': Colors.amber,
          });
        } else {
          notifications.insert(0, {
            'title': '🏋️ Today\'s Exercises',
            'subtitle': 'Day ${currentDay.dayNumber} (${currentDay.focusArea}): $exerciseListStr',
            'time': 'Day Start',
            'icon': Icons.fitness_center,
            'color': const Color(0xFF10B981),
          });
        }
      } else {
        notifications.insert(0, {
          'title': '✅ Today\'s Workout Complete',
          'subtitle': 'Day ${currentDay.dayNumber} (${currentDay.focusArea}) - Today\'s workout complete! Great job finishing all exercises.',
          'time': 'Just now',
          'icon': Icons.check_circle_outline,
          'color': const Color(0xFF10B981),
        });
      }
    } else {
      notifications.insert(0, {
        'title': '🏋️ Today\'s Exercises',
        'subtitle': 'Day 1 (Chest & Triceps): Push-ups, Bench Press, Dumbbell Flyes, Tricep Dips',
        'time': 'Day Start',
        'icon': Icons.fitness_center,
        'color': const Color(0xFF10B981),
      });
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Chip(
                label: Text('${notifications.length} New', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                backgroundColor: const Color(0xFF10B981),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 16),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: (item['color'] as Color).withValues(alpha: 0.2),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  trailing: Text(
                    item['time'] as String,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
