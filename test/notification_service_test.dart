import 'package:flutter_test/flutter_test.dart';
import 'package:gymmate_ai/models/goal_plan_model.dart';
import 'package:gymmate_ai/models/user_model.dart';
import 'package:gymmate_ai/services/goal_planner_service.dart';
import 'package:gymmate_ai/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Daily Progress Tests', () {
    late GoalPlannerService goalService;
    late NotificationService notificationService;
    late UserModel testUser;

    setUp(() {
      goalService = GoalPlannerService();
      notificationService = NotificationService();
      testUser = UserModel(
        uid: 'user_test_123',
        name: 'Test Athlete',
        email: 'test@gymmate.ai',
        age: 26,
        gender: 'Male',
        heightCm: 178.0,
        weightKg: 74.0,
        experienceLevel: 'Intermediate',
      );
    });

    test('Shows list of exercises to complete when day starts (0 completed)', () {
      final plan = goalService.generateAIPlan(
        user: testUser,
        goalTitle: 'Six-Pack Development',
        durationLabel: '2 Weeks',
        durationDays: 14,
      );

      final notifications = notificationService.getNotifications(plan);
      final todayNotif = notifications.firstWhere((n) => n.title.contains('Routine Started'));

      expect(todayNotif.subtitle, contains('Start your workout!'));
      expect(todayNotif.subtitle, contains('exercises to complete'));
    });

    test('Shows completion progress and remaining exercises when partially completed', () {
      final plan = goalService.generateAIPlan(
        user: testUser,
        goalTitle: 'Six-Pack Development',
        durationLabel: '2 Weeks',
        durationDays: 14,
      );

      // Complete 1 exercise
      final firstExId = plan.workoutDays.first.exercises.first.id;
      final updatedTracker = plan.tracker.copyWith(
        completedExerciseIds: [...plan.tracker.completedExerciseIds, firstExId],
      );
      final updatedPlan = plan.copyWith(tracker: updatedTracker);

      final notifications = notificationService.getNotifications(updatedPlan);
      final todayNotif = notifications.firstWhere((n) => n.title.contains('Completed'));

      expect(todayNotif.subtitle, contains('Completed: 1 of'));
      expect(todayNotif.subtitle, contains('Remaining for Day 1:'));
    });

    test('Shows ready for next day workout good luck message when all completed', () {
      final plan = goalService.generateAIPlan(
        user: testUser,
        goalTitle: 'Six-Pack Development',
        durationLabel: '2 Weeks',
        durationDays: 14,
      );

      // Complete all exercises of Day 1
      final day1ExIds = plan.workoutDays.first.exercises.map((e) => e.id).toList();
      final updatedTracker = plan.tracker.copyWith(
        completedExerciseIds: day1ExIds,
      );
      final updatedDays = List<DailyWorkoutSchedule>.from(plan.workoutDays);
      updatedDays[0] = updatedDays[0].copyWith(isCompleted: true);
      final completedPlan = plan.copyWith(tracker: updatedTracker, workoutDays: updatedDays);

      final notifications = notificationService.getNotifications(completedPlan);
      final todayNotif = notifications.firstWhere((n) => n.title.contains('Workout Completed!'));

      expect(todayNotif.subtitle, contains('Day Completed! Today\'s workouts complete — ready for next day workout. Good luck!'));
    });
  });
}
