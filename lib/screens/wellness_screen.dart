import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/ai_fitness_service.dart';

class WellnessScreen extends StatefulWidget {
  final UserModel? userProfile;
  const WellnessScreen({super.key, this.userProfile});

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  double _waterConsumedLiters = 0.0;
  double _waterTargetLiters = 2.5;
  int _sleepTargetHours = 8;
  int _sleepLoggedHours = 0;

  @override
  void initState() {
    super.initState();
    _loadWellnessData();
  }

  Future<void> _loadWellnessData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterConsumedLiters = prefs.getDouble('water_consumed_${_dateKey()}') ?? 0.0;
      _sleepLoggedHours = prefs.getInt('sleep_logged_${_dateKey()}') ?? 0;

      if (widget.userProfile != null) {
        _waterTargetLiters = AIFitnessService.calculateWaterIntake(widget.userProfile!);
        
        // Simple Sleep logic based on activity
        final activity = widget.userProfile?.dailyActivity?.toLowerCase() ?? '';
        if (activity.contains('active') || widget.userProfile?.workoutDaysPerWeek == 7) {
          _sleepTargetHours = 9; // More recovery needed
        } else {
          _sleepTargetHours = 8;
        }
      }
    });
  }

  Future<void> _addWater(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterConsumedLiters += amount;
    });
    await prefs.setDouble('water_consumed_${_dateKey()}', _waterConsumedLiters);
  }

  Future<void> _logSleep(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sleepLoggedHours = hours;
    });
    await prefs.setInt('sleep_logged_${_dateKey()}', _sleepLoggedHours);
  }

  String _dateKey() {
    final now = DateTime.now();
    return '${now.year}-$now.month-$now.day';
  }

  double get _recoveryScore {
    double score = 0;
    if (_sleepLoggedHours >= _sleepTargetHours) {
      score += 50;
    } else {
      score += (_sleepLoggedHours / _sleepTargetHours) * 50;
    }
    
    if (_waterConsumedLiters >= _waterTargetLiters) {
      score += 50;
    } else {
      score += (_waterConsumedLiters / _waterTargetLiters) * 50;
    }
    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Wellness & Recovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Recovery Score
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('AI Recovery Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 12.0,
                      animation: true,
                      percent: _recoveryScore / 100,
                      center: Text(
                        '${_recoveryScore.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0),
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      progressColor: _recoveryScore > 80 ? Colors.green : (_recoveryScore > 50 ? Colors.orange : Colors.red),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Water Reminder
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Water Intake', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (_waterConsumedLiters / _waterTargetLiters).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_waterConsumedLiters.toStringAsFixed(1)}L Consumed'),
                        Text('Target: ${_waterTargetLiters.toStringAsFixed(1)}L'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(onPressed: () => _addWater(0.25), child: const Text('+ 250ml')),
                        OutlinedButton(onPressed: () => _addWater(0.5), child: const Text('+ 500ml')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sleep Recommendation
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bedtime, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Sleep Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Recommended Sleep: $_sleepTargetHours Hours', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Log Last Night: '),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _sleepLoggedHours.toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            label: '$_sleepLoggedHours hrs',
                            activeColor: Colors.indigo,
                            onChanged: (val) {
                              setState(() => _sleepLoggedHours = val.toInt());
                            },
                            onChangeEnd: (val) => _logSleep(val.toInt()),
                          ),
                        ),
                        Text('$_sleepLoggedHours h'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
