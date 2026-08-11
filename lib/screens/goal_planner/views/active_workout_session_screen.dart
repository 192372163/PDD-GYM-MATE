import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../models/goal_plan_model.dart';
import '../../../widgets/exercise_card.dart';
import '../../exercise_detail_screen.dart';
import '../../../models/exercise_model.dart';
import 'daily_completion_modal.dart';

/// Real-time Interactive Workout Session Screen.
/// Features:
/// - Live workout timer (start/pause/reset)
/// - Exercise list with warm-up, main workout, cooldown sections
/// - In-Progress auto-save on exit (WillPopScope)
/// - Rest timer bottom sheet with skip
/// - Per-exercise instructions & common mistakes expansion
/// - Celebration dialog on full completion
class ActiveWorkoutSessionScreen extends StatefulWidget {
  final GoalPlanModel plan;
  final int dayIndex;
  final Function(GoalPlanModel updatedPlan) onPlanUpdated;

  const ActiveWorkoutSessionScreen({
    super.key,
    required this.plan,
    required this.dayIndex,
    required this.onPlanUpdated,
  });

  @override
  State<ActiveWorkoutSessionScreen> createState() => _ActiveWorkoutSessionScreenState();
}

class _ActiveWorkoutSessionScreenState extends State<ActiveWorkoutSessionScreen> {
  // Timer state
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;

  late List<String> _completedIds;

  @override
  void initState() {
    super.initState();
    // Restore previously completed exercises (for resume functionality)
    _completedIds = List<String>.from(widget.plan.tracker.completedExerciseIds);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
      _isTimerRunning = false;
    });
  }

  String get _formattedTime {
    final mins = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  bool _canPop = false;

  /// Save workout as In Progress when user exits mid-session
  void _saveInProgressAndPop() {
    if (_canPop) return;
    final days = widget.plan.workoutDays;
    final activeIndex = widget.dayIndex.clamp(0, days.length - 1);
    final day = days[activeIndex];

    // Only mark in-progress if there's some but not all completed
    final allExercises = day.exercises;
    final completedCount = allExercises.where((ex) => _completedIds.contains(ex.id)).length;

    if (completedCount > 0 && completedCount < allExercises.length) {
      final updatedDays = List<DailyWorkoutSchedule>.from(days);
      updatedDays[activeIndex] = updatedDays[activeIndex].copyWith(
        isInProgress: true,
        lastCompletedExerciseIndex: completedCount,
        workoutDurationSecs: _elapsedSeconds,
      );

      final newTracker = widget.plan.tracker.copyWith(completedExerciseIds: _completedIds);
      final updatedPlan = widget.plan.copyWith(
        tracker: newTracker,
        workoutDays: updatedDays,
      );
      widget.onPlanUpdated(updatedPlan);
    }

    setState(() => _canPop = true);
    Future.microtask(() {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _toggleExercise(WorkoutExercise ex, DailyWorkoutSchedule day) {
    bool isJustCompleted = false;
    setState(() {
      if (_completedIds.contains(ex.id)) {
        _completedIds.remove(ex.id);
      } else {
        _completedIds.add(ex.id);
        isJustCompleted = true;
      }
    });

    final newTracker = widget.plan.tracker.copyWith(completedExerciseIds: _completedIds);
    final isAllDayExercisesDone = day.exercises.every((e) => _completedIds.contains(e.id));
    
    if (isJustCompleted && !isAllDayExercisesDone) {
      _showRestTimer(ex.restSeconds);
    }

    final updatedDays = List<DailyWorkoutSchedule>.from(widget.plan.workoutDays);
    final activeIndex = widget.dayIndex.clamp(0, updatedDays.length - 1);

    if (isAllDayExercisesDone) {
      updatedDays[activeIndex] = updatedDays[activeIndex].copyWith(
        isCompleted: true,
        isInProgress: false,
        completionDate: DateTime.now(),
        workoutDurationSecs: _elapsedSeconds,
      );
    } else {
      updatedDays[activeIndex] = updatedDays[activeIndex].copyWith(
        isInProgress: true,
        lastCompletedExerciseIndex: _completedIds.length,
        workoutDurationSecs: _elapsedSeconds,
      );
    }

    int nextActiveDay = widget.plan.currentActiveDayIndex;
    int completedCount = widget.plan.totalWorkoutDaysCompleted;
    int streak = widget.plan.workoutStreak;
    int calories = widget.plan.totalCaloriesBurned;

    if (isAllDayExercisesDone && !widget.plan.workoutDays[activeIndex].isCompleted) {
      completedCount++;
      streak++;
      calories += day.totalCalories;
      Fluttertoast.showToast(
        msg: "🎉 Today's workout complete!",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.black,
      );
      if (activeIndex + 1 < updatedDays.length) {
        nextActiveDay = activeIndex + 1;
      }
    }

    final updatedPlan = widget.plan.copyWith(
      tracker: newTracker,
      workoutDays: updatedDays,
      currentActiveDayIndex: nextActiveDay,
      totalWorkoutDaysCompleted: completedCount,
      workoutStreak: streak,
      totalCaloriesBurned: calories,
    );

    widget.onPlanUpdated(updatedPlan);

    if (isAllDayExercisesDone) {
      _pauseTimer();
      _showCompletionDialog(day, calories);
    }
  }

  void _showRestTimer(int restSeconds) {
    if (restSeconds <= 0) return;
    int remaining = restSeconds;
    Timer? restTimer;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSheet) {
            restTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (remaining <= 1) {
                t.cancel();
                if (ctx2.mounted) Navigator.pop(ctx2);
                return;
              }
              setSheet(() => remaining--);
            });

            return Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Rest Time', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Text(
                    '$remaining',
                    style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold),
                  ),
                  const Text('seconds', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          restTimer?.cancel();
                          Navigator.pop(ctx2);
                        },
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.black),
                        label: const Text('Skip Rest', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => restTimer?.cancel());
  }

  void _showCompletionDialog(DailyWorkoutSchedule day, int totalCalories) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return DailyCompletionModal(
          dayName: day.dayName,
          caloriesBurned: day.totalCalories,
          durationMins: (_elapsedSeconds ~/ 60).clamp(1, 120),
          currentStreak: widget.plan.workoutStreak + 1,
          achievementBadge: '${day.dayName} Master',
          onUnlockNextDay: () {
            // The modal itself already calls Navigator.pop(context) to close the dialog.
            if (mounted) {
              setState(() => _canPop = true);
              Navigator.of(context).pop(); // close the active session screen
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.plan.workoutDays;
    final dayIndex = widget.dayIndex.clamp(0, days.length - 1);
    final day = days.isNotEmpty
        ? days[dayIndex]
        : DailyWorkoutSchedule(dayNumber: 1, dayName: 'Day 1', focusArea: 'Full Body', workoutExercises: []);

    final allExercises = day.exercises;
    final completedCount = allExercises.where((ex) => _completedIds.contains(ex.id)).length;
    final totalCount = allExercises.length;
    final remainingCount = totalCount - completedCount;
    final double completionPercent = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final int caloriesBurnedSoFar = allExercises
        .where((ex) => _completedIds.contains(ex.id))
        .fold(0, (sum, ex) => sum + ex.caloriesBurned);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _saveInProgressAndPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0F17),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0F17),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: _saveInProgressAndPop,
          ),
          title: Text(
            '${day.dayName}: ${day.focusArea}', // ← fixed interpolation bug
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            // In Progress badge
            if (day.isInProgress && !day.isCompleted)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text('In Progress', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        body: Column(
          children: [
            // Live Stats Header Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF141724), Color(0xFF1B2033)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                    blurRadius: 16,
                  )
                ],
              ),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 36.0,
                    lineWidth: 7.0,
                    percent: completionPercent.clamp(0.0, 1.0),
                    center: Text(
                      '${(completionPercent * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    progressColor: const Color(0xFF76FF03),
                    backgroundColor: Colors.white10,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('✓ Done: $completedCount / $totalCount',
                                style: const TextStyle(color: Color(0xFF76FF03), fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Left: $remainingCount',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFFAB00), size: 16),
                                const SizedBox(width: 4),
                                Text('$caloriesBurnedSoFar kcal',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Color(0xFF00E5FF), size: 14),
                                  const SizedBox(width: 4),
                                  Text(_formattedTime,
                                      style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Timer Controls Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isTimerRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 18),
                    label: Text(_isTimerRunning ? 'Pause' : 'Resume',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.grey, size: 18),
                    label: const Text('Reset', style: TextStyle(color: Colors.grey)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade700),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _saveInProgressAndPop(),
                    icon: const Icon(Icons.save_rounded, color: Color(0xFF10B981), size: 18),
                    label: const Text('Save & Exit', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Exercise List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  if (day.warmupExercises.isNotEmpty) ...[
                    _buildSectionHeader('🔥 Warm-up', const Color(0xFFFFAB00)),
                    ...day.warmupExercises.map((ex) {
                      final isDone = _completedIds.contains(ex.id);
                      return _buildExerciseTile(ex, day, isDone);
                    }),
                  ],
                  if (day.workoutExercises.isNotEmpty) ...[
                    _buildSectionHeader('💪 Main Workout', const Color(0xFF00E5FF)),
                    ...day.workoutExercises.map((ex) {
                      final isDone = _completedIds.contains(ex.id);
                      return _buildExerciseTile(ex, day, isDone);
                    }),
                  ],
                  if (day.cooldownExercises.isNotEmpty) ...[
                    _buildSectionHeader('🧘 Cooldown & Stretch', const Color(0xFFE040FB)),
                    ...day.cooldownExercises.map((ex) {
                      final isDone = _completedIds.contains(ex.id);
                      return _buildExerciseTile(ex, day, isDone);
                    }),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTile(WorkoutExercise ex, DailyWorkoutSchedule day, bool isDone) {
    return Column(
      children: [
        ExerciseCard(
          exercise: ex.copyWith(isCompleted: isDone),
          onToggleCompleted: () => _toggleExercise(ex, day),
          onTapDetail: () => _openExerciseDetail(ex),
        ),
        // Expandable instructions & common mistakes
        if (ex.instructions.isNotEmpty || ex.commonMistakes.isNotEmpty)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: const Text('Instructions & Tips', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.bold)),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              iconColor: const Color(0xFF10B981),
              collapsedIconColor: const Color(0xFF475569),
              children: [
                if (ex.instructions.isNotEmpty) ...[
                  const Text('Steps:', style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...ex.instructions.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.key + 1}. ', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(child: Text(e.value, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12))),
                      ],
                    ),
                  )),
                ],
                if (ex.commonMistakes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('⚠️ Common Mistakes:', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ...ex.commonMistakes.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.amber, fontSize: 12)),
                        Expanded(child: Text(m, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12))),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(title,
          style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  void _openExerciseDetail(WorkoutExercise ex) {
    final legacyModel = ExerciseModel(
      id: ex.id,
      name: ex.name,
      description: ex.instructions.isNotEmpty
          ? ex.instructions.join('\n\n')
          : 'Follow proper form and maintain steady breath rhythm.',
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
      MaterialPageRoute(builder: (context) => ExerciseDetailScreen(exercise: legacyModel)),
    );
  }
}
