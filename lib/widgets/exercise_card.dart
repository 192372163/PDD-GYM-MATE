import 'package:flutter/material.dart';
import '../models/goal_plan_model.dart';
import 'embedded_video_player.dart';

/// Premium glassmorphic exercise item card displaying HD thumbnail,
/// embedded video toggle, exercise stats, instructions preview, and completion checkbox.
class ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final VoidCallback? onToggleCompleted;
  final VoidCallback? onTapDetail;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onToggleCompleted,
    this.onTapDetail,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  bool _showEmbeddedVideo = false;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ex.isCompleted
            ? const Color(0xFF101E24)
            : const Color(0xFF141724),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ex.isCompleted
              ? const Color(0xFF76FF03).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: ex.isCompleted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: ex.isCompleted
                ? const Color(0xFF76FF03).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Main Exercise Header Row
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onTapDetail,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // HD Thumbnail or Play Video Trigger
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEmbeddedVideo = !_showEmbeddedVideo;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            ex.hdThumbnailUrl ??
                                'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=300&q=80',
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 68,
                              height: 68,
                              color: const Color(0xFF1E2336),
                              child: const Icon(Icons.fitness_center_rounded,
                                  color: Color(0xFF00E5FF), size: 28),
                            ),
                          ),
                        ),
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _showEmbeddedVideo
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Exercise Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex.name,
                                style: TextStyle(
                                  color: ex.isCompleted ? Colors.grey.shade400 : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration:
                                      ex.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ex.targetMuscle,
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${ex.sets} Sets × ${ex.reps}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Stats pills
                        Row(
                          children: [
                            Icon(Icons.timer_outlined, color: Colors.grey.shade400, size: 13),
                            const SizedBox(width: 3),
                            Text('${ex.restSeconds}s rest',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                            const SizedBox(width: 10),
                            const Icon(Icons.local_fire_department_rounded,
                                color: Color(0xFFFFAB00), size: 13),
                            const SizedBox(width: 3),
                            Text('${ex.caloriesBurned} kcal',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Completion Checkbox
                  GestureDetector(
                    onTap: widget.onToggleCompleted,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ex.isCompleted
                            ? const Color(0xFF76FF03)
                            : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: ex.isCompleted
                              ? const Color(0xFF76FF03)
                              : Colors.grey.shade600,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: ex.isCompleted ? Colors.black : Colors.transparent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Inline Embedded Demo Video Accordion Expansion
          if (_showEmbeddedVideo)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  EmbeddedVideoPlayer(
                    exerciseName: ex.name,
                    videoUrl: ex.videoUrl,
                    hdThumbnailUrl: ex.hdThumbnailUrl,
                    targetMuscle: ex.targetMuscle,
                    autoPlay: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: widget.onTapDetail,
                        icon: const Icon(Icons.menu_book_rounded,
                            size: 16, color: Color(0xFF00E5FF)),
                        label: const Text(
                          'View Full Instructions & Tips',
                          style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_up_rounded,
                            color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _showEmbeddedVideo = false;
                          });
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
