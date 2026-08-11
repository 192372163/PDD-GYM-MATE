import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/workout_service.dart';
import 'exercise_detail_screen.dart';

class WorkoutDayScreen extends StatelessWidget {
  final String dayName;
  final String workoutName;
  final UserModel? userProfile;

  const WorkoutDayScreen({
    super.key,
    required this.dayName,
    required this.workoutName,
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = WorkoutService().getExercisesForWorkout(workoutName, userProfile);
    
    String explanationText = '';
    if (userProfile?.fitnessGoal != null && userProfile?.goalDurationMonths != null) {
      final goal = userProfile!.fitnessGoal!.toLowerCase();
      final isShort = userProfile!.goalDurationMonths! <= 3;
      
      if (goal.contains('loss') || goal.contains('fat')) {
        explanationText = isShort 
          ? "High-intensity volume (18+ reps, extra sets) selected to maximize calorie burn for your accelerated weight loss goal."
          : "Endurance volume (15 reps) selected to support steady fat loss and maintain muscle over your timeline.";
      } else if (goal.contains('gain') || goal.contains('muscle')) {
        explanationText = isShort
          ? "High-intensity mass building (8 reps, extra sets) selected to drive rapid hypertrophy for your timeline."
          : "Progressive overload volume (10 reps) selected for steady, sustainable muscle growth.";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$dayName: $workoutName'),
      ),
      body: Column(
        children: [
          if (explanationText.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanationText,
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${exercise.sets}x${exercise.reps}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      'Target: $exercise.targetMuscle',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseDetailScreen(exercise: exercise),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final duration = exercises.length * 8; // roughly 8 mins per exercise
                  final calories = duration * 7; // roughly 7 cal per min
                  WorkoutService().completeWorkout(
                    title: workoutName,
                    durationMins: duration,
                    caloriesBurned: calories,
                    exercises: exercises.map((e) => e.name).toList(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Awesome! $workoutName completed.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Mark as Completed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
