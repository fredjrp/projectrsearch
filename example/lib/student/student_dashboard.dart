import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:mapbox_gl/mapbox_gl.dart' as gl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/bolt_theme.dart';
import 'profile_screen.dart';

const String _MAPBOX_TOKEN = String.fromEnvironment(
  'MAPBOX_ACCESS_TOKEN',
  defaultValue: 'pk.eyJ1IjoiZnJlZGp5IiwiYSI6ImNtbmphZ2tiMDBnMjQycnFyNnh0cXF0cmYifQ.eubs9uIGOVmbyfXJakLo9g'
);

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final PanelController _panelController = PanelController();
  gl.MapboxMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _hasLocationPermission = false;
  bool _isMapStyleLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    // Small delay to ensure Mapbox engine is fully warmed up
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _hasLocationPermission = true;
      });
    }
  }

  void _onMapCreated(gl.MapboxMapController controller) {
    _mapController = controller;
  }

  void _updateDriverMarkers(List<DocumentSnapshot> drivers) {
    if (_mapController == null || !_isMapStyleLoaded) return;
    try {
      _mapController!.clearSymbols();
      
      for (var doc in drivers) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('location')) {
          final location = data['location'];
          
          // Safe extraction of coordinates
          double? lat, lng;
          if (location is GeoPoint) {
            lat = location.latitude;
            lng = location.longitude;
          } else if (location is Map) {
            lat = (location['latitude'] as num?)?.toDouble();
            lng = (location['longitude'] as num?)?.toDouble();
          }

          if (lat != null && lng != null) {
            _mapController!.addSymbol(gl.SymbolOptions(
              geometry: gl.LatLng(lat, lng),
              iconImage: "marker-15", // Using a more generic marker
              iconSize: 1.5,
              textField: data['name'] ?? 'Driver',
              textOffset: const Offset(0, 2),
            )).catchError((e) => debugPrint("Error adding symbol: $e"));
          }
        }
      }
    } catch (e) {
      debugPrint("Marker update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 250.0,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: const [BoxShadow(blurRadius: 10.0, color: Colors.black12)],
        panelBuilder: (ScrollController sc) => _buildPanel(sc),
        body: Stack(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateDriverMarkers(snapshot.data!.docs);
                  });
                }
                return gl.MapboxMap(
                  accessToken: _MAPBOX_TOKEN,
                  initialCameraPosition: const gl.CameraPosition(
                    target: gl.LatLng(-1.2921, 36.8219), // Nairobi CBD default
                    zoom: 14.0,
                  ),
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: () {
                    if (mounted) {
                      setState(() {
                        _isMapStyleLoaded = true;
                      });
                    }
                  },
                  myLocationEnabled: _hasLocationPermission,
                  myLocationTrackingMode: _hasLocationPermission 
                      ? gl.MyLocationTrackingMode.Tracking 
                      : gl.MyLocationTrackingMode.None,
                );
              },
            ),
            // Menu Button
            Positioned(
              top: 50,
              left: 16,
              child: FloatingActionButton(
                heroTag: "studentMenuBtn",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentProfileScreen()));
                },
                child: const Icon(Icons.menu, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(ScrollController sc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Where to?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.search, color: BoltTheme.primaryGreen),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search destination",
                      border: InputBorder.none,
                      filled: false,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Suggested Destinations Mock
          _buildSuggestedDestination(Icons.home, "Home", "123 Moi Avenue"),
          _buildSuggestedDestination(Icons.work, "University", "Strathmore Uni"),
          _buildSuggestedDestination(Icons.history, "Recent Location", "Westgate Mall"),
        ],
      ),
    );
  }

  Widget _buildSuggestedDestination(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(icon, color: Colors.black54),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        // Request Ride logic placeholder
        _showRideOptions();
      },
    );
  }

  void _showRideOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Choose a ride", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildRideOption("Bolt", "4 min", "KES 350", true),
            _buildRideOption("Boda", "2 min", "KES 150", false),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close sheet
                  // TODO: Navigate to Active Ride Screen
                },
                child: const Text("Confirm Bolt"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRideOption(String name, String eta, String price, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? BoltTheme.primaryGreen.withOpacity(0.1) : Colors.white,
        border: Border.all(color: selected ? BoltTheme.primaryGreen : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(name == "Boda" ? Icons.motorcycle : Icons.local_taxi, color: BoltTheme.primaryGreen, size: 30),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(eta, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
