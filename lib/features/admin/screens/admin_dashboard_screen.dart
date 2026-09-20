import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../core/config.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, dynamic>> _fetchStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");
    final token = await user.getIdToken();
    
    final response = await http.get(
      Uri.parse('${Config.apiBaseUrl}/admin/dashboard/stats'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load stats: ${response.statusCode} ${response.body}");
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _fetchStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView( // ListView allows RefreshIndicator to work
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red))),
                ],
              );
            }

            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatCard("Total Jobs", data['total_jobs'].toString(), Icons.work, Colors.blue),
                _buildStatCard("Completed Jobs", data['completed_jobs'].toString(), Icons.check_circle, Colors.green),
                _buildStatCard("Total Revenue", "?${data['total_revenue']}", Icons.currency_rupee, Colors.orange),
                _buildStatCard("Active Workers", data['active_workers'].toString(), Icons.people, Colors.purple),
                _buildStatCard("Welfare Fund", "?${data['welfare_fund_balance']}", Icons.account_balance, Colors.teal),
                const SizedBox(height: 24),
                const Text("Platform Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Charts and detailed metrics can be added here in the future."),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        trailing: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
