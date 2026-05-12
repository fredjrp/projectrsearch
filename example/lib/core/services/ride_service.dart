import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createRide(Ride ride) async {
    final docRef = await _firestore.collection('rides').add(ride.toMap());
    return docRef.id;
  }

  Future<void> updateRideStatus(String rideId, RideStatus status) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': status.name,
    });
  }

  Stream<List<Ride>> getAvailableRides() {
    return _firestore
        .collection('rides')
        .where('status', isEqualTo: RideStatus.searching.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Ride.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> acceptRide(String rideId, String riderId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'status': RideStatus.accepted.name,
      'riderId': riderId,
    });
  }

  Future<void> updateRiderWallet(String riderId, double amount) async {
    await _firestore.collection('drivers').doc(riderId).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  Future<void> seedDemoRides(String studentId) async {
    final List<Ride> demoRides = [
      Ride(
        id: '',
        studentId: studentId,
        pickupAddress: "Strathmore University",
        destinationAddress: "Westlands",
        pickupLocation: const GeoPoint(-1.3090, 36.8126),
        destinationLocation: const GeoPoint(-1.2635, 36.8028),
        fare: 450.0,
        status: RideStatus.completed,
        vehicleType: VehicleType.bolt,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Ride(
        id: '',
        studentId: studentId,
        pickupAddress: "USIU Africa",
        destinationAddress: "TRM",
        pickupLocation: const GeoPoint(-1.2188, 36.8885),
        destinationLocation: const GeoPoint(-1.2217, 36.8837),
        fare: 150.0,
        status: RideStatus.completed,
        vehicleType: VehicleType.boda,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      // Add 3 more rides...
    ];

    for (var ride in demoRides) {
      await createRide(ride);
    }
  }
}
