import 'package:flutter/material.dart';

/// Embedded Demo Video Player Widget for GymMate AI.
/// Renders an embedded instructional demo player with controls, progress bar,
/// animated preview, and full-screen modal player.
class EmbeddedVideoPlayer extends StatefulWidget {
  final String exerciseName;
  final String? videoUrl;
  final String? hdThumbnailUrl;
  final String targetMuscle;
  final bool autoPlay;
  final VoidCallback? onVideoCompleted;

  const EmbeddedVideoPlayer({
    super.key,
    required this.exerciseName,
    this.videoUrl,
    this.hdThumbnailUrl,
    this.targetMuscle = 'Full Body',
    this.autoPlay = false,
    this.onVideoCompleted,
  });

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  double _playbackProgress = 0.0;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        if (_isPlaying) {
          setState(() {
            _playbackProgress = _animController.value;
          });
          if (_animController.isCompleted) {
            _animController.repeat();
            widget.onVideoCompleted?.call();
          }
        }
      });

    if (widget.autoPlay) {
      _togglePlay();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.forward(from: _playbackProgress);
      } else {
        _animController.stop();
      }
    });
  }

  void _openFullscreenPlayer() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0D0F17),
          insetPadding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                _buildVideoSurface(isFullScreen: true),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFF141724),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: _buildVideoSurface(isFullScreen: false),
      ),
    );
  }

  Widget _buildVideoSurface({required bool isFullScreen}) {
    final thumbnailUrl = widget.hdThumbnailUrl ??
        'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=800&q=80';

    return Stack(
      children: [
        // Demo Video Backdrop Image / Canvas Animation
        Positioned.fill(
          child: Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1B2033),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fitness_center_rounded,
                        color: Color(0xFF00E5FF), size: 48),
                    const SizedBox(height: 8),
                    Text(
                      widget.exerciseName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Dark gradient overlay for video control readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
        ),

        // Animated HD Pulse Badge & Exercise Tag
        Positioned(
          top: 12,
          left: 12,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0055),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'HD DEMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Text(
                  widget.targetMuscle,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Center Play / Pause Animated Trigger
        Center(
          child: GestureDetector(
            onTap: _togglePlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.85)
                    : Colors.black.withValues(alpha: 0.65),
                border: Border.all(
                  color: const Color(0xFF00E5FF),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: _isPlaying ? 0.6 : 0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _isPlaying ? Colors.black : Colors.white,
                size: 38,
              ),
            ),
          ),
        ),

        // Bottom Controls Bar
        Positioned(
          left: 12,
          right: 12,
          bottom: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.exerciseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isFullScreen)
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                      onPressed: _openFullscreenPlayer,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              // Video Playback Progress Scrubber
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _playbackProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
