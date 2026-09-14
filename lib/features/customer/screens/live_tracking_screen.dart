import 'package:flutter/material.dart';
import '../widgets/rating_dialog.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  int _currentStep = 2; // Simulating 'Worker on the way' state

  final List<String> _steps = [
    'Request Confirmed',
    'Worker Assigned (Ramesh Kumar)',
    'Worker on the way',
    'Service Completed'
  ];

  void _simulateCompletion() {
    setState(() {
      _currentStep = 3;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RatingDialog(),
    ).then((_) {
      if (!mounted) return;
      // User submitted rating or skipped
      Navigator.of(context).pushReplacementNamed('/customerHome');
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
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking Cancelled')),
              );
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  controlsBuilder: (context, details) => const SizedBox.shrink(),
                  steps: List.generate(
                    _steps.length,
                    (index) => Step(
                      title: Text(_steps[index], style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: index == 2 && _currentStep == 2
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ramesh is 5 mins away.'),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: _cancelRequest,
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Cancel Request'),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                      isActive: _currentStep >= index,
                      state: _currentStep > index ? StepState.complete : StepState.indexed,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _currentStep == 2 ? _simulateCompletion : null,
                  child: const Text('DEBUG: Simulate Service Completion'),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('SOS Alert sent to Cooperative Admin and Emergency Contacts!'), backgroundColor: Colors.red),
          );
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
