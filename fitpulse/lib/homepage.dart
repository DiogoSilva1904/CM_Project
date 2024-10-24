import 'package:flutter/material.dart';
import 'map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitpulse/services/mqtt.dart';
import 'package:fitpulse/activity_history.dart';
import 'qrcodepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // List of screens for each tab
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    const MapScreen(),
    QRPage(),
    ActivityHistoryPage(),
  ];

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Activity',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttService _mqttService = MqttService();
  String _heartRate = 'Loading...'; // Default value for heart rate
  int _totalSteps = 0; // Total steps
  double _totalCalories = 0.0; // Total calories
  double _totalDistance = 0.0; // Total distance
  double _caloriesGoal = 2000; // Default calories goal
  double _distanceGoal = 5; // Default distance goal in km
  List<int> _stepsLast7Days = List.generate(7, (_) => 0); // Default step data for last 7 days
  double _maxYValue = 5000; // Default max Y value for the bar chart


  TextEditingController _caloriesGoalController = TextEditingController();
  TextEditingController _distanceGoalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedGoals();
    _loadSavedData();
    _initializeMqtt();
  }

  // Load saved goals from SharedPreferences
  Future<void> _loadSavedGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesGoal = prefs.getDouble('caloriesGoal') ?? 2000; // Default 2000 if not set
      _distanceGoal = prefs.getDouble('distanceGoal') ?? 5; // Default 5 km if not set
      _caloriesGoalController.text = _caloriesGoal.toString();
      _distanceGoalController.text = _distanceGoal.toString();
    });
  }
  

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String key = "workoutData_${DateTime.now().toIso8601String().split('T')[0]}";
      String savedData = prefs.getString(key) ?? '[]'; // Load saved data
      List<dynamic> dataList = jsonDecode(savedData);

      List<int> stepsLast7Days = [];

      for (int i = 0; i < 7; i++) {
        DateTime date = DateTime.now().subtract(Duration(days: i));
        String key = "workoutData_${date.toIso8601String().split('T')[0]}";
        String savedData = prefs.getString(key) ?? '[]'; // Load saved data
        List<dynamic> dataList = jsonDecode(savedData);
        int stepsForDay = 0;

        if (dataList.isNotEmpty) {
          final latestData = dataList.last; // Get the latest entry
          stepsForDay = latestData['steps'] ?? 0;
        }
        stepsLast7Days.add(stepsForDay);
      }
      double maxSteps = _stepsLast7Days.reduce((a, b) => a > b ? a : b).toDouble();

            // Add a buffer to the max steps to ensure some space above the highest bar
      double maxYValue = maxSteps + 500;

      if (dataList.isNotEmpty) {
        final latestData = dataList.last; // Get the latest entry

        setState(() {
          _heartRate = latestData['heartRate'].toString() ?? 'No data';
          _totalSteps = latestData['steps'] ?? 0;
          _totalCalories = latestData['calories'] ?? 0.0;
          _totalDistance = latestData['distance'] ?? 0.0;
          _stepsLast7Days = stepsLast7Days.reversed.toList(); // Reverse to show most recent first ex [1500, 2800, 2200, 3500, 1800, 3000, 1000];
          _maxYValue = maxYValue;

        });
      }
    } catch (e) {
      print("Error loading saved data: $e");
    }
  }

  Future<void> _initializeMqtt() async {
    try {
      await _mqttService.initializeMqttClient();
      print("MQTT Client initialized");

      // Listen to workout updates from the MQTT service
      _mqttService.workoutDataUpdates.listen((workoutData) {
        if (mounted) {
          setState(() {
            _heartRate = workoutData['heartRate']?.toString() ?? 'No data';
            _totalSteps = workoutData['steps'] ?? 0;
            _totalCalories = workoutData['calories'] ?? 0.0;
            _totalDistance = workoutData['distance'] ?? 0.0;
          });
        }
      });
    } catch (e) {
      print("Error initializing MQTT: $e");
    }
  }

  // Save the goals to SharedPreferences
  void _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _caloriesGoal = double.tryParse(_caloriesGoalController.text) ?? _caloriesGoal;
      _distanceGoal = double.tryParse(_distanceGoalController.text) ?? _distanceGoal;

      // Save to SharedPreferences
      prefs.setDouble('caloriesGoal', _caloriesGoal);
      prefs.setDouble('distanceGoal', _distanceGoal);
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? email = user?.email; // Get information from the current logged user

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Progress for Steps
            const SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: _totalSteps / 3500, // Use total steps to show progress
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Icon(
                        Icons.directions_walk,
                        size: 50,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "$_totalSteps/3500", // Update step goal display
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text("Steps"),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Metrics Row (Calories, Move Minutes, Distance)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                MetricWidget(label: 'Cal', value: _totalCalories.toStringAsFixed(2)), // Display total calories with 2 decimals
                MetricWidget(label: 'Move min', value: '154'), // Example value for move minutes
                MetricWidget(label: 'km', value: (_totalDistance / 1000).toStringAsFixed(2)), // Convert distance to kilometers
              ],
            ),
            const SizedBox(height: 20),

            // Heart Rate Section
            Card(
              child: ListTile(
                leading: Icon(Icons.favorite, color: Colors.red),
                title: const Text('Heart Rate'),
                subtitle: Row(
                  children: [
                    Text(
                      '$_heartRate bpm', // Display the updated heart rate value
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Steps Bar Chart for Last 7 Days
            const Text(
              'Steps in the last 7 days',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Calculate the max step count from the list
             // Add a buffer of 500 steps for visualization

           SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: _maxYValue, // Use the calculated maxY based on the highest step value
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false, // Disable top titles to remove the numbers at the top
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['7', '6', '5', '4', '3', '2', '1'];
                        return Text(days[value.toInt() % days.length]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                      interval: 1000,
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _stepsLast7Days[index].toDouble(),
                        width: 15,
                        color: Colors.deepPurple,
                      )
                    ],
                  );
                }),
              ),
            ),
          ),

          const SizedBox(height: 20),



            // Daily Calories and Distance Goal Section
            Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Goals',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  // Button to set daily goals (opens modal dialog)
                  Center(
                    child: ElevatedButton(
                      onPressed: () => _showGoalInputDialog(context),
                      child: const Text('Set Daily Goals'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Show progress towards the goals
                  Text(
                    'Calories Progress: ${(_totalCalories / _caloriesGoal * 100).toStringAsFixed(2)}%',
                  ),
                  LinearProgressIndicator(
                    value: _totalCalories / _caloriesGoal,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Distance Progress: ${((_totalDistance / 1000) / _distanceGoal * 100).toStringAsFixed(2)}%',
                  ),
                  LinearProgressIndicator(
                    value: (_totalDistance / 1000) / _distanceGoal,
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  // Method to show a pop-up modal for entering goals
void _showGoalInputDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Set Daily Goals'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _caloriesGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Calories Goal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _distanceGoalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Distance Goal (km)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog without saving
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveGoals(); // Save the goals
              Navigator.of(context).pop(); // Close the dialog after saving
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  @override
  void dispose() {
    _mqttService.client.disconnect();
    super.dispose();
  }
}



class MetricWidget extends StatelessWidget {
  final String label;
  final String value;

  const MetricWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
