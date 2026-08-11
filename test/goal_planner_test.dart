import 'package:flutter_test/flutter_test.dart';
import 'package:gymmate_ai/models/user_model.dart';
import 'package:gymmate_ai/services/goal_planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Goal Planner & Multi-Day Schedule Generator Tests', () {
    late GoalPlannerService service;
    late UserModel testUser;

    setUp(() {
      service = GoalPlannerService();
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

    test('Generates complete 14-day schedule for Six-Pack Development', () {
      final plan = service.generateAIPlan(
        user: testUser,
        goalTitle: 'Six-Pack Development',
        durationLabel: '2 Weeks',
        durationDays: 14,
        availableWorkoutTimeMins: 45,
      );

      expect(plan.goalTitle, equals('Six-Pack Development'));
      expect(plan.durationDays, equals(14));
      expect(plan.workoutDays.length, equals(14));
      expect(plan.workoutDays.first.dayName, equals('Day 1'));
      expect(plan.workoutDays.last.dayName, equals('Day 14'));
      expect(plan.workoutDays.first.exercises.isNotEmpty, isTrue);
    });

    test('Generates 180-day schedule for 6 Months Muscle Building', () {
      final plan = service.generateAIPlan(
        user: testUser,
        goalTitle: 'Muscle Building',
        durationLabel: '6 Months',
        durationDays: 180,
        availableWorkoutTimeMins: 60,
      );

      expect(plan.durationDays, equals(180));
      expect(plan.workoutDays.length, equals(180));
      expect(plan.workoutDays.last.dayName, equals('Day 180'));
    });

    test('Filters out high impact exercises for Joint Pain condition', () {
      final plan = service.generateAIPlan(
        user: testUser,
        goalTitle: 'Weight Loss',
        durationLabel: '1 Month',
        durationDays: 30,
        medicalConditions: ['Joint Pain'],
      );

      for (var day in plan.workoutDays) {
        for (var ex in day.exercises) {
          expect(ex.name, isNot(equals('Burpees')));
        }
      }
    });

    test('Includes video URL, instructions, mistakes, and safety tips for exercises', () {
      final plan = service.generateAIPlan(
        user: testUser,
        goalTitle: 'General Fitness',
        durationLabel: '1 Month',
        durationDays: 30,
      );

      final ex = plan.workoutDays.first.exercises.first;
      expect(ex.videoUrl, isNotNull);
      expect(ex.hdThumbnailUrl, isNotNull);
      expect(ex.instructions.isNotEmpty, isTrue);
      expect(ex.safetyTips.isNotEmpty, isTrue);
    });
  });
}
