import 'package:flutter/material.dart';
import '../models/goal_plan_model.dart';
import '../services/notification_service.dart';

class NotificationsModal extends StatelessWidget {
  final GoalPlanModel? plan;
  final VoidCallback? onOpenWorkoutPlan;

  const NotificationsModal({super.key, this.plan, this.onOpenWorkoutPlan});

  static void show(BuildContext context, {GoalPlanModel? plan, VoidCallback? onOpenWorkoutPlan}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => NotificationsModal(plan: plan, onOpenWorkoutPlan: onOpenWorkoutPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationItems = NotificationService().getNotifications(plan);
    final hasWarning = notificationItems.any((item) => item.isWarning);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: MediaQuery.of(context).size.height * 0.70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (hasWarning) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 12),
                          SizedBox(width: 4),
                          Text('Missed Alert', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Chip(
                label: Text('${notificationItems.length} Total', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                backgroundColor: const Color(0xFF10B981),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: notificationItems.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 16),
              itemBuilder: (context, index) {
                final item = notificationItems[index];
                return InkWell(
                  onTap: () {
                    if (item.isWarning || item.title.contains('Exercises')) {
                      Navigator.of(context).pop();
                      if (onOpenWorkoutPlan != null) {
                        onOpenWorkoutPlan!();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: item.isWarning
                        ? BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          )
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: item.color.withValues(alpha: 0.2),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: item.isWarning ? Colors.redAccent : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.time,
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: item.isWarning ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                              ),
                              if (item.isWarning) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  '👉 Tap here to catch up on your missed routine',
                                  style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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

