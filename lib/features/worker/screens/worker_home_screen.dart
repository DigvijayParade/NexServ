import 'dart:convert';
import 'package:flutter/material.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../history/screens/job_history_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../../core/state/app_state.dart';
import '../../../core/config.dart';


class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _selectedIndex = 0;
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
        Navigator.pushNamed(context, '/activeJob', arguments: jobId);
      }
      
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


  Widget _buildActiveJobBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('assigned_worker_id', isEqualTo: uid)
          .where('status', whereIn: ['assigned', 'arrived', 'in_progress', 'payment_pending'])
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final job = snapshot.data!.docs.first;
        final jobId = job.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.green.shade800, Colors.green.shade500]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: const Icon(Icons.handshake, color: Colors.white, size: 36),
            title: const Text('Active Session in Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Tap to view job details & status', style: TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/activeJob', arguments: jobId),
          ),
        ).animate().fade().slideY(begin: -0.2, end: 0);
      },
    );
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

  Widget _buildRichOfflineState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bedtime_outlined, size: 80, color: Colors.blueAccent),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),
            const SizedBox(height: 32),
            const Text(
              "You are Currently Offline",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              "Flip the switch at the top to go online and start receiving job requests instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("High Demand Area!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text("Customers are looking for professionals near you right now.", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  // Old code to ignore:
  Widget _oldBuildRichOfflineState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.nightlight_round, size: 80, color: Colors.indigo),
        const SizedBox(height: 16),
        const Text("You're Offline", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
        const SizedBox(height: 8),
        const Text(
          "Take a break! When you're ready to earn, just flip the switch above to go online.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.blue, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Demand is HIGH in your area!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text('Electricians are earning 20% more right now. Go online to catch the wave.', style: TextStyle(fontSize: 12, color: Colors.blue.shade900)),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    ).animate().fade().scaleXY(begin: 0.9, end: 1.0);
  }

  Widget _buildDummyJobCard(String service, String name, String address, double fare) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text('NEW', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(name),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(address),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Est. Earning', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text('₹$fare', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This is a dummy job for demonstration.')));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: const Text('Accept Job'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() { return const SizedBox(); } 
  Widget _oldBuildEmptyState() {
    final isOnline = context.watch<AppState>().isWorkerOnline;
    
    if (isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              const Text('No real jobs match your category.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('But look at these dummy jobs!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ).animate().fade();
    } else {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.power_settings_new_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('You are offline', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Go online to start receiving service requests in your area and earn money.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.online_prediction),
                label: const Text('GO ONLINE NOW'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  context.read<AppState>().toggleWorkerStatus();
                },
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pro Tip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          const SizedBox(height: 4),
                          Text('Workers who are online during 9 AM - 12 PM get 40% more jobs!', style: TextStyle(fontSize: 12, color: Colors.orange.shade900)),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ).animate().fade().slideY(begin: 0.05, end: 0);
    }
  }

  Widget _buildHomeTab(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/auth');
            },
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
                        _buildActiveJobBanner(),
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
                              ? _buildRichOfflineState()
                              : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('jobs')
                                      .where('status', isEqualTo: 'open')
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


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(context),
      JobHistoryScreen(),
      EditProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
