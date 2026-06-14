class RepCounter {
  int reps = 0;
  bool isDown = false;

  void updateSquat(double kneeAngle) {
    if (kneeAngle < 90) {
      isDown = true;
    }

    if (isDown && kneeAngle > 160) {
      reps++;
      isDown = false;
    }
  }

  int getReps() {
    return reps;
  }

  void reset() {
    reps = 0;
    isDown = false;
  }
}
