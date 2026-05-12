import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../core/theme/bolt_theme.dart';

const String _MAPBOX_TOKEN = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue: 'pk.eyJ1IjoiZnJlZGp5IiwiYSI6ImNtbmphZ2tiMDBnMjQycnFyNnh0cXF0cmYifQ.eubs9uIGOVmbyfXJakLo9g'
);

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({Key? key}) : super(key: key);

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  MapBoxNavigationViewController? _mapController;
  bool _isMapStyleLoaded = false;

  void _onMapCreated(gl.MapboxMapController controller) {
    _mapController = controller;
  }

  void _addMockMarkers() {
    if (_mapController == null || !_isMapStyleLoaded) return;
    // Mock Driver
    _mapController?.addMarker(
      latitude: -1.2921,
      longitude: 36.8219,
    );
    // Mock Active Ride
    _mapController?.addMarker(
      latitude: -1.3000,
      longitude: 36.8100,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Fleet Tracking", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          MapBoxNavigationView(
            options: MapBoxOptions(
              initialLatitude: -1.2921,
              initialLongitude: 36.8219,
              zoom: 13.0,
              language: "en",
            ),
            onCreated: (controller) {
              _mapController = controller;
              _mapController!.initialize();
              if (mounted) {
                setState(() {
                  _isMapStyleLoaded = true;
                });
                _addMockMarkers();
              }
            },
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: BoltTheme.primaryGreen),
                      const SizedBox(width: 8),
                      const Text("Available Drivers (42)"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text("Active Rides (142)"),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 12, height: 12, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text("SOS Alerts (0)"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
