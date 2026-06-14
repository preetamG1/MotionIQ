import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_model.dart';

class LocalStorageService {
  static const String _workoutKey = 'offline_workouts';
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // Save workout locally
  Future<void> saveWorkoutLocally(WorkoutModel workout) async {
    final List<WorkoutModel> history = await getLocalWorkouts();
    history.insert(0, workout);
    
    final List<String> encoded = history.map((w) => jsonEncode({
      'userId': w.userId,
      'exercise': w.exercise,
      'reps': w.reps,
      'calories': w.reps, // Simplified mapping for MVP
      'postureScore': w.postureScore,
      'timestamp': w.timestamp.toIso8601String(),
    })).toList();

    await _prefs.setStringList(_workoutKey, encoded);
  }

  // Get local workouts
  Future<List<WorkoutModel>> getLocalWorkouts() async {
    final List<String>? encoded = _prefs.getStringList(_workoutKey);
    if (encoded == null) return [];

    return encoded.map((s) {
      final map = jsonDecode(s);
      return WorkoutModel(
        userId: map['userId'],
        exercise: map['exercise'],
        reps: map['reps'],
        calories: map['calories'],
        postureScore: map['postureScore'],
        timestamp: DateTime.parse(map['timestamp']),
      );
    }).toList();
  }

  // Clear local storage after sync
  Future<void> clearLocalWorkouts() async {
    await _prefs.remove(_workoutKey);
  }
}
