import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/models/workout_model.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../services/service_locator.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics Dashboard")),
      body: StreamBuilder<List<WorkoutModel>>(
        stream: sl<FirebaseService>().getWorkoutHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) {
            return const Center(child: Text("No data for analytics yet."));
          }

          int totalReps = workouts.fold(0, (sum, item) => sum + item.reps);
          int totalCalories = workouts.fold(0, (sum, item) => sum + item.calories);
          int totalWorkouts = workouts.length;

          // Process data for charts
          Map<String, int> exerciseDistribution = {};
          for (var w in workouts) {
            exerciseDistribution[w.exercise] = (exerciseDistribution[w.exercise] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(totalReps, totalCalories, totalWorkouts),
                const SizedBox(height: 30),
                const Text(
                  "Recent Performance",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildRepChart(workouts),
                const SizedBox(height: 30),
                const Text(
                  "Exercise Distribution",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildDistributionChart(exerciseDistribution),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int reps, int cals, int count) {
    return Row(
      children: [
        Expanded(child: _buildMiniStat("Total Reps", "$reps", Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniStat("Calories", "$cals", Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildMiniStat("Workouts", "$count", Colors.green)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRepChart(List<WorkoutModel> workouts) {
    // Show last 7 workouts
    final lastWorkouts = workouts.take(7).toList().reversed.toList();
    
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(lastWorkouts.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: lastWorkouts[index].reps.toDouble(),
                  color: Colors.blue,
                  width: 15,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                )
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDistributionChart(Map<String, int> distribution) {
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple];
    int colorIndex = 0;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: distribution.entries.map((entry) {
            final color = colors[colorIndex % colors.length];
            colorIndex++;
            return PieChartSectionData(
              value: entry.value.toDouble(),
              color: color,
              title: entry.key,
              radius: 60,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }
}
