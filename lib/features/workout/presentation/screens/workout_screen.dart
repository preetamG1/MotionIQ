import 'package:flutter/material.dart';
import 'camera_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> exercises = [
      {'name': 'Pushups', 'icon': Icons.sports_gymnastics, 'color': Colors.blue, 'desc': 'Chest & Triceps'},
      {'name': 'Squats', 'icon': Icons.fitness_center, 'color': Colors.orange, 'desc': 'Legs & Core'},
      {'name': 'Pullups', 'icon': Icons.accessibility_new, 'color': Colors.green, 'desc': 'Back & Arms'},
      {'name': 'Bicep Curls', 'icon': Icons.room_service_outlined, 'color': Colors.red, 'desc': 'Biceps focus'},
      {'name': 'Shoulder Press', 'icon': Icons.upload_sharp, 'color': Colors.purple, 'desc': 'Shoulders focus'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Select Exercise")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return _buildExerciseCard(context, exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Map<String, dynamic> exercise) {
    final color = exercise['color'] as Color;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(manualExercise: exercise['name']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(exercise['icon'], size: 40, color: color),
            const SizedBox(height: 10),
            Text(exercise['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(exercise['desc'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
