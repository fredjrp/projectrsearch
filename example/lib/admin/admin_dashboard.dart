import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/bolt_theme.dart';
import 'live_map_screen.dart';
import 'sos_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewPanel();
      case 1:
        return const LiveMapScreen();
      case 2:
        return const SosManagementScreen();
      case 3:
        return _buildUsersPanel();
      default:
        return const Center(child: Text("Not Implemented"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoltTheme.background,
      body: Row(
        children: [
          // Side Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: BoltTheme.primaryGreen),
            selectedLabelTextStyle: const TextStyle(color: BoltTheme.primaryGreen, fontWeight: FontWeight.bold),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Overview'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: Text('Live Map'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.warning_amber_outlined),
                selectedIcon: Icon(Icons.warning),
                label: Text('SOS Alerts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dashboard Overview", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          // Stats row
          Row(
            children: [
              Expanded(child: _buildStatCard("Total Revenue", "KES 4.2M", Icons.attach_money)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard("Active Rides", "142", Icons.local_taxi)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard("Total Users", "8,432", Icons.people)),
              const SizedBox(width: 24),
              Expanded(child: _buildStatCard("SOS Alerts", "0", Icons.warning, isAlert: false)),
            ],
          ),
          const SizedBox(height: 40),
          const Text("Ride Trends (Last 2 Months)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontSize: 12);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Week 1', style: style); break;
                          case 2: text = const Text('Week 3', style: style); break;
                          case 4: text = const Text('Week 5', style: style); break;
                          case 6: text = const Text('Week 7', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 300),
                      FlSpot(1, 400),
                      FlSpot(2, 350),
                      FlSpot(3, 500),
                      FlSpot(4, 450),
                      FlSpot(5, 600),
                      FlSpot(6, 750),
                      FlSpot(7, 800),
                    ],
                    isCurved: true,
                    color: BoltTheme.primaryGreen,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      color: BoltTheme.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAlert ? Border.all(color: Colors.red) : null,
        boxShadow: isAlert ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: isAlert ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
              Icon(icon, color: isAlert ? Colors.red : BoltTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: BoltTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("User Management", style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: BoltTheme.primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: BoltTheme.primaryGreen,
            tabs: [
              Tab(text: "Students"),
              Tab(text: "Drivers"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList('users'),
            _buildUserList('drivers'),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No users found"));

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data['name'] ?? 'N/A';
            final email = data['email'] ?? 'N/A';
            final phone = data['phone'] ?? 'N/A';
            final photo = data['profileImage'] ?? data['licensePhoto'] ?? '';
            final status = data['status'] ?? (data['profileComplete'] == true ? 'Approved' : 'Incomplete');

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                  child: photo.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("Email: $email"),
                    Text("Phone: $phone"),
                    if (data['institution'] != null) Text("School: ${data['institution']}"),
                    if (data['vehicleMake'] != null) Text("Vehicle: ${data['vehicleMake']} (${data['licensePlate']})"),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status == 'approved' || status == 'active') return Colors.green;
    if (status == 'pending' || status == 'new') return Colors.orange;
    if (status == 'incomplete') return Colors.grey;
    return Colors.red;
  }
}
