import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state.dart';
import '../../../core/config.dart';


class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

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
  }

  Future<void> _loadWorkerProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('workers').doc(uid).get();
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
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Enter OTP to Complete Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ask the customer for the 4-digit OTP displayed on their dashboard.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: const InputDecoration(hintText: '0000', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () => _submitOTP(context, jobId, otpController.text, setDialogState),
              child: isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
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
    setDialogState(() => true); // Mock loading state

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/jobs/$jobId/complete'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          Navigator.pop(context); // Close OTP dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('🎉 Job Completed!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You earned: ₹${data["data"]["worker_earnings"].toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  Text('Cooperative fund: ₹${data["data"]["welfare_contribution"].toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              actions: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
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
    } finally {
      setDialogState(() => false);
    }
  }

  Future<void> _acceptJob(String jobId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final jobRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(jobRef);
        if (!snapshot.exists) throw Exception('Job not found');
        
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['status'] != 'open') {
          throw Exception('Job is no longer available');
        }
        
        transaction.update(jobRef, {
          'status': 'assigned',
          'assigned_worker_id': user.uid,
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job Accepted Successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEarningsDashboard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('assigned_worker_id', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        int completedJobs = 0;
        double earnings = 0.0;
        int coopPoints = 0;

        if (snapshot.hasData) {
          completedJobs = snapshot.data!.docs.length;
          // Calculate dummy earnings based on real job count (e.g., 450 per job)
          earnings = completedJobs * 450.0;
          coopPoints = completedJobs * 10;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.black87, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Earnings', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('₹${earnings.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(Icons.task_alt, 'Jobs', completedJobs.toString()),
                  _buildStatItem(Icons.star, 'Rating', completedJobs > 0 ? '4.9' : '5.0'), // Simplified rating logic based on real jobs
                  _buildStatItem(Icons.group, 'Co-op Points', coopPoints.toString()),
                ],
              )
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildAnnouncements() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.amber.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.campaign, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('High Demand Alert', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('Lots of Electrician requests in South Delhi right now. Go online to accept jobs!', style: TextStyle(fontSize: 12, color: Colors.black87)),
              ],
            ),
          )
        ],
      ),
    ).animate().fade(delay: 200.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.2),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1.5.seconds).fade(end: 0),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.shade400,
                ),
                child: const Icon(Icons.radar, color: Colors.white, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanning for customers...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
          ).animate().fade(duration: 1.seconds),
          const SizedBox(height: 8),
          const Text(
            'You are online and visible to customers\nbooking a service.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Jobs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking for new jobs...'), duration: Duration(seconds: 1)));
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person, color: Colors.white),
            onSelected: (String value) async {
              if (value == 'Logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              
              const PopupMenuItem<String>(value: 'Logout', child: Text('Logout')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Text(appState.isWorkerOnline ? 'Online' : 'Offline', style: TextStyle(color: appState.isWorkerOnline ? Colors.greenAccent : Colors.grey, fontWeight: FontWeight.bold)),
                Switch(
                  value: appState.isWorkerOnline,
                  onChanged: (val) => appState.toggleWorkerStatus(),
                  activeColor: Colors.greenAccent,
                  activeTrackColor: Colors.green.withOpacity(0.5),
                ),
              ],
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/worker_premium_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.3)), // Dark overlay
          ),
          SafeArea(
            child: _isLoadingProfile 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : RefreshIndicator(
                  onRefresh: () async {
                    setState((){});
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildEarningsDashboard(),
                        _buildAnnouncements(),
                        const SizedBox(height: 24),
                        
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.5),
                          child: !appState.isWorkerOnline
                              ? const Center(child: Text("Go online to receive job requests.", style: TextStyle(fontSize: 18, color: Colors.grey)))
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
                                    
                                    final List<Map<String, dynamic>> nearbyJobs = [];
                                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                                      for (var doc in snapshot.data!.docs) {
                                        final data = doc.data() as Map<String, dynamic>;
                                        data['id'] = doc.id;
                                        nearbyJobs.add(data);
                                      }
                                    }

                                    if (nearbyJobs.isEmpty) {
                                      return _buildEmptyState();
                                    }

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Active Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        ...nearbyJobs.map((job) {
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(job['service_category'] ?? 'Service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(12)),
                                                        child: Text(job['status']?.toUpperCase() ?? 'OPEN', style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Expanded(child: Text(job['address'] ?? 'No address provided', style: TextStyle(color: Colors.grey.shade600))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  if (job['status'] == 'open')
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: () => _acceptJob(job['id']),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                                        child: const Text('Accept Job'),
                                                      ),
                                                    ),
                                                  if (job['status'] == 'assigned')
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: () => _showOTPDialog(context, job['id'], job),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                                        child: const Text('Complete Job (Enter OTP)'),
                                                      ),
                                                    )
                                                ],
                                              ),
                                            ),
                                          ).animate().fade().slideX();
                                        }).toList()
                                      ],
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
