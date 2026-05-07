import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Track the verification ID for OTP
  static String _verificationId = '';

  // Send OTP
  Future<void> sendOtp({
    required String phoneNumber,
    required Function() onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  // Verify OTP
  Future<UserCredential> verifyOtp({
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("OTP Verification Error: $e");
      rethrow;
    }
  }

  // Sign up with Email and Password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String role, // 'student' or 'driver'
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document
      if (userCredential.user != null) {
        String collection = role == 'driver' ? 'drivers' : 'users';
        await _firestore.collection(collection).doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'name': name,
          'email': email,
          'phone': '',
          'role': role,
          'status': role == 'driver' ? 'new' : 'approved',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return userCredential;
    } catch (e) {
      debugPrint("Email Sign Up Error: $e");
      rethrow;
    }
  }

  // Check Driver Status
  Future<String> checkDriverStatus(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('drivers').doc(uid).get();
      if (doc.exists) {
        return doc.get('status') ?? 'new';
      }
      return 'new'; // If doc doesn't exist, they are new
    } catch (e) {
      debugPrint("Check Driver Status Error: $e");
      return 'new';
    }
  }

  // Update Driver Registration Details
  Future<void> submitDriverRegistration({
    required String uid,
    required String vehicleMake,
    required String licensePlate,
    required String phone,
    required String licensePhotoPath, // Placeholder path for now
  }) async {
    await _firestore.collection('drivers').doc(uid).set({
      'uid': uid,
      'vehicleMake': vehicleMake,
      'licensePlate': licensePlate,
      'phone': phone,
      'licensePhoto': licensePhotoPath,
      'status': 'pending', // Now waiting for admin
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
