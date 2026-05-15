import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/stdeli_theme.dart';
import 'update_profile_screen.dart';
import 'ride_history_screen.dart';
import 'support_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? "demo_student_123";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Student";
        String photo = "";
        Map<String, dynamic> userData = {};

        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
          name = userData['name'] ?? "Student";
          photo = userData['profileImage'] ?? "";
        }

        return Scaffold(
          backgroundColor: StDeliTheme.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: const Text("Profile", style: TextStyle(color: Colors.black)),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        backgroundColor: Colors.grey.shade200,
                        child: photo.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateProfileScreen(userData: userData)));
                              },
                              child: const Text("Edit Profile", style: TextStyle(color: StDeliTheme.primaryGreen, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuItem(context, Icons.payment, "Payment", () {}),
                _buildMenuItem(context, Icons.history, "Ride History", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
                }),
                _buildMenuItem(context, Icons.local_offer, "Promotions", () {}),
                _buildMenuItem(context, Icons.support, "Support", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                }),
                _buildMenuItem(context, Icons.settings, "Settings", () {}),
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                    child: const Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      child: ListTile(
        leading: Icon(icon, color: StDeliTheme.darkText),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
