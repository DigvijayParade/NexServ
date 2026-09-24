import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../history/screens/job_history_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'live_tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (mounted && doc.exists) {
        setState(() => _userName = doc.data()?['name'] ?? 'Valued Customer');
      }
    } catch (_) {}
  }

  final List<Map<String, dynamic>> _services = [
    {"name": "Electrician", "icon": Icons.electrical_services, "color": Colors.orange},
    {"name": "Plumber", "icon": Icons.plumbing, "color": Colors.blue},
    {"name": "Carpenter", "icon": Icons.handyman, "color": Colors.brown},
    {"name": "Home Cleaner", "icon": Icons.cleaning_services, "color": Colors.teal},
    {"name": "Appliance Repair", "icon": Icons.kitchen, "color": Colors.purple},
    {"name": "Painter", "icon": Icons.format_paint, "color": Colors.redAccent},
  ];

  void _showBookingSheet(BuildContext context, String serviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingBottomSheet(categoryName: serviceName),
    );
  }

  // Widget that listens for any active/pending job for this customer
  Widget _buildActiveJobBanner() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('jobs')
          .where('customer_id', isEqualTo: uid)
          .where('status', whereIn: ['open', 'assigned', 'arrived', 'in_progress', 'payment_pending'])
          // .orderBy removed to prevent composite index requirement in debug phase
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final job = snapshot.data!.docs.first;
        final jobData = job.data() as Map<String, dynamic>;
        final status = jobData['status'] ?? 'open';
        final jobId = job.id;

        if (status == 'open') {
          // Pending - waiting for worker
          return _buildPendingBanner(jobData, jobId);
        } else if (['assigned', 'arrived', 'in_progress', 'payment_pending'].contains(status)) {
          // Worker accepted! Show worker profile card
          return _buildWorkerAcceptedCard(jobData, jobId);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingBanner(Map<String, dynamic> jobData, String jobId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade700, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Request Pending', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Waiting for a ${jobData['service_category'] ?? ''} to accept...',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('jobs').doc(jobId).update({'status': 'cancelled'});
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildWorkerAcceptedCard(Map<String, dynamic> jobData, String jobId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(jobData['assigned_worker_id'] ?? jobData['worker_id']).get(),
      builder: (context, workerSnap) {
        String workerName = 'Your Professional';
        String workerPhone = '';
        String? workerImage;

        if (workerSnap.hasData && workerSnap.data!.exists) {
          final wd = workerSnap.data!.data() as Map<String, dynamic>;
          workerName = wd['name'] ?? 'Your Professional';
          workerPhone = wd['phone'] ?? '';
          workerImage = wd['profile_image_base64'];
        }

        Uint8List? imageBytes;
        if (workerImage != null && workerImage.isNotEmpty) {
          try { imageBytes = base64Decode(workerImage); } catch(_) {}
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Professional On The Way!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                    child: imageBytes == null ? const Icon(Icons.person, color: Colors.white, size: 30) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const Text('⭐ 5.0  Verified Professional', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        if (workerPhone.isNotEmpty)
                          Text(workerPhone, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveTrackingScreen(jobId: jobId))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View Booking Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 300.ms);
      },
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('NexServ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/customer_premium_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                    ).animate().fade(duration: 400.ms).slideY(begin: -0.2, end: 0),
                    const SizedBox(height: 4),
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ).animate().fade(delay: 200.ms, duration: 400.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 20),

                    // Live Active Job Banner
                    _buildActiveJobBanner(),

                    // Promo Banner
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/images/promo_banner.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.bottomLeft,
                        child: const Text(
                          'Get 20% off on your first\nDeep Cleaning service!',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().fade(delay: 400.ms).scaleXY(begin: 0.9, end: 1.0, duration: 400.ms),

                    const SizedBox(height: 40),
                    const Text(
                      'Our Services',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ).animate().fade(delay: 600.ms),
                    const SizedBox(height: 20),

                    GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return GestureDetector(
                          onTap: () => _showBookingSheet(context, service['name']),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(service['icon'], size: 36, color: service['color'] ?? Colors.white),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  service['name'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fade(delay: (600 + (100 * index)).ms).slideY(begin: 0.2, end: 0);
                      },
                    ),
                    const SizedBox(height: 40),
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
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
