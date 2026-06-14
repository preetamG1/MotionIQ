import 'package:flutter/material.dart';
import '../../../../core/models/workout_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/exercise_service.dart';
import '../../../../services/service_locator.dart';

class ResultScreen extends StatefulWidget {
  final String exercise;
  final int reps;
  final int calories;
  final int score;
  final Map<ExerciseType, int>? sessionStats;

  const ResultScreen({
    super.key,
    required this.exercise,
    required this.reps,
    required this.calories,
    required this.score,
    this.sessionStats,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveWorkout() async {
    setState(() => _isSaving = true);
    
    final userId = sl<FirebaseService>().currentUserId;
    if (userId != null) {
      // If we have mixed stats, we might want to save them individually or as one summary.
      // For MVP, we'll save the summary with the exercise name provided.
      final workout = WorkoutModel(
        userId: userId,
        exercise: widget.exercise,
        reps: widget.reps,
        calories: widget.calories,
        postureScore: widget.score,
        timestamp: DateTime.now(),
      );
      
      await sl<FirebaseService>().saveWorkout(workout);
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Not signed in")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Session Summary"),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              "Session Complete!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            _buildResultCard(),
            if (widget.sessionStats != null && widget.sessionStats!.values.any((v) => v > 0)) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Detailed Stats:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              _buildDetailedStats(),
            ],
            const SizedBox(height: 40),
            if (!_isSaved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "Saving..." : "Save to History", style: const TextStyle(fontSize: 18)),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Back to Home", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: widget.sessionStats!.entries
            .where((e) => e.value > 0)
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toString().split('.').last.toUpperCase(), style: const TextStyle(fontSize: 16)),
                      Text("${e.value} Reps", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildResultRow("Total Reps", "${widget.reps}", Icons.repeat),
          const Divider(height: 32),
          _buildResultRow("Total Calories", "${widget.calories} kcal", Icons.local_fire_department),
          const Divider(height: 32),
          _buildResultRow("Avg Posture Score", "${widget.score}%", Icons.spellcheck),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
