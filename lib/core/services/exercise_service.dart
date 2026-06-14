import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'angle_calculator.dart';

enum ExerciseType { pushups, squats, pullups, curls, press, unknown }

class ExerciseService {
  ExerciseType currentExercise = ExerciseType.unknown;
  Map<ExerciseType, int> sessionReps = {
    ExerciseType.pushups: 0,
    ExerciseType.squats: 0,
    ExerciseType.pullups: 0,
    ExerciseType.curls: 0,
    ExerciseType.press: 0,
  };

  bool isDown = false;
  String feedback = "Position yourself";
  bool isPaused = false;
  DateTime lastMovementTime = DateTime.now();
  
  final double confidenceThreshold = 0.7;
  final List<ExerciseType> _detectionHistory = [];
  final int _bufferSize = 15;

  void processPose(Pose pose, {String? manualType}) {
    _checkMovement(pose);
    if (isPaused) {
      feedback = "PAUSED";
      return;
    }

    if (manualType != null) {
      // Locked Mode: Only count the selected exercise
      currentExercise = _stringToType(manualType);
    } else {
      // Auto Mode: Detect and switch
      ExerciseType detected = _detectExerciseType(pose);
      _updateDetectionHistory(detected);

      if (_isConfident()) {
        ExerciseType dominant = _getDominantExercise();
        if (dominant != currentExercise && dominant != ExerciseType.unknown) {
          currentExercise = dominant;
          isDown = false;
          feedback = "Start ${dominant.toString().split('.').last.toUpperCase()}";
        }
      }
    }

    _countReps(pose);
  }

  ExerciseType _stringToType(String type) {
    switch (type.toLowerCase()) {
      case 'pushups': return ExerciseType.pushups;
      case 'squats': return ExerciseType.squats;
      case 'pullups': return ExerciseType.pullups;
      case 'bicep curls': return ExerciseType.curls;
      case 'shoulder press': return ExerciseType.press;
      default: return ExerciseType.unknown;
    }
  }

  void _updateDetectionHistory(ExerciseType type) {
    _detectionHistory.add(type);
    if (_detectionHistory.length > _bufferSize) {
      _detectionHistory.removeAt(0);
    }
  }

  bool _isConfident() {
    return _detectionHistory.length >= _bufferSize;
  }

  ExerciseType _getDominantExercise() {
    Map<ExerciseType, int> counts = {};
    for (var type in _detectionHistory) {
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  ExerciseType _detectExerciseType(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    if (!_isLandmarkReliable(leftShoulder) || !_isLandmarkReliable(leftHip)) {
      return ExerciseType.unknown;
    }

    double dy = (leftShoulder!.y - leftHip!.y).abs();
    double dx = (leftShoulder.x - leftHip.x).abs();
    bool isHorizontal = dy < dx * 0.7;

    if (isHorizontal) {
      return ExerciseType.pushups;
    } else {
      if (_isLandmarkReliable(leftKnee)) {
        double kneeAngle = _getAngle(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
        if (kneeAngle < 150) return ExerciseType.squats;
      }
      
      if (_isLandmarkReliable(leftWrist) && _isLandmarkReliable(leftElbow)) {
        if (leftWrist!.y < leftShoulder.y) return ExerciseType.pullups;
        if (leftElbow!.y < leftShoulder.y) return ExerciseType.press;
        double elbowAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
        if (elbowAngle < 120) return ExerciseType.curls;
      }
    }

    return ExerciseType.unknown;
  }

  bool _isLandmarkReliable(PoseLandmark? landmark) {
    return landmark != null && landmark.likelihood > confidenceThreshold;
  }

  double _getAngle(Pose pose, PoseLandmarkType t1, PoseLandmarkType t2, PoseLandmarkType t3) {
    final p1 = pose.landmarks[t1];
    final p2 = pose.landmarks[t2];
    final p3 = pose.landmarks[t3];
    if (p1 == null || p2 == null || p3 == null) return 180.0;
    return AngleCalculator.calculateAngle(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
  }

  void _countReps(Pose pose) {
    switch (currentExercise) {
      case ExerciseType.pushups: _countPushups(pose); break;
      case ExerciseType.squats: _countSquats(pose); break;
      case ExerciseType.curls: _countCurls(pose); break;
      case ExerciseType.pullups: _countPullups(pose); break;
      case ExerciseType.press: _countShoulderPress(pose); break;
      default: feedback = "Identify exercise...";
    }
  }

  void _countPushups(Pose pose) {
    double elbowAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    double hipAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);

    if (hipAngle < 150) { feedback = "Keep Back Straight!"; return; }

    if (elbowAngle > 160) {
      if (isDown) { sessionReps[ExerciseType.pushups] = (sessionReps[ExerciseType.pushups] ?? 0) + 1; isDown = false; feedback = "Good Pushup!"; }
      else { feedback = "Go Down"; }
    } else if (elbowAngle < 85) { isDown = true; feedback = "Push Up!"; }
  }

  void _countSquats(Pose pose) {
    double kneeAngle = _getAngle(pose, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);
    double hipAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);

    if (hipAngle < 80) { feedback = "Keep Chest Up!"; return; }

    if (kneeAngle > 165) {
      if (isDown) { sessionReps[ExerciseType.squats] = (sessionReps[ExerciseType.squats] ?? 0) + 1; isDown = false; feedback = "Great Squat!"; }
      else { feedback = "Squat Down"; }
    } else if (kneeAngle < 100) { isDown = true; feedback = "Stand Up!"; }
  }

  void _countCurls(Pose pose) {
    double elbowAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    if (elbowAngle > 160) {
      if (isDown) { sessionReps[ExerciseType.curls] = (sessionReps[ExerciseType.curls] ?? 0) + 1; isDown = false; feedback = "Excellent!"; }
      else { feedback = "Curl Up"; }
    } else if (elbowAngle < 40) { isDown = true; feedback = "Lower Slow"; }
  }

  void _countPullups(Pose pose) {
    final wrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    if (wrist != null && shoulder != null) {
      if (shoulder.y < wrist.y) {
        if (isDown) { sessionReps[ExerciseType.pullups] = (sessionReps[ExerciseType.pullups] ?? 0) + 1; isDown = false; feedback = "Great Pull!"; }
      } else {
        isDown = true;
        feedback = "Pull Up!";
      }
    }
  }

  void _countShoulderPress(Pose pose) {
    double elbowAngle = _getAngle(pose, PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
    if (elbowAngle > 160) {
      if (isDown) { sessionReps[ExerciseType.press] = (sessionReps[ExerciseType.press] ?? 0) + 1; isDown = false; feedback = "Excellent Press!"; }
    } else if (elbowAngle < 90) {
      isDown = true;
      feedback = "Push High!";
    }
  }

  void _checkMovement(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    if (nose != null && nose.likelihood > 0.8) {
      lastMovementTime = DateTime.now();
      isPaused = false;
    } else {
      if (DateTime.now().difference(lastMovementTime).inSeconds > 3) { isPaused = true; }
    }
  }

  void reset() {
    sessionReps.updateAll((key, value) => 0);
    currentExercise = ExerciseType.unknown;
    isDown = false;
    feedback = "Position yourself";
  }

  String get exerciseName => currentExercise.toString().split('.').last.toUpperCase();
  int get currentReps => sessionReps[currentExercise] ?? 0;
}
