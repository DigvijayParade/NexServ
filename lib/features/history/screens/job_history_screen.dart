import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class JobHistoryScreen extends StatelessWidget {
  const JobHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job History'),
      ),
      body: user == null
          ? const Center(child: Text('Please login to view history'))
          : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                final role = userSnap.data?.get('role') ?? 'customer';
                final isWorker = role.toString().toLowerCase() == 'worker';

                final queryField = isWorker ? 'assigned_worker_id' : 'customer_id';

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('jobs')
                      .where(queryField, isEqualTo: user.uid)
                      // .orderBy removed to prevent composite index requirement in debug phase
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No job history found.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final job = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        
                        final service = job['service_category'] ?? 'Service';
                        final status = job['status'] ?? 'unknown';
                        final price = job['base_fare'] ?? 299;
                        
                        DateTime? date;
                        if (job['created_at'] != null) {
                          date = (job['created_at'] as Timestamp).toDate();
                        }

                        Color statusColor = Colors.grey;
                        if (status == 'completed') statusColor = Colors.green;
                        if (status == 'cancelled') statusColor = Colors.red;
                        if (status == 'assigned' || status == 'arrived') statusColor = Colors.orange;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text('INR ' + price.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (date != null)
                                      Text(DateFormat('MMM dd, yyyy - hh:mm a').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                if (status == 'completed') ...[
                                  const Divider(height: 24),
                                  const Text('Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  if (job['arrived_at'] != null)
                                    Text('- Arrived: ' + DateFormat('hh:mm a').format((job['arrived_at'] as Timestamp).toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (job['paid_at'] != null)
                                    Text('- Paid (Cash): ' + DateFormat('hh:mm a').format((job['paid_at'] as Timestamp).toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  if (job['completed_at'] != null)
                                    Text('- Completed: ' + DateFormat('hh:mm a').format((job['completed_at'] as Timestamp).toDate()), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
