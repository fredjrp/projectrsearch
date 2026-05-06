import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as gl;
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
  gl.MapboxMapController? _mapController;

  void _onMapCreated(gl.MapboxMapController controller) {
    _mapController = controller;
    // Simulate active drivers and rides
    _addMockMarkers();
  }

  void _addMockMarkers() {
    // Mock Driver
    _mapController?.addSymbol(
      const gl.SymbolOptions(
        geometry: gl.LatLng(-1.2921, 36.8219),
        iconImage: "car-15",
        iconSize: 2.0,
      ),
    );
    // Mock Active Ride
    _mapController?.addSymbol(
      const gl.SymbolOptions(
        geometry: gl.LatLng(-1.3000, 36.8100),
        iconImage: "marker-15",
        iconColor: "#0000FF", // Blue for ride
      ),
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
          gl.MapboxMap(
            accessToken: _MAPBOX_TOKEN,
            initialCameraPosition: const gl.CameraPosition(
              target: gl.LatLng(-1.2921, 36.8219),
              zoom: 13.0,
            ),
            onMapCreated: _onMapCreated,
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
