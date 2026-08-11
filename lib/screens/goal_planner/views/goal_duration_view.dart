import 'package:flutter/material.dart';

class GoalDurationView extends StatefulWidget {
  final String selectedGoal;
  final VoidCallback onPrevious;
  final Function(String label, int days) onGeneratePlan;

  const GoalDurationView({
    super.key,
    required this.selectedGoal,
    required this.onPrevious,
    required this.onGeneratePlan,
  });

  @override
  State<GoalDurationView> createState() => _GoalDurationViewState();
}

class _GoalDurationViewState extends State<GoalDurationView> {
  String _selectedLabel = '1 Month';
  int _selectedDays = 30;

  final List<Map<String, dynamic>> _durationOptions = [
    {'label': '2 Weeks', 'days': 14, 'desc': 'Sprint Transformation'},
    {'label': '1 Month', 'days': 30, 'desc': 'Standard Kickstart'},
    {'label': '2 Months', 'days': 60, 'desc': 'Steady Athletic Growth'},
    {'label': '3 Months', 'days': 90, 'desc': 'Complete Body Recomp'},
    {'label': '6 Months', 'days': 180, 'desc': 'Ultimate Mastery'},
    {'label': 'Custom Duration', 'days': 45, 'desc': 'Custom Timeline'},
  ];

  DateTime get _estimatedCompletionDate =>
      DateTime.now().add(Duration(days: _selectedDays));

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} $dt.day, $dt.year';
  }

  Future<void> _pickCustomDuration() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 45)),
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E5FF),
              onPrimary: Colors.black,
              surface: Color(0xFF191D2C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final daysDiff = pickedDate.difference(DateTime.now()).inDays;
      setState(() {
        _selectedLabel = 'Custom ($daysDiff Days)';
        _selectedDays = daysDiff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetDateFormatted = _formatDate(_estimatedCompletionDate);

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
                  color: const Color(0xFF76FF03).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF76FF03).withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'STEP 2 OF 2',
                  style: TextStyle(
                    color: Color(0xFF76FF03),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Goal: $widget.selectedGoal',
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'When do you want to achieve your goal?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your target timeline to calibrate workout intensity & nutritional pace.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
          ),
          const SizedBox(height: 20),

          // Options Grid
          Expanded(
            child: ListView.separated(
              itemCount: _durationOptions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = _durationOptions[index];
                final isSelected = _selectedLabel == option['label'] ||
                    (_selectedLabel.startsWith('Custom') &&
                        option['label'] == 'Custom Duration');

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF192338)
                        : const Color(0xFF141724),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF76FF03)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF76FF03).withValues(alpha: 0.3),
                              blurRadius: 14,
                              spreadRadius: 0.5,
                            )
                          ]
                        : [],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (option['label'] == 'Custom Duration') {
                        _pickCustomDuration();
                      } else {
                        setState(() {
                          _selectedLabel = option['label'];
                          _selectedDays = option['days'];
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 15),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: isSelected
                                ? const Color(0xFF76FF03)
                                : Colors.grey.shade500,
                            size: 22,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option['label'] == 'Custom Duration' &&
                                          _selectedLabel.startsWith('Custom')
                                      ? _selectedLabel
                                      : option['label'],
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade200,
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option['desc'],
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF76FF03).withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${option['label'] == 'Custom Duration' ? _selectedDays : option['days']} Days',
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF76FF03)
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
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

          // Estimated Date Display Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  const Color(0xFF76FF03).withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF00E5FF),
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Completion Date',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetDateFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Previous & Generate Plan Action Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: widget.onPrevious,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade700),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Previous',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => widget.onGeneratePlan(_selectedLabel, _selectedDays),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF76FF03),
                      foregroundColor: Colors.black,
                      elevation: 8,
                      shadowColor: const Color(0xFF76FF03).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Generate AI Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
