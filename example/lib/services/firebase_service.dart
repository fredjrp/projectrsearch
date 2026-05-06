import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class Hub {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String category;
  double? distance; // in km

  Hub({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.distance,
  });

  factory Hub.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Hub(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      category: data['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
    };
  }

  WayPoint toWayPoint() {
    return WayPoint(
      name: name,
      latitude: latitude,
      longitude: longitude,
      isSilent: false,
    );
  }
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> autoPopulateHubs() async {
    final snapshot = await _db.collection('hubs').get();
    if (snapshot.docs.isEmpty) {
      final sampleHubs = [
        Hub(
          id: '',
          name: "Havit Hub - Rongai",
          description: "Premium Power Bank Hub - 27000mAh Ultra Fast Charging",
          imageUrl: "https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?w=300",
          latitude: -1.396,
          longitude: 36.762,
          category: "Tech",
        ),
        Hub(
          id: '',
          name: "Kuhl Hub - Nairobi West",
          description: "High Capacity Portable Charging Solutions",
          imageUrl: "https://images.unsplash.com/photo-1620189507195-68309c04c4d0?w=300",
          latitude: -1.315,
          longitude: 36.815,
          category: "Tech",
        ),
        Hub(
          id: '',
          name: "Vention Hub - Kilimani",
          description: "100W Laptop Power Bank Distribution Point",
          imageUrl: "https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=300",
          latitude: -1.292,
          longitude: 36.785,
          category: "Tech",
        ),
      ];

      for (var hub in sampleHubs) {
        await _db.collection('hubs').add(hub.toFirestore());
      }
    }
  }

  Stream<List<Hub>> streamHubs(Position? userPosition) {
    return _db.collection('hubs').snapshots().map((snapshot) {
      final hubs = snapshot.docs.map((doc) => Hub.fromFirestore(doc)).toList();
      
      if (userPosition != null) {
        for (var hub in hubs) {
          hub.distance = Geolocator.distanceBetween(
            userPosition.latitude,
            userPosition.longitude,
            hub.latitude,
            hub.longitude,
          ) / 1000; // Convert to km
        }
        hubs.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
      }
      
      return hubs;
    });
  }
}
