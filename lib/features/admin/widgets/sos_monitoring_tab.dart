import 'package:flutter/material.dart';

class SosMonitoringTab extends StatefulWidget {
  const SosMonitoringTab({super.key});

  @override
  State<SosMonitoringTab> createState() => _SosMonitoringTabState();
}

class _SosMonitoringTabState extends State<SosMonitoringTab> {
  String _filter = 'All Active Jobs';
  
  final List<Map<String, dynamic>> _mockJobs = [
    {
      'id': 'J-101',
      'customer': 'Anjali Gupta',
      'worker': 'Ramesh Kumar',
      'service': 'Electrician',
      'status': 'En Route',
      'isEmergency': false,
    },
    {
      'id': 'J-102',
      'customer': 'Priya Singh',
      'worker': 'Suresh Verma',
      'service': 'Plumber',
      'status': 'In Progress',
      'isEmergency': true,
      'emergencyDetails': 'Customer reported aggressive behavior.',
      'location': '28.5355° N, 77.3910° E (Noida Sec 18)',
    },
    {
      'id': 'J-103',
      'customer': 'Rahul Sharma',
      'worker': 'Vikash Patel',
      'service': 'Carpenter',
      'status': 'Completed',
      'isEmergency': false,
    },
  ];

  void _markResolved(String jobId) {
    setState(() {
      final job = _mockJobs.firstWhere((j) => j['id'] == jobId);
      job['isEmergency'] = false;
      job['status'] = 'Resolved / Completed';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Incident for $jobId marked as resolved.'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedJobs = _filter == 'All Active Jobs' 
        ? _mockJobs 
        : _mockJobs.where((j) => j['isEmergency'] == true).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'All Active Jobs', label: Text('All Active Jobs')),
              ButtonSegment(value: 'Flagged / SOS', label: Text('Flagged / SOS')),
            ],
            selected: {_filter},
            onSelectionChanged: (val) {
              setState(() {
                _filter = val.first;
              });
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: displayedJobs.length,
            itemBuilder: (context, index) {
              final job = displayedJobs[index];
              final bool isSos = job['isEmergency'];

              if (isSos) {
                return _buildSosCard(job);
              }
              return _buildNormalJobCard(job);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNormalJobCard(Map<String, dynamic> job) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.work)),
        title: Text('${job['service']} - ${job['id']}'),
        subtitle: Text('Customer: ${job['customer']} | Worker: ${job['worker']}'),
        trailing: Chip(
          label: Text(job['status'], style: const TextStyle(fontSize: 10)),
          backgroundColor: job['status'] == 'Completed' ? Colors.green.shade100 : Colors.blue.shade100,
        ),
      ),
    );
  }

  Widget _buildSosCard(Map<String, dynamic> job) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(
                  'SOS EMERGENCY - ${job['id']}',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(),
            Text('Customer: ${job['customer']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Worker: ${job['worker']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Details: ${job['emergencyDetails']}'),
            Text('Live Location: ${job['location']}', style: const TextStyle(color: Colors.blueAccent)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.map),
                  label: const Text('View Live GPS'),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.call),
                  label: const Text('Call Worker'),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.local_police),
                  label: const Text('Local Authorities'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _markResolved(job['id']),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark Resolved'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
