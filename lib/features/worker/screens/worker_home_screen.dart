import '../../profile/screens/profile_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state.dart';
import '../../../core/config.dart';
import '../../../core/utils.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  String _workerProfession = '';
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerProfile();
    _loadWorkerProfile();
  }

    Future<void> _loadWorkerProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profession = doc.data()?['service_category'] ?? '';
      if (mounted) {
        setState(() {
          _workerProfession = profession;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _showOTPDialog(BuildContext context, String jobId, Map<String, dynamic> jobData) {
    final otpController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enter OTP to Complete Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ask the customer for the 4-digit OTP displayed on their dashboard.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(
                  hintText: '0000',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _submitOTP(context, jobId, otpController.text, setState),
              child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOTP(BuildContext context, String jobId, String otp, Function setDialogState) async {
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 4-digit OTP')));
      return;
    }

     // Need to define _isLoading locally inside StatefulBuilder or just ignore loading state for hackathon speed

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/jobs/$jobId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pop(context); // Close OTP dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('? Job Completed!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You earned: ₹${data["data"]["worker_earnings"].toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text(
                    'Cooperative fund: ₹${data["data"]["welfare_contribution"].toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${data["message"]}'), backgroundColor: Colors.red));
        
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      
    }
  }
  Future<void> _acceptJob(String jobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();
      
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/jobs/$jobId/accept'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );
      
      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job Accepted Successfully!')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to accept job')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Worker Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.person, color: Colors.black),
              onSelected: (String value) async {
                if (value == 'Profile') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                } else if (value == 'Logout') {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Profile',
                  child: Text('My Profile'),
                ),
                const PopupMenuItem<String>(
                  value: 'Logout',
                  child: Text('Logout'),
                ),
              ],
            ),
            Row(
            children: [
              Text(appState.isWorkerOnline ? 'Online' : 'Offline', style: TextStyle(color: appState.isWorkerOnline ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
              Switch(
                value: appState.isWorkerOnline,
                onChanged: (val) => appState.toggleWorkerStatus(),
                activeColor: Colors.green,
              ),
            ],
          )
        ],
      ),
      body: _isLoadingProfile 
        ? const Center(child: CircularProgressIndicator())
        : !appState.isWorkerOnline
            ? const Center(child: Text("Go online to see nearby jobs", style: TextStyle(fontSize: 18, color: Colors.grey)))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .where('status', whereIn: ['open', 'assigned'])
                    .where('service_category', isEqualTo: _workerProfession)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No ${_workerProfession.isEmpty ? "matching" : _workerProfession} jobs available right now', style: TextStyle(fontSize: 18, color: Colors.grey)));
                  }

                  // Simple list - already filtered by profession in stream query
                    final List<Map<String, dynamic>> nearbyJobs = [];
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      data['id'] = doc.id;
                      nearbyJobs.add(data);
                    }

                    if (nearbyJobs.isEmpty) {
                    return Center(child: Text(
                        'No ${_workerProfession.isEmpty ? "matching" : _workerProfession} jobs available right now',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: nearbyJobs.length,
                    itemBuilder: (context, index) {
                      final job = nearbyJobs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(job['service_type'] ?? 'Gig', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text('₹${job["service_rate"]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(job['service_category'] ?? '', style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () => _acceptJob(job['id']),
                                  child: const Text('Accept Job'),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
