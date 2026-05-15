import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/stdeli_theme.dart';

class SosManagementScreen extends StatelessWidget {
  const SosManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StDeliTheme.background,
      appBar: AppBar(
        title: const Text("SOS Alert Management", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos_alerts')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final alerts = snapshot.data!.docs;
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text("No active SOS alerts.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Your fleet is safe.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index].data() as Map<String, dynamic>;
              return _buildSosAlertCard(alert, alerts[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildSosAlertCard(Map<String, dynamic> alert, String alertId) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 2)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning, color: Colors.red, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("HIGH PRIORITY ALERT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      Text("Type: ${alert['type'] ?? 'Emergency'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Text(_formatTime(alert['timestamp']), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                _buildUserAvatar(alert['userPhoto'], alert['userName']),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert['userName'] ?? 'Unknown User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Role: ${alert['userRole']?.toUpperCase() ?? 'USER'}", style: const TextStyle(color: Colors.grey)),
                      Text("Phone: ${alert['userPhone'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Logic to track on map
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text("Track"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      FirebaseFirestore.instance.collection('sos_alerts').doc(alertId).update({'status': 'resolved'});
                    },
                    child: const Text("Mark Resolved"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Call emergency services logic
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Call Emergency"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? photoUrl, String? name) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl == null || photoUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
