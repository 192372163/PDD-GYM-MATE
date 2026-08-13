/**
 * GymMate AI Project Knowledge Base & RAG Retriever Module
 * Provides domain-specific fitness, nutrition, hydration, and recovery guidelines.
 */

class KnowledgeRetriever {
  constructor() {
    this.workoutDatabase = {
      chest: ["Bench Press (3x10)", "Incline Dumbbell Press (3x12)", "Cable Flyes (3x15)", "Push-ups (3xMax)"],
      legs: ["Barbell Squats (4x8)", "Romanian Deadlifts (3x10)", "Leg Press (3x12)", "Walking Lunges (3x15 per leg)"],
      back: ["Lat Pulldowns (4x10)", "Barbell Bent-Over Rows (3x8)", "Seated Cable Rows (3x12)", "Face Pulls (3x15)"],
      shoulders: ["Overhead Dumbbell Press (4x8)", "Lateral Raises (4x15)", "Front Raises (3x12)", "Rear Delt Flyes (3x15)"],
      arms: ["Bicep Barbell Curls (3x12)", "Hammer Curls (3x12)", "Tricep Rope Pushdowns (3x15)", "Skull Crushers (3x10)"],
      abs: ["Hanging Leg Raises (3x15)", "Ab Wheel Rollouts (3x12)", "Plank (3x60 sec)", "Russian Twists (3x20)"],
      full_body: ["Squats", "Bench Press", "Bent-Over Rows", "Overhead Press", "Planks"]
    };

    this.recoveryGuidelines = [
      "Muscle soreness (DOMS) usually peaks 24-48 hours post-workout. Active recovery like light walking promotes blood flow.",
      "Hydration and 7-9 hours of deep sleep are essential for protein synthesis and tissue repair.",
      "Magnesium and protein intake post-workout significantly reduce muscle cramping and soreness."
    ];
  }

  /**
   * Calculates energy and macro metrics for a given user profile
   * @param {Object} user 
   */
  calculateUserMetrics(user) {
    if (!user) return null;
    const weight = parseFloat(user.weightKg) || null;
    const height = parseFloat(user.heightCm) || null;
    const age = parseInt(user.age) || null;
    const gender = (user.gender || 'male').toLowerCase();
    const goal = (user.fitnessGoal || '').toLowerCase();
    const activity = (user.dailyActivity || '').toLowerCase();

    if (!weight || !height || !age) {
      return null;
    }

    // Mifflin-St Jeor Formula
    let bmr = (10 * weight) + (6.25 * height) - (5 * age);
    bmr += (gender === 'male') ? 5 : -161;

    let multiplier = 1.2;
    if (activity.includes('light')) multiplier = 1.375;
    else if (activity.includes('very active')) multiplier = 1.725;
    else if (activity.includes('active')) multiplier = 1.55;

    let tdee = bmr * multiplier;
    if (goal.includes('weight loss') || goal.includes('fat loss')) tdee -= 500;
    else if (goal.includes('muscle') || goal.includes('bulk')) tdee += 500;

    let proteinMultiplier = 1.2;
    if (goal.includes('muscle') || goal.includes('gain')) proteinMultiplier = 2.2;
    else if (goal.includes('weight loss') || goal.includes('fat loss')) proteinMultiplier = 1.8;

    const proteinGrams = weight * proteinMultiplier;
    const waterLiters = (weight * 35) / 1000 + (activity.includes('active') ? 0.5 : 0.0);

    return {
      bmr: Math.round(bmr),
      tdee: Math.round(tdee),
      proteinGrams: Math.round(proteinGrams),
      waterLiters: parseFloat(waterLiters.toFixed(1))
    };
  }

  /**
   * Retrieves domain knowledge snippets based on NLP structured analysis
   * @param {Object} nlpAnalysis 
   * @param {Object} userProfile 
   */
  retrieveKnowledge(nlpAnalysis, userProfile) {
    const knowledgeSnippets = [];
    const metrics = this.calculateUserMetrics(userProfile);

    if (metrics) {
      knowledgeSnippets.push(
        `Calculated User Metrics -> Daily Calorie Target: ${metrics.tdee} kcal, Daily Protein Target: ${metrics.proteinGrams} g, Daily Water Target: ${metrics.waterLiters} L.`
      );
    }

    const intent = nlpAnalysis.intent;
    const bodyPart = nlpAnalysis.entities.bodyPart;

    if (intent === 'workout_request') {
      if (bodyPart && this.workoutDatabase[bodyPart]) {
        knowledgeSnippets.push(`Recommended ${bodyPart.toUpperCase()} Exercises: ${this.workoutDatabase[bodyPart].join(', ')}.`);
      } else {
        knowledgeSnippets.push(`Standard Full-Body Workout Routine: ${this.workoutDatabase.full_body.join(', ')}.`);
      }
    } else if (intent === 'recovery_advice') {
      knowledgeSnippets.push(`GymMate Recovery Protocol: ${this.recoveryGuidelines.join(' ')}`);
    } else if (intent === 'water_intake_inquiry') {
      knowledgeSnippets.push(`GymMate Hydration Protocol: Drink 35ml per kg of body weight daily. Increase intake by 500ml during intense training.`);
    }

    return knowledgeSnippets;
  }
}

module.exports = new KnowledgeRetriever();
