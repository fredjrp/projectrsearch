import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryType { ride, package, document, group }
enum DeliveryStatus { pending, accepted, pickedUp, delivered, completed, cancelled }

class DeliveryRequest {
  final String id;
  final String studentId;
  final String? riderId;
  final DeliveryType type;
  final DeliveryStatus status;
  final String pickupAddress;
  final String destinationAddress;
  final GeoPoint pickupLocation;
  final GeoPoint destinationLocation;
  final double baseFare;
  final double serviceFee; // Printing or extra handling fee
  final double totalFare;
  final String? itemDescription;
  final String? documentUrl;
  final int? pageCount;
  final DateTime timestamp;
  final bool paymentReleased;

  DeliveryRequest({
    required this.id,
    required this.studentId,
    this.riderId,
    required this.type,
    this.status = DeliveryStatus.pending,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.baseFare,
    this.serviceFee = 0.0,
    required this.totalFare,
    this.itemDescription,
    this.documentUrl,
    this.pageCount,
    required this.timestamp,
    this.paymentReleased = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'riderId': riderId,
      'type': type.name,
      'status': status.name,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLocation': pickupLocation,
      'destinationLocation': destinationLocation,
      'baseFare': baseFare,
      'serviceFee': serviceFee,
      'totalFare': totalFare,
      'itemDescription': itemDescription,
      'documentUrl': documentUrl,
      'pageCount': pageCount,
      'timestamp': timestamp,
      'paymentReleased': paymentReleased,
    };
  }

  factory DeliveryRequest.fromMap(String id, Map<String, dynamic> map) {
    return DeliveryRequest(
      id: id,
      studentId: map['studentId'] ?? '',
      riderId: map['riderId'],
      type: DeliveryType.values.firstWhere((e) => e.name == map['type'], orElse: () => DeliveryType.ride),
      status: DeliveryStatus.values.firstWhere((e) => e.name == map['status'], orElse: () => DeliveryStatus.pending),
      pickupAddress: map['pickupAddress'] ?? '',
      destinationAddress: map['destinationAddress'] ?? '',
      pickupLocation: map['pickupLocation'] ?? const GeoPoint(0, 0),
      destinationLocation: map['destinationLocation'] ?? const GeoPoint(0, 0),
      baseFare: (map['baseFare'] ?? 0.0).toDouble(),
      serviceFee: (map['serviceFee'] ?? 0.0).toDouble(),
      totalFare: (map['totalFare'] ?? 0.0).toDouble(),
      itemDescription: map['itemDescription'],
      documentUrl: map['documentUrl'],
      pageCount: map['pageCount'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      paymentReleased: map['paymentReleased'] ?? false,
    );
  }
}
