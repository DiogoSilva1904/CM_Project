import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer to detect app lifecycle changes
    _getCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer when the widget is disposed
    super.dispose();
  }

  // This method gets called when the app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRequestingLocation) {
      // When the app resumes, check the location again if we were requesting it
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // If location services are disabled, prompt the user to enable them
        _isRequestingLocation = true;
        _showGpsDisabledDialog();
        return;
      }

      // If location services are enabled, reset the flag
      _isRequestingLocation = false;

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('Location permission denied.');
          return;
        }
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });

      // Move the map after it's rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null) {
          _mapController.move(_currentPosition!, 15.0);
        }
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  // Show dialog to ask user to enable GPS
  void _showGpsDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enable GPS'),
        content: Text('GPS is required to use this app. Would you like to enable it?'),
        actions: [
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Yes'),
            onPressed: () {
              Geolocator.openLocationSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching location
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
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
