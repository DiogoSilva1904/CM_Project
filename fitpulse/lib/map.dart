import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];  // Store the points of the route
  StreamSubscription<Position>? _positionStream;
  bool _isMapReady = false;
  bool _isTracking = false;  // To manage start/stop tracking

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();  // Cancel location stream on disposal
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if GPS is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          return;
        }
      }

      // Get the initial position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _currentPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _isMapReady = true;
      });

      // Move the map to the initial location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15.0);
        }
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  // Start tracking movement
  Future<void> _startTrackingMovement() async {
    if (_isTracking) return;  // If already tracking, do nothing

    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,  // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      if (position != null) {
        LatLng newPoint = LatLng(position.latitude, position.longitude);

        // Add new point to the route
        setState(() {
          _currentPosition = newPoint;
          _routePoints.add(newPoint);  // Store new point in the route list
        });

        // Move the map to the new location
        _mapController.move(newPoint, 15.0);
      }
    });

    setState(() {
      _isTracking = true;  // Set tracking state to true
    });
  }

  // Stop tracking movement
  void _stopTrackingMovement() {
    if (!_isTracking) return;  // If not tracking, do nothing

    _positionStream?.cancel();  // Stop listening to location updates
    setState(() {
      _isTracking = false;  // Set tracking state to false
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator())  // Show loading while fetching location
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition!,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    // Display the route on the map
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,  // List of points representing the route
                          strokeWidth: 4.0,
                          color: Colors.deepPurple,  // Customize the path's color
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition!,
                          width: 80,
                          height: 80,
                          child: Icon(Icons.location_on, size: 50, color: Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isTracking ? null : _startTrackingMovement,  // Disable button if tracking is active
                  child: const Text('Start Tracking'),
                ),
                ElevatedButton(
                  onPressed: _isTracking ? _stopTrackingMovement : null,  // Disable button if not tracking
                  child: const Text('Stop Tracking'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

