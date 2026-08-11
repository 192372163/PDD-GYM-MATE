import 'package:flutter/material.dart';

/// Status badges for workout days used across Progress and Dashboard screens.
enum WorkoutDayStatus { completed, inProgress, notDone, locked, today }

class WorkoutStatusBadge extends StatelessWidget {
  final WorkoutDayStatus status;
  final bool compact;

  const WorkoutStatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: TextStyle(fontSize: compact ? 11 : 13)),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.color,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (status) {
      case WorkoutDayStatus.completed:
        return const _BadgeConfig('✅', 'Completed', Color(0xFF10B981));
      case WorkoutDayStatus.inProgress:
        return const _BadgeConfig('🟡', 'In Progress', Colors.amber);
      case WorkoutDayStatus.notDone:
        return const _BadgeConfig('❌', 'Not Done', Colors.redAccent);
      case WorkoutDayStatus.locked:
        return const _BadgeConfig('🔒', 'Locked', Color(0xFF475569));
      case WorkoutDayStatus.today:
        return const _BadgeConfig('▶️', 'Today', Color(0xFF06B6D4));
    }
  }
}

class _BadgeConfig {
  final String emoji;
  final String label;
  final Color color;
  const _BadgeConfig(this.emoji, this.label, this.color);
}

/// Glassmorphism stat card used across Dashboard and Progress screens.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }
}
