import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MqttService {
  late MqttServerClient client;
  final StreamController<Map<String, dynamic>> _workoutDataUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get workoutDataUpdates => _workoutDataUpdateController.stream;

  Future<void> initializeMqttClient() async {
    client = MqttServerClient('broker.emqx.io', 'flutter_client_android');
    client.logging(on: true);

    // Configure callbacks
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
      print('MQTT: Successfully connected to the broker.');
    } catch (e) {
      print('MQTT: Connection exception - $e');
      client.disconnect();
      return; // Exit the method if connection fails
    }

    // Subscribe to the topic
    const topic = 'sensor/data';
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('MQTT: Message received - $payload');
      _handleWorkoutData(payload);
    });
  }

  void _handleWorkoutData(String payload) async {
    try {
      // Parse the payload as JSON
      final Map<String, dynamic> data = jsonDecode(payload);

      // Check if necessary keys exist in the received data
      if (data.containsKey('heartRate') &&
          data.containsKey('steps') &&
          data.containsKey('calories') &&
          data.containsKey('distance')) {
        final workoutData = {
          'heartRate': data['heartRate'].toString(),
          'steps': data['steps'] as int,
          'calories': data['calories'] as double,
          'distance': data['distance'] as double,
          'timestamp': DateTime.now().toIso8601String(),
        };
        print("Workout Data: $workoutData");

        // Add the workout data to the stream
        _workoutDataUpdateController.add(workoutData);

        // Save data to SharedPreferences
        await saveWorkoutData(workoutData);
      } else {
        print("Incomplete workout data found in payload.");
      }
    } catch (e) {
      print("Error processing payload: $e");
      _workoutDataUpdateController.add({'error': 'Error processing data'}); // Send error to stream in case of failure
    }
  }

  Future<void> saveWorkoutData(Map<String, dynamic> workoutData) async {
  final prefs = await SharedPreferences.getInstance();
  
  // Use today's date as the key (formatted as 'workoutData_YYYY-MM-DD')
  String key = "workoutData_${DateTime.now().toIso8601String().split('T')[0]}";
  
  // Save the new workout data directly, replacing any existing data for this date
  await prefs.setString(key, jsonEncode([workoutData]));
}


  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker.');
  }
}
