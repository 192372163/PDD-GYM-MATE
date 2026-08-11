import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../models/goal_plan_model.dart';
import '../../../models/user_model.dart';
import '../../../widgets/exercise_card.dart';
import '../../exercise_detail_screen.dart';
import '../../../models/exercise_model.dart';
import 'active_workout_session_screen.dart';

/// Screen 3: AI Workout Plan View displaying multi-day workout schedule,
/// Warm-up -> Main Workout -> Cooldown structure, HD thumbnail video players,
/// missed day resumption, and live workout launcher.
class AIWorkoutPlanView extends StatefulWidget {
  final GoalPlanModel plan;
  final UserModel? userProfile;
  final Function(GoalPlanModel updatedPlan)? onPlanUpdated;

  const AIWorkoutPlanView({
    super.key,
    required this.plan,
    this.userProfile,
    this.onPlanUpdated,
  });

  @override
  State<AIWorkoutPlanView> createState() => _AIWorkoutPlanViewState();
}

class _AIWorkoutPlanViewState extends State<AIWorkoutPlanView> {
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = widget.plan.currentActiveDayIndex.clamp(0, widget.plan.workoutDays.length - 1);
  }

  @override
  void didUpdateWidget(covariant AIWorkoutPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.plan.currentActiveDayIndex != oldWidget.plan.currentActiveDayIndex) {
      _selectedDayIndex = widget.plan.currentActiveDayIndex.clamp(0, widget.plan.workoutDays.length - 1);
    }
  }

  void _startLiveSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutSessionScreen(
          plan: widget.plan,
          dayIndex: _selectedDayIndex,
          onPlanUpdated: (updated) {
            widget.onPlanUpdated?.call(updated);
          },
        ),
      ),
    );
  }

  bool _checkIsLocked(GoalPlanModel plan, DailyWorkoutSchedule d, int index, List<bool> outIsLockedForTomorrow) {
    bool isLocked = index > plan.currentActiveDayIndex && !d.isCompleted;
    bool lockedForTomorrow = false;

    if (!isLocked && index == plan.currentActiveDayIndex && index > 0) {
      final prevDay = plan.workoutDays[index - 1];
      if (prevDay.isCompleted && prevDay.completionDate != null) {
        final now = DateTime.now();
        final completedDate = prevDay.completionDate!;
        if (now.year == completedDate.year &&
            now.month == completedDate.month &&
            now.day == completedDate.day) {
          isLocked = true;
          lockedForTomorrow = true;
        }
      }
    }

    if (index > plan.currentActiveDayIndex || 
        (index == plan.currentActiveDayIndex && lockedForTomorrow)) {
      isLocked = true;
    }
    
    if (outIsLockedForTomorrow.isNotEmpty) {
      outIsLockedForTomorrow[0] = lockedForTomorrow;
    }
    return isLocked;
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final days = plan.workoutDays;
    final activeIndex = plan.currentActiveDayIndex.clamp(0, days.length - 1);
    final currentDaySchedule = (days.isNotEmpty && _selectedDayIndex < days.length)
        ? days[_selectedDayIndex]
        : DailyWorkoutSchedule(dayNumber: 1, dayName: 'Day 1', focusArea: 'Full Body', workoutExercises: []);

    final bool isMissedDay = _selectedDayIndex < activeIndex && !currentDaySchedule.isCompleted;

    final selectedDayLockedForTomorrow = <bool>[false];
    final isSelectedDayLocked = _checkIsLocked(plan, currentDaySchedule, _selectedDayIndex, selectedDayLockedForTomorrow);

    return Container(
      color: const Color(0xFF0D0F17),
      child: CustomScrollView(
        slivers: [
          // Header Summary Card & Biometrics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Banner
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Color(0xFF00E5FF),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${plan.goalTitle} Program',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'AI Schedule • ${plan.durationLabel} (${plan.durationDays} Days)',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Biometrics row chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _metricChip('Age', '${plan.userAge} yrs', Icons.person_outline),
                        _metricChip('Gender', plan.userGender, Icons.wc),
                        _metricChip('Height', '${plan.userHeightCm.toInt()} cm', Icons.height),
                        _metricChip('Weight', '${plan.currentWeight} kg', Icons.monitor_weight_outlined),
                        _metricChip('BMI', '${plan.currentBmi}', Icons.speed),
                        _metricChip('Level', plan.userFitnessLevel, Icons.military_tech_outlined),
                        _metricChip('Time', '${plan.availableWorkoutTimeMins}m/day', Icons.timer_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Missed Day Resumption Banner
                  if (isMissedDay)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFAB00).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFAB00).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded, color: Color(0xFFFFAB00), size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Missed Workout Detected',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Resume this workout without losing streak progress!',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _startLiveSession,
                            child: const Text('Resume',
                                style: TextStyle(
                                    color: Color(0xFFFFAB00),
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Day Selector Chips (Day 1..Day N)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daily Schedule (Day ${_selectedDayIndex + 1} of ${days.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currentDaySchedule.totalDurationMins} Mins Total',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Day Scroll Selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(days.length, (index) {
                        final d = days[index];
                        final outLockedTomorrow = <bool>[false];
                        final isLocked = _checkIsLocked(plan, d, index, outLockedTomorrow);

                        final isSelected = _selectedDayIndex == index;
                        final isCurrentActive = plan.currentActiveDayIndex == index && !isLocked;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: d.isCompleted
                                ? const Icon(Icons.check_circle, size: 16, color: Colors.black)
                                : (isLocked
                                    ? const Icon(Icons.lock, size: 14, color: Colors.grey)
                                    : (isCurrentActive
                                        ? const Icon(Icons.play_circle_filled,
                                            size: 16, color: Color(0xFF00E5FF))
                                        : null)),
                            label: Text(d.dayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (isLocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🔒 Workout Locked! Complete Day ${plan.currentActiveDayIndex + 1} first.'),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (selected) {
                                setState(() => _selectedDayIndex = index);
                              }
                            },
                            selectedColor: const Color(0xFF00E5FF),
                            backgroundColor: const Color(0xFF141724),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : (isLocked ? Colors.grey.shade600 : Colors.grey.shade300),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Focus area banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161925),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.center_focus_strong, color: Color(0xFF76FF03), size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Focus Area: ',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        ),
                        Text(
                          currentDaySchedule.focusArea,
                          style: const TextStyle(
                            color: Color(0xFF76FF03),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (currentDaySchedule.isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF76FF03).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('✓ COMPLETED',
                                style: TextStyle(
                                    color: Color(0xFF76FF03),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Start Live Workout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? null : _startLiveSession,
                      icon: Icon(
                        (isSelectedDayLocked || currentDaySchedule.isCompleted) ? Icons.lock_clock_rounded : Icons.play_arrow_rounded, 
                        color: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? Colors.grey.shade400 : Colors.black, 
                        size: 24
                      ),
                      label: Text(
                        selectedDayLockedForTomorrow[0]
                            ? 'Next Workout Unlocks Tomorrow'
                            : isSelectedDayLocked
                                ? 'Complete Previous Days First'
                                : currentDaySchedule.isCompleted
                                    ? '${currentDaySchedule.dayName} Workout Completed'
                                    : 'Start ${currentDaySchedule.dayName} Workout Session',
                        style: TextStyle(
                            color: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? Colors.grey.shade400 : Colors.black, 
                            fontSize: 15, 
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? const Color(0xFF1E293B) : const Color(0xFF76FF03),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? 0 : 6,
                        shadowColor: (isSelectedDayLocked || currentDaySchedule.isCompleted) ? Colors.transparent : const Color(0xFF76FF03).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Exercise List or Completed Message
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            sliver: currentDaySchedule.isCompleted
                ? SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161925),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF76FF03).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.emoji_events_rounded, size: 64, color: Color(0xFF76FF03)),
                          const SizedBox(height: 16),
                          Text(
                            '${currentDaySchedule.dayName} Completed!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Awesome work! You burned ${currentDaySchedule.totalCalories} kcal. Keep up the streak and proceed to the next day!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildListDelegate([
                      if (currentDaySchedule.warmupExercises.isNotEmpty) ...[
                        _buildSectionTitle('🔥 Warm-up', const Color(0xFFFFAB00)),
                        ...currentDaySchedule.warmupExercises.map((ex) {
                          final isDone = plan.tracker.completedExerciseIds.contains(ex.id);
                          return ExerciseCard(
                            exercise: ex.copyWith(isCompleted: isDone),
                            onToggleCompleted: () => _toggleExerciseInPlan(ex),
                            onTapDetail: () => _openExerciseDetail(ex),
                          );
                        }),
                      ],
                      if (currentDaySchedule.workoutExercises.isNotEmpty) ...[
                        _buildSectionTitle('💪 Main Workout', const Color(0xFF00E5FF)),
                        ...currentDaySchedule.workoutExercises.map((ex) {
                          final isDone = plan.tracker.completedExerciseIds.contains(ex.id);
                          return ExerciseCard(
                            exercise: ex.copyWith(isCompleted: isDone),
                            onToggleCompleted: () => _toggleExerciseInPlan(ex),
                            onTapDetail: () => _openExerciseDetail(ex),
                          );
                        }),
                      ],
                      if (currentDaySchedule.cooldownExercises.isNotEmpty) ...[
                        _buildSectionTitle('🧘 Cooldown', const Color(0xFFE040FB)),
                        ...currentDaySchedule.cooldownExercises.map((ex) {
                          final isDone = plan.tracker.completedExerciseIds.contains(ex.id);
                          return ExerciseCard(
                            exercise: ex.copyWith(isCompleted: isDone),
                            onToggleCompleted: () => _toggleExerciseInPlan(ex),
                            onTapDetail: () => _openExerciseDetail(ex),
                          );
                        }),
                      ],
                      const SizedBox(height: 30),
                    ]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _toggleExerciseInPlan(WorkoutExercise ex) {
    final currentIds = List<String>.from(widget.plan.tracker.completedExerciseIds);
    if (currentIds.contains(ex.id)) {
      currentIds.remove(ex.id);
    } else {
      currentIds.add(ex.id);
    }

    final newTracker = widget.plan.tracker.copyWith(completedExerciseIds: currentIds);
    final plan = widget.plan;
    final days = List<DailyWorkoutSchedule>.from(plan.workoutDays);
    final activeIndex = plan.currentActiveDayIndex.clamp(0, days.length - 1);
    
    // Check if the current active day is now fully completed
    final currentDaySchedule = days[activeIndex];
    final isAllDayExercisesDone = currentDaySchedule.exercises.every((e) => currentIds.contains(e.id));
    
    if (isAllDayExercisesDone) {
      days[activeIndex] = days[activeIndex].copyWith(
        isCompleted: true,
        isInProgress: false,
        completionDate: DateTime.now(),
      );
    } else {
      final someDone = currentDaySchedule.exercises.any((e) => currentIds.contains(e.id));
      if (someDone && !days[activeIndex].isCompleted) {
        days[activeIndex] = days[activeIndex].copyWith(isInProgress: true);
      } else if (!someDone) {
        days[activeIndex] = days[activeIndex].copyWith(isInProgress: false);
      }
    }

    int nextActiveDay = plan.currentActiveDayIndex;
    int completedCount = plan.totalWorkoutDaysCompleted;
    int streak = plan.workoutStreak;
    int calories = plan.totalCaloriesBurned;

    if (isAllDayExercisesDone && !plan.workoutDays[activeIndex].isCompleted) {
      completedCount++;
      streak++;
      calories += currentDaySchedule.totalCalories;
      Fluttertoast.showToast(
        msg: "🎉 Today's workout complete!",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.black,
      );
      if (activeIndex + 1 < days.length) {
        nextActiveDay = activeIndex + 1;
      }
    }

    final updated = plan.copyWith(
      tracker: newTracker,
      workoutDays: days,
      currentActiveDayIndex: nextActiveDay,
      totalWorkoutDaysCompleted: completedCount,
      workoutStreak: streak,
      totalCaloriesBurned: calories,
    );
    widget.onPlanUpdated?.call(updated);
  }

  void _openExerciseDetail(WorkoutExercise ex) {
    final legacyModel = ExerciseModel(
      id: ex.id,
      name: ex.name,
      description: ex.instructions.isNotEmpty
          ? ex.instructions.join('\n\n')
          : 'Maintain form, breathe steadily, and complete required sets.',
      targetMuscle: ex.targetMuscle,
      sets: ex.sets,
      reps: int.tryParse(ex.reps.split(' ').first) ?? 12,
      restTimeSec: ex.restSeconds,
      caloriesBurned: ex.caloriesBurned,
      difficulty: ex.difficulty,
      imageUrl: ex.hdThumbnailUrl,
      videoUrl: ex.videoUrl,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(exercise: legacyModel),
      ),
    );
  }

  Widget _metricChip(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF00E5FF), size: 14),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
