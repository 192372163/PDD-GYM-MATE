import 'package:flutter/material.dart';
import '../models/goal_plan_model.dart';

class NotificationItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  final bool isWarning;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.isWarning = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'icon': icon,
      'color': color,
      'isWarning': isWarning,
    };
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Returns whether the user has missed exercises from yesterday or past days
  bool hasMissedExercises(GoalPlanModel? plan) {
    if (plan == null) return false;
    final activeIndex = plan.currentActiveDayIndex.clamp(0, plan.workoutDays.length - 1);
    if (activeIndex <= 0) return false;

    for (int i = 0; i < activeIndex; i++) {
      if (!plan.workoutDays[i].isCompleted) {
        return true;
      }
    }
    return false;
  }

  /// Returns summary details of yesterday's missed exercises if present
  String? getYesterdayMissedSummary(GoalPlanModel? plan) {
    if (plan == null) return null;
    final activeIndex = plan.currentActiveDayIndex.clamp(0, plan.workoutDays.length - 1);
    if (activeIndex <= 0) return null;

    final yesterdaySchedule = plan.workoutDays[activeIndex - 1];
    if (!yesterdaySchedule.isCompleted) {
      final completedIds = plan.tracker.completedExerciseIds;
      final missedList = yesterdaySchedule.exercises
          .where((e) => !completedIds.contains(e.id))
          .toList();

      final missedNames = missedList.isNotEmpty
          ? missedList.map((e) => e.name).join(', ')
          : 'All exercises for Day ${yesterdaySchedule.dayNumber}';

      return 'Day ${yesterdaySchedule.dayNumber} (${yesterdaySchedule.focusArea}): $missedNames';
    }
    return null;
  }

  /// Returns the notification list for a given GoalPlanModel
  List<NotificationItem> getNotifications(GoalPlanModel? plan) {
    final List<NotificationItem> items = [];

    if (plan != null) {
      final activeIndex = plan.currentActiveDayIndex.clamp(0, plan.workoutDays.length - 1);

      // 1. Yesterday's Missed Exercise Alert
      if (activeIndex > 0) {
        final yesterdaySchedule = plan.workoutDays[activeIndex - 1];
        if (!yesterdaySchedule.isCompleted) {
          final completedIds = plan.tracker.completedExerciseIds;
          final missedList = yesterdaySchedule.exercises
              .where((e) => !completedIds.contains(e.id))
              .toList();

          final missedNames = missedList.isNotEmpty
              ? missedList.map((e) => e.name).join(', ')
              : 'All exercises for Day ${yesterdaySchedule.dayNumber}';

          items.add(
            NotificationItem(
              title: '⚠️ Missed Exercises Alert (Yesterday)',
              subtitle:
                  'You missed Day ${yesterdaySchedule.dayNumber} (${yesterdaySchedule.focusArea}): $missedNames. Tap to catch up today!',
              time: 'Yesterday',
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
              isWarning: true,
            ),
          );
        }
      }

      // Check older missed days if any
      for (int i = 0; i < activeIndex - 1; i++) {
        final pastSchedule = plan.workoutDays[i];
        if (!pastSchedule.isCompleted) {
          items.add(
            NotificationItem(
              title: '⚠️ Missed Day ${pastSchedule.dayNumber} Routine',
              subtitle: 'Day ${pastSchedule.dayNumber} (${pastSchedule.focusArea}) was left incomplete. Keep moving forward!',
              time: 'Past Day',
              icon: Icons.running_with_errors_rounded,
              color: Colors.orangeAccent,
              isWarning: true,
            ),
          );
        }
      }

      // 2. Today's Daily Exercises Notification
      final currentDay = plan.workoutDays[activeIndex];
      final exerciseListStr = currentDay.exercises.map((e) => e.name).join(', ');
      final completedIds = plan.tracker.completedExerciseIds;
      final completedTodayCount = currentDay.exercises.where((e) => completedIds.contains(e.id)).length;
      final totalTodayCount = currentDay.exercises.length;

      final isDayFinished = currentDay.isCompleted || (totalTodayCount > 0 && completedTodayCount >= totalTodayCount);

      if (!isDayFinished) {
        if (completedTodayCount == 0) {
          // Starting the day - notification shows exercises to complete
          items.add(
            NotificationItem(
              title: '🏋️ Day ${currentDay.dayNumber} Routine Started',
              subtitle: 'Start your workout! Today (${currentDay.focusArea}): $exerciseListStr ($totalTodayCount exercises to complete).',
              time: 'Today',
              icon: Icons.fitness_center,
              color: const Color(0xFF10B981),
            ),
          );
        } else {
          // In progress
          final incompleteExercises = currentDay.exercises.where((e) => !completedIds.contains(e.id)).toList();
          final remainingStr = incompleteExercises.map((e) => e.name).join(', ');
          items.add(
            NotificationItem(
              title: '🏋️ Today\'s Exercises ($completedTodayCount/$totalTodayCount Completed)',
              subtitle: 'Completed: $completedTodayCount of $totalTodayCount exercises. Remaining for Day ${currentDay.dayNumber}: $remainingStr.',
              time: 'Just now',
              icon: Icons.fitness_center,
              color: Colors.amber,
            ),
          );
        }
      } else {
        // All completed today
        final isLastDay = activeIndex >= plan.workoutDays.length - 1;
        final nextDayText = isLastDay
            ? 'You finished the entire program! Amazing job!'
            : 'Day Completed! Today\'s workouts complete — ready for next day workout. Good luck! 🚀';

        items.add(
          NotificationItem(
            title: '🎉 Day ${currentDay.dayNumber} Workout Completed!',
            subtitle: nextDayText,
            time: 'Today',
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
          ),
        );
      }
    } else {
      items.add(
        NotificationItem(
          title: '🏋️ Today\'s Exercises',
          subtitle: 'Day 1 (Chest & Triceps): Push-ups, Bench Press, Dumbbell Flyes, Tricep Dips',
          time: 'Today',
          icon: Icons.fitness_center,
          color: const Color(0xFF10B981),
        ),
      );
    }

    // 3. Wellness & Progress Reminders
    items.addAll([
      NotificationItem(
        title: '💧 Water Intake Reminder',
        subtitle: 'You are 1.4L away from your 3.5L daily target. Keep sipping!',
        time: '1 hour ago',
        icon: Icons.local_drink,
        color: const Color(0xFF06B6D4),
      ),
      NotificationItem(
        title: '🥗 Meal Log Alert',
        subtitle: 'Don\'t forget to track your High-Protein Lunch!',
        time: '3 hours ago',
        icon: Icons.restaurant,
        color: Colors.amber,
      ),
      NotificationItem(
        title: '🔥 Daily Streak Active!',
        subtitle: 'Awesome consistency! You earned bonus XP for logging in.',
        time: 'Yesterday',
        icon: Icons.local_fire_department,
        color: Colors.orangeAccent,
      ),
      NotificationItem(
        title: '😴 Sleep & Recovery Reminder',
        subtitle: 'Target 8 hours of sleep tonight for optimal muscle repair.',
        time: 'Yesterday',
        icon: Icons.nightlight_round,
        color: Colors.purpleAccent,
      ),
    ]);

    return items;
  }
}
