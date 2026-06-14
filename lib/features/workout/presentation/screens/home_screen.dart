import 'package:flutter/material.dart';
import 'workout_screen.dart';
import 'camera_screen.dart';
import '../../../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../../../features/analytics/presentation/screens/advisor_screen.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../services/service_locator.dart';
import '../../../../core/models/workout_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("MotionIQ Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await sl<FirebaseService>().signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: StreamBuilder<List<WorkoutModel>>(
        stream: sl<FirebaseService>().getWorkoutHistoryStream(),
        builder: (context, snapshot) {
          int totalReps = 0;
          int totalWorkouts = 0;
          int totalCalories = 0;

          if (snapshot.hasData) {
            totalWorkouts = snapshot.data!.length;
            totalReps = snapshot.data!.fold(0, (sum, item) => sum + item.reps);
            totalCalories = snapshot.data!.fold(0, (sum, item) => sum + item.calories);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildStatsBanner(totalReps, totalWorkouts, totalCalories),
              const SizedBox(height: 30),
              const Text("Train with AI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                title: "Choose Workout",
                subtitle: "Select targeted exercise mode",
                icon: Icons.fitness_center,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutScreen())),
              ),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                title: "Auto-Detect AI",
                subtitle: "Full-body automatic identification",
                icon: Icons.auto_awesome,
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CameraScreen())),
              ),
              const SizedBox(height: 30),
              const Text("AI Coaching", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                title: "AI Advisor",
                subtitle: "Personalized posture feedback",
                icon: Icons.psychology,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdvisorScreen())),
              ),
              const SizedBox(height: 15),
              _buildFeatureCard(
                context,
                title: "Analytics Hub",
                subtitle: "Visual progress and history",
                icon: Icons.analytics,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBanner(int reps, int count, int cals) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade600]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem("Total Reps", "$reps"),
          _buildStatItem("Sessions", "$count"),
          _buildStatItem("Calories", "$cals"),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
