import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:permission_handler/permission_handler.dart';  // Import permission handler
import 'package:workout/workout.dart';

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

class _HeartRateMonitorState extends State<HeartRateMonitor> {
  final workout = Workout();
  double heartRate = 0;
  late MqttServerClient client;

  @override
  void initState() {
    super.initState();
    requestPermissions(); // Call permissions request here
    initializeMqttClient();
    startWorkoutListener();
  }

  // Request required permissions
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
      //send a message to the broker
      
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
  }

  void startWorkoutListener() {
    workout
        .start(
      exerciseType: ExerciseType.walking,
      features: [WorkoutFeature.heartRate],
      enableGps: false,
    )
        .then((result) {
      if (result.unsupportedFeatures.isEmpty) {
        workout.stream.listen((event) {
          if (event.feature == WorkoutFeature.heartRate) {
            setState(() {
              heartRate = event.value;
            });
          }
        });

        // Start a timer to send heart rate data every 5 seconds
        Timer.periodic(const Duration(seconds: 5), (Timer timer) {
          publishHeartRate();
          print('Heart rate data sent via MQTT');
        });
      }
    }).catchError((error) {
      print('Error starting workout: $error');
    });
  }

  void publishHeartRate() {
    // Create a JSON object with the heart rate data
    final Map<String, dynamic> heartRateData = {
      'heartRate': heartRate.round(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Convert the map to a JSON string
    final String heartRateJson = jsonEncode(heartRateData);

    // Build the payload
    final builder = MqttClientPayloadBuilder();
    builder.addString(heartRateJson);

    // Publish the message
    client.publishMessage('sensor/data', MqttQos.atLeastOnce, builder.payload!);
    print('Heart rate data sent via MQTT: $heartRateJson');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Heart Rate: ${heartRate.round()} bpm',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    workout.stop();
    client.disconnect();
    super.dispose();
  }
}
