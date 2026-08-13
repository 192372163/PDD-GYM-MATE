import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void _showEditProfileModal(BuildContext context, UserModel profile) {
    final nameController = TextEditingController(text: profile.name);
    final photoController = TextEditingController(text: profile.photoUrl ?? '');
    final heightController = TextEditingController(text: (profile.heightCm ?? 175.0).toString());
    final weightController = TextEditingController(text: (profile.weightKg ?? 70.0).toString());
    final ageController = TextEditingController(text: (profile.age ?? 25).toString());

    String selectedGoal = profile.fitnessGoal ?? 'Muscle Building';
    String selectedActivity = profile.dailyActivity ?? 'Moderate';
    String selectedFoodPref = profile.foodPreference ?? 'Non-Veg';
    String selectedGender = profile.gender ?? 'Male';

    final goals = [
      'Weight Loss',
      'Weight Gain',
      'Muscle Building',
      'Six Pack',
      'Strength Training',
      'General Fitness',
    ];
    final activities = ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'];
    final foodPrefs = ['Veg', 'Non-Veg', 'Vegan', 'Keto', 'Eggetarian'];
    final genders = ['Male', 'Female', 'Other'];

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Profile',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Icon(Icons.edit_note, color: Color(0xFF10B981), size: 24),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name
                    _buildModalTextField(
                      controller: nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),

                    // Photo URL
                    _buildModalTextField(
                      controller: photoController,
                      label: 'Profile Photo URL',
                      icon: Icons.image,
                    ),
                    const SizedBox(height: 12),

                    // Age & Gender row
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            controller: ageController,
                            label: 'Age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatefulBuilder(
                            builder: (ctx, setGenderState) =>
                              _buildModalDropdown<String>(
                                value: genders.contains(selectedGender) ? selectedGender : 'Male',
                                label: 'Gender',
                                icon: Icons.wc_rounded,
                                items: genders,
                                onChanged: (val) {
                                  setModalState(() => selectedGender = val!);
                                },
                              ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Height & Weight
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalTextField(
                            controller: heightController,
                            label: 'Height (cm)',
                            icon: Icons.height,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildModalTextField(
                            controller: weightController,
                            label: 'Weight (kg)',
                            icon: Icons.monitor_weight,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fitness Goal Dropdown
                    _buildModalDropdown<String>(
                      value: goals.contains(selectedGoal) ? selectedGoal : goals.first,
                      label: 'Fitness Goal',
                      icon: Icons.flag,
                      items: goals,
                      onChanged: (val) => setModalState(() => selectedGoal = val!),
                    ),
                    const SizedBox(height: 12),

                    // Activity Level Dropdown
                    _buildModalDropdown<String>(
                      value: activities.contains(selectedActivity) ? selectedActivity : activities[2],
                      label: 'Activity Level',
                      icon: Icons.directions_run,
                      items: activities,
                      onChanged: (val) => setModalState(() => selectedActivity = val!),
                    ),
                    const SizedBox(height: 12),

                    // Food Preference Dropdown
                    _buildModalDropdown<String>(
                      value: foodPrefs.contains(selectedFoodPref) ? selectedFoodPref : foodPrefs[1],
                      label: 'Food Preference',
                      icon: Icons.restaurant,
                      items: foodPrefs,
                      onChanged: (val) => setModalState(() => selectedFoodPref = val!),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setModalState(() => isSaving = true);
                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  final newHeight = double.tryParse(heightController.text) ?? profile.heightCm ?? 175.0;
                                  final newWeight = double.tryParse(weightController.text) ?? profile.weightKg ?? 70.0;
                                  final newAge = int.tryParse(ageController.text) ?? profile.age ?? 25;

                                  final updatedData = {
                                    'name': nameController.text.trim(),
                                    'photoUrl': photoController.text.trim().isNotEmpty
                                        ? photoController.text.trim()
                                        : null,
                                    'heightCm': newHeight,
                                    'weightKg': newWeight,
                                    'age': newAge,
                                    'gender': selectedGender,
                                    'fitnessGoal': selectedGoal,
                                    'dailyActivity': selectedActivity,
                                    'foodPreference': selectedFoodPref,
                                  };

                                  await _firestoreService.updateUserProfile(profile.uid, updatedData);

                                  if (mounted) {
                                    nav.pop();
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('✅ Profile updated successfully!'),
                                        backgroundColor: Color(0xFF10B981),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Error updating profile: $e')),
                                  );
                                }
                              },
                        child: isSaving
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('Save Profile Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      ),
    );
  }

  Widget _buildModalDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<T> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      dropdownColor: const Color(0xFF0F172A),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF06B6D4)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('Not signed in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Athlete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Sign Out',
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.getUserProfileStream(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
          }

          final user = snapshot.data ??
              UserModel(
                uid: firebaseUser.uid,
                name: firebaseUser.displayName ?? 'Athlete',
                email: firebaseUser.email ?? 'athlete@gymmate.ai',
                photoUrl: firebaseUser.photoURL,
              );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Avatar & Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null || user.photoUrl!.isEmpty
                                ? Text(
                                    user.name.trim().isNotEmpty ? user.name.trim()[0].toUpperCase() : 'A',
                                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.black, size: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      // Quick Stats Strip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatBadge('🔥 Streak', '${user.streakCount} Days', Colors.orangeAccent),
                          _buildStatBadge('⚡ XP', '${user.totalXp} XP', const Color(0xFF06B6D4)),
                          _buildStatBadge('🏆 Workouts', '${user.completedDaysCount}', const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditProfileModal(context, user),
                          icon: const Icon(Icons.edit, color: Color(0xFF10B981), size: 18),
                          label: const Text('Edit Profile Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF10B981)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Physical Details Card
                _buildCardSection(
                  title: 'Body & Goal Metrics',
                  icon: Icons.monitor_weight_outlined,
                  children: [
                    _buildRow('Age', '${user.age ?? 25} years'),
                    _buildRow('Gender', user.gender ?? 'Male'),
                    _buildRow('Height', '${user.heightCm ?? 175.0} cm'),
                    _buildRow('Weight', '${user.weightKg ?? 70.0} kg'),
                    _buildRow('BMI', user.bmi != null ? user.bmi!.toStringAsFixed(1) : '22.8'),
                    _buildRow('Fitness Goal', user.fitnessGoal ?? 'Muscle Building'),
                    _buildRow('Program Duration', '${user.goalDurationDays ?? 90} Days'),
                    _buildRow('Workout Level', user.experienceLevel ?? 'Intermediate'),
                  ],
                ),
                const SizedBox(height: 16),

                // Lifestyle & Preferences Card
                _buildCardSection(
                  title: 'Lifestyle & Preferences',
                  icon: Icons.emoji_events_outlined,
                  children: [
                    _buildRow('Activity Level', user.dailyActivity ?? 'Moderate'),
                    _buildRow('Food Preference', user.foodPreference ?? 'Non-Veg'),
                    _buildRow('Workout Days/Wk', '${user.workoutDaysPerWeek ?? 5} Days'),
                    _buildRow('Joined', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                    _buildRow('Total Calories Burned', '${user.totalCaloriesBurned} kcal'),
                    _buildRow('Medical Conditions',
                        user.medicalConditions.isEmpty ? 'None' : user.medicalConditions.join(', ')),
                  ],
                ),
                const SizedBox(height: 16),

                // Achievements Grid
                _buildAchievementsCard(user),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          Flexible(
            child: Text(value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(UserModel user) {
    final achievements = [
      {'name': 'Early Bird', 'icon': Icons.wb_sunny_rounded, 'color': const Color(0xFFFBBF24), 'desc': 'Joined GymMate'},
      {'name': 'First Step', 'icon': Icons.directions_run_rounded, 'color': const Color(0xFF10B981), 'desc': 'First workout'},
      {'name': 'Week Warrior', 'icon': Icons.local_fire_department, 'color': Colors.orangeAccent, 'desc': '7-day streak'},
      {'name': 'Goal Setter', 'icon': Icons.flag_rounded, 'color': const Color(0xFF06B6D4), 'desc': 'Set a goal plan'},
      {'name': 'Calorie Crusher', 'icon': Icons.bolt_rounded, 'color': Colors.purpleAccent, 'desc': 'Burned 1000 kcal'},
      {'name': 'Iron Will', 'icon': Icons.fitness_center, 'color': Colors.redAccent, 'desc': '14 workouts done'},
      {'name': 'Consistency', 'icon': Icons.trending_up_rounded, 'color': Colors.greenAccent, 'desc': '30-day streak'},
      {'name': 'Champion', 'icon': Icons.military_tech_rounded, 'color': const Color(0xFFFBBF24), 'desc': 'Complete a program'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.military_tech_rounded, color: Color(0xFFFBBF24), size: 20),
              SizedBox(width: 8),
              Text('Achievements & Badges', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Color(0xFF334155), height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, i) {
              final badge = achievements[i];
              final isUnlocked = user.unlockedBadges.contains(badge['name'] as String) ||
                  (badge['name'] == 'Early Bird') ||
                  (badge['name'] == 'First Step' && user.completedDaysCount > 0) ||
                  (badge['name'] == 'Week Warrior' && user.streakCount >= 7) ||
                  (badge['name'] == 'Goal Setter' && user.hasCompletedProfileSetup) ||
                  (badge['name'] == 'Calorie Crusher' && user.totalCaloriesBurned >= 1000) ||
                  (badge['name'] == 'Iron Will' && user.completedDaysCount >= 14) ||
                  (badge['name'] == 'Consistency' && user.streakCount >= 30) ||
                  (badge['name'] == 'Champion' && user.completedDaysCount >= (user.goalDurationDays ?? 90));
              final color = badge['color'] as Color;
              final icon = badge['icon'] as IconData;

              return Tooltip(
                message: badge['desc'] as String,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUnlocked ? color.withValues(alpha: 0.12) : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked ? color.withValues(alpha: 0.4) : const Color(0xFF1E293B),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: isUnlocked ? color : const Color(0xFF334155), size: 24),
                      const SizedBox(height: 6),
                      Text(
                        badge['name'] as String,
                        style: TextStyle(
                          color: isUnlocked ? color : const Color(0xFF334155),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isUnlocked) ...[
                        const SizedBox(height: 4),
                        const Icon(Icons.lock_rounded, color: Color(0xFF334155), size: 10),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

