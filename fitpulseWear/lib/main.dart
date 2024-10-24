import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workout/workout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wear OS Heart Rate Monitor',
      theme: ThemeData.dark(),
      home: const HeartRateMonitor(),
    );
  }
}

class HeartRateMonitor extends StatefulWidget {
  const HeartRateMonitor({Key? key}) : super(key: key);

  @override
  _HeartRateMonitorState createState() => _HeartRateMonitorState();
}

class _HeartRateMonitorState extends State<HeartRateMonitor> with WidgetsBindingObserver {
  final workout = Workout();
  double heartRate = 0;
  int totalSteps = 0; // Total step count
  int sessionSteps = 0; // Steps in the current session
  double totalCalories = 0; // Total calories
  double sessionCalories = 0; // Calories burned in the current session
  double totalDistance = 0; // Total distance
  double sessionDistance = 0; // Distance covered in the current session
  late MqttServerClient client;
  late Timer workoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    requestPermissions();
    initializeMqttClient();
    loadSavedData(); // Load saved steps, calories, and distance from SharedPreferences
    startWorkoutListener();
  }

  // Load saved data from SharedPreferences
  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalSteps = prefs.getInt('totalSteps') ?? 0;
      totalCalories = prefs.getDouble('totalCalories') ?? 0.0;
      totalDistance = prefs.getDouble('totalDistance') ?? 0.0;
    });
  }

  // Save current data to SharedPreferences
  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalSteps', totalSteps + sessionSteps);
    await prefs.setDouble('totalCalories', totalCalories + sessionCalories);
    await prefs.setDouble('totalDistance', totalDistance + sessionDistance);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveData(); // Save data when the app is paused
      stopWorkoutTracking();
    } else if (state == AppLifecycleState.resumed) {
      loadSavedData(); // Load data and restart tracking when app is resumed
      initializeMqttClient();
      startWorkoutListener();
    }
  }

  Future<void> requestPermissions() async {
    var sensorStatus = await Permission.sensors.status;
    if (!sensorStatus.isGranted) {
      await Permission.sensors.request();
    }

    var bluetoothStatus = await Permission.bluetoothConnect.status;
    if (!bluetoothStatus.isGranted) {
      await Permission.bluetoothConnect.request();
    }

    var locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> initializeMqttClient() async {
    client = MqttServerClient('broker.emqx.io', 'wear_os_heart_rate');
    client.logging(on: true);

    try {
      await client.connect();
      print('Connected to the MQTT broker');
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void startWorkoutListener() {
    workout
        .start(
      exerciseType: ExerciseType.walking,
      features: [
        WorkoutFeature.heartRate,
        WorkoutFeature.steps,
        WorkoutFeature.calories,
        WorkoutFeature.distance,
      ],
      enableGps: false,
    )
        .then((result) {
      if (result.unsupportedFeatures.isEmpty) {
        workout.stream.listen((event) {
          setState(() {
            if (event.feature == WorkoutFeature.heartRate) {
              heartRate = event.value;
            } else if (event.feature == WorkoutFeature.steps) {
              sessionSteps = event.value.toInt();
            } else if (event.feature == WorkoutFeature.calories) {
              sessionCalories = event.value; // Assuming this value is in calories
            } else if (event.feature == WorkoutFeature.distance) {
              sessionDistance = event.value; // Assuming this value is in meters
            }
          });
        });

        // Start a timer to send data every 5 seconds
        workoutTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
          publishWorkoutData();
          print('Workout data sent via MQTT');
        });
      }
    }).catchError((error) {
      print('Error starting workout: $error');
    });
  }

  void publishWorkoutData() {
    final Map<String, dynamic> workoutData = {
      'heartRate': heartRate.round(),
      'steps': totalSteps + sessionSteps,
      'calories': totalCalories + sessionCalories,
      'distance': totalDistance + sessionDistance, // Convert to kilometers if needed
      'timestamp': DateTime.now().toIso8601String(),
    };

    final String workoutJson = jsonEncode(workoutData);

    final builder = MqttClientPayloadBuilder();
    builder.addString(workoutJson);

    client.publishMessage('sensor/data', MqttQos.atLeastOnce, builder.payload!);
    print('Workout data sent via MQTT: $workoutJson');
  }

  void stopWorkoutTracking() {
    workout.stop();
    workoutTimer.cancel();
    print('Workout tracking stopped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Heart Rate: ${heartRate.round()} bpm',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Steps: ${totalSteps + sessionSteps}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Calories: ${(totalCalories + sessionCalories).toStringAsFixed(2)} kcal', // Display total calories with 2 decimals
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Distance: ${((totalDistance + sessionDistance) / 1000).toStringAsFixed(2)} km', // Display total distance in kilometers with 2 decimals
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    saveData(); // Save data when the widget is disposed
    stopWorkoutTracking();
    client.disconnect();
    super.dispose();
  }
}
