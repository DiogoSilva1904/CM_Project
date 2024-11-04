import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QRGen extends StatefulWidget {
  @override
  _QRGenState createState() => _QRGenState();
}

class _QRGenState extends State<QRGen> {
  int _steps = 0;
  double _calories = 0.0;
  double _distance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    final prefs = await SharedPreferences.getInstance();
    String key = "workoutData_${DateTime.now().toIso8601String().split('T')[0]}";
    
    try {
      String savedData = prefs.getString(key) ?? '[]';
      List<dynamic> dataList = jsonDecode(savedData);

      if (dataList.isNotEmpty) {
        final latestData = dataList.last;
        setState(() {
          _steps = latestData['steps'] ?? 0;
          _calories = latestData['calories'] ?? 0.0;
          _distance = latestData['distance'] ?? 0.0;
        });
      } else {
        print("No workout data found for today.");
      }
    } catch (e) {
      print("Error loading workout data: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = jsonEncode({
      'steps': _steps,
      'calories': _calories,
      'distance': _distance,
    });

    return Scaffold(
      body: Center(
        child: QrImageView(
          data: data,
          version: QrVersions.auto,
          size: 200.0,
        ),
      ),
    );
  }
}
