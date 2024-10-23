import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttService {
  late MqttServerClient client;
  final StreamController<String> _heartRateUpdateController = StreamController<String>.broadcast();

  Stream<String> get heartRateUpdates => _heartRateUpdateController.stream;

  Future<void> initializeMqttClient() async {
    client = MqttServerClient('broker.emqx.io', 'flutter_client_android');
    client.logging(on: true);

    // Configure callbacks
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
      print('MQTT: Conectado com sucesso ao broker.');
    } catch (e) {
      print('MQTT: Exception na conexão - $e');
      client.disconnect();
    }

    // Subscribe to the topic
    const topic = 'sensor/data';
    client.subscribe(topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('MQTT: Mensagem recebida - $payload');
      _handleHeartRateData(payload);
    });
  }

  void _handleHeartRateData(String payload) {
  try {
    // Parse the payload as JSON
    final Map<String, dynamic> data = jsonDecode(payload);

    // Check if heartRate key exists in the received data
    if (data.containsKey('heartRate')) {
      final heartRate = data['heartRate'].toString();
      print("Heart Rate: $heartRate");

      // Add the heart rate data to the stream
      _heartRateUpdateController.add(heartRate);
    } else {
      print("No heart rate data found in payload.");
    }
  } catch (e) {
    print("Error processing payload: $e");
    _heartRateUpdateController.add('Error');  // Send error to stream in case of failure
  }
}


  void onConnected() {
    print('Connected to MQTT broker.');
  }

  void onDisconnected() {
    print('Disconnected from MQTT broker.');
  }
}

