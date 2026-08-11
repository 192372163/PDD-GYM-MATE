import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../models/goal_plan_model.dart';
import '../../workout_diet_screen.dart';

class AINutritionPlanView extends StatelessWidget {
  final GoalPlanModel plan;

  const AINutritionPlanView({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    final meals = plan.meals;

    // Calculate current consumed macros from completed meals
    double consumedCalories = 0;
    double consumedProtein = 0;
    double consumedCarbs = 0;
    double consumedFat = 0;

    for (var m in meals) {
      if (plan.tracker.completedMealIds.contains(m.id)) {
        consumedCalories += m.calories;
        consumedProtein += m.proteinGrams;
        consumedCarbs += m.carbsGrams;
        consumedFat += m.fatGrams;
      }
    }

    final double proteinRatio =
        (consumedProtein / (plan.dailyProteinTarget == 0 ? 1 : plan.dailyProteinTarget)).clamp(0.0, 1.0);
    final double carbsRatio =
        (consumedCarbs / (plan.dailyCarbsTarget == 0 ? 1 : plan.dailyCarbsTarget)).clamp(0.0, 1.0);
    final double fatRatio =
        (consumedFat / (plan.dailyFatTarget == 0 ? 1 : plan.dailyFatTarget)).clamp(0.0, 1.0);

    return Container(
      color: const Color(0xFF0D0F17),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF76FF03).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu_rounded,
                          color: Color(0xFF76FF03),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AI Nutrition Plan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tailored for $plan.goalTitle • $plan.dailyCalorieTarget kcal/day',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Today's Workout-Based Diet & Juice Screen Trigger Button
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => WorkoutDietScreen(plan: plan)),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF76FF03), Color(0xFF10B981)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF76FF03).withValues(alpha: 0.3),
                            blurRadius: 12,
                          )
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_dining_rounded, color: Colors.black, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Workout Food & Juices 🍹',
                                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Morning, Afternoon & Evening meals tailored for today\'s workout focus.',
                                  style: TextStyle(color: Colors.black87, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.black, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Total Daily Calories Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1E2638),
                          Color(0xFF141724),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Daily Target',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.dailyCalorieTarget} kcal',
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Consumed Today',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${consumedCalories.toInt()} kcal',
                              style: const TextStyle(
                                color: Color(0xFF76FF03),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Circular Progress Indicators for Macros
                  const Text(
                    'Macronutrient Targets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macroCircularIndicator(
                        label: 'Protein',
                        current: consumedProtein,
                        target: plan.dailyProteinTarget,
                        ratio: proteinRatio,
                        color: const Color(0xFF00E5FF),
                        unit: 'g',
                      ),
                      _macroCircularIndicator(
                        label: 'Carbs',
                        current: consumedCarbs,
                        target: plan.dailyCarbsTarget,
                        ratio: carbsRatio,
                        color: const Color(0xFF76FF03),
                        unit: 'g',
                      ),
                      _macroCircularIndicator(
                        label: 'Fat',
                        current: consumedFat,
                        target: plan.dailyFatTarget,
                        ratio: fatRatio,
                        color: const Color(0xFFFFAB00),
                        unit: 'g',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Daily Meal Blueprint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Meal Cards List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final meal = meals[index];
                  final isDone = plan.tracker.completedMealIds.contains(meal.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141724),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDone
                            ? const Color(0xFF76FF03).withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getMealColor(meal.mealType).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _getMealIcon(meal.mealType),
                                  color: _getMealColor(meal.mealType),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      meal.mealType,
                                      style: TextStyle(
                                        color: _getMealColor(meal.mealType),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      meal.foodName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${meal.calories} kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 10),

                          // Macronutrient Badges: Protein, Carbs, Fat, Water
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _macroItem('Protein', '${meal.proteinGrams.toInt()}g', const Color(0xFF00E5FF)),
                              _macroItem('Carbs', '${meal.carbsGrams.toInt()}g', const Color(0xFF76FF03)),
                              _macroItem('Fat', '${meal.fatGrams.toInt()}g', const Color(0xFFFFAB00)),
                              _macroItem('Water Rec.', '${meal.waterRecommendationLiters}L', const Color(0xFF40C4FF)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: meals.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _macroCircularIndicator({
    required String label,
    required double current,
    required double target,
    required double ratio,
    required Color color,
    required String unit,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 38.0,
          lineWidth: 7.0,
          animation: true,
          percent: ratio,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${current.toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                '/${target.toInt()}$unit',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          circularStrokeCap: CircularStrokeCap.round,
          progressColor: color,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'evening snack':
      case 'snack':
        return Icons.free_breakfast_rounded;
      case 'dinner':
        return Icons.nightlife_rounded;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return const Color(0xFFFFAB00);
      case 'lunch':
        return const Color(0xFF00E5FF);
      case 'evening snack':
      case 'snack':
        return const Color(0xFFE040FB);
      case 'dinner':
        return const Color(0xFF76FF03);
      default:
        return const Color(0xFF00E5FF);
    }
  }
}
