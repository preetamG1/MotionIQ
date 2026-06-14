import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    // Determine scale to maintain aspect ratio without compression
    final double scaleX = size.width / absoluteImageSize.height;
    final double scaleY = size.height / absoluteImageSize.width;
    
    // Use the maximum scale to ensure the skeleton covers the full preview area
    // This matches the "Cover" logic used in the CameraPreview
    final double scale = scaleX > scaleY ? scaleX : scaleY;
    
    // Offset to center the skeleton if the preview is cropped
    final double offsetX = (size.width - absoluteImageSize.height * scale) / 2;
    final double offsetY = (size.height - absoluteImageSize.width * scale) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    for (final pose in poses) {
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paint) {
        final joint1 = pose.landmarks[type1];
        final joint2 = pose.landmarks[type2];
        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
            Offset(
              _translateX(joint1.x, scale, offsetX, size),
              _translateY(joint1.y, scale, offsetY, size),
            ),
            Offset(
              _translateX(joint2.x, scale, offsetX, size),
              _translateY(joint2.y, scale, offsetY, size),
            ),
            paint,
          );
        }
      }

      // Draw Skeleton Connections
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);

      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);

      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);

      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      // Draw Landmark Dots
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
          Offset(
            _translateX(landmark.x, scale, offsetX, size),
            _translateY(landmark.y, scale, offsetY, size),
          ),
          4,
          Paint()..color = Colors.white,
        );
      });
    }
  }

  double _translateX(double x, double scale, double offsetX, Size size) {
    // For front camera, we usually need to flip horizontally
    // But for iQOO/Android back camera, we map directly
    if (rotation == InputImageRotation.rotation90deg) {
      return x * scale + offsetX;
    } else {
      return size.width - (x * scale + offsetX);
    }
  }

  double _translateY(double y, double scale, double offsetY, Size size) {
    return y * scale + offsetY;
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize || oldDelegate.poses != poses;
  }
}
