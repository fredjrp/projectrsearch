import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/theme/stdeli_theme.dart';
import 'profile_screen.dart';
import 'driver_navigation_screen.dart';

import '../core/models/ride_model.dart';
import '../core/services/ride_service.dart';
import '../core/models/delivery_model.dart';
import '../core/services/delivery_service.dart';

const String _MAPBOX_TOKEN = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue: 'pk.eyJ1IjoiZnJlZGp5IiwiYSI6ImNtbmphZ2tiMDBnMjQycnFyNnh0cXF0cmYifQ.eubs9uIGOVmbyfXJakLo9g'
);

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  bool _isOnline = false;
  bool _hasLocationPermission = false;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<List<Ride>>? _rideSubscription;
  StreamSubscription<List<DeliveryRequest>>? _deliverySubscription;
  final RideService _rideService = RideService();
  final DeliveryService _deliveryService = DeliveryService();
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _listenToWallet();
  }

  void _listenToWallet() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance.collection('drivers').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        setState(() {
          _walletBalance = (doc.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        });
      }
    });
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        setState(() => _hasLocationPermission = true);
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _rideSubscription?.cancel();
    _deliverySubscription?.cancel();
    _setOfflineInFirestore();
    super.dispose();
  }

  void _toggleOnlineStatus() async {
    bool hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    setState(() => _isOnline = !_isOnline);

    if (_isOnline) {
      _startLocationUpdates();
      _startListeners();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are now online! Listening for requests...")));
    } else {
      _stopLocationUpdates();
      _rideSubscription?.cancel();
      _deliverySubscription?.cancel();
    }
  }

  void _startListeners() {
    // Ride Listener
    _rideSubscription = _rideService.getAvailableRides().listen((rides) {
      if (rides.isNotEmpty && _isOnline) {
        _showRideRequestDialog(rides.first);
      }
    });

    // Delivery/Logistics Listener
    _deliverySubscription = _deliveryService.getAvailableDeliveries().listen((deliveries) {
      if (deliveries.isNotEmpty && _isOnline) {
        _showDeliveryRequestDialog(deliveries.first);
      }
    });
  }

  void _showRideRequestDialog(Ride ride) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Ride Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pickup: ${ride.pickupAddress}"),
            const SizedBox(height: 8),
            Text("Dropoff: ${ride.destinationAddress}"),
            const SizedBox(height: 8),
            Text("Est. Earnings: KES ${ride.fare}", style: const TextStyle(fontWeight: FontWeight.bold, color: StDeliTheme.primaryGreen)),
            const Divider(height: 24),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(ride.studentId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final studentData = snapshot.data!.data() as Map<String, dynamic>?;
                final studentName = studentData?['name'] ?? 'Student';
                final studentPhoto = studentData?['profileImage'] ?? '';
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: studentPhoto.isNotEmpty ? NetworkImage(studentPhoto) : null,
                      child: studentPhoto.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Decline", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              String? uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await _rideService.acceptRide(ride.id, uid);
                if (mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverNavigationScreen()));
                }
              }
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  void _showDeliveryRequestDialog(DeliveryRequest delivery) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("New ${delivery.type.name.toUpperCase()} Request!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pickup: ${delivery.pickupAddress}"),
            const SizedBox(height: 8),
            Text("Dropoff: ${delivery.destinationAddress}"),
            const SizedBox(height: 16),
            if (delivery.type == DeliveryType.document) ...[
              const Text("Service: Document Printing", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Pages: ${delivery.pageCount}"),
            ] else if (delivery.type == DeliveryType.package) ...[
              const Text("Service: Package Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Item: ${delivery.itemDescription ?? 'Package'}"),
            ],
            const SizedBox(height: 16),
            Text("Earnings: KES ${delivery.totalFare}", style: const TextStyle(fontWeight: FontWeight.bold, color: StDeliTheme.primaryGreen)),
            const Divider(height: 24),
            _buildStudentInfo(delivery.studentId),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Decline", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              String? uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await _deliveryService.updateStatus(delivery.id, DeliveryStatus.accepted);
                if (mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Accepted!")));
                }
              }
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(String studentId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final studentData = snapshot.data!.data() as Map<String, dynamic>?;
        final studentName = studentData?['name'] ?? 'Student';
        final studentPhoto = studentData?['profileImage'] ?? '';
        
        return Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: studentPhoto.isNotEmpty ? NetworkImage(studentPhoto) : null,
              child: studentPhoto.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services are disabled.')));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied.')));
      return false;
    }
    return true;
  }

  void _startLocationUpdates() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    FirebaseFirestore.instance.collection('drivers').doc(uid).update({'isOnline': true});

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    });
  }

  void _stopLocationUpdates() {
    _positionStream?.cancel();
    _setOfflineInFirestore();
  }

  void _setOfflineInFirestore() {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      FirebaseFirestore.instance.collection('drivers').doc(uid).update({'isOnline': false});
    }
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
              zoom: 15.0,
              language: "en",
              accessToken: _MAPBOX_TOKEN,
              mapStyleUrlDay: "mapbox://styles/mapbox/streets-v11",
              mapStyleUrlNight: "mapbox://styles/mapbox/dark-v10",
            ),
            onCreated: (controller) {
              controller.initialize();
            },
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
                  child: Text("KES ${_walletBalance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 48), // Spacer to balance the layout
              ],
            ),
          ),
          
          // Online Toggle
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: GestureDetector(
                onTap: _toggleOnlineStatus,
                child: Container(
                  height: 64,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.red : StDeliTheme.primaryGreen,
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
