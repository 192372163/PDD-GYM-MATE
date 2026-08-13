import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../services/auth_service.dart';
import '../services/goal_planner_service.dart';
import '../models/goal_plan_model.dart';
import 'report_preview_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  final _plannerService = GoalPlannerService();

  GoalPlanModel? _plan;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlan();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlan() async {
    setState(() => _isLoading = true);
    final uid = _authService.currentUser?.uid;
    GoalPlanModel? plan;
    if (uid != null) {
      plan = await _plannerService.loadActiveGoalPlan(uid: uid);
    }
    plan ??= _plannerService.loadLocalActiveGoalPlan();
    if (mounted) setState(() { _plan = plan; _isLoading = false; });
  }

  Future<void> _openPreviewScreen(BuildContext context) async {
    if (_plan == null) return;
    final pdfData = await _plannerService.generateProgressReportPdf(_plan!);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(
          pdfFuture: Future.value(pdfData),
          reportName: 'GymMate_AI_Progress_Report_${_plan!.goalTitle.replaceAll(' ', '_')}.pdf',
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    if (_plan == null) return;
    final plan = _plan!;
    final reportText = '''
🏋️ *GymMate AI - Progress Report* 🏋️
🎯 *Goal:* ${plan.goalTitle}
⚖️ *Current Weight:* ${plan.currentWeight} kg -> *Target:* ${plan.targetWeight} kg
🔥 *Daily Calories Target:* ${plan.dailyCalorieTarget} kcal
📅 *Duration:* ${plan.durationLabel}

Check out my workout and fitness progress on GymMate AI! 💪
''';

    final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(reportText)}');
    final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?text=${Uri.encodeComponent(reportText)}');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalNonBrowserApplication);
        return;
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    final pdfData = await _plannerService.generateProgressReportPdf(_plan!);
    final file = await _savePdfToFile(pdfData);
    await SharePlus.instance.share(
      ShareParams(
        text: reportText,
        files: [XFile(file.path, mimeType: 'application/pdf')],
      ),
    );
  }

  Future<File> _savePdfToFile(Uint8List data) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/progress_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(data);
    return file;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Progress Tracker', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981)),
            tooltip: 'Download & Share Report',
            onPressed: () {
              if (_plan != null) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF1E293B),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Share Report To...',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ListTile(
                            leading: const Icon(Icons.chat_rounded, color: Colors.greenAccent),
                            title: const Text('WhatsApp', style: TextStyle(color: Colors.white)),
                            onTap: () async {
                              Navigator.pop(context);
                              await _shareViaWhatsApp(context);
                            },
                          ),
                          const Divider(color: Color(0xFF334155)),
                          ListTile(
                            leading: const Icon(Icons.remove_red_eye, color: Color(0xFF10B981)),
                            title: const Text('Preview PDF (Default)', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.pop(context);
                              _openPreviewScreen(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF10B981)),
            onPressed: _loadPlan,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: const [
            Tab(text: 'Workout Days'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : _plan == null
              ? _buildNoPlanState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkoutDaysTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildNoPlanState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, color: Color(0xFF334155), size: 64),
          SizedBox(height: 16),
          Text('No Active Plan', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Start a goal plan to track your progress', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Workout Days Tab ─────────────────────────────────────────────────────
  Widget _buildWorkoutDaysTab() {
    final plan = _plan!;
    final completedDays = plan.workoutDays.where((d) => d.isCompleted).length;
    final inProgressDays = plan.workoutDays.where((d) => d.isInProgress && !d.isCompleted).length;
    final missedDays = plan.workoutDays.where((d) {
      return !d.isCompleted && !d.isInProgress && d.dayNumber < plan.currentActiveDayIndex + 1;
    }).length;
    final remainingDays = plan.durationDays - completedDays;

    return RefreshIndicator(
      onRefresh: _loadPlan,
      color: const Color(0xFF10B981),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Statistics Grid ────────────────────────────────────────────
          _buildStatsGrid(plan, completedDays, inProgressDays, missedDays, remainingDays),
          const SizedBox(height: 20),

          // ── Progress Bar ──────────────────────────────────────────────
          _buildOverallProgressBar(plan, completedDays),
          const SizedBox(height: 20),

          // ── Section Label ─────────────────────────────────────────────
          const Text('WORKOUT DAYS', style: TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          // ── Day Cards ─────────────────────────────────────────────────
          ...plan.workoutDays.map((day) => _buildDayCard(plan, day)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(GoalPlanModel plan, int completed, int inProgress, int missed, int remaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatBox('Total Days', '${plan.durationDays}', const Color(0xFF64748B), Icons.calendar_month_outlined),
              const SizedBox(width: 10),
              _buildStatBox('Completed', '$completed', const Color(0xFF10B981), Icons.check_circle_rounded),
              const SizedBox(width: 10),
              _buildStatBox('Remaining', '$remaining', const Color(0xFF06B6D4), Icons.hourglass_bottom_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBox('Missed', '$missed', Colors.redAccent, Icons.cancel_rounded),
              const SizedBox(width: 10),
              _buildStatBox('🔥 Streak', '${plan.workoutStreak}d', Colors.orangeAccent, Icons.local_fire_department),
              const SizedBox(width: 10),
              _buildStatBox('Calories', '${plan.totalCaloriesBurned}', Colors.purpleAccent, Icons.bolt_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallProgressBar(GoalPlanModel plan, int completed) {
    final percent = (plan.durationDays > 0 ? completed / plan.durationDays : 0.0).clamp(0.0, 1.0);
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Completion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          LinearPercentIndicator(
            lineHeight: 10,
            percent: percent,
            backgroundColor: const Color(0xFF334155),
            linearGradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF06B6D4)]),
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Text('${plan.goalTitle} · ${plan.durationLabel}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDayCard(GoalPlanModel plan, DailyWorkoutSchedule day) {
    final isCurrentDay = day.dayNumber == plan.currentActiveDayIndex + 1;
    final isLocked = !day.isCompleted && !day.isInProgress &&
        day.dayNumber > plan.currentActiveDayIndex + 1;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    Color cardBorder;

    if (day.isCompleted) {
      statusColor = const Color(0xFF10B981);
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Completed';
      cardBorder = const Color(0xFF10B981);
    } else if (day.isInProgress) {
      statusColor = Colors.amber;
      statusIcon = Icons.pending_rounded;
      statusLabel = 'In Progress';
      cardBorder = Colors.amber;
    } else if (isLocked) {
      statusColor = const Color(0xFF334155);
      statusIcon = Icons.lock_rounded;
      statusLabel = 'Locked';
      cardBorder = const Color(0xFF1E293B);
    } else {
      // Not completed, not locked — missed or today
      statusColor = isCurrentDay ? const Color(0xFF06B6D4) : Colors.redAccent;
      statusIcon = isCurrentDay ? Icons.play_circle_rounded : Icons.cancel_rounded;
      statusLabel = isCurrentDay ? 'Today' : 'Not Done';
      cardBorder = isCurrentDay ? const Color(0xFF06B6D4) : const Color(0xFF334155);
    }

    final exercisesDone = day.isCompleted
        ? day.exercises.length
        : day.isInProgress ? day.lastCompletedExerciseIndex : 0;
    final totalExercises = day.exercises.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: isLocked ? 0.2 : 0.5)),
        boxShadow: day.isCompleted || isCurrentDay
            ? [BoxShadow(color: statusColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Day number circle
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isLocked ? 0.05 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: isLocked ? 0.2 : 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      '${day.dayNumber}',
                      style: TextStyle(
                        color: isLocked ? const Color(0xFF334155) : statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day.focusArea,
                        style: TextStyle(
                          color: isLocked ? const Color(0xFF475569) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(day.dayName,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isLocked ? 0.05 : 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: isLocked ? 0.2 : 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: isLocked ? const Color(0xFF334155) : statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(statusLabel,
                          style: TextStyle(
                            color: isLocked ? const Color(0xFF334155) : statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ],
            ),

            if (!isLocked) ...[
              const SizedBox(height: 12),
              // Stats row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildDayStatChip(Icons.timer_outlined, '${day.totalDurationMins}min', const Color(0xFF64748B)),
                  _buildDayStatChip(Icons.local_fire_department_outlined, '${day.totalCalories}kcal', Colors.orangeAccent),
                  _buildDayStatChip(Icons.fitness_center_outlined, '$totalExercises ex', const Color(0xFF06B6D4)),
                  if (day.isCompleted && day.completionDate != null)
                    _buildDayStatChip(Icons.calendar_today_outlined,
                        '${day.completionDate!.day}/${day.completionDate!.month}', const Color(0xFF10B981)),
                ],
              ),

              // Progress bar for in-progress
              if (day.isInProgress && !day.isCompleted) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$exercisesDone / $totalExercises exercises done',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    Text('${totalExercises > 0 ? ((exercisesDone / totalExercises) * 100).toInt() : 0}%',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                LinearPercentIndicator(
                  lineHeight: 6,
                  percent: totalExercises > 0 ? (exercisesDone / totalExercises).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: const Color(0xFF334155),
                  progressColor: Colors.amber,
                  barRadius: const Radius.circular(3),
                  padding: EdgeInsets.zero,
                ),
              ],

              // Completed exercises count
              if (day.isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text('All $totalExercises exercises completed',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayStatChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }





  // ─── Analytics Tab ─────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    final plan = _plan!;
    final completedDays = plan.workoutDays.where((d) => d.isCompleted).toList();
    final completionRate = plan.durationDays > 0
        ? (completedDays.length / plan.durationDays * 100).clamp(0.0, 100.0)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary stats
        _buildAnalyticsSummary(plan, completedDays, completionRate),
        const SizedBox(height: 20),

        // Weekly bar chart
        _buildWeeklyChart(plan),
        const SizedBox(height: 20),

        // Monthly trend line chart
        _buildMonthlyTrendChart(plan),
        const SizedBox(height: 20),

        // Achievements
        _buildAchievementsSection(plan),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAnalyticsSummary(GoalPlanModel plan, List<DailyWorkoutSchedule> completedDays, double completionRate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1F3C), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Program Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryMetric('Completion Rate', '${completionRate.toInt()}%', const Color(0xFF10B981))),
              Expanded(child: _buildSummaryMetric('🔥 Streak', '${plan.workoutStreak} days', Colors.orangeAccent)),
              Expanded(child: _buildSummaryMetric('Calories Burned', '${plan.totalCaloriesBurned}', Colors.purpleAccent)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryMetric('Workouts Done', '${completedDays.length}', const Color(0xFF06B6D4))),
              Expanded(child: _buildSummaryMetric('Goal', plan.goalTitle, const Color(0xFFFBBF24))),
              Expanded(child: _buildSummaryMetric('Duration', plan.durationLabel, const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildWeeklyChart(GoalPlanModel plan) {
    final history = plan.dynamicWeeklyProgress;
    final todayWeekdayIdx = DateTime.now().weekday - 1; // 0=Mon, ..., 2=Wed

    final bars = List.generate(
      7,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: i <= todayWeekdayIdx ? history[i].clamp(0.0, 100.0) : 0.0,
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
    );

    final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
              Icon(Icons.bar_chart_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text('Weekly Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Workout completion % per day of the week',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: bars.isEmpty
                ? const Center(child: Text('No data yet', style: TextStyle(color: Color(0xFF64748B))))
                : BarChart(
                    BarChartData(
                      barGroups: bars,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFF334155), strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          interval: 25,
                          reservedSize: 32,
                          getTitlesWidget: (v, m) => Text('${v.toInt()}%',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx >= 0 && idx < weekDays.length) {
                              return Text(weekDays[idx],
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10));
                            }
                            return const Text('');
                          },
                        )),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      maxY: 100,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendChart(GoalPlanModel plan) {
    final history = plan.weightProgressHistory;
    final completedWeeksCount = (plan.totalWorkoutDaysCompleted / 7).ceil().clamp(1, history.length);
    final visibleCount = completedWeeksCount;
    final spots = List.generate(
      visibleCount,
      (i) => FlSpot(i.toDouble(), history[i]),
    );

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
              Icon(Icons.trending_down_rounded, color: Color(0xFF06B6D4), size: 20),
              SizedBox(width: 8),
              Text('Weight Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Weight trend over program duration (kg)',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: spots.isEmpty
                ? const Center(child: Text('No data yet', style: TextStyle(color: Color(0xFF64748B))))
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF10B981)]),
                          barWidth: 3,
                          dotData: FlDotData(
                            getDotPainter: (spot, _, bar, idx) => FlDotCirclePainter(
                              radius: 3,
                              color: const Color(0xFF06B6D4),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF06B6D4).withValues(alpha: 0.3),
                                const Color(0xFF06B6D4).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (v) => const FlLine(color: Color(0xFF334155), strokeWidth: 1),
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (v, m) => Text('${v.toInt()}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        )),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) => Text('W${v.toInt() + 1}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        )),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(GoalPlanModel plan) {
    final allBadges = [
      {'name': 'First Step', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFFBBF24), 'req': 1},
      {'name': 'Week Warrior', 'icon': Icons.local_fire_department, 'color': Colors.orangeAccent, 'req': 7},
      {'name': 'Two Weeks Strong', 'icon': Icons.fitness_center, 'color': const Color(0xFF10B981), 'req': 14},
      {'name': 'Month Master', 'icon': Icons.stars_rounded, 'color': const Color(0xFF06B6D4), 'req': 30},
      {'name': 'Calorie Crusher', 'icon': Icons.bolt_rounded, 'color': Colors.purpleAccent, 'req': 0},
      {'name': 'Consistency King', 'icon': Icons.trending_up_rounded, 'color': Colors.greenAccent, 'req': 0},
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
              Text('Achievements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: allBadges.length,
            itemBuilder: (context, i) {
              final badge = allBadges[i];
              final req = badge['req'] as int;
              final isUnlocked = plan.unlockedBadges.contains(badge['name'] as String) ||
                  (req > 0 && plan.totalWorkoutDaysCompleted >= req) ||
                  (req == 0 && plan.totalCaloriesBurned > 500);
              final color = badge['color'] as Color;
              final icon = badge['icon'] as IconData;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked ? color.withValues(alpha: 0.12) : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUnlocked ? color.withValues(alpha: 0.5) : const Color(0xFF1E293B),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: isUnlocked ? color : const Color(0xFF334155), size: 28),
                    const SizedBox(height: 6),
                    Text(
                      badge['name'] as String,
                      style: TextStyle(
                        color: isUnlocked ? color : const Color(0xFF334155),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isUnlocked) ...[
                      const SizedBox(height: 4),
                      const Icon(Icons.lock_rounded, color: Color(0xFF334155), size: 12),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
