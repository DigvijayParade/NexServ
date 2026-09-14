import 'package:flutter/material.dart';

class WelfareFundTab extends StatefulWidget {
  const WelfareFundTab({super.key});

  @override
  State<WelfareFundTab> createState() => _WelfareFundTabState();
}

class _WelfareFundTabState extends State<WelfareFundTab> {
  bool _isLoading = false;

  void _disburseDividend() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Monthly Cooperative Dividend successfully disbursed to all eligible members!'),
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
          Card(
            color: Colors.blue.shade800,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: const [
                  Text(
                    'Accumulated Reserve Pool',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹4,85,000',
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fund Allocation Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildAllocationItem(
            title: 'Worker Health & Term Insurance Reserve',
            percentage: '40%',
            amount: '₹1,94,000',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildAllocationItem(
            title: 'Pension & Accident Shield Pool',
            percentage: '40%',
            amount: '₹1,94,000',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildAllocationItem(
            title: 'Emergency Micro-Loans Pool',
            percentage: '20%',
            amount: '₹97,000',
            color: Colors.orange,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _isLoading ? null : _disburseDividend,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Icon(Icons.account_balance_wallet),
            label: Text(_isLoading ? 'Processing...' : 'Disburse Monthly Cooperative Dividend'),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationItem({
    required String title,
    required String percentage,
    required String amount,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(
            percentage,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
