import '../models/user_model.dart';

class MealItem {
  final String name;
  final String description;
  final String rationale;

  const MealItem({
    required this.name,
    required this.description,
    required this.rationale,
  });
}

class AdviceItem {
  final String item;
  final String reason;

  const AdviceItem({
    required this.item,
    required this.reason,
  });
}

class DietPlan {
  final int totalCalories;
  final int proteinGrams;
  final String proteinRationale;
  final int carbsGrams;
  final String carbsRationale;
  final int fatGrams;
  final String fatRationale;
  final double waterIntakeLiters;
  final String waterRationale;

  final MealItem preWorkout;
  final MealItem breakfast;
  final MealItem morningSnack;
  final MealItem lunch;
  final MealItem eveningSnack;
  final MealItem postWorkout;
  final MealItem dinner;

  final List<AdviceItem> healthyAlternatives;
  final List<AdviceItem> cheatMeals;
  final List<AdviceItem> foodsToAvoid;
  final List<AdviceItem> indianFoodRecommendations;

  final String hydrationAdvice;
  final String? diabeticNotice;
  final String medicalAdviceDisclaimer;

  DietPlan({
    required this.totalCalories,
    required this.proteinGrams,
    required this.proteinRationale,
    required this.carbsGrams,
    required this.carbsRationale,
    required this.fatGrams,
    required this.fatRationale,
    required this.waterIntakeLiters,
    required this.waterRationale,
    required this.preWorkout,
    required this.breakfast,
    required this.morningSnack,
    required this.lunch,
    required this.eveningSnack,
    required this.postWorkout,
    required this.dinner,
    required this.healthyAlternatives,
    required this.cheatMeals,
    required this.foodsToAvoid,
    required this.indianFoodRecommendations,
    required this.hydrationAdvice,
    this.diabeticNotice,
    required this.medicalAdviceDisclaimer,
  });
}

class NutritionService {
  /// Generates a personalized diet plan based on the user's physical profile,
  /// fitness goals, daily activity, food preferences, and medical conditions.
  Future<DietPlan> generateDietPlan(UserModel user) async {
    // Simulate short network delay for AI analysis
    await Future.delayed(const Duration(milliseconds: 1200));

    final double weight = user.weightKg ?? 70.0;
    final double height = user.heightCm ?? 170.0;
    final int age = user.age ?? 25;
    final String gender = (user.gender ?? 'Male').toLowerCase();
    final String goal = user.fitnessGoal ?? 'Muscle Gain';
    final String foodPref = user.foodPreference ?? 'Non Vegetarian';
    final String activity = user.dailyActivity ?? 'Moderately Active';
    final List<String> medicalConditions = user.medicalConditions;
    final bool isVegetarian = foodPref.toLowerCase().contains('veg') &&
        !foodPref.toLowerCase().contains('non');
    final bool isDiabetic = medicalConditions.any(
        (c) => c.toLowerCase().contains('diabet') || c.toLowerCase().contains('sugar'));

    // 1. Calculate BMR (Mifflin-St Jeor)
    double bmr;
    if (gender == 'female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    // 2. Activity Multiplier -> TDEE
    double activityMultiplier = 1.375;
    if (activity.toLowerCase().contains('sedentary')) {
      activityMultiplier = 1.2;
    } else if (activity.toLowerCase().contains('light')) {
      activityMultiplier = 1.375;
    } else if (activity.toLowerCase().contains('moderate')) {
      activityMultiplier = 1.55;
    } else if (activity.toLowerCase().contains('very') || activity.toLowerCase().contains('high')) {
      activityMultiplier = 1.725;
    }

    double tdee = bmr * activityMultiplier;

    // 3. Calorie Target by Goal
    int targetCalories;
    if (goal.toLowerCase().contains('loss') || goal.toLowerCase().contains('fat')) {
      targetCalories = (tdee - 500).round();
    } else if (goal.toLowerCase().contains('gain') || goal.toLowerCase().contains('muscle')) {
      targetCalories = (tdee + 350).round();
    } else {
      targetCalories = tdee.round();
    }

    // Prevent dangerously low calories
    if (targetCalories < 1200) targetCalories = 1200;

    // 4. Macro Splits
    // Protein: 1.8g to 2.2g per kg bodyweight based on goal
    double proteinPerKg = goal.toLowerCase().contains('gain') ? 2.2 : 2.0;
    int proteinGrams = (weight * proteinPerKg).round();
    int proteinCalories = proteinGrams * 4;

    // Fat: ~25% of total calories
    int fatCalories = (targetCalories * 0.25).round();
    int fatGrams = (fatCalories / 9).round();

    // Carbs: Remaining calories
    int carbCalories = targetCalories - (proteinCalories + fatCalories);
    int carbsGrams = (carbCalories / 4).round();
    if (carbsGrams < 50) carbsGrams = 50;

    // 5. Water Intake Calculation
    // Base 35ml/kg + 500ml for workout activity
    double waterLiters = ((weight * 35) + 500) / 1000.0;
    waterLiters = double.parse(waterLiters.toStringAsFixed(1));

    // Explication / Rationale strings
    final String proteinRationale =
        "Recommended ${proteinGrams}g (~${proteinPerKg}g/kg) to maximize muscle protein synthesis, aid post-workout repair, and preserve lean tissue during training.";
    final String carbsRationale =
        "Allocated ${carbsGrams}g of complex carbohydrates to replenish muscle glycogen stores, provide steady energy for workouts, and maintain cellular hydration.";
    final String fatRationale =
        "Estimated ${fatGrams}g of healthy unsaturated fats for optimal hormonal function (testosterone/estrogen synthesis), joint health, and nutrient absorption.";
    final String waterRationale =
        "Calculated $waterLiters Liters based on your body mass ($weight kg) and daily physical activity level to maintain peak electrolyte balance and thermoregulation.";

    // 6. Build Meal Plan (with strict Vegetarian / Diabetic adaptation & reasoning)
    MealItem preWorkout;
    MealItem breakfast;
    MealItem morningSnack;
    MealItem lunch;
    MealItem eveningSnack;
    MealItem postWorkout;
    MealItem dinner;

    final bool isWeightLoss = goal.toLowerCase().contains('loss') || goal.toLowerCase().contains('fat');
    final bool isMuscleGain = goal.toLowerCase().contains('gain') || goal.toLowerCase().contains('muscle');

    if (isVegetarian) {
      if (isWeightLoss) {
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel (Weight Loss)",
          description: "1 Small Apple + Green Tea",
          rationale: "Low-calorie fast carbs to fuel the workout without spiking insulin, maximizing fat oxidation.",
        );
        breakfast = const MealItem(
          name: "High-Fiber Breakfast",
          description: "Oats porridge with Water/Almond Milk, Chia Seeds, & 50g Paneer/Tofu bhurji",
          rationale: "High fiber and moderate protein for sustained energy and satiety on a calorie deficit.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Nutrition",
          description: "1 cup Sprouted Moong Salad with lemon & cucumber",
          rationale: "Extremely low calorie, high volume snack to keep you full and provide micronutrients.",
        );
        lunch = const MealItem(
          name: "Lean Vegetarian Lunch",
          description: "1 Multigrain Roti + 1 bowl Chana Dal + Large portion of Steamed Broccoli & Palak",
          rationale: "Prioritizes vegetables for volume eating, with just enough complex carbs for energy.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Handful of Roasted Makhana + Green Tea",
          rationale: "Low calorie crunchy snack to curb evening cravings.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Plant/Whey Protein Isolate in water",
          rationale: "Pure protein to protect muscle mass during weight loss without excess calories.",
        );
        dinner = const MealItem(
          name: "Restorative Dinner",
          description: "Grilled Tofu (100g) with Mixed Vegetable Soup",
          rationale: "Zero-carb evening meal prevents nighttime fat storage while supplying protein for recovery.",
        );
      } else if (isMuscleGain) {
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel (Muscle Gain)",
          description: "2 Bananas + 1 tbsp Peanut Butter + Black Coffee",
          rationale: "Abundant fast-digesting glucose to maximize ATP energy and power output for heavy lifting.",
        );
        breakfast = const MealItem(
          name: "Power Breakfast",
          description: "Large bowl Oats porridge with Whole Milk, 2 tbsp Peanut Butter, Almonds & 150g Paneer",
          rationale: "Calorie-dense breakfast combining complex carbs and high-quality fats/protein for mass gain.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Nutrition",
          description: "Roasted Makhana + 1 cup Greek Yogurt with Honey",
          rationale: "Provides extra calories and probiotics while maintaining steady blood glucose.",
        );
        lunch = const MealItem(
          name: "Mass Building Lunch",
          description: "3 Whole Wheat Rotis + Large bowl Chana Dal + 1 cup Quinoa/Rice + 1 cup Steamed Veggies",
          rationale: "High carbohydrate load to replenish glycogen, paired with complete vegetarian protein.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Handful of Mixed Nuts + Fruit Smoothie",
          rationale: "Nutrient-dense liquid calories to easily meet your surplus calorie target.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Plant/Whey Protein Isolate in milk + 1 Banana",
          rationale: "Spikes insulin to drive amino acids into muscles for maximum hypertrophy.",
        );
        dinner = const MealItem(
          name: "Restorative Dinner",
          description: "Grilled Tofu/Paneer (200g) with Brown Rice & Dal",
          rationale: "Substantial evening meal for overnight muscle repair and sustained caloric surplus.",
        );
      } else { // Maintain
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel",
          description: "1 Medium Banana + 1 tbsp Peanut Butter + Black Coffee / Green Tea",
          rationale: "Fast-digesting glucose from banana provides immediate ATP energy; caffeine boosts focus.",
        );
        breakfast = const MealItem(
          name: "Power Breakfast",
          description: "Oats porridge with Soya Milk, Chia Seeds, Crushed Almonds & 100g Paneer/Tofu bhurji",
          rationale: "Combines slow-release complex carbs with high quality vegetarian protein to sustain amino acid levels.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Nutrition",
          description: "Roasted Makhana (Fox nuts) + 1 cup Sprouted Moong Salad with lemon & cucumber",
          rationale: "High fiber and micronutrients keep blood glucose stable while offering a crunchy, low-calorie snack.",
        );
        lunch = const MealItem(
          name: "Balanced Vegetarian Lunch",
          description: "2 Whole Wheat / Multigrain Rotis + 1 bowl Chana Dal + 1 cup Steamed Broccoli & Palak + Greek Yogurt",
          rationale: "Chana dal paired with whole wheat creates a complete amino acid profile.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Handful of Roasted Chana + Unsweetened Almond Milk or Green Tea",
          rationale: "Provides satiety between lunch and dinner with low glycemic index carbs and plant-based protein.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Plant/Whey Protein Isolate in water + 1/2 cup Watermelon or Dates",
          rationale: "Rapidly delivers essential amino acids to fatigued muscle fibers.",
        );
        dinner = const MealItem(
          name: "Restorative Dinner",
          description: "Grilled Tofu / Paneer Tikka (150g) with Quinoa or Brown Rice & Mixed Vegetable Soup",
          rationale: "Low carb, high protein evening meal prevents nighttime fat storage.",
        );
      }
    } else { // Non-vegetarian
      if (isWeightLoss) {
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel (Weight Loss)",
          description: "1 Rice cake with black coffee",
          rationale: "Minimal calories while providing a slight energy bump for training.",
        );
        breakfast = const MealItem(
          name: "Lean Protein Breakfast",
          description: "4 Egg Whites Omelette with Spinach & Tomatoes",
          rationale: "Extremely low calorie and fat, pure protein to start the day in a deficit.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Boost",
          description: "1 Green Apple",
          rationale: "Low sugar fruit with high pectin fiber for satiety.",
        );
        lunch = const MealItem(
          name: "Fat Loss Lunch",
          description: "150g Grilled Chicken Breast + Large Green Salad (No oil dressing)",
          rationale: "High protein and high volume vegetables to keep you full without excess carbs/fats.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Cucumber slices or 2 Boiled Egg Whites",
          rationale: "Virtually zero calories to curb hunger before dinner.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Whey Protein Isolate in water",
          rationale: "Pure protein for muscle preservation during a caloric deficit.",
        );
        dinner = const MealItem(
          name: "Lean Dinner",
          description: "150g Baked White Fish + Steamed Asparagus",
          rationale: "Very low calorie evening meal prioritizing protein and micronutrients.",
        );
      } else if (isMuscleGain) {
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel (Muscle Gain)",
          description: "2 Rice cakes with 2 tbsp Almond Butter + 1 cup Black Coffee",
          rationale: "High energy carbs and fats for heavy compound lifts.",
        );
        breakfast = const MealItem(
          name: "Protein Breakfast",
          description: "4 Whole Eggs + 2 slices Whole Grain Toast + Oatmeal",
          rationale: "High calorie, rich in healthy fats and complex carbs for morning energy.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Boost",
          description: "Protein Shake or Greek Yogurt with Walnuts & Almonds",
          rationale: "Maintains a constant stream of amino acids into the bloodstream.",
        );
        lunch = const MealItem(
          name: "Mass Building Lunch",
          description: "200g Grilled Chicken/Beef + 2 cups White Rice + Olive Oil dressing",
          rationale: "High protein and easily digestible carbs for optimal glycogen replenishment and surplus calories.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Whole Wheat Chicken Wrap or Tuna Sandwich",
          rationale: "Substantial snack to easily meet high caloric requirements.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Whey Protein + 5g Creatine + 1 Large Banana in Milk",
          rationale: "Maximum insulin spike for nutrient delivery and muscle protein synthesis.",
        );
        dinner = const MealItem(
          name: "Restorative Dinner",
          description: "200g Salmon/Steak + Sweet Potato + Salad",
          rationale: "Rich in omega-3s, saturated fats for testosterone, and slow carbs for overnight growth.",
        );
      } else { // Maintain
        preWorkout = const MealItem(
          name: "Pre-Workout Fuel",
          description: "2 Rice cakes with 1 tbsp Almond Butter + 1 cup Black Coffee",
          rationale: "Easily digestible carbs raise blood sugar efficiently before training.",
        );
        breakfast = const MealItem(
          name: "Protein Breakfast",
          description: "3 Whole Egg Omelette with Spinach & Tomatoes + 2 slices Whole Grain Toast",
          rationale: "Whole eggs furnish complete proteins, choline, and healthy fats.",
        );
        morningSnack = const MealItem(
          name: "Mid-Morning Boost",
          description: "1 Apple + Handful of Mixed Walnuts & Almonds",
          rationale: "Pectin fiber in apple slows sugar absorption while omega-3s reduce inflammation.",
        );
        lunch = const MealItem(
          name: "Lean Muscle Lunch",
          description: "150g Grilled Chicken Breast + 1 cup Brown Rice / Sweet Potato + Steamed Asparagus & Carrots",
          rationale: "Lean poultry offers high leucine content for muscle protein synthesis.",
        );
        eveningSnack = const MealItem(
          name: "Evening Snack",
          description: "Boiled Egg Whites (3) or Greek Yogurt with Berries",
          rationale: "Low-fat, high-protein snack curbs appetite.",
        );
        postWorkout = const MealItem(
          name: "Post-Workout Recovery",
          description: "1 Scoop Whey Protein Isolate + 1 Banana or 5g Creatine",
          rationale: "Spikes muscle protein synthesis and restores intracellular glycogen rapidly.",
        );
        dinner = const MealItem(
          name: "Restorative Dinner",
          description: "150g Baked Fish or Chicken + Large Green Salad with Olive Oil drizzle",
          rationale: "Omega-3 rich fish supports heart health and joint lubrication.",
        );
      }
    }

    // 7. Indian Food Recommendations
    final List<AdviceItem> indianFoodRecs = isVegetarian
        ? const [
            AdviceItem(
              item: "Moong Dal Chilla with Paneer Filling",
              reason: "Rich in plant protein and dietary fiber with low glycemic load; ideal for breakfast or dinner.",
            ),
            AdviceItem(
              item: "Soya Chunks Curry with Brown Rice",
              reason: "Soya chunks contain over 52g protein per 100g dry weight, making it one of the richest vegetarian protein sources.",
            ),
            AdviceItem(
              item: "Palak Paneer (Light Oil / Skimmed Milk Paneer)",
              reason: "Provides calcium, iron, and slow-release casein protein to support bone density and muscle maintenance.",
            ),
            AdviceItem(
              item: "Rajma (Kidney Beans) / Chole with Multigrain Roti",
              reason: "High soluble fiber lowers LDL cholesterol while complex carbs sustain energy.",
            ),
          ]
        : const [
            AdviceItem(
              item: "Tandoori Chicken / Chicken Tikka (Minimal Oil)",
              reason: "High protein, ultra-low carb lean option packed with traditional spices like turmeric (curcumin) and ginger.",
            ),
            AdviceItem(
              item: "Fish Curry with Tomato & Mustard Seed Base",
              reason: "Rich in omega-3 fatty acids, iodine, and vitamin D for cardiovascular and thyroid support.",
            ),
            AdviceItem(
              item: "Egg Bhurji with Whole Wheat Roti & Cucumber Raita",
              reason: "Quick, balanced Indian meal providing bioavailable protein, healthy fats, and probiotics.",
            ),
            AdviceItem(
              item: "Dal Tadka with Soya Chunks & Mixed Salad",
              reason: "Fuses traditional Indian comfort food with high-density protein for optimum macro distribution.",
            ),
          ];

    // 8. Healthy Alternatives, Cheat Meals, Foods to Avoid
    final List<AdviceItem> alternatives = [
      const AdviceItem(
        item: "Swap White Rice for Brown Rice, Quinoa, or Foxtail Millet",
        reason: "Millets and brown rice have a significantly lower glycemic index, preventing insulin spikes and reducing fat storage.",
      ),
      const AdviceItem(
        item: "Swap Refined Sugar for Stevia / Monk Fruit or Small Amount of Honey",
        reason: "Eliminates empty calories and prevents blood glucose volatility.",
      ),
      const AdviceItem(
        item: "Swap Butter/Vanaspati for Extra Virgin Olive Oil or Cold-Pressed Mustard Oil",
        reason: "Replaces saturated and trans fats with monounsaturated fatty acids that protect cardiac health.",
      ),
    ];

    final List<AdviceItem> cheatMealIdeas = [
      const AdviceItem(
        item: "Homemade Thin-Crust Whole Wheat Veggie / Paneer / Chicken Pizza",
        reason: "Allows psychological flexibility while controlling sodium, portion size, and oil quality.",
      ),
      const AdviceItem(
        item: "Dark Chocolate (70%+ cacao, 2-3 squares)",
        reason: "Rich in polyphenols and flavanols that boost nitric oxide and improve vascular endothelial function.",
      ),
    ];

    final List<AdviceItem> avoidFoods = [
      const AdviceItem(
        item: "Deep-Fried Snacks (Samosas, Pakoras, French Fries)",
        reason: "Contains oxidized trans-fats that trigger systemic arterial inflammation and cellular oxidation.",
      ),
      const AdviceItem(
        item: "Sugary Drinks, Carbonated Sodas & Bottled Juices",
        reason: "Delivers rapid liquid fructose that causes hepatic fat accumulation and blunts fat oxidation.",
      ),
      const AdviceItem(
        item: "Refined Flour Products (Maida, White Bread, Bakery Pastries)",
        reason: "Lacks dietary fiber, leading to swift blood sugar spikes followed by energy crashes.",
      ),
    ];

    const String hydrationAdvice =
        "Drink 500ml water immediately upon waking to activate metabolism. Drink 250-300ml every 20 minutes during workouts. Avoid drinking large amounts of water immediately after heavy meals to maintain gastric digestive enzyme concentration.";

    final String? diabeticNotice = isDiabetic
        ? "SPECIAL DIABETIC DIET NOTICE: Because your profile indicates diabetes, all refined sugars, sweet beverages, and high-GI simple carbs have been strictly replaced with high-fiber whole foods, leguminous proteins, and complex carbohydrates to maintain stable glycated hemoglobin (HbA1c) levels."
        : null;

    const String medicalAdviceDisclaimer =
        "DISCLAIMER: This diet plan is generated by GymMate AI for general fitness, body composition, and nutritional guidance. If you have chronic medical conditions (such as advanced kidney disease, severe diabetes, cardiac ailments, or food allergies), please consult a licensed medical doctor or certified clinical dietitian before making drastic dietary changes.";

    return DietPlan(
      totalCalories: targetCalories,
      proteinGrams: proteinGrams,
      proteinRationale: proteinRationale,
      carbsGrams: carbsGrams,
      carbsRationale: carbsRationale,
      fatGrams: fatGrams,
      fatRationale: fatRationale,
      waterIntakeLiters: waterLiters,
      waterRationale: waterRationale,
      preWorkout: preWorkout,
      breakfast: breakfast,
      morningSnack: morningSnack,
      lunch: lunch,
      eveningSnack: eveningSnack,
      postWorkout: postWorkout,
      dinner: dinner,
      healthyAlternatives: alternatives,
      cheatMeals: cheatMealIdeas,
      foodsToAvoid: avoidFoods,
      indianFoodRecommendations: indianFoodRecs,
      hydrationAdvice: hydrationAdvice,
      diabeticNotice: diabeticNotice,
      medicalAdviceDisclaimer: medicalAdviceDisclaimer,
    );
  }
}
