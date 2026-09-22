import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'live_tracking_screen.dart';

class SearchingWorkerScreen extends StatefulWidget {
  final String jobId;
  const SearchingWorkerScreen({super.key, required this.jobId});

  @override
  State<SearchingWorkerScreen> createState() => _SearchingWorkerScreenState();
}

class _SearchingWorkerScreenState extends State<SearchingWorkerScreen> {
  bool _cancelled = false;

  void _cancelSearch() async {
    setState(() => _cancelled = true);
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'status': 'cancelled',
      'updated_at': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      Navigator.pop(context); // Go back to home
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Premium dark background
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
              final jobData = snapshot.data!.data() as Map<String, dynamic>;
              if (jobData['status'] == 'assigned' && !_cancelled) {
                // Worker accepted! Navigate to live tracking
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(jobId: widget.jobId),
                    ),
                  );
                });
              } else if (jobData['status'] == 'cancelled') {
                 WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) Navigator.pop(context);
                 });
              }
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Radar Animation Effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withOpacity(0.1),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).scaleXY(begin: 0.5, end: 1.5, duration: 1500.ms).fade(begin: 1, end: 0, duration: 1500.ms),
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal.withOpacity(0.2),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).scaleXY(begin: 0.5, end: 1.5, duration: 1500.ms, delay: 500.ms).fade(begin: 1, end: 0, duration: 1500.ms),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.teal,
                      ),
                      child: const Icon(Icons.radar, color: Colors.white, size: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Connecting you to a nearby worker...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ).animate().fade(duration: 800.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  'Please wait while we broadcast your request.',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                ).animate().fade(delay: 400.ms),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _cancelSearch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.redAccent,
                      ),
                      child: const Text('Cancel Request', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
