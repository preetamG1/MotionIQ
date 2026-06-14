import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutModel {
  final String? id;
  final String userId;
  final String exercise;
  final int reps;
  final int calories;
  final int postureScore;
  final DateTime timestamp;

  WorkoutModel({
    this.id,
    required this.userId,
    required this.exercise,
    required this.reps,
    required this.calories,
    required this.postureScore,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exercise': exercise,
      'reps': reps,
      'calories': calories,
      'postureScore': postureScore,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory WorkoutModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WorkoutModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      exercise: data['exercise'] ?? '',
      reps: data['reps'] ?? 0,
      calories: data['calories'] ?? 0,
      postureScore: data['postureScore'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
