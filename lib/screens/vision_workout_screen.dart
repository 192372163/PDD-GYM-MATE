import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/pose_detection_service.dart';

class VisionWorkoutScreen extends StatefulWidget {
  final String exerciseName;
  const VisionWorkoutScreen({super.key, required this.exerciseName});

  @override
  State<VisionWorkoutScreen> createState() => _VisionWorkoutScreenState();
}

class _VisionWorkoutScreenState extends State<VisionWorkoutScreen> {
  CameraController? _cameraController;
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isBusy = false;
  
  final int _repCount = 0;
  final String _feedbackMessage = "Position yourself in frame";
  final bool _isCorrectPosture = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.low,
      enableAudio: false,
    );

    await _cameraController?.initialize();
    
    if (!mounted) return;
    setState(() {});

    _cameraController?.startImageStream(_processCameraImage);
  }

  void _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    // Convert CameraImage to InputImage for ML Kit
    // (Implementation omitted for brevity, usually involves plane extraction or bytes)
    // For scaffolding, we just simulate detection:
    
    // final inputImage = InputImage.fromBytes(...);
    // final poses = await _poseService.processImage(inputImage);
    
    // Simulated rep counting logic
    // if (false) { // Scaffold placeholder
    //   _analyzePose(Pose(landmarks: {}));
    // }

    _isBusy = false;
  }

  // void _analyzePose(Pose pose) {
  //   // Example Squat detection:
  //   // Calculate angle at knee and hip
  //   // if angle < 90 -> rep down
  //   // if angle > 160 -> rep up (count++)
  //   // if back bent -> _feedbackMessage = "❌ Bend your back"; _isCorrectPosture = false;
  //   
  //   // Using the variables to satisfy the analyzer
  //   setState(() {
  //     _repCount++;
  //     _feedbackMessage = "Good job!";
  //     _isCorrectPosture = true;
  //   });
  // }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('AI Vision: $widget.exerciseName'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraController != null && _cameraController!.value.isInitialized)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
            
          // Rep Counter Overlay
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('REPS', style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text('$_repCount', style: const TextStyle(color: Colors.greenAccent, fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Feedback Overlay
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrectPosture ? Colors.green.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_isCorrectPosture ? Icons.check_circle : Icons.warning, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _feedbackMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
