import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ActiveJobScreen extends StatefulWidget {
  final String? jobId;
  const ActiveJobScreen({super.key, this.jobId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  Timer? _locationTimer;

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() async {
    if (_locationTimer != null && _locationTimer!.isActive) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (widget.jobId != null) {
            await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).collection('location_pings').add({
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          // ignore
        }
      });
    }
  }


  bool _isUploading = false;

  Future<void> _captureAndUploadPhoto(String photoType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 15); // Heavily compressed for Firestore
    if (pickedFile == null || widget.jobId == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).set({
        'proof_of_work': {
          '${photoType}_url': base64String,
          '${photoType}_time': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildMilestoneRow(String title, String type, Map<String, dynamic> jobData) {
    final proof = jobData['proof_of_work'] as Map<String, dynamic>?;
    final isUploaded = proof != null && proof['${type}_url'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isUploaded ? Icons.check_circle : Icons.camera_alt, color: isUploaded ? Colors.green : Colors.grey),
        title: Text(title, style: TextStyle(decoration: isUploaded ? TextDecoration.lineThrough : null, fontWeight: isUploaded ? FontWeight.normal : FontWeight.bold)),
        trailing: isUploaded 
            ? const Text('Uploaded', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            : ElevatedButton(
                onPressed: _isUploading ? null : () => _captureAndUploadPhoto(type),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                child: const Text('Capture'),
              ),
      ),
    );
  }

  Future<void> _updateJobStatus(String newStatus) async {
    if (widget.jobId == null) return;
    final data = {
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    };
    if (newStatus == 'arrived') data['arrived_at'] = FieldValue.serverTimestamp();
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update(data);
  }

  Future<void> _completePaymentAndJob() async {
    if (widget.jobId == null) return;
    await FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).update({
      'status': 'completed',
      'completed_at': FieldValue.serverTimestamp(),
    });
    if (mounted) {
      Navigator.popUntil(context, ModalRoute.withName('/workerHome'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jobId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Session')),
        body: const Center(child: Text('No Job ID Provided')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Session'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('jobs').doc(widget.jobId).snapshots(),
        builder: (context, jobSnapshot) {
          if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobData = jobSnapshot.data!.data() as Map<String, dynamic>;
          final customerId = jobData['customer_id'];
          final status = jobData['status'];
          final paymentStatus = jobData['payment_status'] ?? 'pending';

          if (status == 'in_progress') {
            _startLocationTracking();
          } else {
            _locationTimer?.cancel();
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(customerId).get().asStream(),
            builder: (context, customerSnapshot) {
              String customerName = "Customer";
              String customerPhone = "";
              if (customerSnapshot.hasData && customerSnapshot.data!.exists) {
                final customerData = customerSnapshot.data!.data() as Map<String, dynamic>;
                customerName = customerData['name'] ?? "Customer";
                customerPhone = customerData['phone'] ?? "";
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CUSTOMER DETAILS CARD
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Customer Details', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.teal.shade700,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      Text(customerPhone, style: TextStyle(color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.call, color: Colors.green),
                                  onPressed: () async {
                                    if (customerPhone.isNotEmpty) {
                                      final Uri launchUri = Uri(scheme: 'tel', path: customerPhone);
                                      await launchUrl(launchUri);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // JOB DETAILS CARD
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Description', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(jobData['issue_description'] ?? 'No description provided.', style: const TextStyle(fontSize: 16)),
                            const Divider(),
                            Text('Address: ${jobData['address'] ?? 'Customer Address'}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text('Category: ${jobData['service_category']}', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text('Job Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // BUTTON LOCK LOGIC
                    if (status == 'assigned') ...[
                      const Text('Travel to the customer\'s location and press Arrived.', style: TextStyle(color: Colors.grey)),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _updateJobStatus('arrived'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Arrived at destination', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ] 
                    else if (status == 'arrived') ...[
                      const Center(child: Text('Waiting for Customer to approve your arrival...', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold))),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null, // LOCKED
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Job is Done (Locked)'),
                        ),
                      ),
                    ]
                    else if (status == 'in_progress') ...[
                      const Center(child: Text('Work in progress.', style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold))),
                      const SizedBox(height: 16),
                      const Text('Proof of Work Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _buildMilestoneRow('1. Before starting work', 'before_photo', jobData),
                      _buildMilestoneRow('2. Mid-way progress', 'progress_photo', jobData),
                      _buildMilestoneRow('3. Final finished work', 'after_photo', jobData),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            final proof = jobData['proof_of_work'] as Map<String, dynamic>?;
                            final hasBefore = proof != null && proof['before_photo_url'] != null;
                            final hasAfter = proof != null && proof['after_photo_url'] != null;
                            
                            if (hasBefore && hasAfter) {
                              _updateJobStatus('payment_pending');
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You MUST upload at least the Before and After photos to complete the job!'), backgroundColor: Colors.red)
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('Job is Done', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ]
                    else if (status == 'payment_pending') ...[
                      if (paymentStatus == 'paid') ...[
                        const Center(child: Text('Customer marked Payment as Done!', style: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold))),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _completePaymentAndJob,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Approve Payment & Finish', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ] else ...[
                        const Center(child: Text('Waiting for Customer to make Payment...', style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold))),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null, // LOCKED
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Approve Payment (Locked)'),
                          ),
                        ),
                      ]
                    ]
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }
}
