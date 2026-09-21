import 'dart:math';
import 'package:flutter/material.dart';

class ActiveJobScreen extends StatefulWidget {
  const ActiveJobScreen({super.key});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final _otpController = TextEditingController();
  final _partsController = TextEditingController();
  
  bool _isStarted = false;
  bool _isCompleted = false;
  double _extraPartsCost = 0.0;
  final double _baseFare = 299.0;
  late String _generatedOtp;

  @override
  void initState() {
    super.initState();
    // Generate a random 4-digit OTP for this job session
    _generatedOtp = (1000 + Random().nextInt(9000)).toString();
  }

  @override
  void dispose() {
    _otpController.dispose(); // BUG FIX #4: Missing dispose calls
    _partsController.dispose();
    super.dispose();
  }

  void _verifyOTP() {
    if (_otpController.text == _generatedOtp) {
      setState(() {
        _isStarted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified. Service Started.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP! Ask customer for 4-digit code.'), backgroundColor: Colors.red),
      );
    }
  }

  void _completeService() {
    setState(() {
      _extraPartsCost = double.tryParse(_partsController.text) ?? 0.0;
      _isCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    double total = _baseFare + _extraPartsCost;
    double welfareDeduction = total * 0.03; // 3%
    double finalPayout = total - welfareDeduction;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isStarted && !_isCompleted) {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please complete the job before leaving!')),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF0F5A47),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: const Text('Customer'),
                      subtitle: const Text('Address on file'),
                      trailing: IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Calling customer...')),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    const Text('Electrician - Fan Repair', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (!_isStarted) ...[
                      const Text('Enter 4-Digit OTP to Start Service'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                hintText: '4-digit OTP',
                                counterText: '', // BUG FIX #5: Hide ugly counter text under OTP field
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _verifyOTP,
                            child: const Text('Verify & Start', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ] else if (!_isCompleted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Service In Progress', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _partsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Extra Parts Cost (₹)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.currency_rupee),
                          hintText: '0',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _completeService,
                        child: const Text('Generate Final Bill & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      const Icon(Icons.check_circle, color: Colors.green, size: 64),
                      const SizedBox(height: 8),
                      const Text('Job Completed Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            _buildBillRow('Base Fare', '₹${_baseFare.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _buildBillRow('Extra Parts', '₹${_extraPartsCost.toStringAsFixed(2)}'),
                            const Divider(),
                            _buildBillRow('Total Bill (To Collect)', '₹${total.toStringAsFixed(2)}', isBold: true),
                            const SizedBox(height: 16),
                            _buildBillRow('Coop Welfare (3%)', '- ₹${welfareDeduction.toStringAsFixed(2)}', color: Colors.red),
                            const Divider(),
                            _buildBillRow('Your Net Payout', '₹${finalPayout.toStringAsFixed(2)}', isBold: true, color: Colors.green, fontSize: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Return to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // BUG FIX #6: Extracted bill row widget to prevent very long Row lines that could overflow on narrow screens
  Widget _buildBillRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
