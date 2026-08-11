import 'package:flutter/material.dart';

/// User Profile configuration step in the AI Goal Wizard.
/// Collects Age, Gender, Height, Weight, BMI, Fitness Level, Medical Conditions,
/// and Available Workout Time for customized workout schedule generation.
class UserProfileFormView extends StatefulWidget {
  final String selectedGoal;
  final String selectedDurationLabel;
  final int selectedDurationDays;
  final VoidCallback onPrevious;
  final Function({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String level,
    required List<String> medicalConditions,
    required int availableTimeMins,
  }) onGenerateAIPlan;

  const UserProfileFormView({
    super.key,
    required this.selectedGoal,
    required this.selectedDurationLabel,
    required this.selectedDurationDays,
    required this.onPrevious,
    required this.onGenerateAIPlan,
  });

  @override
  State<UserProfileFormView> createState() => _UserProfileFormViewState();
}

class _UserProfileFormViewState extends State<UserProfileFormView> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController(text: '26');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '72');

  String _gender = 'Male';
  String _fitnessLevel = 'Intermediate';
  int _availableTimeMins = 45;

  final List<String> _selectedMedicalConditions = [];

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _levelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  final List<int> _timeOptions = [15, 30, 45, 60, 90];
  final List<String> _medicalOptions = [
    'None',
    'Joint Pain',
    'Hypertension',
    'Asthma',
    'Lower Back Pain',
    'Heart Condition',
    'Recovering from Injury',
  ];

  double get _calculatedBmi {
    final h = double.tryParse(_heightController.text) ?? 175.0;
    final w = double.tryParse(_weightController.text) ?? 72.0;
    if (h <= 0) return 0.0;
    final hM = h / 100;
    return w / (hM * hM);
  }

  String get _bmiCategory {
    final bmi = _calculatedBmi;
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal Weight';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text) ?? 25;
    final height = double.tryParse(_heightController.text) ?? 175.0;
    final weight = double.tryParse(_weightController.text) ?? 72.0;

    widget.onGenerateAIPlan(
      age: age,
      gender: _gender,
      heightCm: height,
      weightKg: weight,
      level: _fitnessLevel,
      medicalConditions: _selectedMedicalConditions.isEmpty
          ? ['None']
          : _selectedMedicalConditions,
      availableTimeMins: _availableTimeMins,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bmiVal = _calculatedBmi.toStringAsFixed(1);

    return Container(
      color: const Color(0xFF0D0F17),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header Progress
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
                    'STEP 3 OF 3',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.selectedGoal} ($widget.selectedDurationLabel)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Personalize Your AI Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Provide biometrics to calculate calorie burn & filter safe exercise routines.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Form inputs scroll view
            Expanded(
              child: ListView(
                children: [
                  // Age, Gender, Height, Weight Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _ageController,
                          label: 'Age (Years)',
                          icon: Icons.cake_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Gender',
                          value: _gender,
                          items: _genderOptions,
                          onChanged: (val) => setState(() => _gender = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _heightController,
                          label: 'Height (cm)',
                          icon: Icons.height,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: _weightController,
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Calculated Live BMI Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141724),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF00E5FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.speed_rounded, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Calculated Body Mass Index (BMI)',
                                style: TextStyle(color: Colors.grey, fontSize: 11)),
                            Row(
                              children: [
                                Text(
                                  bmiVal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF76FF03).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _bmiCategory,
                                    style: const TextStyle(
                                      color: Color(0xFF76FF03),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Fitness Level Picker
                  const Text('Fitness Level',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: _levelOptions.map((level) {
                      final isSelected = _fitnessLevel == level;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Center(child: Text(level)),
                            selected: isSelected,
                            onSelected: (sel) {
                              if (sel) setState(() => _fitnessLevel = level);
                            },
                            selectedColor: const Color(0xFF00E5FF),
                            backgroundColor: const Color(0xFF141724),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Available Workout Time (15, 30, 45, 60, 90 mins)
                  const Text('Available Workout Time (Per Day)',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _timeOptions.map((time) {
                        final isSelected = _availableTimeMins == time;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$time Minutes'),
                            selected: isSelected,
                            onSelected: (sel) {
                              if (sel) setState(() => _availableTimeMins = time);
                            },
                            selectedColor: const Color(0xFF76FF03),
                            backgroundColor: const Color(0xFF141724),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.grey.shade300,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Medical Conditions Filter
                  const Text('Medical Conditions / Constraints',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'AI will automatically filter out contraindicated exercises.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _medicalOptions.map((cond) {
                      final isSelected = _selectedMedicalConditions.contains(cond) ||
                          (cond == 'None' && _selectedMedicalConditions.isEmpty);
                      return FilterChip(
                        label: Text(cond),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (cond == 'None') {
                              _selectedMedicalConditions.clear();
                            } else {
                              _selectedMedicalConditions.remove('None');
                              if (selected) {
                                _selectedMedicalConditions.add(cond);
                              } else {
                                _selectedMedicalConditions.remove(cond);
                              }
                            }
                          });
                        },
                        selectedColor: const Color(0xFFFF0055).withValues(alpha: 0.3),
                        checkmarkColor: const Color(0xFFFF0055),
                        backgroundColor: const Color(0xFF141724),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade300,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Actions
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
                      child: const Text('Previous'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submit,
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
                          Icon(Icons.auto_awesome, size: 20),
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
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF141724),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF191D2C),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF141724),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
      ),
    );
  }
}
