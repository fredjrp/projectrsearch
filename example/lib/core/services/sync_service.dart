import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Key for storing pending uploads in SharedPreferences
  static const String _pendingUploadsKey = 'pending_uploads';

  /// Add an image to the sync queue
  Future<void> addToQueue({
    required String uid,
    required String localPath,
    required String storagePath,
    required String collection, // 'users' or 'drivers'
    required String field, // 'profileImage' or 'licensePhoto'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_pendingUploadsKey) ?? [];
    
    // Format: uid|localPath|storagePath|collection|field
    final entry = "$uid|$localPath|$storagePath|$collection|$field";
    queue.add(entry);
    
    await prefs.setStringList(_pendingUploadsKey, queue);
    debugPrint("Added to sync queue: $entry");
  }

  /// Attempt to upload all pending images
  Future<void> syncNow() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_pendingUploadsKey) ?? [];
    if (queue.isEmpty) return;

    debugPrint("Starting background sync for ${queue.length} items...");
    List<String> remaining = [];

    for (var entry in queue) {
      final parts = entry.split('|');
      if (parts.length != 5) continue;

      final uid = parts[0];
      final localPath = parts[1];
      final storagePath = parts[2];
      final collection = parts[3];
      final field = parts[4];

      try {
        final file = File(localPath);
        if (!await file.exists()) {
          debugPrint("File no longer exists: $localPath");
          continue;
        }

        // Upload to Storage
        Reference ref = _storage.ref().child(storagePath);
        await ref.putFile(file);
        String downloadUrl = await ref.getDownloadURL();

        // Update Firestore
        await _firestore.collection(collection).doc(uid).update({
          field: downloadUrl,
        });

        debugPrint("Successfully synced $uid to $downloadUrl");
      } catch (e) {
        debugPrint("Sync failed for $uid: $e");
        remaining.add(entry);
      }
    }

    await prefs.setStringList(_pendingUploadsKey, remaining);
  }
}
