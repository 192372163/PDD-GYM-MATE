import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/goal_plan_model.dart';
import '../services/auth_service.dart';
import '../services/goal_planner_service.dart';

/// Screen displaying Workout-Specific Diet Items and Juices tailored for Morning, Afternoon, and Evening
/// based on Today's Workout Focus Area.
class WorkoutDietScreen extends StatefulWidget {
  final GoalPlanModel? plan;
  final String? initialWorkoutFocus;

  const WorkoutDietScreen({
    super.key,
    this.plan,
    this.initialWorkoutFocus,
  });

  @override
  State<WorkoutDietScreen> createState() => _WorkoutDietScreenState();
}

class _WorkoutDietScreenState extends State<WorkoutDietScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoalPlanModel? _activePlan;
  bool _isLoading = false;
  
  late String _selectedWorkoutFocus;
  final Set<String> _loggedMealKeys = {};

  final List<String> _workoutFocusOptions = [
    'Chest & Triceps',
    'Legs & Core',
    'Back & Biceps',
    'Shoulders & Abs',
    'HIIT & Cardio',
    'Rest & Recovery',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _activePlan = widget.plan;
    
    if (widget.initialWorkoutFocus != null) {
      _selectedWorkoutFocus = widget.initialWorkoutFocus!;
    } else if (_activePlan != null) {
      final activeDay = _activePlan!.workoutDays[_activePlan!.currentActiveDayIndex.clamp(0, _activePlan!.workoutDays.length - 1)];
      _selectedWorkoutFocus = activeDay.focusArea;
    } else {
      _selectedWorkoutFocus = 'Chest & Triceps';
      _loadPlanIfNeeded();
    }
  }

  Future<void> _loadPlanIfNeeded() async {
    if (_activePlan != null) return;
    setState(() => _isLoading = true);
    final user = AuthService().currentUser;
    final plan = await GoalPlannerService().loadActiveGoalPlan(uid: user?.uid);
    if (mounted) {
      setState(() {
        _activePlan = plan;
        if (plan != null) {
          final activeDay = plan.workoutDays[plan.currentActiveDayIndex.clamp(0, plan.workoutDays.length - 1)];
          _selectedWorkoutFocus = activeDay.focusArea;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getDietForFocus(String focus) {
    final lower = focus.toLowerCase();
    
    if (lower.contains('leg')) {
      return {
        'focus': 'Legs & Core (Heavy Lower Body)',
        'strategy': '⚡ High glycogen replenishment, high potassium & electrolytes to prevent muscle cramps and sustain heavy leg power.',
        'accentColor': const Color(0xFFFF5252),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'Rolled Oatmeal with Banana, Greek Yogurt & Chia Seeds',
              'calories': 460,
              'protein': 26,
              'carbs': 62,
              'fats': 12,
              'rationale': 'Slow-release complex carbohydrates build glycogen reserves for lower body power.',
              'ingredients': ['1 cup Rolled Oats', '1 Banana', '150g Greek Yogurt', '1 tbsp Chia Seeds', 'Honey'],
              'prep': 'Cook oats in water/milk, top with sliced banana, Greek yogurt, chia seeds and honey.',
            },
            'juice': {
              'name': '🍌 Banana Potassium Power Smoothie',
              'calories': 210,
              'keyNutrient': 'Potassium & Sodium Electrolytes',
              'rationale': 'Rich in potassium to prevent quad/hamstring cramping during heavy leg workouts.',
              'ingredients': ['1 Ripe Banana', '250ml Oat Milk', '1 cup Baby Spinach', '2 Medjool Dates'],
              'prep': 'Blend all ingredients on high speed for 60 seconds until silky smooth.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Post-Workout & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Lean Ground Turkey / Tofu Bowl with Brown Rice & Avocado',
              'calories': 580,
              'protein': 46,
              'carbs': 64,
              'fats': 16,
              'rationale': 'High leucine protein and complex carbs for rapid quad and glute muscular synthesis.',
              'ingredients': ['200g Lean Turkey/Tofu', '1 cup Brown Rice', '1/2 Avocado', 'Black Beans', 'Salsa'],
              'prep': 'Sauté turkey/tofu with spices, assemble with warm rice, beans, fresh avocado and salsa.',
            },
            'juice': {
              'name': '🍉 Watermelon Mint Hydramax Electrolyte Juice',
              'calories': 130,
              'keyNutrient': 'L-Citrulline & Hydration',
              'rationale': 'Natural L-citrulline reduces muscle soreness (DOMS) in legs post-workout.',
              'ingredients': ['2 cups Fresh Watermelon', '5 Mint Leaves', '150ml Coconut Water', 'Pinch of Himalayan Salt'],
              'prep': 'Blend watermelon, mint, and coconut water; stir in Himalayan pink salt and serve over ice.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Grilled Steak / Paneer with Quinoa & Steamed Broccoli',
              'calories': 490,
              'protein': 42,
              'carbs': 38,
              'fats': 16,
              'rationale': 'Sustained amino acid supply for overnight lower body muscle fiber rebuilding.',
              'ingredients': ['180g Lean Steak or Paneer', '3/4 cup Cooked Quinoa', '1.5 cups Steamed Broccoli', 'Olive Oil'],
              'prep': 'Grill steak/paneer to perfection, serve alongside warm quinoa and steamed garlic broccoli.',
            },
            'juice': {
              'name': '🥝 Kiwi Spinach Green Nerve Relaxation Juice',
              'calories': 105,
              'keyNutrient': 'Magnesium & Vitamin C',
              'rationale': 'High magnesium relaxes lower back and leg motor nerves for deep sleep.',
              'ingredients': ['2 Kiwis peeled', '1 cup Spinach', '1/2 Green Apple', 'Lemon Juice'],
              'prep': 'Juice kiwis, spinach, and apple; finish with a squeeze of fresh lemon juice.',
            }
          }
        ]
      };
    } else if (lower.contains('back') || lower.contains('biceps')) {
      return {
        'focus': 'Back & Biceps (Upper Body Pull)',
        'strategy': '💪 Targeted high-density amino acids and collagen support for lats, rhomboids and biceps recovery.',
        'accentColor': const Color(0xFF3B82F6),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'Whole Egg & Spinach Scramble on Toast with Tomatoes',
              'calories': 410,
              'protein': 30,
              'carbs': 34,
              'fats': 16,
              'rationale': 'Whole egg choline and protein activate central nervous system for pulling exercises.',
              'ingredients': ['3 Whole Eggs', '1 cup Spinach', '2 Slices Whole Grain Toast', 'Cherry Tomatoes'],
              'prep': 'Scramble eggs with spinach, serve on toasted whole grain bread with sliced tomatoes.',
            },
            'juice': {
              'name': '🍏 Green Apple Celery Alkaline Juice',
              'calories': 95,
              'keyNutrient': 'Joint Fluid Hydration & Silica',
              'rationale': 'Provides essential bio-minerals to support shoulder and elbow joint cartilage during pulls.',
              'ingredients': ['1 Green Apple', '3 Celery Stalks', '1/2 Cucumber', 'Fresh Lemon'],
              'prep': 'Pass apple, celery, and cucumber through juicer; stir in fresh lemon juice.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Post-Workout & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Seared Tuna Steak / Chickpea Power Bowl with Wild Rice',
              'calories': 520,
              'protein': 48,
              'carbs': 48,
              'fats': 12,
              'rationale': 'Ultra-lean protein to repair micro-tears in latissimus dorsi and bicep brachii.',
              'ingredients': ['180g Tuna Steak or Chickpeas', '1 cup Wild Rice', 'Bell Peppers', 'Sesame Soy Dressing'],
              'prep': 'Sear tuna for 2 mins per side; bowl with wild rice, sauted peppers, and light sesame soy.',
            },
            'juice': {
              'name': '🫐 Blueberry Whey Biceps Recovery Shake',
              'calories': 220,
              'keyNutrient': 'Antioxidants & Fast Whey Protein',
              'rationale': 'Antioxidants flush oxidative stress from heavy lat pulldowns and bicep curls.',
              'ingredients': ['1 scoop Whey Protein', '1/2 cup Wild Blueberries', '250ml Unsweetened Almond Milk', 'Ice'],
              'prep': 'Blend whey protein, blueberries, almond milk, and ice on high for 45 seconds.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Herb Roasted Chicken Breast with Sweet Potato Mash',
              'calories': 470,
              'protein': 44,
              'carbs': 38,
              'fats': 12,
              'rationale': 'Clean, easily digestible protein combined with slow carbs for nighttime repair.',
              'ingredients': ['200g Chicken Breast', '1 Medium Sweet Potato', 'Roasted Carrots', 'Rosemary & Thyme'],
              'prep': 'Season chicken with herbs and bake at 200°C for 25 mins. Serve with mashed sweet potato.',
            },
            'juice': {
              'name': '🥛 Golden Turmeric & Honey Recovery Elixir',
              'calories': 140,
              'keyNutrient': 'Curcumin & Anti-Inflammatory',
              'rationale': 'Curcumin reduces upper back stiffness and spinal muscle tension.',
              'ingredients': ['250ml Warm Almond Milk', '1/2 tsp Turmeric', 'Pinch Black Pepper', '1 tsp Raw Honey'],
              'prep': 'Whisk turmeric and black pepper into warm almond milk, sweeten with honey before bed.',
            }
          }
        ]
      };
    } else if (lower.contains('cardio') || lower.contains('hiit')) {
      return {
        'focus': 'HIIT & Cardio (Endurance & Fat Loss)',
        'strategy': '🏃 High hydration, rapid electrolyte recovery, moderate lean protein, low heavy fats.',
        'accentColor': const Color(0xFFFFAB00),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'Fruit & Granola Yogurt Parfait with Flaxseeds',
              'calories': 380,
              'protein': 20,
              'carbs': 58,
              'fats': 8,
              'rationale': 'Light carbohydrate loading provides quick energy without heavy stomach fullness.',
              'ingredients': ['150g Low-fat Yogurt', '1/2 cup Mixed Berries', '1/3 cup Granola', '1 tbsp Flaxseeds'],
              'prep': 'Layer yogurt, fresh berries, crunchy granola, and ground flaxseeds in a bowl.',
            },
            'juice': {
              'name': '🍊 Citrus Carrot Ginger Energizer Juice',
              'calories': 115,
              'keyNutrient': 'Vitamin C & Metabolic Gingerol',
              'rationale': 'Fires up metabolism and delivers fast natural glucose for high-intensity intervals.',
              'ingredients': ['2 Fresh Oranges', '2 Carrots', '1 inch Ginger root', '1/2 Lemon'],
              'prep': 'Juice oranges, carrots, and ginger together; serve over fresh ice cubes.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Post-Workout & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Grilled Chicken / Tofu Salad Wrap with Hummus & Spinach',
              'calories': 440,
              'protein': 36,
              'carbs': 42,
              'fats': 12,
              'rationale': 'Balanced, clean protein wrap to replenish energy stores without sluggishness.',
              'ingredients': ['150g Grilled Chicken/Tofu', '1 Whole Wheat Tortilla', '2 tbsp Hummus', 'Baby Spinach'],
              'prep': 'Spread hummus over tortilla, top with sliced chicken/tofu and spinach, wrap tightly.',
            },
            'juice': {
              'name': '🥥 Pure Coconut Lime Electrolyte Hydramax Juice',
              'calories': 75,
              'keyNutrient': 'Natural Isotonic Electrolytes',
              'rationale': 'Replaces lost sweat minerals (Sodium, Potassium, Magnesium) instantly after HIIT.',
              'ingredients': ['300ml Fresh Coconut Water', 'Squeeze of 1/2 Lime', 'Pinch Sea Salt'],
              'prep': 'Mix chilled coconut water with fresh lime juice and a tiny pinch of sea salt.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Steamed White Fish / Tofu Stir-Fry with Brown Rice',
              'calories': 410,
              'protein': 38,
              'carbs': 44,
              'fats': 7,
              'rationale': 'Ultra lean meal preventing fat storage while refueling cellular stamina.',
              'ingredients': ['180g White Fish or Tofu', '3/4 cup Brown Rice', 'Mixed Bell Peppers & Peas', 'Soy Ginger Sauce'],
              'prep': 'Steam fish/tofu with ginger and soy, serve over brown rice and stir-fried vegetables.',
            },
            'juice': {
              'name': '🍇 Grapefruit Mint Fat-Burn & Detox Juice',
              'calories': 85,
              'keyNutrient': 'Naringin & Enzymes',
              'rationale': 'Supports nocturnal lipid metabolism and maintains systemic hydration.',
              'ingredients': ['1 Pink Grapefruit', '1/4 cup Cranberry Juice (Unsweetened)', 'Fresh Mint'],
              'prep': 'Press fresh grapefruit juice, blend with cranberry juice and crushed mint leaves.',
            }
          }
        ]
      };
    } else if (lower.contains('shoulder') || lower.contains('abs') || lower.contains('arm')) {
      return {
        'focus': 'Shoulders & Abs (Sculpt & Definition)',
        'strategy': '🔥 Sodium-controlled lean protein density to promote vascularity and abdominal muscle definition.',
        'accentColor': const Color(0xFF00E5FF),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'High-Protein Oat Pancakes with Fresh Berries',
              'calories': 420,
              'protein': 32,
              'carbs': 48,
              'fats': 8,
              'rationale': 'Delivers high amino acid density to sculpt deltoids while staying low in fat.',
              'ingredients': ['1 cup Oat Flour', '1 scoop Vanilla Whey', '2 Egg Whites', '1/2 cup Blueberries'],
              'prep': 'Whisk flour, whey, egg whites and water. Cook on non-stick skillet; top with berries.',
            },
            'juice': {
              'name': '🥭 Mango Spinach Beta-Carotene Boost Juice',
              'calories': 130,
              'keyNutrient': 'Vitamin A & Antioxidants',
              'rationale': 'Supports connective tissue elasticity around shoulder rotators.',
              'ingredients': ['1/2 cup Mango chunks', '1 cup Fresh Spinach', '200ml Coconut Water', 'Lime'],
              'prep': 'Blend mango, spinach, coconut water, and a squeeze of lime juice until smooth.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Post-Workout & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Egg White & Grilled Chicken Salad Bowl with Quinoa',
              'calories': 480,
              'protein': 50,
              'carbs': 38,
              'fats': 10,
              'rationale': 'Pure lean protein block maximizing shoulder hypertrophy and abdominal tightness.',
              'ingredients': ['150g Chicken Breast', '3 Hard Boiled Egg Whites', '1/2 cup Quinoa', 'Cucumber & Tomato'],
              'prep': 'Toss sliced chicken, egg whites, quinoa, cucumber, and tomatoes with lemon dressing.',
            },
            'juice': {
              'name': '🍓 Strawberry Basil Hydration Tonic',
              'calories': 95,
              'keyNutrient': 'Polyphenols & Hydration',
              'rationale': 'Flushes extracellular water retention to enhance core muscle visibility.',
              'ingredients': ['1 cup Strawberries', '4 Basil Leaves', '200ml Filtered Water', '1 tsp Lemon'],
              'prep': 'Blend strawberries and basil with cold water; strain and serve over ice.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Cottage Cheese / Baked Cod with Steamed Green Beans',
              'calories': 400,
              'protein': 42,
              'carbs': 28,
              'fats': 9,
              'rationale': 'Slow-release casein / white fish protein keeps core tight and metabolically active.',
              'ingredients': ['200g Cottage Cheese or Cod Filet', '1.5 cups Green Beans', '1/3 cup Brown Rice', 'Herbs'],
              'prep': 'Bake cod with lemon & herbs or serve fresh seasoned cottage cheese with green beans.',
            },
            'juice': {
              'name': '🥒 Cucumber Mint Core Definition Refresher',
              'calories': 45,
              'keyNutrient': 'Natural Diuretic Potassium',
              'rationale': 'Acts as a natural mild diuretic to keep waistline sleek overnight.',
              'ingredients': ['1 Whole Cucumber', 'Handful Mint', '1/2 Lemon', 'Pinch Pink Salt'],
              'prep': 'Juice cucumber and mint; stir in lemon juice and a tiny pinch of pink salt.',
            }
          }
        ]
      };
    } else if (lower.contains('rest') || lower.contains('recovery')) {
      return {
        'focus': 'Rest Day & Active Recovery',
        'strategy': '🌿 Anti-inflammatory nutrients, reduced total calories, gut-friendly fiber and cellular repair.',
        'accentColor': const Color(0xFF10B981),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'Avocado Toast with Poached Eggs & Pumpkin Seeds',
              'calories': 360,
              'protein': 22,
              'carbs': 28,
              'fats': 18,
              'rationale': 'Healthy monounsaturated fats restore hormone balance on rest days.',
              'ingredients': ['2 Poached Eggs', '1/2 Ripe Avocado', '1 Slice Sourdough Toast', '1 tbsp Pumpkin Seeds'],
              'prep': 'Mash avocado onto warm sourdough, top with poached eggs and toasted pumpkin seeds.',
            },
            'juice': {
              'name': '🍋 Warm Lemon Honey Detox Elixir',
              'calories': 55,
              'keyNutrient': 'Bioflavonoids & Digestive Enzymes',
              'rationale': 'Gently stimulates liver metabolism and digestion on non-training mornings.',
              'ingredients': ['300ml Warm Water', 'Juice of 1/2 Lemon', '1 tsp Raw Honey', 'Pinch Cayenne'],
              'prep': 'Stir fresh lemon juice and raw honey into warm water; add cayenne pepper.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Recovery & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Mediterranean Chickpea & Feta Salad with Olive Oil',
              'calories': 420,
              'protein': 20,
              'carbs': 46,
              'fats': 16,
              'rationale': 'High dietary fiber and polyphenols optimize gut microbiome health.',
              'ingredients': ['1 cup Cooked Chickpeas', '30g Feta Cheese', 'Cucumber', 'Olives', 'Extra Virgin Olive Oil'],
              'prep': 'Combine chickpeas, diced cucumber, kalamata olives, crumbled feta, and olive oil.',
            },
            'juice': {
              'name': '🥒 Super Green Alkalizing Detox Juice',
              'calories': 85,
              'keyNutrient': 'Chlorophyll & Micronutrients',
              'rationale': 'Restores body pH balance and supplies micronutrients for systemic healing.',
              'ingredients': ['2 Kale Leaves', '1 Celery Stalk', '1 Cucumber', '1 Green Apple', 'Lemon'],
              'prep': 'Juice all green ingredients together; stir well and consume fresh.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Light Lentil & Vegetable Soup with Whole Grain Bread',
              'calories': 380,
              'protein': 24,
              'carbs': 52,
              'fats': 6,
              'rationale': 'Easy on the digestive tract, allowing maximum energy for cellular repair during sleep.',
              'ingredients': ['1 cup Yellow Lentil Soup', 'Mixed Vegetables (Carrot, Zucchini)', '1 Slice Bread'],
              'prep': 'Simmer lentils with diced vegetables and cumin until tender. Serve warm with bread.',
            },
            'juice': {
              'name': '🍒 Tart Cherry & Chamomile Melatonin Sleep Juice',
              'calories': 60,
              'keyNutrient': 'Natural Melatonin & Anthocyanins',
              'rationale': 'Proven to increase sleep duration and reduce DOMS muscle soreness by 40%.',
              'ingredients': ['150ml Pure Tart Cherry Juice', '100ml Cold Brewed Chamomile Tea', 'Honey'],
              'prep': 'Mix tart cherry juice with chilled chamomile tea; sweeten lightly if desired.',
            }
          }
        ]
      };
    } else {
      // Default: Chest & Triceps / Upper Body Push
      return {
        'focus': 'Chest & Triceps (Upper Body Push)',
        'strategy': '🏋️ High Leucine protein for muscle fiber repair, moderate complex carbs for stamina, nitric oxide juices.',
        'accentColor': const Color(0xFF76FF03),
        'meals': [
          {
            'slot': 'Morning',
            'slotName': '🌅 Morning Fuel & Juice',
            'time': '07:00 AM - 09:00 AM',
            'food': {
              'name': 'Spinach & Cheese Omelet with Whole Wheat Toast',
              'calories': 400,
              'protein': 28,
              'carbs': 32,
              'fats': 16,
              'rationale': 'Optimal morning protein and complex carbs to prime upper body muscles.',
              'ingredients': ['3 Eggs', '1 cup Spinach', '30g Low-fat Cheese', '2 Slices Toast'],
              'prep': 'Whisk eggs, pour onto skillet with spinach and cheese, fold and serve with toast.',
            },
            'juice': {
              'name': '🍊 Citrus Beet Nitric Oxide Power Juice',
              'calories': 110,
              'keyNutrient': 'Dietary Nitrates & Vitamin C',
              'rationale': 'Boosts nitric oxide for blood vessel dilation, enhancing muscle pump.',
              'ingredients': ['1/2 Medium Beetroot', '1 Orange', '1 Carrot', '1/2 inch Ginger'],
              'prep': 'Pass beetroot, orange, carrot, and ginger through a juicer and serve cold.',
            }
          },
          {
            'slot': 'Afternoon',
            'slotName': '☀️ Afternoon Post-Workout & Juice',
            'time': '12:30 PM - 02:30 PM',
            'food': {
              'name': 'Grilled Chicken Breast with Quinoa & Steamed Asparagus',
              'calories': 530,
              'protein': 50,
              'carbs': 44,
              'fats': 11,
              'rationale': '50g pure protein refueling chest & tricep muscle fibers immediately post-lift.',
              'ingredients': ['200g Chicken Breast', '1 cup Cooked Quinoa', 'Steamed Asparagus', 'Olive Oil'],
              'prep': 'Grill seasoned chicken breast, serve alongside fluffy quinoa and tender asparagus.',
            },
            'juice': {
              'name': '🥤 Pineapple Ginger Bromelain Recovery Smoothie',
              'calories': 195,
              'keyNutrient': 'Bromelain & Protein Synthesis',
              'rationale': 'Bromelain enzymes accelerate tissue repair and soothe tendon tightness.',
              'ingredients': ['1 cup Pineapple chunks', '1 scoop Whey Protein', '200ml Coconut Water', 'Ginger'],
              'prep': 'Blend pineapple, whey protein, coconut water, and grated ginger until creamy.',
            }
          },
          {
            'slot': 'Evening',
            'slotName': '🌙 Evening Recovery & Juice',
            'time': '07:00 PM - 09:00 PM',
            'food': {
              'name': 'Pan-Seared Salmon / Paneer with Sweet Potato Mash',
              'calories': 480,
              'protein': 40,
              'carbs': 38,
              'fats': 17,
              'rationale': 'Omega-3 fatty acids cut down joint inflammation from heavy bench pressing.',
              'ingredients': ['180g Salmon or Paneer', '1 Medium Sweet Potato', 'Steamed Broccoli', 'Lemon'],
              'prep': 'Sear salmon skin-side down for 4 mins per side, pair with mashed sweet potato.',
            },
            'juice': {
              'name': '🍓 Tart Cherry & Magnesium Bedtime Repair Shake',
              'calories': 120,
              'keyNutrient': 'Tart Cherry Anthocyanins',
              'rationale': 'Stimulates overnight muscle protein synthesis and promotes deep sleep.',
              'ingredients': ['150ml Tart Cherry Juice', '200ml Almond Milk', '1 tbsp Chia Seeds'],
              'prep': 'Stir tart cherry juice into cold almond milk with chia seeds; let rest 5 mins before drinking.',
            }
          }
        ]
      };
    }
  }

  void _toggleLogMeal(String key, String title) {
    setState(() {
      if (_loggedMealKeys.contains(key)) {
        _loggedMealKeys.remove(key);
        Fluttertoast.showToast(msg: "Removed $title from diet log");
      } else {
        _loggedMealKeys.add(key);
        Fluttertoast.showToast(
          msg: "✅ Logged $title for today!",
          backgroundColor: const Color(0xFF10B981),
          textColor: Colors.black,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dietData = _getDietForFocus(_selectedWorkoutFocus);
    final Color accentColor = dietData['accentColor'] as Color;
    final List<Map<String, dynamic>> meals = List<Map<String, dynamic>>.from(dietData['meals']);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141724),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Workout-Based Diet & Juices',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tailored for $_selectedWorkoutFocus',
              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF76FF03)))
          : Column(
              children: [
                // Top Selector Bar for Workout Focus
                Container(
                  color: const Color(0xFF141724),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Select Today\'s Workout Focus:',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _workoutFocusOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final opt = _workoutFocusOptions[index];
                            final isSelected = opt.toLowerCase() == _selectedWorkoutFocus.toLowerCase() ||
                                _selectedWorkoutFocus.toLowerCase().contains(opt.split(' ')[0].toLowerCase());
                            return ChoiceChip(
                              label: Text(
                                opt,
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: accentColor,
                              backgroundColor: const Color(0xFF1E2638),
                              onSelected: (_) {
                                setState(() {
                                  _selectedWorkoutFocus = opt;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Strategy Banner
                Container(
                  margin: const EdgeInsets.all(14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: accentColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dietData['focus'] as String,
                              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dietData['strategy'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Timeline Filter Tabs (All, Morning, Afternoon, Evening)
                TabBar(
                  controller: _tabController,
                  indicatorColor: accentColor,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'All Day'),
                    Tab(text: '🌅 Morning'),
                    Tab(text: '☀️ Afternoon'),
                    Tab(text: '🌙 Evening'),
                  ],
                ),

                // Tab Content View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMealList(meals, accentColor),
                      _buildMealList(meals.where((m) => m['slot'] == 'Morning').toList(), accentColor),
                      _buildMealList(meals.where((m) => m['slot'] == 'Afternoon').toList(), accentColor),
                      _buildMealList(meals.where((m) => m['slot'] == 'Evening').toList(), accentColor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMealList(List<Map<String, dynamic>> slotMeals, Color accentColor) {
    if (slotMeals.isEmpty) {
      return const Center(
        child: Text('No meals found for this slot.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: slotMeals.length,
      itemBuilder: (context, index) {
        final slotData = slotMeals[index];
        final food = slotData['food'] as Map<String, dynamic>;
        final juice = slotData['juice'] as Map<String, dynamic>;
        final slotName = slotData['slotName'] as String;
        final time = slotData['time'] as String;
        final foodKey = '${_selectedWorkoutFocus}_${slotData['slot']}_food';
        final juiceKey = '${_selectedWorkoutFocus}_${slotData['slot']}_juice';
        final isFoodLogged = _loggedMealKeys.contains(foodKey);
        final isJuiceLogged = _loggedMealKeys.contains(juiceKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot Time Header
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    slotName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // 1. Food Item Card
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF141724),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isFoodLogged ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.08),
                  width: isFoodLogged ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFAB00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFFAB00), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food['name'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '💡 Why today: ${food['rationale']}',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Macros Pill Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroBadge('Calories', '${food['calories']} kcal', const Color(0xFFFFAB00)),
                      _buildMacroBadge('Protein', '${food['protein']}g', const Color(0xFF76FF03)),
                      _buildMacroBadge('Carbs', '${food['carbs']}g', const Color(0xFF00E5FF)),
                      _buildMacroBadge('Fats', '${food['fats']}g', const Color(0xFFFF5252)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),

                  // Ingredients & Quick Recipe
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('📋 Ingredients & Recipe', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingredients:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (food['ingredients'] as List<String>).map((ing) {
                              return Chip(
                                label: Text(ing, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                backgroundColor: const Color(0xFF1E2638),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          const Text('Preparation:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(food['prep'] as String, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, height: 1.3)),
                          const SizedBox(height: 8),
                        ],
                      )
                    ],
                  ),

                  // Log Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _toggleLogMeal(foodKey, food['name'] as String),
                      icon: Icon(
                        isFoodLogged ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                        color: isFoodLogged ? const Color(0xFF10B981) : accentColor,
                        size: 18,
                      ),
                      label: Text(
                        isFoodLogged ? 'Logged' : 'Log Food',
                        style: TextStyle(
                          color: isFoodLogged ? const Color(0xFF10B981) : accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // 2. Juice / Smoothie Card
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E2638),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isJuiceLogged ? const Color(0xFF10B981) : accentColor.withValues(alpha: 0.3),
                  width: isJuiceLogged ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_drink_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    juice['name'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${juice['calories']} kcal',
                                    style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🥤 Target Nutrients: ${juice['keyNutrient']}',
                              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              juice['rationale'] as String,
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ingredients & Quick Recipe
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('🍹 Juice Ingredients & Blender Recipe', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ingredients:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: (juice['ingredients'] as List<String>).map((ing) {
                              return Chip(
                                label: Text(ing, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                backgroundColor: const Color(0xFF141724),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          const Text('Blender Method:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(juice['prep'] as String, style: TextStyle(color: Colors.grey.shade300, fontSize: 11, height: 1.3)),
                          const SizedBox(height: 8),
                        ],
                      )
                    ],
                  ),

                  // Log Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _toggleLogMeal(juiceKey, juice['name'] as String),
                      icon: Icon(
                        isJuiceLogged ? Icons.check_circle_rounded : Icons.local_drink_rounded,
                        color: isJuiceLogged ? const Color(0xFF10B981) : accentColor,
                        size: 18,
                      ),
                      label: Text(
                        isJuiceLogged ? 'Logged' : 'Log Juice',
                        style: TextStyle(
                          color: isJuiceLogged ? const Color(0xFF10B981) : accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMacroBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
