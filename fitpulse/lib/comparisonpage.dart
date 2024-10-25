import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComparisonPage extends StatelessWidget {
  final int scannedSteps;
  final double scannedCalories;
  final double scannedDistance;

  ComparisonPage({
    required this.scannedSteps,
    required this.scannedCalories,
    required this.scannedDistance,
  });

  Future<Map<String, dynamic>> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    String key = "workoutData_${DateTime.now().toIso8601String().split('T')[0]}";
    
    try {
      String savedData = prefs.getString(key) ?? '[]';
      List<dynamic> dataList = jsonDecode(savedData);

      if (dataList.isNotEmpty) {
        final latestData = dataList.last;
        return {
          'steps': latestData['steps'] ?? 0,
          'calories': latestData['calories'] ?? 0.0,
          'distance': latestData['distance'] ?? 0.0,
        };
      } else {
        print("No workout data found for today.");
      }
    } catch (e) {
      print("Error loading workout data: $e");
    }
    return {'steps': 0, 'calories': 0.0, 'distance': 0.0};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Comparison", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadWorkoutData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading data"));
          } else {
            final data = snapshot.data!;
            final currentUserSteps = data['steps'] as int;
            final currentUserCalories = data['calories'] as double;
            final currentUserDistance = (data['distance'] as double) / 1000;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildComparisonRow("Steps", currentUserSteps, scannedSteps, Icons.directions_walk),
                  Divider(color: Colors.grey[300], thickness: 1),
                  _buildComparisonRow("Calories", currentUserCalories.toStringAsFixed(2), scannedCalories.toStringAsFixed(2), Icons.local_fire_department),
                  Divider(color: Colors.grey[300], thickness: 1),
                  _buildComparisonRow("Distance (km)", currentUserDistance.toStringAsFixed(2), (scannedDistance / 1000).toStringAsFixed(2), Icons.map),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildComparisonRow(String label, dynamic currentUserData, dynamic scannedData, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Icon(icon, color: Colors.blueAccent, size: 30),
              SizedBox(height: 4),
              Text(
                "You",
                style: TextStyle(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.bold),
              ),
              Text(
                "$currentUserData",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          Column(
            children: [
              Icon(icon, color: Colors.green, size: 30),
              SizedBox(height: 4),
              Text(
                "Scanned",
                style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                "$scannedData",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
