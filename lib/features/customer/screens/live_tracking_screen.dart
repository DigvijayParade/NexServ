import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/rating_dialog.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String jobId;
  const LiveTrackingScreen({super.key, required this.jobId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  int _currentStep = 2; // Simulating 'Worker on the way' state

  final List<String> _steps = [
    'Request Confirmed',
    'Worker Assigned',
    'Worker on the way',
    'Service Completed'
  ];

  void _showRatingAndComplete() {
    setState(() => _currentStep = 3);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RatingDialog(),
    ).then((_) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/customerHome');
    });
  }

  void _cancelRequest() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
                'status': 'cancelled'
              });
              if (mounted) Navigator.pop(context); // Go back home
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).snapshots(),
        builder: (context, jobSnapshot) {
          if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobData = jobSnapshot.data!.data() as Map<String, dynamic>;
          final workerId = jobData['assigned_worker_id'];
          final status = jobData['status'];

          if (status == 'completed' && _currentStep != 3) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _showRatingAndComplete();
            });
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: workerId != null ? FirebaseFirestore.instance.collection('users').doc(workerId).snapshots() : null,
            builder: (context, workerSnapshot) {
              String workerName = "Worker";
              String workerPhone = "";
              if (workerSnapshot.hasData && workerSnapshot.data!.exists) {
                final workerData = workerSnapshot.data!.data() as Map<String, dynamic>;
                workerName = workerData['name'] ?? "Worker";
                workerPhone = workerData['phone'] ?? "";
              }

              return Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Live Map Integration Pending'),
                            Text('Tracking $workerName to your location...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.teal.shade100,
                                child: const Icon(Icons.person, color: Colors.teal),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(workerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('4.9 -? (120+ jobs)', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chat, color: Colors.blue),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text('OTP for Service Completion:', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('1 2 3 4', style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _cancelRequest,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Cancel Request'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text('Pay Now'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          );
        }
      ),
    );
  }
}
