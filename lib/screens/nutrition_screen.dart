import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/nutrition_service.dart';
import 'diet_preferences_screen.dart';
import 'workout_diet_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _nutritionService = NutritionService();

  bool _isGenerating = false;
  DietPlan? _dietPlan;
  String? _lastGeneratedGoal;
  int? _lastGeneratedDuration;

  Future<void> _generatePlan(UserModel user) async {
    setState(() => _isGenerating = true);
    try {
      final plan = await _nutritionService.generateDietPlan(user);
      if (mounted) {
        setState(() {
          _dietPlan = plan;
          _lastGeneratedGoal = user.fitnessGoal;
          _lastGeneratedDuration = user.goalDurationMonths;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating plan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('Not signed in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('AI Dietitian', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF94A3B8)),
            tooltip: 'Diet Preferences',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DietPreferencesScreen()),
              );
              if (mounted) {
                setState(() {
                  _dietPlan = null;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: _firestoreService.streamUserProfile(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF06B6D4)));
          }

          final profile = snapshot.data;

          if (profile == null) {
            return const Center(child: Text('Profile not found.', style: TextStyle(color: Colors.white)));
          }

          // If user hasn't completed diet preferences
          if (profile.foodPreference == null || profile.dailyActivity == null) {
            return _buildSetupState(context);
          }

          // If the profile's goal or duration has changed since we last generated, 
          // prompt the user to generate a new plan.
          bool goalChanged = _lastGeneratedGoal != null && _lastGeneratedGoal != profile.fitnessGoal;
          bool durationChanged = _lastGeneratedDuration != null && _lastGeneratedDuration != profile.goalDurationMonths;

          if (_dietPlan == null || goalChanged || durationChanged) {
            if (!_isGenerating) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _generatePlan(profile);
                }
              });
            }
            return _buildGeneratingState(profile);
          }

          return _buildDietPlanView(profile, _dietPlan!);
        },
      ),
    );
  }

  Widget _buildSetupState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_menu, size: 80, color: Color(0xFF06B6D4)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Personalized AI Nutrition',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'To generate a precision diet plan certified by our AI Nutrition Assistant, please select your food preferences, activity level, and medical history.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DietPreferencesScreen()),
                  );
                  if (mounted) {
                    setState(() {
                      _dietPlan = null;
                    });
                  }
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text('Set Diet Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneratingState(UserModel profile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating Your Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Calculating macros, calories & meal timing based on your profile...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8), height: 1.4),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ],
        ),
      ),
    );
  }

  Widget _buildDietPlanView(UserModel profile, DietPlan plan) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your AI Diet Plan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              OutlinedButton.icon(
                onPressed: () => _generatePlan(profile),
                icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF06B6D4)),
                label: const Text('Refresh', style: TextStyle(color: Color(0xFF06B6D4))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF06B6D4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Profile Quick Stats Strip
          _buildUserProfileSummary(profile),
          const SizedBox(height: 16),

          // Workout-Based Food & Juices Feature Card
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorkoutDietScreen()),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF10B981),
                    Color(0xFF059669),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_dining_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Workout Diet & Juices',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Morning, Afternoon & Evening food items & juices matching today\'s exercise routine.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Diabetic Notice (if applicable)
          if (plan.diabeticNotice != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB45309).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB45309).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      plan.diabeticNotice!,
                      style: const TextStyle(fontSize: 13, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Daily Calories & Macro Breakdown
          _buildMacrosCard(plan),
          const SizedBox(height: 24),

          // Water Intake & Hydration Advice
          _buildHydrationCard(plan),
          const SizedBox(height: 28),

          // Meal Plan Header
          const Text(
            'Daily Meal Plan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            '7 customized meal slots with certified dietitian explanations',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
          const SizedBox(height: 16),

          // 7 Meal Tiles
          _buildMealCard('Pre-Workout', plan.preWorkout, Icons.bolt, const Color(0xFFF59E0B)),
          _buildMealCard('Breakfast', plan.breakfast, Icons.wb_sunny, const Color(0xFF10B981)),
          _buildMealCard('Morning Snack', plan.morningSnack, Icons.apple, const Color(0xFF84CC16)),
          _buildMealCard('Lunch', plan.lunch, Icons.restaurant, const Color(0xFF3B82F6)),
          _buildMealCard('Evening Snack', plan.eveningSnack, Icons.local_cafe, const Color(0xFF8B5CF6)),
          _buildMealCard('Post-Workout', plan.postWorkout, Icons.fitness_center, const Color(0xFFEF4444)),
          _buildMealCard('Dinner', plan.dinner, Icons.nightlight_round, const Color(0xFF6366F1)),
          const SizedBox(height: 28),

          // Indian Food Recommendations
          const Text(
            'Indian Food Recommendations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...plan.indianFoodRecommendations.map((item) => _buildAdviceTile(item, Icons.rice_bowl, const Color(0xFFF97316))),
          const SizedBox(height: 24),

          // Healthy Alternatives
          const Text(
            'Healthy Food Alternatives',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...plan.healthyAlternatives.map((item) => _buildAdviceTile(item, Icons.swap_horiz, const Color(0xFF14B8A6))),
          const SizedBox(height: 24),

          // Cheat Meal Suggestions
          const Text(
            'Controlled Cheat Meal Suggestions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...plan.cheatMeals.map((item) => _buildAdviceTile(item, Icons.cake, const Color(0xFFEC4899))),
          const SizedBox(height: 24),

          // Foods to Avoid
          const Text(
            'Foods to Avoid',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...plan.foodsToAvoid.map((item) => _buildAdviceTile(item, Icons.block, const Color(0xFFEF4444))),
          const SizedBox(height: 28),

          // Medical Disclaimer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, color: Color(0xFF94A3B8), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan.medicalAdviceDisclaimer,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserProfileSummary(UserModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniProfileStat('Weight', '${profile.weightKg ?? "--"} kg'),
          _buildMiniProfileStat('Goal', profile.fitnessGoal ?? "--"),
          _buildMiniProfileStat('Diet', profile.foodPreference ?? "--"),
          _buildMiniProfileStat('Activity', profile.dailyActivity ?? "--"),
        ],
      ),
    );
  }

  Widget _buildMiniProfileStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _buildMacrosCard(DietPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Calorie Target', style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8))),
              Text('${plan.totalCalories} kcal', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFF334155), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroStat('Protein', '${plan.proteinGrams}g', const Color(0xFFEF4444)),
              _buildMacroStat('Carbs', '${plan.carbsGrams}g', const Color(0xFFF59E0B)),
              _buildMacroStat('Fat', '${plan.fatGrams}g', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 16),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              iconColor: const Color(0xFF06B6D4),
              collapsedIconColor: const Color(0xFF06B6D4),
              title: const Text(
                'Why these macro numbers?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
              ),
              children: [
                _buildRationaleRow('Protein:', plan.proteinRationale),
                _buildRationaleRow('Carbs:', plan.carbsRationale),
                _buildRationaleRow('Fats:', plan.fatRationale),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
      ],
    );
  }

  Widget _buildRationaleRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildHydrationCard(DietPlan plan) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 8),
              const Text('Daily Hydration Target', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              Text('${plan.waterIntakeLiters} L', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
            ],
          ),
          const SizedBox(height: 12),
          Text(plan.hydrationAdvice, style: const TextStyle(color: Color(0xFF94A3B8), height: 1.4, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMealCard(String title, MealItem meal, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: color,
          collapsedIconColor: color,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 8),
                  Text(meal.description, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            meal.rationale,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceTile(AdviceItem advice, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(advice.item, style: const TextStyle(fontSize: 14, color: Color(0xFFE2E8F0), height: 1.4, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(advice.reason, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
