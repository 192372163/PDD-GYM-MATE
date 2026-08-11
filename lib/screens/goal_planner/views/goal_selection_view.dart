import 'package:flutter/material.dart';

class GoalSelectionView extends StatefulWidget {
  final String? initialGoal;
  final ValueChanged<String> onGoalSelected;
  final VoidCallback onContinue;

  const GoalSelectionView({
    super.key,
    this.initialGoal,
    required this.onGoalSelected,
    required this.onContinue,
  });

  @override
  State<GoalSelectionView> createState() => _GoalSelectionViewState();
}

class _GoalSelectionViewState extends State<GoalSelectionView> {
  late String _selectedGoal;

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Weight Loss',
      'subtitle': 'Burn fat, increase energy & lean down',
      'icon': Icons.local_fire_department_rounded,
      'color': const Color(0xFFFF5252),
    },
    {
      'title': 'Weight Gain',
      'subtitle': 'Healthy bulk & healthy calorie surplus',
      'icon': Icons.trending_up_rounded,
      'color': const Color(0xFFFFAB00),
    },
    {
      'title': 'Muscle Building',
      'subtitle': 'Hypertrophy training for peak physique',
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFF00E5FF),
    },
    {
      'title': 'Strength Training',
      'subtitle': 'Maximize power, deadlift & compound lifts',
      'icon': Icons.sports_gymnastics_rounded,
      'color': const Color(0xFF76FF03),
    },
    {
      'title': 'Six-Pack Development',
      'subtitle': 'Targeted abs, core density & low body fat',
      'icon': Icons.grid_4x4_rounded,
      'color': const Color(0xFF00E676),
    },
    {
      'title': 'General Fitness',
      'subtitle': 'Overall stamina, health & daily vitality',
      'icon': Icons.favorite_rounded,
      'color': const Color(0xFFFF4081),
    },
    {
      'title': 'Endurance',
      'subtitle': 'Stamina, running, cycling & high cardio',
      'icon': Icons.directions_run_rounded,
      'color': const Color(0xFF40C4FF),
    },
    {
      'title': 'Flexibility',
      'subtitle': 'Joint health, yoga & injury prevention',
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFFE040FB),
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedGoal = widget.initialGoal ?? _goals.first['title'];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0F17),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Step Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'STEP 1 OF 2',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'AI Goal Wizard',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'What is your Fitness Goal?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select the primary target for your personalized AI program.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable Grid of Selectable Cards
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _goals[index];
                final isSelected = _selectedGoal == item['title'];
                final itemColor = item['color'] as Color;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1F30)
                        : const Color(0xFF141724),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E5FF)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 2.2 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _selectedGoal = item['title'];
                      });
                      widget.onGoalSelected(_selectedGoal);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          // Glowing Icon Container
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? itemColor.withValues(alpha: 0.25)
                                  : Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: itemColor.withValues(alpha: 0.5),
                                        blurRadius: 12,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: isSelected ? itemColor : Colors.grey.shade400,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade200,
                                    fontSize: 17,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item['subtitle'],
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Radio indicator glowing
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00E5FF)
                                    : Colors.grey.shade600,
                                width: 2,
                              ),
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.black,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.black,
                elevation: 8,
                shadowColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
