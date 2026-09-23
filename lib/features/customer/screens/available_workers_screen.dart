import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'searching_worker_screen.dart';

class AvailableWorkersScreen extends StatefulWidget {
  final String categoryName;
  final String? subService;
  final String serviceMode;
  final String address;
  final String issueDescription;

  const AvailableWorkersScreen({
    super.key,
    required this.categoryName,
    this.subService,
    required this.serviceMode,
    required this.address,
    required this.issueDescription,
  });

  @override
  State<AvailableWorkersScreen> createState() => _AvailableWorkersScreenState();
}

class _AvailableWorkersScreenState extends State<AvailableWorkersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _workers = [];
  
  final List<String> _dummyNames = ['Ramesh Kumar', 'Suresh Patel', 'Vikram Singh', 'Abdul Khan', 'Manoj Sharma'];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      // Fetch the real worker for the demo (who matches the service)
      final QuerySnapshot workerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('service_category', isEqualTo: widget.categoryName)
          .get();

      List<Map<String, dynamic>> realWorkers = [];
      for (var doc in workerSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        realWorkers.add({
          'id': doc.id,
          'name': data['name'] ?? 'Professional Worker',
          'rating': 5.0,
          'jobs_completed': 124,
          'is_real': true,
        });
      }

      // Generate some dummy workers
      List<Map<String, dynamic>> dummyWorkers = [];
      final rand = Random();
      _dummyNames.shuffle();
      
      for (int i = 0; i < 3; i++) {
        dummyWorkers.add({
          'id': 'dummy_$i',
          'name': _dummyNames[i],
          'rating': (3.5 + rand.nextDouble() * 1.3).toStringAsFixed(1), // Random between 3.5 and 4.8
          'jobs_completed': rand.nextInt(50) + 10,
          'is_real': false,
        });
      }

      // Combine and put real workers at the top
      _workers = [...realWorkers, ...dummyWorkers];
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmBooking(Map<String, dynamic> worker) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: worker['is_real'] ? Colors.amber.shade100 : Colors.grey.shade200,
              child: Icon(Icons.person, size: 40, color: worker['is_real'] ? Colors.orange : Colors.grey),
            ),
            const SizedBox(height: 16),
            Text('Send request to ${worker['name']}?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Rating: ⭐ ${worker['rating']} | ${worker['jobs_completed']} jobs done'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _createJobAndNavigate(worker);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _createJobAndNavigate(Map<String, dynamic> worker) async {
    // Show a quick loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final String otp = (1000 + Random().nextInt(9000)).toString();

      // Fetch customer phone
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final customerPhone = userDoc.data()?['phone'] ?? '';

      final docRef = await FirebaseFirestore.instance.collection('jobs').add({
        'customer_id': user.uid,
        'customer_phone': customerPhone,
        'service_category': widget.categoryName,
        'sub_service': widget.subService,
        'service_mode': widget.serviceMode,
        'address': widget.address,
        'issue_description': widget.issueDescription,
        'status': 'open',
        'otp': otp,
        'created_at': FieldValue.serverTimestamp(),
        // Optional: you can store targeted_worker_id if you want strict routing, 
        // but for the demo leaving it open allows the real worker to see it instantly.
      });

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.popUntil(context, ModalRoute.withName('/customerHome'));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('${widget.categoryName} Professionals', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _workers.isEmpty
              ? const Center(child: Text('No professionals available right now.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _workers.length,
                  itemBuilder: (context, index) {
                    final worker = _workers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: worker['is_real'] ? 4 : 1,
                      shadowColor: worker['is_real'] ? Colors.orange.withOpacity(0.4) : Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: worker['is_real'] ? const BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () => _confirmBooking(worker),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: worker['is_real'] ? Colors.amber.shade100 : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person, size: 36, color: worker['is_real'] ? Colors.orange : Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(worker['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        if (worker['is_real']) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                                            child: const Text('TOP RATED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                          )
                                        ]
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text('${worker['rating']} (${worker['jobs_completed']} jobs)'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('₹399 Base visit charge', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
                  },
                ),
    );
  }
}
