import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as gl;
import '../core/theme/bolt_theme.dart';
import 'profile_screen.dart';
import 'driver_navigation_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isOnline = false;

  void _simulateIncomingRide() {
    if (!_isOnline) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Ride Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Pickup: Strathmore University"),
            SizedBox(height: 8),
            Text("Dropoff: Westlands"),
            SizedBox(height: 8),
            Text("Est. Earnings: KES 450", style: TextStyle(fontWeight: FontWeight.bold, color: BoltTheme.primaryGreen)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Decline", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverNavigationScreen()));
            },
            child: const Text("Accept"),
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
          gl.MapboxMap(
            accessToken: const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: 'YOUR_MAPBOX_TOKEN'),
            initialCameraPosition: const gl.CameraPosition(
              target: gl.LatLng(-1.2921, 36.8219),
              zoom: 15.0,
            ),
            myLocationEnabled: true,
            myLocationTrackingMode: gl.MyLocationTrackingMode.Tracking,
          ),
          
          // Top Bar
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  heroTag: "driverMenuBtn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
                  },
                  child: const Icon(Icons.menu, color: Colors.black87),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: const Text("KES 1,250.00", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                FloatingActionButton(
                  heroTag: "testRideBtn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _simulateIncomingRide,
                  child: const Icon(Icons.notifications_active, color: BoltTheme.primaryGreen),
                ),
              ],
            ),
          ),
          
          // Online Toggle
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: GestureDetector(
                onTap: () {
                  setState(() => _isOnline = !_isOnline);
                  if (_isOnline) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are now online! Listening for rides...")));
                  }
                },
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.red : BoltTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text(
                      _isOnline ? "GO OFFLINE" : "GO ONLINE",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
