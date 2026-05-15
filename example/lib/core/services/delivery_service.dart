import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_model.dart';

class DeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double PRINT_PRICE_PER_PAGE = 5.0;
  static const double BASE_DELIVERY_FEE = 150.0;

  /// Calculate total price for a delivery or printing task
  double calculatePrice({
    required DeliveryType type,
    int pageCount = 0,
    double distanceKm = 0.0,
  }) {
    double total = BASE_DELIVERY_FEE;
    
    if (type == DeliveryType.document) {
      total += (pageCount * PRINT_PRICE_PER_PAGE);
    } else if (type == DeliveryType.ride) {
      total = distanceKm * 30.0; // Basic ride calculation
    }
    
    return total;
  }

  /// Create a new delivery/printing request
  Future<String> createRequest(DeliveryRequest request) async {
    final docRef = await _firestore.collection('deliveries').add(request.toMap());
    return docRef.id;
  }

  /// Update request status
  Future<void> updateStatus(String requestId, DeliveryStatus status) async {
    await _firestore.collection('deliveries').doc(requestId).update({
      'status': status.name,
    });
  }

  /// Release payment to the rider's wallet
  Future<void> releasePayment(String requestId, String riderId, double amount) async {
    await _firestore.runTransaction((transaction) async {
      final requestRef = _firestore.collection('deliveries').doc(requestId);
      final riderRef = _firestore.collection('drivers').doc(riderId);

      transaction.update(requestRef, {'paymentReleased': true, 'status': DeliveryStatus.completed.name});
      transaction.update(riderRef, {'walletBalance': FieldValue.increment(amount)});
    });
  }

  /// Stream of active deliveries for a student
  Stream<List<DeliveryRequest>> getStudentDeliveries(String studentId) {
    return _firestore
        .collection('deliveries')
        .where('studentId', isEqualTo: studentId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Stream of available deliveries for riders
  Stream<List<DeliveryRequest>> getAvailableDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: DeliveryStatus.pending.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DeliveryRequest.fromMap(doc.id, doc.data()))
            .toList());
  }
}
