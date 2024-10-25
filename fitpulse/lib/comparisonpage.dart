import 'package:flutter/material.dart';

class ComparisonPage extends StatelessWidget {
  final int scannedSteps;
  final double scannedCalories;
  final double scannedDistance;

  ComparisonPage({required this.scannedSteps, required this.scannedCalories, required this.scannedDistance});

  @override
  Widget build(BuildContext context) {
    // Assume current user's data is available for comparison
    final int currentUserSteps = 100; // get current user steps
    final double currentUserCalories = 15.0; // get current user calories
    final double currentUserDistance = 1.5; // get current user distance

    return Scaffold(
      appBar: AppBar(title: Text("Data Comparison")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildComparisonRow("Steps", currentUserSteps, scannedSteps),
            _buildComparisonRow("Calories", currentUserCalories, scannedCalories),
            _buildComparisonRow("Distance (km)", currentUserDistance, scannedDistance),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, dynamic currentUserData, dynamic scannedData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text("You: $currentUserData"),
        Text("Scanned: $scannedData"),
      ],
    );
  }
}
