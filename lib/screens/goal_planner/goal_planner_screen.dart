import 'package:flutter/material.dart';
import '../../models/goal_plan_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/goal_planner_service.dart';
import 'views/goal_selection_view.dart';
import 'views/goal_duration_view.dart';
import 'views/user_profile_form_view.dart';
import 'views/ai_workout_plan_view.dart';
import 'views/ai_nutrition_plan_view.dart';
import 'views/daily_task_tracker_view.dart';
import 'views/daily_progress_dashboard_view.dart';
import 'views/goal_progress_dashboard_view.dart';
import 'views/goal_completion_view.dart';

class GoalPlannerScreen extends StatefulWidget {
  final UserModel? userProfile;
  final GoalPlanModel? initialPlan;

  const GoalPlannerScreen({
    super.key,
    this.userProfile,
    this.initialPlan,
  });

  @override
  State<GoalPlannerScreen> createState() => _GoalPlannerScreenState();
}

class _GoalPlannerScreenState extends State<GoalPlannerScreen> {
  final GoalPlannerService _plannerService = GoalPlannerService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  GoalPlanModel? _activePlan;
  UserModel? _userProfile;
  bool _isLoading = true;

  // Wizard state
  bool _isCreatingNewGoal = false;
  int _wizardStep = 1; // 1: Selection, 2: Duration, 3: Profile Form
  String _selectedGoalTitle = 'Weight Loss';
  String _selectedDurationLabel = '1 Month';
  int _selectedDurationDays = 30;

  // Navigation tab state
  int _currentNavIndex = 0;
  int _progressSubTab = 0; // 0: Daily Dashboard, 1: Goal Dashboard

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null) {
      _activePlan = widget.initialPlan;
    }
    _loadProfileAndPlan();
  }

  Future<void> _loadProfileAndPlan() async {
    setState(() => _isLoading = true);

    UserModel? profile = widget.userProfile;
    final uid = _authService.currentUser?.uid;

    if (profile == null && uid != null) {
      profile = await _firestoreService.getUserProfile(uid);
    }
    _userProfile = profile;

    if (uid != null) {
      final existingPlan = await _plannerService.getActiveGoalPlan(uid);
      if (existingPlan != null) {
        _activePlan = existingPlan;
      }
    }

    if (_activePlan == null && _userProfile != null) {
      _activePlan = _plannerService.generateAIPlan(
        user: _userProfile!,
        goalTitle: _selectedGoalTitle,
        durationLabel: '1 Month',
        durationDays: 30,
      );
      await _plannerService.saveGoalPlan(_activePlan!);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onGenerateFinalAIPlan({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String level,
    required List<String> medicalConditions,
    required int availableTimeMins,
  }) async {
    setState(() => _isLoading = true);

    final baseUser = _userProfile ??
        UserModel(
          uid: _authService.currentUser?.uid ?? 'guest',
          name: 'Athlete',
          email: 'user@gymmate.ai',
          weightKg: weightKg,
          heightCm: heightCm,
          age: age,
          gender: gender,
          experienceLevel: level,
          medicalConditions: medicalConditions,
        );

    final newPlan = _plannerService.generateAIPlan(
      user: baseUser,
      goalTitle: _selectedGoalTitle,
      durationLabel: _selectedDurationLabel,
      durationDays: _selectedDurationDays,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      fitnessLevel: level,
      medicalConditions: medicalConditions,
      availableWorkoutTimeMins: availableTimeMins,
    );

    await _plannerService.saveGoalPlan(newPlan);

    setState(() {
      _activePlan = newPlan;
      _isCreatingNewGoal = false;
      _wizardStep = 1;
      _currentNavIndex = 0; // Jump to Workout Home tab
      _isLoading = false;
    });
  }

  void _updatePlanState(GoalPlanModel updated) {
    setState(() {
      _activePlan = updated;
    });
    _plannerService.saveGoalPlan(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0F17),
        elevation: 0,
        centerTitle: false,
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF00E5FF), size: 26),
            SizedBox(width: 10),
            Text(
              'Goal-Based AI Planner',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          if (_activePlan != null && !_isCreatingNewGoal)
            IconButton(
              icon: const Icon(Icons.add_task_rounded, color: Color(0xFF76FF03)),
              tooltip: 'New Goal Wizard',
              onPressed: () {
                setState(() {
                  _isCreatingNewGoal = true;
                  _wizardStep = 1;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
            )
          : (_activePlan == null || _isCreatingNewGoal)
              ? _buildWizardFlow()
              : _buildMainPlannerModule(),
      bottomNavigationBar: (_activePlan != null && !_isCreatingNewGoal)
          ? _buildBottomNavigationBar()
          : null,
    );
  }

  /// Renders the 3-step Goal Setup Wizard
  Widget _buildWizardFlow() {
    if (_wizardStep == 1) {
      return GoalSelectionView(
        initialGoal: _selectedGoalTitle,
        onGoalSelected: (goal) {
          setState(() {
            _selectedGoalTitle = goal;
          });
        },
        onContinue: () {
          setState(() {
            _wizardStep = 2;
          });
        },
      );
    } else if (_wizardStep == 2) {
      return GoalDurationView(
        selectedGoal: _selectedGoalTitle,
        onPrevious: () {
          setState(() {
            _wizardStep = 1;
          });
        },
        onGeneratePlan: (label, days) {
          setState(() {
            _selectedDurationLabel = label;
            _selectedDurationDays = days;
            _wizardStep = 3;
          });
        },
      );
    } else {
      return UserProfileFormView(
        selectedGoal: _selectedGoalTitle,
        selectedDurationLabel: _selectedDurationLabel,
        selectedDurationDays: _selectedDurationDays,
        onPrevious: () {
          setState(() {
            _wizardStep = 2;
          });
        },
        onGenerateAIPlan: _onGenerateFinalAIPlan,
      );
    }
  }

  /// Renders the main 5-tab Goal Planner Module
  Widget _buildMainPlannerModule() {
    final plan = _activePlan!;

    switch (_currentNavIndex) {
      case 0:
        return AIWorkoutPlanView(
          plan: plan,
          userProfile: _userProfile,
          onPlanUpdated: _updatePlanState,
        );
      case 1:
        return DailyTaskTrackerView(
          plan: plan,
          onPlanUpdated: _updatePlanState,
        );
      case 2:
        return AINutritionPlanView(
          plan: plan,
        );
      case 3:
        return Column(
          children: [
            Container(
              color: const Color(0xFF0D0F17),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Daily Dashboard')),
                      selected: _progressSubTab == 0,
                      selectedColor: const Color(0xFF00E5FF),
                      backgroundColor: const Color(0xFF141724),
                      labelStyle: TextStyle(
                        color: _progressSubTab == 0 ? Colors.black : Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (sel) {
                        if (sel) setState(() => _progressSubTab = 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Goal Analytics')),
                      selected: _progressSubTab == 1,
                      selectedColor: const Color(0xFF76FF03),
                      backgroundColor: const Color(0xFF141724),
                      labelStyle: TextStyle(
                        color: _progressSubTab == 1 ? Colors.black : Colors.grey.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (sel) {
                        if (sel) setState(() => _progressSubTab = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _progressSubTab == 0
                  ? DailyProgressDashboardView(plan: plan)
                  : GoalProgressDashboardView(
                      plan: plan,
                      onCompleteGoalTrigger: () {
                        setState(() {
                          _currentNavIndex = 4;
                        });
                      },
                    ),
            ),
          ],
        );
      case 4:
        return GoalCompletionView(
          plan: plan,
          onSetNewGoal: () {
            setState(() {
              _isCreatingNewGoal = true;
              _wizardStep = 1;
            });
          },
        );
      default:
        return AIWorkoutPlanView(
          plan: plan,
          onPlanUpdated: _updatePlanState,
        );
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141724),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF141724),
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
