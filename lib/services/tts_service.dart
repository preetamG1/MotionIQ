import 'package:flutter_tts/flutter_tts.dart';

import '../core/services/exercise_service.dart';

class TtsService {
  TtsService() {
    _init();
  }

  final FlutterTts _flutterTts = FlutterTts();
  String? _lastSpokenFeedback;
  DateTime _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _cooldown = Duration(seconds: 4);

  Future<void> _init() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.awaitSpeakCompletion(false);
  }

  void speakFeedback(ExerciseType exercise, String feedback) {
    final message = _coachMessage(exercise, feedback);
    if (message == null) return;

    final now = DateTime.now();
    if (message == _lastSpokenFeedback) return;
    if (now.difference(_lastSpokenAt) < _cooldown) return;

    _lastSpokenFeedback = message;
    _lastSpokenAt = now;
    _flutterTts.speak(message);
  }

  void speakWorkoutCompleted() {
    _speakPriority('Excellent work. Workout completed');
  }

  void reset() {
    _lastSpokenFeedback = null;
    _lastSpokenAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> stop() => _flutterTts.stop();

  void _speakPriority(String message) {
    if (message == _lastSpokenFeedback) return;

    _lastSpokenFeedback = message;
    _lastSpokenAt = DateTime.now();
    _flutterTts.speak(message);
  }

  String? _coachMessage(ExerciseType exercise, String feedback) {
    final normalized = feedback.toLowerCase();

    if (normalized.contains('position') ||
        normalized.contains('identify') ||
        normalized.contains('start')) {
      return 'Position yourself correctly';
    }

    switch (exercise) {
      case ExerciseType.pushups:
        if (normalized.contains('back')) return 'Keep your back straight';
        if (normalized.contains('go down')) return 'Go lower';
        if (normalized.contains('good')) return 'Great rep';
        if (normalized.contains('push up')) return 'Good form';
        break;
      case ExerciseType.squats:
        if (normalized.contains('chest') || normalized.contains('back')) {
          return 'Keep your back straight';
        }
        if (normalized.contains('squat down')) return 'Go lower';
        if (normalized.contains('great')) return 'Great rep';
        if (normalized.contains('stand up')) return 'Good form';
        break;
      case ExerciseType.pullups:
        if (normalized.contains('pull up')) return 'Pull higher';
        if (normalized.contains('great')) return 'Great rep';
        break;
      case ExerciseType.curls:
        if (normalized.contains('curl') || normalized.contains('lower')) {
          return 'Full range of motion';
        }
        if (normalized.contains('excellent')) return 'Great rep';
        break;
      case ExerciseType.press:
        if (normalized.contains('push high')) return 'Extend fully';
        if (normalized.contains('back')) return 'Keep your back straight';
        if (normalized.contains('excellent')) return 'Great rep';
        break;
      case ExerciseType.unknown:
        return 'Position yourself correctly';
    }

    return null;
  }
}