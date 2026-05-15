import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../core/theme/bolt_theme.dart';
import '../core/widgets/mapbox_static_map.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _onMapCreated(MapBoxNavigationViewController controller) {
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
          _buildMap(),
          Positioned(
            top: 20,
            right: 20,
            child: _buildLegend(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (Platform.isAndroid || Platform.isIOS) {
      return MapBoxNavigationView(
        options: MapBoxOptions(
          initialLatitude: -1.2921,
          initialLongitude: 36.8219,
          zoom: 13.0,
          language: "en",
          mapStyleUrlDay: "mapbox://styles/mapbox/streets-v11",
          mapStyleUrlNight: "mapbox://styles/mapbox/dark-v10",
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
      );
    } else {
      // Windows/Desktop - Use Static Map API
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
        builder: (context, driverSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('active_rides').snapshots(),
            builder: (context, rideSnapshot) {
              List<MapMarker> markers = [];
              
              // Add Driver Markers (Green)
              if (driverSnapshot.hasData) {
                for (var doc in driverSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['lat'] != null && data['lng'] != null) {
                    markers.add(MapMarker(
                      latitude: data['lat'],
                      longitude: data['lng'],
                      color: BoltTheme.primaryGreen,
                    ));
                  }
                }
              }

              // Add Active Ride Markers (Blue)
              if (rideSnapshot.hasData) {
                for (var doc in rideSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['currentLat'] != null && data['currentLng'] != null) {
                    markers.add(MapMarker(
                      latitude: data['currentLat'],
                      longitude: data['currentLng'],
                      color: Colors.blue,
                    ));
                  }
                }
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return MapboxStaticMap(
                    latitude: -1.2921,
                    longitude: 36.8219,
                    zoom: 12.0,
                    width: constraints.maxWidth.toInt() ~/ 2, // Mapbox static limit is 1280
                    height: constraints.maxHeight.toInt() ~/ 2,
                    accessToken: _MAPBOX_TOKEN,
                    markers: markers,
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  Widget _buildLegend() {
    return Container(
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
              const Text("Available Drivers"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.blue),
              const SizedBox(width: 8),
              const Text("Active Rides"),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 12, height: 12, color: Colors.red),
              const SizedBox(width: 8),
              const Text("SOS Alerts"),
            ],
          ),
        ],
      ),
    );
  }
}
