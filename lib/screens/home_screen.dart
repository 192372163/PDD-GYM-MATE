import 'dart:async';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/goal_planner_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/goal_plan_model.dart';

import 'profile_screen.dart';
import 'nutrition_screen.dart';
import 'progress_screen.dart';
import 'ai_chat_screen.dart';
import 'notifications_modal.dart';
import 'goal_planner/goal_planner_screen.dart';
import 'goal_planner/views/active_workout_session_screen.dart';
import 'workout_diet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Services
  final _firestoreService = FirestoreService();

  // Water Tracker state
  double _waterIntake = 0.0;
  double get _waterTarget => _activePlan?.dailyWaterTargetLiters ?? 3.5;

  // Nutrition state — pulled from active plan
  int get _caloriesConsumed => 1650; // TODO: pull from real nutrition log
  int get _caloriesTarget => _activePlan?.dailyCalorieTarget ?? 2200;
  int get _proteinConsumed => 120;
  int get _proteinTarget => (_activePlan?.dailyProteinTarget ?? 160).toInt();

  // Challenge state
  bool _isChallengeCompleted = false;

  // User profile (streamed from Firestore)
  UserModel? _userProfile;

  // Plan state
  GoalPlanModel? _activePlan;
  bool _isLoadingPlan = true;
  bool _welcomePopupShown = false;

  @override
  void initState() {
    super.initState();
    _loadWaterIntake();
    _loadUserPlan();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final profile = await _firestoreService.getUserProfile(uid);
    if (mounted) setState(() => _userProfile = profile);
  }

  Future<void> _loadWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterIntake = prefs.getDouble('gymmate_water_intake') ?? 0.0;
    });
    // Also try to load from Firestore
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      final firestoreVal = await _firestoreService.getWaterIntake(uid);
      if (mounted && firestoreVal > 0) setState(() => _waterIntake = firestoreVal);
    }
  }

  Future<void> _saveWaterIntake() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('gymmate_water_intake', _waterIntake);
    // Also persist to Firestore
    final uid = AuthService().currentUser?.uid;
    if (uid != null) {
      _firestoreService.saveWaterIntake(uid, _waterIntake);
    }
  }

  void _incrementWater() {
    setState(() {
      _waterIntake = (_waterIntake + 0.25).clamp(0.0, 10.0);
      _waterIntake = double.parse(_waterIntake.toStringAsFixed(2));
    });
    _saveWaterIntake();
  }

  void _decrementWater() {
    setState(() {
      _waterIntake = (_waterIntake - 0.25).clamp(0.0, 10.0);
      _waterIntake = double.parse(_waterIntake.toStringAsFixed(2));
    });
    _saveWaterIntake();
  }

  Future<void> _loadUserPlan() async {
    final authUser = AuthService().currentUser;
    GoalPlanModel? plan = await GoalPlannerService().loadActiveGoalPlan(uid: authUser?.uid);

    if (plan == null) {
      // Fallback sample user plan if needed
      final dummyUser = UserModel(
        uid: authUser?.uid ?? 'guest',
        name: authUser?.displayName ?? 'Chandra',
        email: authUser?.email ?? 'chandra@gymmate.ai',
        fitnessGoal: 'Muscle Building',
      );
      plan = GoalPlannerService().generateAIPlan(
        user: dummyUser,
        goalTitle: 'Muscle Building',
        durationLabel: '90 Days Challenge',
        durationDays: 90,
      );
      
      // Save it so the user's progress persists for this generated plan
      await GoalPlannerService().saveActiveGoalPlan(plan, uid: authUser?.uid);
    }

    if (mounted) {
      setState(() {
        _activePlan = plan;
        _isLoadingPlan = false;
      });

      _checkMissedExercisesAlert(plan);
      
      if (!_welcomePopupShown) {
        _welcomePopupShown = true;
        _showWelcomeBackModal();
      }
    }
  }

  void _checkMissedExercisesAlert(GoalPlanModel? plan) {
    if (plan == null) return;
    final missedSummary = NotificationService().getYesterdayMissedSummary(plan);
    if (missedSummary != null) {
      Future.microtask(() {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            duration: const Duration(seconds: 7),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Missed Exercises Alert (Yesterday)',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        missedSummary,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'CATCH UP',
              textColor: const Color(0xFF10B981),
              onPressed: () {
                setState(() => _currentIndex = 1);
              },
            ),
          ),
        );
      });
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showWelcomeBackModal() {
    final plan = _activePlan;
    final dayIndex = plan?.currentActiveDayIndex ?? 4; // Day 5
    final currentDay = (plan != null && dayIndex < plan.workoutDays.length)
        ? plan.workoutDays[dayIndex]
        : null;

    final isTodayCompleted = currentDay?.isCompleted ?? false;
    final dayNumber = (currentDay?.dayNumber) ?? 5;
    final workoutTitle = currentDay?.focusArea ?? 'Back & Biceps';
    final estTime = currentDay?.totalDurationMins ?? 45;
    final calories = currentDay?.totalCalories ?? 420;

    final sampleExercises = currentDay != null && currentDay.workoutExercises.isNotEmpty
        ? currentDay.workoutExercises.take(4).map((e) => e.name).toList()
        : ['Pull Ups', 'Lat Pulldown', 'Dumbbell Row', 'Hammer Curl'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome Back, ${AuthService().currentUser?.displayName ?? 'Chandra'} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (!isTodayCompleted) ...[
                  const Text(
                    'Today\'s Workout',
                    style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $dayNumber – $workoutTitle',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      _buildMiniBadge(Icons.timer_outlined, '$estTime Minutes', const Color(0xFF06B6D4)),
                      const SizedBox(width: 12),
                      _buildMiniBadge(Icons.local_fire_department, '$calories kcal', Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Exercises:',
                    style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  ...sampleExercises.map((ex) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Text(ex, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _startActiveWorkoutSession(dayIndex);
                          },
                          child: const Text('Start Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _currentIndex = 1); // Workout tab
                        },
                        child: const Text('View Full Plan', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ] else ...[
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.verified, color: Color(0xFF10B981), size: 56),
                        const SizedBox(height: 12),
                        const Text(
                          '✅ Great Job!',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You completed Day $dayNumber.',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            children: [
                              const Text('Tomorrow:', style: TextStyle(color: Color(0xFF06B6D4), fontSize: 12)),
                              Text(
                                'Day ${dayNumber + 1} – Legs',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('Keep your streak alive! 🔥', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 46),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Continue to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _startActiveWorkoutSession(int dayIndex) {
    if (_activePlan == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutSessionScreen(
          plan: _activePlan!,
          dayIndex: dayIndex,
          onPlanUpdated: (updatedPlan) {
            setState(() {
              _activePlan = updatedPlan;
            });
            final authUser = AuthService().currentUser;
            GoalPlannerService().saveActiveGoalPlan(updatedPlan, uid: authUser?.uid);
          },
        ),
      ),
    );
  }

  // ── Sidebar nav item data ────────────────────────────────────────────────
  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined,       activeIcon: Icons.dashboard,           label: 'Dashboard'),
    _NavItem(icon: Icons.fitness_center_outlined,  activeIcon: Icons.fitness_center,       label: 'Workout'),
    _NavItem(icon: Icons.smart_toy_outlined,       activeIcon: Icons.smart_toy,            label: 'AI Coach'),
    _NavItem(icon: Icons.show_chart_outlined,      activeIcon: Icons.show_chart,           label: 'Progress'),
    _NavItem(icon: Icons.person_outline,           activeIcon: Icons.person,               label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      drawer: _buildSidebar(context, user),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Open menu',
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.bolt, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text('GymMate AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => NotificationsModal.show(
                  context,
                  plan: _activePlan,
                  onOpenWorkoutPlan: () {
                    setState(() => _currentIndex = 1);
                  },
                ),
              ),
              if (NotificationService().hasMissedExercises(_activePlan))
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildWorkoutTab(),
          AIChatScreen(userProfile: _userProfile),
          const ProgressScreen(),
          const ProfileScreen(), // Settings/Profile
        ],
      ),
    );
  }

  // ── Premium Sidebar Drawer ────────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context, dynamic user) {
    final userName = _userProfile?.name ?? user?.displayName ?? 'Athlete';
    final userEmail = _userProfile?.email ?? user?.email ?? 'athlete@gymmate.ai';
    final photoUrl = _userProfile?.photoUrl ?? user?.photoURL;

    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
          border: Border(right: BorderSide(color: Color(0xFF334155), width: 0.5)),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header / User Card ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                              userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'G',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '⚡ Premium Member',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Text('NAVIGATION', style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),

              // ── Nav Items ───────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _navItems.length,
                  itemBuilder: (context, i) {
                    final item = _navItems[i];
                    final isActive = _currentIndex == i;
                    return _buildDrawerItem(
                      context: context,
                      item: item,
                      index: i,
                      isActive: isActive,
                    );
                  },
                ),
              ),

              // ── Divider & Logout ────────────────────────────────────────
              const Divider(color: Color(0xFF334155), indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  ),
                  title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () async {
                    Navigator.pop(context);
                    await AuthService().signOut();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required _NavItem item,
    required int index,
    required bool isActive,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              )
            : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.30),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.18)
                : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? Colors.white : const Color(0xFF64748B),
            size: 20,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: isActive
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: () {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // DASHBOARD TAB CONTENT
  Widget _buildDashboardTab() {
    final user = AuthService().currentUser;
    final userName = user?.displayName ?? 'Chandra';
    final plan = _activePlan;

    final currentDayIndex = plan?.currentActiveDayIndex ?? 14;
    final totalDays = plan?.durationDays ?? 90;
    final streak = plan?.workoutStreak ?? 15;
    final caloriesBurned = plan?.totalCaloriesBurned ?? 6250;
    final progressPercent = plan != null ? (currentDayIndex / totalDays).clamp(0.0, 1.0) : 0.17;

    final todaySchedule = (plan != null && currentDayIndex < plan.workoutDays.length)
        ? plan.workoutDays[currentDayIndex]
        : null;

    return RefreshIndicator(
      onRefresh: _loadUserPlan,
      color: const Color(0xFF10B981),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. WELCOME SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $userName 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '"Success starts with self-discipline."',
                      style: TextStyle(color: Color(0xFF06B6D4), fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 4),
                  child: const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF10B981),
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. TODAY'S WORKOUT CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 16,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          'DAY ${todaySchedule?.dayNumber ?? (currentDayIndex + 1)}',
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        padding: EdgeInsets.zero,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan?.userFitnessLevel ?? 'Intermediate',
                          style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    todaySchedule?.focusArea ?? 'Chest & Triceps Hypertrophy',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildCardStat(Icons.timer_outlined, '${todaySchedule?.totalDurationMins ?? 45} mins'),
                      const SizedBox(width: 16),
                      _buildCardStat(Icons.local_fire_department_outlined, '${todaySchedule?.totalCalories ?? 420} kcal'),
                      const SizedBox(width: 16),
                      _buildCardStat(Icons.fitness_center_outlined, '${todaySchedule?.exercises.length ?? 6} Exercises'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (ctx) {
                      bool isLockedForTomorrow = false;
                      if (currentDayIndex > 0 && plan != null) {
                        final prevDay = plan.workoutDays[currentDayIndex - 1];
                        if (prevDay.isCompleted && prevDay.completionDate != null) {
                          final now = DateTime.now();
                          final completedDate = prevDay.completionDate!;
                          if (now.year == completedDate.year &&
                              now.month == completedDate.month &&
                              now.day == completedDate.day) {
                            isLockedForTomorrow = true;
                          }
                        }
                      }

                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLockedForTomorrow ? const Color(0xFF1E293B) : const Color(0xFF10B981),
                            foregroundColor: isLockedForTomorrow ? Colors.grey.shade400 : Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: isLockedForTomorrow ? null : () => _startActiveWorkoutSession(currentDayIndex),
                          icon: Icon(isLockedForTomorrow ? Icons.lock_clock_rounded : Icons.play_arrow_rounded, size: 24),
                          label: Text(
                            isLockedForTomorrow ? 'Next Workout Unlocks Tomorrow' : 'Start Workout', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. PROGRESS CARD
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Day ${currentDayIndex + 1} / $totalDays',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Progress: ${(progressPercent * 100).toInt()}%',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearPercentIndicator(
                    lineHeight: 8.0,
                    percent: progressPercent,
                    backgroundColor: const Color(0xFF334155),
                    progressColor: const Color(0xFF10B981),
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProgressMetric('🔥 Streak', '$streak Days', Colors.orangeAccent),
                      _buildProgressMetric('⚡ Burned', '$caloriesBurned kcal', const Color(0xFF06B6D4)),
                      _buildProgressMetric('⚖️ Weight', '70 kg', Colors.purpleAccent),
                      _buildProgressMetric('📊 BMI', '22.8', const Color(0xFF10B981)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. DAILY CHALLENGE CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF1E1B4B)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Challenge', style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 12, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('100 Squats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 2),
                        Text('Reward: +50 XP', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isChallengeCompleted ? Colors.grey : Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() => _isChallengeCompleted = !_isChallengeCompleted);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isChallengeCompleted ? '🎉 Challenge Claimed! +50 XP Added.' : 'Challenge reset'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                    child: Text(_isChallengeCompleted ? 'Claimed ✓' : 'Complete'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 5. WORKOUT-BASED DIET & JUICES CARD
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WorkoutDietScreen(plan: _activePlan)),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workout Food & Juices 🍹',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Morning, Afternoon & Evening meals tailored for today\'s workout.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 5. WATER INTAKE TRACKER
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 36.0,
                    lineWidth: 7.0,
                    percent: (_waterIntake / _waterTarget).clamp(0.0, 1.0),
                    center: const Icon(Icons.local_drink, color: Color(0xFF06B6D4), size: 24),
                    progressColor: const Color(0xFF06B6D4),
                    backgroundColor: const Color(0xFF334155),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Water Intake Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                          '${_waterIntake.toStringAsFixed(2)}L / ${_waterTarget}L Goal',
                          style: const TextStyle(color: Color(0xFF06B6D4), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF94A3B8)),
                        onPressed: _decrementWater,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF06B6D4), size: 28),
                        onPressed: _incrementWater,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. NUTRITION SUMMARY
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nutrition Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const NutritionScreen()));
                        },
                        child: const Text('Details →', style: TextStyle(color: Color(0xFF10B981))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Consumed: $_caloriesConsumed kcal', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      Text('Remaining: ${_caloriesTarget - _caloriesConsumed} kcal', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    lineHeight: 6.0,
                    percent: (_caloriesConsumed / _caloriesTarget).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFF334155),
                    progressColor: const Color(0xFF10B981),
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMacroItem('Protein', '$_proteinConsumed / ${_proteinTarget}g', const Color(0xFF10B981)),
                      _buildMacroItem('Carbs', '190 / 220g', const Color(0xFF06B6D4)),
                      _buildMacroItem('Fats', '52 / 65g', Colors.amber),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 7. AI RECOMMENDATION CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology, color: Color(0xFF10B981), size: 22),
                      SizedBox(width: 8),
                      Text('AI Coach Recommendations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTipRow('💡 Increase protein intake by 30g today for optimal muscle synthesis.'),
                  _buildTipRow('🧘 Stretch hamstring & back muscles after today\'s heavy session.'),
                  _buildTipRow('😴 Aim for at least 8 hours of sleep for peak testosterone recovery.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // WORKOUT ROADMAP TAB CONTENT
  Widget _buildWorkoutTab() {
    if (_isLoadingPlan || _activePlan == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }
    return GoalPlannerScreen(initialPlan: _activePlan);
  }

  Widget _buildCardStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
      ],
    );
  }

  Widget _buildProgressMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildTipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(tip, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
    );
  }
}

// ── Data class for sidebar nav items ─────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
