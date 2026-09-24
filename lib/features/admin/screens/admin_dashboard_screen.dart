import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminOverviewTab(),
    const AdminDisputesTab(),
    const AdminUsersTab(),
    const AdminFinancialsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey.shade600,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Disputes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Finance'),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TAB 1: OVERVIEW
// ----------------------------------------------------------------------
class AdminOverviewTab extends StatelessWidget {
  const AdminOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Users', 'users', Icons.people, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Active Jobs', 'jobs', Icons.work, Colors.orange)),
            ],
          ).animate().fade().slideY(),
          const SizedBox(height: 24),
          const Text('Live System Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.security, color: Colors.green),
              title: const Text('Platform running securely.'),
              subtitle: const Text('Just now'),
            ),
          ).animate().fade(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(collection).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return Text('${snapshot.data!.docs.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
              },
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TAB 2: ACTIVE DISPUTES
// ----------------------------------------------------------------------
class AdminDisputesTab extends StatelessWidget {
  const AdminDisputesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Dispute Resolution Center', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text('Customer claims and proof of work photos will appear here when a dispute is filed.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TAB 3: USER MANAGEMENT
// ----------------------------------------------------------------------
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('User Management Data', style: TextStyle(color: Colors.grey)));
  }
}

// ----------------------------------------------------------------------
// TAB 4: FINANCIALS
// ----------------------------------------------------------------------
class AdminFinancialsTab extends StatelessWidget {
  const AdminFinancialsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Co-op Welfare Pool & Financials', style: TextStyle(color: Colors.grey)));
  }
}
