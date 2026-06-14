class PushupCounter {
  int reps = 0;

  bool isDown = false;

  void update(double elbowAngle) {
    if (elbowAngle < 90) {
      isDown = true;
    }

    if (isDown && elbowAngle > 160) {
      reps++;
      isDown = false;
    }
  }
}
