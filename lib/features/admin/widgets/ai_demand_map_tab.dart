import 'package:flutter/material.dart';

class AIDemandMapTab extends StatefulWidget {
  const AIDemandMapTab({super.key});

  @override
  State<AIDemandMapTab> createState() => _AIDemandMapTabState();
}

class _AIDemandMapTabState extends State<AIDemandMapTab> {
  void _dispatchNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Zone Shift Notification Broadcasted successfully to 15 workers.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Text(
                    'Simulated Interactive Map\n(Delhi NCR Region)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                // Red Zone (High Demand)
                Positioned(
                  top: 60,
                  left: 50,
                  child: _buildHeatmapZone(
                    color: Colors.red,
                    label: 'Dwarka Sec 14\nSurge 1.5x (45 pending)',
                    size: 120,
                  ),
                ),
                // Green Zone (Balanced)
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: _buildHeatmapZone(
                    color: Colors.green,
                    label: 'Zone A\nBalanced (15 idle)',
                    size: 90,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Colors.amber.shade50,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.amber.shade400, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amber, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'AI Automated Recommendation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'High evening demand predicted in Sector 14. Recommend re-allocating 15 idle Electricians from Zone A.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: _dispatchNotification,
            icon: const Icon(Icons.send),
            label: const Text('Dispatch AI Zone Shift Push Notification'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapZone({required Color color, required String label, required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color.withValues(alpha: 1.0), // solid text
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
