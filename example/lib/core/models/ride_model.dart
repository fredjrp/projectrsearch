import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus {
  pending_payment,
  searching,
  accepted,
  on_trip,
  completed,
  cancelled
}

enum VehicleType {
  bolt,
  bolt_ev,
  boda,
  bolt_xl
}

class Ride {
  final String id;
  final String studentId;
  final String? riderId;
  final String pickupAddress;
  final String destinationAddress;
  final GeoPoint pickupLocation;
  final GeoPoint destinationLocation;
  final double fare;
  final RideStatus status;
  final VehicleType vehicleType;
  final DateTime timestamp;

  Ride({
    required this.id,
    required this.studentId,
    this.riderId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.fare,
    required this.status,
    required this.vehicleType,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'riderId': riderId,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'fare': fare,
      'status': status.name,
      'vehicleType': vehicleType.name,
      'timestamp': timestamp,
    };
  }

  factory Ride.fromMap(String id, Map<String, dynamic> map) {
    return Ride(
      id: id,
      studentId: map['studentId'] ?? '',
      riderId: map['riderId'],
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      pickupLocation: map['pickupLocation'] as GeoPoint,
      destinationLocation: map['destinationLocation'] as GeoPoint,
      fare: (map['fare'] as num?)?.toDouble() ?? 0.0,
      status: RideStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => RideStatus.pending_payment),
      vehicleType: VehicleType.values.firstWhere((e) => e.name == map['vehicleType'], orElse: () => VehicleType.bolt),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
