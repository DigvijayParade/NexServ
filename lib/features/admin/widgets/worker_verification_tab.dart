import 'package:flutter/material.dart';

class WorkerVerificationTab extends StatefulWidget {
  const WorkerVerificationTab({super.key});

  @override
  State<WorkerVerificationTab> createState() => _WorkerVerificationTabState();
}

class _WorkerVerificationTabState extends State<WorkerVerificationTab> {
  String _selectedProfessionFilter = 'All';
  final List<String> _professions = [
    'All',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Home Cleaner',
    'Appliance Repair'
  ];

  final List<Map<String, dynamic>> _applicants = [
    {
      'id': 'A1',
      'name': 'Rahul Verma',
      'mobile': '+91 98****1234',
      'profession': 'Electrician',
      'aadhaar': 'XXXX-XXXX-9876',
    },
    {
      'id': 'A2',
      'name': 'Sunita Devi',
      'mobile': '+91 76****5555',
      'profession': 'Home Cleaner',
      'aadhaar': 'XXXX-XXXX-1122',
    },
    {
      'id': 'A3',
      'name': 'Amit Kumar',
      'mobile': '+91 88****0001',
      'profession': 'Plumber',
      'aadhaar': 'XXXX-XXXX-4321',
    },
  ];

  void _approveWorker(String id, String name) {
    setState(() {
      _applicants.removeWhere((a) => a['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name has been verified and added to the active database.'), backgroundColor: Colors.green),
    );
  }

  void _showRejectDialog(String id, String name) {
    String? selectedReason;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Reject / Request Docs for $name'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Please select a reason for rejection:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      hint: const Text('Select Reason'),
                      initialValue: selectedReason,
                      items: const [
                        DropdownMenuItem(value: 'Invalid Aadhaar Number', child: Text('Invalid Aadhaar Number')),
                        DropdownMenuItem(value: 'Incomplete Document Upload', child: Text('Incomplete Document Upload')),
                        DropdownMenuItem(value: 'Unverified Skill Certificate', child: Text('Unverified Skill Certificate')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          selectedReason = val;
                        });
                      },
                      validator: (val) => val == null ? 'Reason is required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      setState(() {
                        _applicants.removeWhere((a) => a['id'] == id);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name rejected: $selectedReason'), backgroundColor: Colors.orange),
                      );
                    }
                  },
                  child: const Text('Submit Rejection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _previewDocument(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Document Preview: $name'),
        content: Container(
          height: 200,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.picture_as_pdf, size: 64, color: Colors.grey),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedApplicants = _selectedProfessionFilter == 'All'
        ? _applicants
        : _applicants.where((a) => a['profession'] == _selectedProfessionFilter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  initialValue: _selectedProfessionFilter,
                  items: _professions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedProfessionFilter = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: displayedApplicants.isEmpty
              ? const Center(child: Text('No applicants pending verification.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: displayedApplicants.length,
                  itemBuilder: (context, index) {
                    final app = displayedApplicants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(app['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Chip(
                                  label: Text(app['profession']),
                                  backgroundColor: Colors.blue.shade100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Mobile: ${app['mobile']}'),
                            Text('Aadhaar / Coop ID: ${app['aadhaar']}'),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Icon(Icons.verified_user, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('e-Shram Linked', style: TextStyle(fontSize: 12, color: Colors.green)),
                                SizedBox(width: 12),
                                Icon(Icons.domain_verification, color: Colors.blue, size: 16),
                                SizedBox(width: 4),
                                Text('National DB Checked', style: TextStyle(fontSize: 12, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _previewDocument(app['name']),
                                    icon: const Icon(Icons.description),
                                    label: const Text('Preview Doc'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    onPressed: () => _showRejectDialog(app['id'], app['name']),
                                    child: const Text('Reject / Docs'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                    onPressed: () => _approveWorker(app['id'], app['name']),
                                    child: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
