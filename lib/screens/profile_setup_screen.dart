import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/goal_planner_service.dart';
import '../models/user_model.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _ageController = TextEditingController(text: '25');
  final _heightController = TextEditingController(text: '175');
  final _weightController = TextEditingController(text: '70');
  final _medicalController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedGoal = 'Muscle Building';
  int _selectedDurationDays = 90;
  String _selectedExperience = 'Intermediate';
  int _workoutDaysPerWeek = 5;
  String _selectedFoodPreference = 'Non-Veg';
  String _selectedActivity = 'Moderate';

  bool _isLoading = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _goals = [
    'Weight Loss',
    'Weight Gain',
    'Muscle Building',
    'Six Pack',
    'Strength Training',
    'General Fitness',
  ];
  final List<int> _durations = [30, 60, 90];
  final List<String> _experiences = ['Beginner', 'Intermediate', 'Advanced'];
  final List<String> _foodPreferences = ['Veg', 'Non-Veg', 'Vegan', 'Keto', 'Eggetarian'];
  final List<String> _activities = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];

  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        _photoUrlController.text = user.photoURL!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _medicalController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndGeneratePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authUser = AuthService().currentUser;
      if (authUser == null) return;
      final uid = authUser.uid;

      final age = int.tryParse(_ageController.text) ?? 25;
      final height = double.tryParse(_heightController.text) ?? 175.0;
      final weight = double.tryParse(_weightController.text) ?? 70.0;
      final medicalList = _medicalController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final updatedUser = UserModel(
        uid: uid,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Fitness Champ',
        email: authUser.email ?? '',
        photoUrl: _photoUrlController.text.trim().isNotEmpty
            ? _photoUrlController.text.trim()
            : null,
        age: age,
        gender: _selectedGender,
        heightCm: height,
        weightKg: weight,
        fitnessGoal: _selectedGoal,
        goalDurationDays: _selectedDurationDays,
        goalDurationMonths: (_selectedDurationDays / 30).round(),
        experienceLevel: _selectedExperience,
        workoutDaysPerWeek: _workoutDaysPerWeek,
        foodPreference: _selectedFoodPreference,
        medicalConditions: medicalList,
        dailyActivity: _selectedActivity,
        hasCompletedProfileSetup: true,
        currentWorkoutDay: 1,
        streakCount: 1,
        totalXp: 150,
        completedDaysCount: 0,
        totalCaloriesBurned: 0,
      );

      // Save user profile to Firestore
      await FirestoreService().updateUserProfile(uid, updatedUser.toMap());

      // Auto-generate AI Workout Plan & Diet Plan
      final aiPlan = GoalPlannerService().generateAIPlan(
        user: updatedUser,
        goalTitle: _selectedGoal,
        durationLabel: '$_selectedDurationDays Days Challenge',
        durationDays: _selectedDurationDays,
        age: age,
        gender: _selectedGender,
        heightCm: height,
        weightKg: weight,
        fitnessLevel: _selectedExperience,
        medicalConditions: medicalList,
        availableWorkoutTimeMins: 45,
      );

      await GoalPlannerService().saveActiveGoalPlan(aiPlan, uid: uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Profile Setup Completed! Personalized Plan Generated.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Profile Setup', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0xFF10B981),
                        child: Icon(Icons.bolt, color: Colors.black, size: 28),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalize Your AI Coach',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'One-time setup to build your dynamic 90-day workout & meal roadmap.',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Name & Photo
                _buildSectionHeader('Basic Information', Icons.person_outline),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _photoUrlController,
                  label: 'Profile Photo URL (Optional)',
                  icon: Icons.image_outlined,
                ),
                const SizedBox(height: 20),

                // Biometrics
                _buildSectionHeader('Biometrics & Physical Details', Icons.fitness_center),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || int.tryParse(v) == null ? 'Enter age' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField<String>(
                        value: _selectedGender,
                        label: 'Gender',
                        icon: Icons.wc,
                        items: _genders,
                        onChanged: (val) => setState(() => _selectedGender = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Valid height' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || double.tryParse(v) == null ? 'Valid weight' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Goals & Duration
                _buildSectionHeader('Fitness Goals & Schedule', Icons.emoji_events_outlined),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  value: _selectedGoal,
                  label: 'Fitness Goal',
                  icon: Icons.flag,
                  items: _goals,
                  onChanged: (val) => setState(() => _selectedGoal = val!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField<int>(
                        value: _selectedDurationDays,
                        label: 'Target Duration',
                        icon: Icons.timer,
                        items: _durations,
                        itemText: (d) => '$d Days',
                        onChanged: (val) => setState(() => _selectedDurationDays = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField<String>(
                        value: _selectedExperience,
                        label: 'Experience',
                        icon: Icons.bar_chart,
                        items: _experiences,
                        onChanged: (val) => setState(() => _selectedExperience = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField<int>(
                        value: _workoutDaysPerWeek,
                        label: 'Days Per Week',
                        icon: Icons.calendar_today,
                        items: [3, 4, 5, 6, 7],
                        itemText: (d) => '$d Days/Wk',
                        onChanged: (val) => setState(() => _workoutDaysPerWeek = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDropdownField<String>(
                        value: _selectedActivity,
                        label: 'Activity Level',
                        icon: Icons.directions_run,
                        items: _activities,
                        onChanged: (val) => setState(() => _selectedActivity = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Nutrition & Health
                _buildSectionHeader('Nutrition & Health', Icons.restaurant_menu),
                const SizedBox(height: 12),
                _buildDropdownField<String>(
                  value: _selectedFoodPreference,
                  label: 'Food Preference',
                  icon: Icons.restaurant,
                  items: _foodPreferences,
                  onChanged: (val) => setState(() => _selectedFoodPreference = val!),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _medicalController,
                  label: 'Medical Conditions (e.g. Asthma, Knee Pain, None)',
                  icon: Icons.medical_services_outlined,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfileAndGeneratePlan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Generate Personalized Plan',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    String Function(T)? itemText,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(itemText != null ? itemText(item) : item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
