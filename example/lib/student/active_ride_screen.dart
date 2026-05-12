import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../core/theme/bolt_theme.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({Key? key}) : super(key: key);

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency SOS", style: TextStyle(color: Colors.red)),
        content: const Text("Are you in danger? This will alert admins and share your live location immediately."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // TODO: Write SOS alert to Firebase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("SOS Alert Sent! Help is on the way."), backgroundColor: Colors.red),
              );
            },
            child: const Text("SEND SOS"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapBoxNavigationView(
            options: MapBoxOptions(
              initialLatitude: -1.2921,
              initialLongitude: 36.8219,
              zoom: 16.0,
              language: "en",
              mapStyleUrlDay: "mapbox://styles/mapbox/streets-v11",
              mapStyleUrlNight: "mapbox://styles/mapbox/dark-v10",
            ),
            onCreated: (controller) {
              controller.initialize();
            },
          ),
          
          // SOS Button
          Positioned(
            top: 50,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "sosBtn",
              backgroundColor: Colors.red,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: const Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: _triggerSOS,
            ),
          ),
          
          // Bottom Driver Info Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Driver arriving in 3 min", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage('assets/images/placeholder_profile.png'),
                        backgroundColor: Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("John Doe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Toyota Aqua • KCD 123A", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BoltTheme.primaryGreen.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.phone, color: BoltTheme.primaryGreen),
                      ),
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
