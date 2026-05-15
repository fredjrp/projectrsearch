import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../core/theme/stdeli_theme.dart';
import '../core/models/ride_model.dart';
import '../core/services/payment_service.dart';
import '../core/services/ride_service.dart';
import '../core/models/delivery_model.dart';
import '../core/services/delivery_service.dart';
import 'profile_screen.dart';
import 'logistics_screen.dart';

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
  MapBoxNavigationViewController? _mapController;
  final PanelController _panelController = PanelController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(text: "254");
  bool _hasLocationPermission = false;
  bool _isMapStyleLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _seedDemoData();
  }

  Future<void> _seedDemoData() async {
    // Check if we've already seeded to avoid duplicates
    final prefs = await FirebaseFirestore.instance.collection('rides').where('studentId', isEqualTo: 'demo_student_123').get();
    if (prefs.docs.isEmpty) {
      await _rideService.seedDemoRides('demo_student_123');
    }
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

  void _updateDriverMarkers(List<DocumentSnapshot> drivers) {
    if (_mapController == null || !_isMapStyleLoaded) return;
    
    _mapController!.clearMarkers();
    
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
          _mapController!.addMarker(
            latitude: lat,
            longitude: lng,
          );
        }
      }
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
                if (snapshot.hasData && _mapController != null && _isMapStyleLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateDriverMarkers(snapshot.data!.docs);
                  });
                }
                return MapBoxNavigationView(
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
                    _mapController = controller;
                    _mapController!.initialize();
                    setState(() {
                      _isMapStyleLoaded = true;
                    });
                  },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 600;
        
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 40.0 : 20.0,
            vertical: 12.0
          ),
          child: ListView(
            controller: sc,
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
                    const Icon(Icons.search, color: StDeliTheme.primaryGreen),
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildActiveDeliveries(),
              const SizedBox(height: 24),
              _buildServicesGrid(),
              const SizedBox(height: 24),
              // Promo Banner
              _buildPromoBanner(),
              const SizedBox(height: 24),
              _buildSuggestedDestination(Icons.home, "Home", "123 Moi Avenue"),
              _buildSuggestedDestination(Icons.work, "University", "Strathmore Uni"),
              _buildSuggestedDestination(Icons.history, "Recent Location", "Westgate Mall"),
            ],
          ),
        );
      }
    );
  }

  final DeliveryService _deliveryService = DeliveryService();

  Widget _buildActiveDeliveries() {
    return StreamBuilder<List<DeliveryRequest>>(
      stream: _deliveryService.getStudentDeliveries("demo_student_123"), // Replace with actual UID
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final active = snapshot.data!.where((d) => d.status != DeliveryStatus.completed && d.status != DeliveryStatus.cancelled).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Active Logistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...active.map((delivery) => _buildDeliveryCard(delivery)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildDeliveryCard(DeliveryRequest delivery) {
    bool isDelivered = delivery.status == DeliveryStatus.delivered;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  delivery.type == DeliveryType.document ? Icons.print : Icons.inventory_2,
                  color: isDelivered ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${delivery.type.name.toUpperCase()} - ${delivery.status.name}", 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("To: ${delivery.destinationAddress}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text("KES ${delivery.totalFare}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (isDelivered) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (delivery.riderId != null) {
                      await _deliveryService.releasePayment(delivery.id, delivery.riderId!, delivery.totalFare);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment released to rider!")));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: StDeliTheme.primaryGreen),
                  child: const Text("Release Payment"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Our Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildServiceCard("Ride", Icons.local_taxi, Colors.green, () => _panelController.open()),
            _buildServiceCard("Package", Icons.inventory_2_outlined, Colors.blue, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LogisticsScreen(initialType: DeliveryType.package)));
            }),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildServiceCard("Print", Icons.print_outlined, Colors.orange, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LogisticsScreen(initialType: DeliveryType.document)));
            }),
            _buildServiceCard("Group", Icons.groups_outlined, Colors.purple, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LogisticsScreen(initialType: DeliveryType.group)));
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [StDeliTheme.primaryGreen, StDeliTheme.primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Get 20% off", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("On your first EV ride!", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Image.network(
            "https://cdn-icons-png.flaticon.com/512/3202/3202926.png",
            height: 50,
            color: Colors.white,
          ),
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
      onTap: () => _showRideOptions(),
    );
  }

  VehicleType _selectedType = VehicleType.stdeli;

  void _showRideOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Choose a ride", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "M-Pesa Phone Number",
                    hintText: "e.g. 254712345678",
                    prefixIcon: const Icon(Icons.phone_iphone, color: StDeliTheme.primaryGreen),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      _buildRideOption("STDELI", "4 min", "KES 350", VehicleType.stdeli, setModalState),
                      _buildRideOption("STDELI EV", "6 min", "KES 320", VehicleType.stdeli_ev, setModalState),
                      _buildRideOption("Boda", "2 min", "KES 150", VehicleType.boda, setModalState),
                      _buildRideOption("STDELI XL", "8 min", "KES 550", VehicleType.stdeli_xl, setModalState),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handlePaymentAndBooking(),
                    child: Text("Confirm ${_selectedType.name.split('_').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}"),
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildRideOption(String name, String eta, String price, VehicleType type, StateSetter setModalState) {
    bool selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setModalState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? StDeliTheme.primaryGreen.withOpacity(0.1) : Colors.white,
          border: Border.all(color: selected ? StDeliTheme.primaryGreen : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  type == VehicleType.boda ? Icons.motorcycle : 
                  type == VehicleType.stdeli_ev ? Icons.electric_car :
                  type == VehicleType.stdeli_xl ? Icons.airport_shuttle : Icons.local_taxi, 
                  color: StDeliTheme.primaryGreen, 
                  size: 32
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(eta, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
            Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
      ),
    );
  }

  final PaymentService _paymentService = PaymentService();
  final RideService _rideService = RideService();

  void _handlePaymentAndBooking() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid M-Pesa number")));
      return;
    }
    
    Navigator.pop(context); // Close selection sheet
    
    String phoneNumber = _phoneController.text; 
    double amount = _selectedType == VehicleType.boda ? 150.0 : 350.0;

    _showPaymentLoading();

    final result = await _paymentService.initiateStkPush(
      phoneNumber: phoneNumber,
      amount: amount,
      callbackUrl: "https://your-render-callback-url.com/mpesa/callback",
    );

    if (result["success"]) {
      // Simulate waiting for user to enter PIN
      final paid = await _paymentService.simulatePaymentVerification(result["checkoutRequestId"]);
      
      if (paid && mounted) {
        Navigator.pop(context); // Close loading dialog
        _createNewRide();
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result["message"]), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createNewRide() async {
    final ride = Ride(
      id: '',
      studentId: "demo_student_123", // Replace with actual user ID
      pickupAddress: "Current Location",
      destinationAddress: _searchController.text.isNotEmpty ? _searchController.text : "University",
      pickupLocation: const GeoPoint(-1.2921, 36.8219), // Replace with actual location
      destinationLocation: const GeoPoint(-1.3090, 36.8126), // Replace with actual destination
      fare: _selectedType == VehicleType.boda ? 150.0 : 350.0,
      status: RideStatus.searching,
      vehicleType: _selectedType,
      timestamp: DateTime.now(),
    );

    try {
      final rideId = await _rideService.createRide(ride);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride booked successfully! Searching for riders..."), backgroundColor: StDeliTheme.primaryGreen),
        );
        // TODO: Navigate to Active Ride Screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating ride: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: StDeliTheme.primaryGreen),
            const SizedBox(height: 24),
            const Text("Waiting for M-Pesa Prompt...", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Check your phone to complete payment", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
