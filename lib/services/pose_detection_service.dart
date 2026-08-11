import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  
  bool _isProcessing = false;

  /// Process the camera image and return detected poses
  Future<List<Pose>> processImage(InputImage inputImage) async {
    if (_isProcessing) return [];
    _isProcessing = true;
    
    try {
      final poses = await _poseDetector.processImage(inputImage);
      return poses;
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _poseDetector.close();
  }

  /// Calculates the angle between three landmarks.
  /// Helpful for detecting squats, pushups, etc.
  static double getAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    // Basic angle calculation placeholder
    // Math logic using coordinates (x,y)
    return 90.0; 
  }
}
