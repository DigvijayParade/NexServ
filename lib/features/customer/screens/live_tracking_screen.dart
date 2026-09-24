import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:typed_data';

class LiveTrackingScreen extends StatefulWidget {
  final String jobId;
  const LiveTrackingScreen({super.key, required this.jobId});


  Widget _buildPhotoThumbnail(String label, String? url) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: (url != null && url.isNotEmpty) 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8), 
                  child: Image.memory(
                    base64Decode(url),
                    fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.grey)
                  )
                )
              : const Icon(Icons.photo_camera_outlined, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  int _currentStep = 1;

  void _showRatingAndComplete() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 24, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Job Completed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Rate your professional', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => const Icon(Icons.star_border, size: 40, color: Colors.orange)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (mounted) Navigator.popUntil(context, ModalRoute.withName('/customerHome'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _triggerSOS() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    
    // In our new schema, customer has em1, em2, em3
    final data = doc.data() as Map<String, dynamic>;
    final em1 = data['em1'];
    final em2 = data['em2'];
    final em3 = data['em3'];
    
    String emergencyPhones = [em1, em2, em3].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    
    if (emergencyPhones.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Emergency Contacts saved in profile!'), backgroundColor: Colors.red));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('THREAT ALERT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('This will send an emergency SMS with your live location and job details to your emergency contacts:\n$emergencyPhones.\n\nProceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Emergency alert sent to contacts!'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
            },
            child: const Text('SEND SOS'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Session'),
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
          final workerId = jobData['assigned_worker_id'] ?? jobData['worker_id'];
          final status = jobData['status'];

          if (status == 'completed' && _currentStep != 3) {
            _currentStep = 3;
            WidgetsBinding.instance.addPostFrameCallback((_) {
               _showRatingAndComplete();
            });
          }

          String topMessage = 'Waiting for professional...';
          IconData topIcon = Icons.map;
          Color topColor = Colors.grey;
          
          if (status == 'arrived') {
            topMessage = 'Professional has arrived at your location!';
            topIcon = Icons.location_on;
            topColor = Colors.orange;
          } else if (status == 'in_progress') {
            topMessage = 'Work is currently in progress.';
            topIcon = Icons.build;
            topColor = Colors.blue;
          } else if (status == 'payment_pending') {
            topMessage = 'Job is Done! Payment Required.';
            topIcon = Icons.payment;
            topColor = Colors.green;
          } else if (status == 'completed') {
            topMessage = 'Service Completed!';
            topIcon = Icons.check_circle;
            topColor = Colors.green.shade800;
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: workerId != null ? FirebaseFirestore.instance.collection('users').doc(workerId).snapshots() : null,
            builder: (context, workerSnapshot) {
              String workerName = "Worker";
              String workerPhone = "";
              Uint8List? imageBytes;
              
              if (workerSnapshot.hasData && workerSnapshot.data!.exists) {
                final workerData = workerSnapshot.data!.data() as Map<String, dynamic>;
                workerName = workerData['name'] ?? "Worker";
                workerPhone = workerData['phone'] ?? "";
                final img = workerData['profile_image_base64'];
                if (img != null && img.isNotEmpty) {
                  try { imageBytes = base64Decode(img); } catch(_) {}
                }
              }

              return Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Stack(
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).collection('location_pings').orderBy('timestamp', descending: true).limit(1).snapshots(),
                          builder: (context, mapSnap) {
                            if (!mapSnap.hasData || mapSnap.data!.docs.isEmpty) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(topIcon, size: 60, color: topColor),
                                      const SizedBox(height: 16),
                                      Text(topMessage, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: topColor)),
                                      const SizedBox(height: 8),
                                      const Text('Waiting for GPS connection...', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            final posData = mapSnap.data!.docs.first.data() as Map<String, dynamic>;
                            final lat = posData['lat'] as double;
                            final lng = posData['lng'] as double;
                            
                            return FlutterMap(
                              options: MapOptions(
                                initialCenter: LatLng(lat, lng),
                                initialZoom: 16.0,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.example.coop_gig_app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(lat, lng),
                                      width: 50,
                                      height: 50,
                                      child: const Icon(Icons.engineering, color: Colors.blue, size: 40),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        
                        // Status badge overlay
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                            ),
                            child: Row(
                              children: [
                                Icon(topIcon, color: topColor, size: 24),
                                const SizedBox(width: 12),
                                Expanded(child: Text(topMessage, style: TextStyle(fontWeight: FontWeight.bold, color: topColor))),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                                backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
                                child: imageBytes == null ? const Icon(Icons.person, color: Colors.teal) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(workerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text('Verified Professional', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () async {
                                      if (workerPhone.isNotEmpty) {
                                        final Uri launchUri = Uri(scheme: 'tel', path: workerPhone);
                                        await launchUrl(launchUri);
                                      }
                                    },
                                  ),
                                  // ONLY SHOW SOS IF IN PROGRESS OR PENDING PAYMENT
                                  if (status == 'in_progress' || status == 'payment_pending')
                                    IconButton(
                                      icon: const Icon(Icons.warning, color: Colors.red),
                                      onPressed: _triggerSOS,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          if (status == 'arrived') ...[
                            const Text('The professional has marked that they arrived.', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({'status': 'in_progress'});
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    child: const Text('Approve'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
                                        'status': 'cancelled',
                                        'cancelled_by': 'customer_disapproved_arrival',
                                        'cancelled_at': FieldValue.serverTimestamp()
                                      });
                                      if (workerId != null) {
                                        await FirebaseFirestore.instance.collection('users').doc(workerId).update({
                                          'strike_count': FieldValue.increment(1)
                                        });
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arrival Disapproved! Worker has been penalized and job is cancelled.'), backgroundColor: Colors.red));
                                        Navigator.popUntil(context, ModalRoute.withName('/customerHome'));
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    child: const Text('Disapprove'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          if (status == 'in_progress') ...[
                            const Center(
                              child: Text('Work in Progress...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const Spacer(),
                            const Text('Waiting for the professional to mark the job as done.', style: TextStyle(color: Colors.grey)),
                          ],

                          if (status == 'payment_pending') ...[
                            const Text('Job is Finished! Please hand over the cash to the professional.', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Customer marks payment as done
                                  await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({'payment_status': 'paid'});
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waiting for professional to approve payment...'), backgroundColor: Colors.green));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: jobData['payment_status'] == 'paid' ? Colors.grey : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(jobData['payment_status'] == 'paid' ? 'Waiting for Worker to Verify...' : 'Payment Done (Cash)'),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
          );
        },
      ),
    );
  }
}
