import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../models/user_model.dart';
import 'workout_day_screen.dart';

class WorkoutListScreen extends StatefulWidget {
  final UserModel? userProfile;
  const WorkoutListScreen({super.key, this.userProfile});

  @override
  State<WorkoutListScreen> createState() => _WorkoutListScreenState();
}

class _WorkoutListScreenState extends State<WorkoutListScreen> {
  late Map<String, String> _split;

  @override
  void initState() {
    super.initState();
    _split = WorkoutService().generateRecommendedSplit(
      widget.userProfile ?? UserModel(uid: '', name: 'Guest', email: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommended Split'),
      ),
      body: Column(
        children: [
          if (widget.userProfile?.fitnessGoal != null && widget.userProfile?.goalDurationMonths != null)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Text(
                'Your ${widget.userProfile!.goalDurationMonths}-Month Plan to ${widget.userProfile!.fitnessGoal}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (widget.userProfile?.goalDurationMonths ?? 1) * 4,
              itemBuilder: (context, weekIndex) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    title: Text(
                      'Week ${weekIndex + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    children: List.generate(_split.keys.length, (dayIndex) {
                      final day = _split.keys.elementAt(dayIndex);
                      final workout = _split[day]!;
                      final isRest = workout.toLowerCase() == 'rest';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Card(
                          elevation: 1,
                          color: isRest ? Colors.grey.shade100 : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: isRest ? Colors.grey.shade300 : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                              child: Icon(
                                isRest ? Icons.weekend : Icons.fitness_center,
                                color: isRest ? Colors.grey.shade700 : Theme.of(context).primaryColor,
                              ),
                            ),
                            title: Text(
                              day,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              workout,
                              style: TextStyle(
                                color: isRest ? Colors.grey : Colors.black87,
                                fontSize: 14,
                                fontWeight: isRest ? FontWeight.normal : FontWeight.w600,
                              ),
                            ),
                            trailing: isRest ? null : const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: isRest ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WorkoutDayScreen(
                                    dayName: 'Week ${weekIndex + 1} - $day',
                                    workoutName: workout,
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
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
