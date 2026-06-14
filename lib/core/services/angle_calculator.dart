import 'dart:math';

class AngleCalculator {
  static double calculateAngle(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final ab = Point(ax - bx, ay - by);
    final cb = Point(cx - bx, cy - by);

    double dot = (ab.x * cb.x) + (ab.y * cb.y);

    double magAB = sqrt(ab.x * ab.x + ab.y * ab.y);

    double magCB = sqrt(cb.x * cb.x + cb.y * cb.y);

    double angle = acos(dot / (magAB * magCB));

    return angle * 180 / pi;
  }
}
