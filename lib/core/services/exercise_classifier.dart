class ExerciseClassifier {
  String detectExercise({
    required double elbowAngle,
    required double kneeAngle,
  }) {
    // Pushup
    if (elbowAngle < 100 && kneeAngle > 150) {
      return "Pushup";
    }

    // Squat
    if (kneeAngle < 110) {
      return "Squat";
    }

    // Bicep Curl
    if (elbowAngle < 70) {
      return "Bicep Curl";
    }

    return "Unknown";
  }
}
