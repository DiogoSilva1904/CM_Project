import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ActivityHistoryPage extends StatefulWidget {
  @override
  _ActivityHistoryPageState createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  List<Map<String, dynamic>> _activityHistory = [];

  @override
  void initState() {
    super.initState();
    _loadActivityHistory();
  }

  Future<void> _loadActivityHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    List<Map<String, dynamic>> activityHistory = [];

    // Filter keys that start with 'workoutData_' to only get relevant workout data
    for (String key in keys) {
      if (key.startsWith('workoutData_')) {
        String? jsonData = prefs.getString(key);
        if (jsonData != null) {
          List<dynamic> data = jsonDecode(jsonData);
          // Store each day's data as a map with the date
          activityHistory.add({
            'date': key.replaceFirst('workoutData_', ''), // Extract the date part from the key
            'data': data
          });
        }
      }
    }

    setState(() {
      _activityHistory = activityHistory;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Page Title
            Padding(
              padding: const EdgeInsets.only(top: 56.0, bottom: 12.0),
              child: Text(
                "Activity History",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            
            // Activity List
            Expanded(
              child: _activityHistory.isEmpty
                  ? const Center(child: Text("No activity data available."))
                  : ListView.builder(
                      itemCount: _activityHistory.length,
                      itemBuilder: (context, index) {
                        final dayData = _activityHistory[index];
                        final date = dayData['date'];
                        final stats = dayData['data'] as List<dynamic>;

                        // There should only be one set of stats per day, so we take the first entry
                        final stat = stats[0];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Activity on $date",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildStatItem("Steps", stat['steps'].toString()),
                                      _buildStatItem("Calories", stat['calories'].toStringAsFixed(2)),
                                      _buildStatItem("Distance", (stat['distance'] / 1000).toStringAsFixed(2) + " km"),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build individual stat widgets
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
