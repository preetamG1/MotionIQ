import 'package:flutter/material.dart';
import '../../../../core/models/workout_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../services/service_locator.dart';

class AdvisorScreen extends StatelessWidget {
  const AdvisorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Fitness Advisor"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<WorkoutModel>>(
        stream: sl<FirebaseService>().getWorkoutHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final workouts = snapshot.data ?? [];
          if (workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    "I need some data to advise you!\nStart your first workout.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildFormScore(workouts),
              const SizedBox(height: 30),
              const Text(
                "Personalized Insights",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _generateAdviceCards(workouts),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFormScore(List<WorkoutModel> workouts) {
    double avgScore = workouts.fold(0.0, (sum, item) => sum + item.postureScore) / workouts.length;
    
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Overall Performance Score",
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            "${avgScore.toStringAsFixed(1)}%",
            style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: avgScore / 100,
              backgroundColor: Colors.white24,
              color: Colors.greenAccent,
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Target: 95% for Elite Form",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _generateAdviceCards(List<WorkoutModel> workouts) {
    List<Widget> cards = [];

    // Push-up advice
    final pushups = workouts.where((w) => w.exercise.contains("PUSHUPS")).toList();
    if (pushups.isNotEmpty) {
      bool lowScore = pushups.any((w) => w.postureScore < 85);
      cards.add(_buildAdviceCard(
        "Push-up Master",
        lowScore 
          ? "Keep your core tighter. Your AI data shows a slight hip sag during the 'Up' phase."
          : "Your push-up form is world-class! Try slow-motion reps to increase intensity.",
        lowScore ? Icons.warning_amber_rounded : Icons.verified_user,
        lowScore ? Colors.orange : Colors.green,
      ));
    }

    // Squat advice
    final squats = workouts.where((w) => w.exercise.contains("SQUATS")).toList();
    if (squats.isNotEmpty) {
      bool lowScore = squats.any((w) => w.postureScore < 80);
      cards.add(_buildAdviceCard(
        "Squat Deep",
        lowScore 
          ? "Your knee angle isn't consistently hitting 90°. Go slightly lower for full glute activation."
          : "Great depth on your squats! Ensure you're keeping your weight on your heels.",
        lowScore ? Icons.info_outline : Icons.bolt,
        lowScore ? Colors.blue : Colors.purple,
      ));
    }

    // Consistency advice
    cards.add(_buildAdviceCard(
      "Workout Rhythm",
      workouts.length > 5 
        ? "You've completed ${workouts.length} sessions this week. You are building a solid habit!"
        : "Let's pick up the pace! Aim for at least one AI-tracked session tomorrow.",
      Icons.calendar_month,
      Colors.indigo,
    ));

    return Column(children: cards);
  }

  Widget _buildAdviceCard(String title, String advice, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    advice,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
