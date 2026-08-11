import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/exercise_model.dart';
import '../services/workout_service.dart';

class TimerScreen extends StatefulWidget {
  final ExerciseModel exercise;
  const TimerScreen({super.key, required this.exercise});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late FlutterTts flutterTts;
  
  // Timer States
  bool _hasStarted = false;
  bool _isWorkout = false;
  bool _isResting = false;
  bool _isPaused = false;
  bool _isWaitingForRest = false;
  bool _isWaitingForWorkout = false;
  bool _isCompleted = false;

  int _countdown = 3;
  int _goalTime = 45; // Default goal time in seconds
  int _timeRemaining = 0;
  int _currentSet = 1;
  late int _totalSets;
  DateTime? _startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _totalSets = widget.exercise.sets > 0 ? widget.exercise.sets : 3;
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _initiateWorkout() {
    setState(() {
      _hasStarted = true;
      _startTime = DateTime.now();
    });
    _startCountdown();
  }

  void _startCountdown() async {
    setState(() {
      _isWorkout = false;
      _isResting = false;
      _isWaitingForWorkout = false;
      _countdown = 3;
    });
    await _speak("Ready. 3. 2. 1. Start set $_currentSet of $widget.exercise.name");
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _startWorkout();
      }
    });
  }

  void _startWorkout() {
    setState(() {
      _isWorkout = true;
      _isResting = false;
      _timeRemaining = _goalTime;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _onWorkoutFinished();
      }
    });
  }

  void _onWorkoutFinished() {
    if (_currentSet >= _totalSets) {
      _completeAllSets();
    } else {
      setState(() {
        _isWorkout = false;
        _isWaitingForRest = true;
      });
      _speak("Set completed. Start rest when ready.");
    }
  }

  void _triggerRest() {
    setState(() {
      _isWaitingForRest = false;
    });
    _startRest();
  }

  void _startRest() async {
    setState(() {
      _isWorkout = false;
      _isResting = true;
      _timeRemaining = widget.exercise.restTimeSec;
    });
    
    await _speak("Rest for $_timeRemaining seconds.");

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      if (_timeRemaining > 0) {
        setState(() => _timeRemaining--);
      } else {
        timer.cancel();
        _onRestFinished();
      }
    });
  }

  void _onRestFinished() {
    setState(() {
      _isResting = false;
      _isWaitingForWorkout = true;
      _currentSet++;
    });
    _speak("Rest completed. Start next set when ready.");
  }

  void _completeAllSets() {
    final totalDuration = ((_goalTime * _totalSets) / 60).ceil();
    final calories = widget.exercise.caloriesBurned > 0 
        ? widget.exercise.caloriesBurned 
        : (totalDuration * 7); // estimation
    
    WorkoutService().completeWorkout(
      title: 'Single Exercise Session',
      durationMins: totalDuration,
      caloriesBurned: calories,
      exercises: [widget.exercise.name],
    );

    setState(() {
      _isWorkout = false;
      _isResting = false;
      _isCompleted = true;
    });
    _speak("Awesome! You completed all $_totalSets sets of $widget.exercise.name.");
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    _speak(_isPaused ? "Paused" : "Resumed");
  }

  @override
  void dispose() {
    _timer?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.exercise.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_hasStarted) ...[
                const Text(
                  'Set Your Goal Time',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 40),
                      onPressed: () {
                        if (_goalTime > 5) {
                          setState(() => _goalTime -= 5);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_goalTime s',
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 40),
                      onPressed: () {
                        setState(() => _goalTime += 5);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [30, 45, 60, 90].map((t) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ChoiceChip(
                        label: Text('$t sec', style: TextStyle(color: _goalTime == t ? Colors.black : Colors.white)),
                        selected: _goalTime == t,
                        selectedColor: Colors.amber,
                        backgroundColor: Colors.grey.shade900,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _goalTime = t);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _initiateWorkout,
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text('Start Workout', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ] else if (_isCompleted) ...[
                const Icon(Icons.stars, color: Colors.amber, size: 100),
                const SizedBox(height: 24),
                const Text(
                  'EXERCISE COMPLETED!',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Completed $_totalSets sets of $widget.exercise.name.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Finish', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                if (_startTime != null) ...[
                  Text(
                    'Started at: ${_formatTime(_startTime)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Goal Time: $_goalTime seconds | Set: $_currentSet of $_totalSets',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                ],
                if (!_isWorkout && !_isResting && !_isWaitingForRest && !_isWaitingForWorkout) ...[
                  const Text('GET READY', style: TextStyle(color: Colors.white, fontSize: 24)),
                  Text('$_countdown', style: const TextStyle(color: Colors.amber, fontSize: 120, fontWeight: FontWeight.bold)),
                ] else if (_isWaitingForRest) ...[
                  const Text('SET COMPLETED', style: TextStyle(color: Colors.green, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _triggerRest,
                    icon: const Icon(Icons.timer, color: Colors.black),
                    label: const Text('Start Rest', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ] else if (_isWaitingForWorkout) ...[
                  Text('REST COMPLETED', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _startCountdown,
                    icon: const Icon(Icons.play_arrow, color: Colors.black),
                    label: Text('Start Set $_currentSet', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ] else if (_isWorkout) ...[
                  Text(
                    _isPaused ? 'PAUSED' : 'WORKOUT',
                    style: TextStyle(color: _isPaused ? Colors.red : Colors.green, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '00:${_timeRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                  ),
                  Text('${widget.exercise.name} - Set $_currentSet of $_totalSets', style: const TextStyle(color: Colors.white, fontSize: 20)),
                ] else if (_isResting) ...[
                  Text(
                    _isPaused ? 'REST PAUSED' : 'REST',
                    style: TextStyle(color: _isPaused ? Colors.red : Colors.blue, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '00:${_timeRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                  ),
                ],
                
                const SizedBox(height: 64),
                if (!_isWaitingForRest && !_isWaitingForWorkout)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton(
                        heroTag: 'pause',
                        backgroundColor: Colors.grey.shade800,
                        onPressed: _togglePause,
                        child: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                      ),
                      FloatingActionButton(
                        heroTag: 'skip',
                        backgroundColor: Colors.grey.shade800,
                        onPressed: () {
                          _timer?.cancel();
                          if (_isWorkout) {
                            _onWorkoutFinished();
                          } else if (_isResting) {
                            _onRestFinished();
                          }
                        },
                        child: const Icon(Icons.skip_next, color: Colors.white),
                      )
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
