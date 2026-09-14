import 'package:flutter/material.dart';

class AIMatchingOverlay extends StatefulWidget {
  const AIMatchingOverlay({super.key});

  @override
  State<AIMatchingOverlay> createState() => _AIMatchingOverlayState();
}

class _AIMatchingOverlayState extends State<AIMatchingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _statusIndex = 0;
  final List<String> _statuses = [
    "Analyzing nearby cooperative workers...",
    "Checking skill match & availability...",
    "Worker Matched!"
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _simulateMatching();
  }

  void _simulateMatching() async {
    for (int i = 1; i < _statuses.length; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _statusIndex = i;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Simulated map background
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: Stack(
                  children: [
                    Positioned(top: 40, left: 40, child: Icon(Icons.person_pin_circle, color: Colors.blue, size: 24)),
                    Positioned(top: 120, right: 30, child: Icon(Icons.person_pin_circle, color: Colors.green, size: 24)),
                    Positioned(bottom: 20, left: 80, child: Icon(Icons.person_pin_circle, color: Colors.orange, size: 24)),
                  ],
                ),
              ),
              // Radar pulse
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 150 * _controller.value,
                    height: 150 * _controller.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 1 - _controller.value),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              // Center User Pin
              const Icon(Icons.my_location, color: Colors.red, size: 40),
            ],
          ),
          const SizedBox(height: 24),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _statuses[_statusIndex],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
