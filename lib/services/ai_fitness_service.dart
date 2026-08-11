import '../models/user_model.dart';

class AIFitnessService {
  /// Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  static double _calculateBMR(UserModel user) {
    if (user.weightKg == null || user.heightCm == null || user.age == null || user.gender == null) {
      return 0.0;
    }
    
    double bmr = (10 * user.weightKg!) + (6.25 * user.heightCm!) - (5 * user.age!);
    
    if (user.gender?.toLowerCase() == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    
    return bmr;
  }

  /// Calculates Total Daily Energy Expenditure (TDEE) based on activity level
  static double calculateDailyCalories(UserModel user) {
    double bmr = _calculateBMR(user);
    if (bmr == 0) return 0.0;

    double multiplier = 1.2; // Sedentary
    final activity = user.dailyActivity?.toLowerCase() ?? 'sedentary';
    
    if (activity.contains('light')) {
      multiplier = 1.375;
    } else if (activity.contains('very active')) {
      multiplier = 1.725;
    } else if (activity.contains('active')) {
      multiplier = 1.55;
    }

    double tdee = bmr * multiplier;

    // Adjust for goal
    final goal = user.fitnessGoal?.toLowerCase() ?? '';
    if (goal.contains('weight loss')) {
      tdee -= 500; // Caloric deficit
    } else if (goal.contains('muscle gain')) {
      tdee += 500; // Caloric surplus
    }
    
    return tdee;
  }

  /// Calculates recommended daily protein intake in grams
  static double calculateProteinIntake(UserModel user) {
    if (user.weightKg == null) return 0.0;
    
    double multiplier = 1.2; // Default for maintenance/sedentary
    final goal = user.fitnessGoal?.toLowerCase() ?? '';
    final exp = user.experienceLevel?.toLowerCase() ?? '';
    
    if (goal.contains('muscle gain') || exp.contains('advanced')) {
      multiplier = 2.2; // High protein for muscle gain
    } else if (goal.contains('weight loss')) {
      multiplier = 1.8; // Higher protein to preserve muscle in deficit
    } else if (user.dailyActivity?.toLowerCase().contains('active') ?? false) {
      multiplier = 1.6;
    }
    
    return user.weightKg! * multiplier;
  }

  /// Calculates recommended daily water intake in liters
  static double calculateWaterIntake(UserModel user) {
    if (user.weightKg == null) return 2.5; // Default fallback
    
    // Base rule: 35ml per kg of body weight
    double liters = (user.weightKg! * 35) / 1000;
    
    // Add 0.5L for active individuals
    if (user.dailyActivity?.toLowerCase().contains('active') ?? false) {
      liters += 0.5;
    }
    
    return liters;
  }

  /// Estimates Body Fat Percentage
  static double estimateBodyFat(UserModel user) {
    if (user.bmi == null || user.age == null || user.gender == null) return 0.0;
    
    final bmi = user.bmi!;
    final age = user.age!;
    final isMale = user.gender?.toLowerCase() == 'male';
    
    // Adult body fat % = (1.20 × BMI) + (0.23 × Age) - (10.8 × gender) - 5.4
    // where gender = 1 for male, 0 for female
    double bf = (1.20 * bmi) + (0.23 * age) - (10.8 * (isMale ? 1 : 0)) - 5.4;
    
    return bf > 0 ? bf : 0.0;
  }

  /// Calculates ideal weight range (kg) based on healthy BMI range (18.5 - 24.9)
  static Map<String, double> getIdealWeightRange(double heightCm) {
    final heightM = heightCm / 100;
    final heightSquared = heightM * heightM;
    
    return {
      'min': 18.5 * heightSquared,
      'max': 24.9 * heightSquared,
    };
  }

  /// Predicts goal completion date based on weekly progress
  static DateTime? predictGoalCompletion(UserModel user, double targetWeightKg) {
    if (user.weightKg == null || user.fitnessGoal == null) return null;
    
    final currentWeight = user.weightKg!;
    final weightDiff = (currentWeight - targetWeightKg).abs();
    
    if (weightDiff < 1) return DateTime.now().add(const Duration(days: 7)); // Almost there
    
    // Assume 0.5 kg change per week (healthy rate)
    final weeksNeeded = (weightDiff / 0.5).ceil();
    return DateTime.now().add(Duration(days: weeksNeeded * 7));
  }
}
