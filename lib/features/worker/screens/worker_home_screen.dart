import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/state/app_state.dart';
import '../../../core/routes/app_routes.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _dialogShown = false; // BUG FIX #1: Prevent multiple dialogs from stacking

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showIncomingJobDialog(BuildContext context, AppState appState) {
    if (_dialogShown) return; // Guard against re-entry
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _IncomingJobDialog(
        onAccept: () {
          appState.acceptIncomingJob();
          _dialogShown = false;
          Navigator.pop(ctx);
          AppRoutes.navigatorKey.currentState?.pushNamed('/activeJob');
        },
        onDecline: () {
          appState.clearIncomingJob();
          _dialogShown = false;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isHindi = appState.locale == 'Hindi';

    // BUG FIX #1: Check for incoming job simulation — with guard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appState.isWorkerOnline && appState.hasIncomingJob && !_dialogShown) {
        _showIncomingJobDialog(context, appState);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'कार्यकर्ता डैशबोर्ड' : 'Worker Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isHindi
                    ? 'Voice Assist: "आप ऑनलाइन हैं। अभी कोई नई बुकिंग नहीं है।"'
                    : 'Voice Assist: "You are online. No new bookings right now."')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          )
        ],
      ),
      body: SingleChildScrollView( // BUG FIX #2: Wrap in scroll view to prevent Spacer overflow on small screens
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                AppBar().preferredSize.height - 
                MediaQuery.of(context).padding.top - 32,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Duty Guard Toggle
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          appState.isWorkerOnline
                              ? (isHindi ? 'आप ऑनलाइन हैं' : 'You are ONLINE')
                              : (isHindi ? 'आप ऑफ़लाइन हैं' : 'You are OFFLINE'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: appState.isWorkerOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Transform.scale(
                          scale: 1.5,
                          child: Switch(
                            value: appState.isWorkerOnline,
                            activeTrackColor: Colors.green.shade200,
                            activeThumbColor: Colors.green,
                            onChanged: (val) {
                              appState.toggleWorkerStatus();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          appState.isWorkerOnline
                              ? (isHindi ? 'नज़दीकी काम ढूंढ रहे हैं...' : 'Searching for nearby jobs...')
                              : (isHindi ? 'ऑनलाइन जाएं सेवा अनुरोध प्राप्त करने के लिए' : 'Go online to receive service requests.'),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // AI Heatmap Banner
                if (appState.isWorkerOnline)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1 + (_pulseController.value * 0.1)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.red, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHindi ? 'AI सर्ज का पता चला' : 'AI Surge Detected',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isHindi
                                        ? 'सेक्टर 14 में ज़्यादा माँग। 1.5x कमाई के लिए इस ज़ोन की ओर जाएं!'
                                        : 'High demand in Sector 14. Move towards this zone for 1.5x earnings!',
                                    style: const TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                
                // Earnings summary card
                if (appState.isWorkerOnline) ...[
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            isHindi ? "आज की कमाई" : "Today's Earnings",
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹1,450',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isHindi ? '5 काम पूरे हुए' : '5 Jobs Completed',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),
                // Mock trigger for demo purposes if not using customer app
                if (appState.isWorkerOnline && !appState.hasIncomingJob)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Simulate an incoming job manually for testing
                        appState.addBooking(); // This will trigger hasIncomingJob
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: Text(isHindi ? 'इनकमिंग जॉब सिमुलेट करें (डीबग)' : 'Simulate Incoming Job (Debug)'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomingJobDialog extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingJobDialog({required this.onAccept, required this.onDecline});

  @override
  State<_IncomingJobDialog> createState() => _IncomingJobDialogState();
}

class _IncomingJobDialogState extends State<_IncomingJobDialog> {
  int _timer = 30;
  late Timer _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        if (mounted) setState(() => _timer--);
      } else {
        _countdown.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _countdown.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.bolt, color: Colors.amber, size: 32),
          SizedBox(width: 8),
          Flexible(child: Text('New Service Request')), // BUG FIX #3: Prevent title overflow
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Electrician - Fan Repair', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Customer: Anjali Gupta'),
          const Text('Distance: 1.4 km (Sector 18)'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('Estimated Earning:', style: TextStyle(fontWeight: FontWeight.bold))),
                Text('₹299', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Accept within $_timer s',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _countdown.cancel();
            widget.onDecline();
          },
          child: const Text('Delegate to Peer'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () {
            _countdown.cancel();
            widget.onAccept();
          },
          child: const Text('Accept Job'),
        ),
      ],
    );
  }
}
