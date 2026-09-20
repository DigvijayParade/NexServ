import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/state/app_state.dart';
import 'ai_matching_overlay.dart';

class BookingBottomSheet extends StatefulWidget {
  final String categoryName;
  const BookingBottomSheet({super.key, required this.categoryName});

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _currentStep = 1;

  // Step 1 State
  String _serviceMode = 'Instant';
  String? _selectedSubService;
  final _issueController = TextEditingController();

  // Step 2 State
  String? _selectedDate;
  String? _selectedTime;
  final _addressController = TextEditingController();
  bool _showStep1Error = false;
  bool _showStep2Error = false;

  // Step 4 State
  String _paymentMethod = 'UPI / GPay / PhonePe';

  final List<String> _dates = ['Today', 'Tomorrow', 'Select Custom Date'];
  final List<String> _times = ['09:00 AM', '11:30 AM', '02:00 PM', '05:00 PM'];

  String _tr(String text) {
    final appState = Provider.of<AppState>(context, listen: true);
    String loc = appState.locale;
    if (loc == 'English' || loc == 'en') return text;
    if (loc == 'Hindi') loc = 'hi';
    if (loc == 'Marathi') loc = 'mr';
    
    final translations = {
      'Book ': {'hi': 'बुक करें ', 'mr': 'बुक करा '},
      'Electrician': {'hi': 'इलेक्ट्रीशियन', 'mr': 'इलेक्ट्रिशियन'},
      'Plumber': {'hi': 'प्लंबर', 'mr': 'प्लंबर'},
      'Carpenter': {'hi': 'बढ़ई', 'mr': 'सुतार'},
      'Cleaning': {'hi': 'सफाई', 'mr': 'स्वच्छता'},
      'Repair': {'hi': 'मरम्मत', 'mr': 'दुरुस्ती'},
      'Service Mode': {'hi': 'सेवा मोड', 'mr': 'सेवा मोड'},
      'Instant AI Dispatch (15 Mins)': {'hi': 'त्वरित AI डिस्पैच (15 मिनट)', 'mr': 'त्वरित AI डिस्पॅच (15 मिनिटे)'},
      'Schedule for Later': {'hi': 'बाद के लिए शेड्यूल करें', 'mr': 'नंतरसाठी शेड्यूल करा'},
      'Select Sub-Service': {'hi': 'उप-सेवा चुनें', 'mr': 'उप-सेवा निवडा'},
      'Describe your issue (optional)': {'hi': 'अपनी समस्या बताएं (वैकल्पिक)', 'mr': 'तुमच्या समस्येचे वर्णन करा (पर्यायी)'},
      'Continue to Schedule': {'hi': 'शेड्यूल जारी रखें', 'mr': 'शेड्यूल सुरू ठेवा'},
      'Service Address': {'hi': 'सेवा का पता', 'mr': 'सेवा पत्ता'},
      'Flat / House No / Landmark': {'hi': 'फ्लैट / मकान नंबर / लैंडमार्क', 'mr': 'फ्लॅट / घर क्र. / खूण'},
      'Select Date': {'hi': 'तारीख चुनें', 'mr': 'तारीख निवडा'},
      'Select Time Slot': {'hi': 'समय चुनें', 'mr': 'वेळ निवडा'},
    };
    
    if (text.startsWith('Book ')) {
      final cat = text.replaceAll('Book ', '');
      final translatedCat = translations[cat]?[loc] ?? cat;
      final translatedBook = translations['Book ']?[loc] ?? 'Book ';
      return loc == 'hi' ? '$translatedCat $translatedBook' : '$translatedCat $translatedBook';
    }
    
    return translations[text]?[loc] ?? text;
  }

  List<String> _getSubServices() {
    switch (widget.categoryName) {
      case 'Electrician':
        return ['Fan Repair - ₹1299', 'Switchboard Fixing - ₹1199', 'Full Wiring Inspection - ₹1499'];
      case 'Plumber':
        return ['Leakage Fix - ₹1249', 'Pipe Replacement - ₹1399', 'Tap Fitting - ₹1149'];
      case 'Carpenter':
        return ['Furniture Assembly - ₹1499', 'Door Hinge Fix - ₹1199', 'Custom Woodwork - ₹1999'];
              case 'Painter':
          return ['Wall Painting - ₹2999', 'Wood Polishing - ₹1499', 'Texture Painting - ₹3999'];
        case 'Cleaning':
      case 'Home & Community Cleaner':
        return ['Deep Cleaning - ₹1999', 'Sofa Dry Cleaning - ₹1499', 'Kitchen Cleaning - ₹1599'];
      case 'Repair':
      case 'Appliance Repair Specialist':
        return ['AC Servicing - ₹1599', 'Washing Machine Repair - ₹1499', 'Refrigerator Check - ₹1399'];
      default:
        return ['General Service - ₹1299'];
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedSubService == null) {
        setState(() => _showStep1Error = true);
        return;
      }
      setState(() {
        _showStep1Error = false;
        _currentStep = 2;
      });
    } else if (_currentStep == 2) {
      if ((_serviceMode == 'Scheduled' && (_selectedDate == null || _selectedTime == null)) ||
          _addressController.text.trim().isEmpty) {
        setState(() => _showStep2Error = true);
        return;
      }
      setState(() {
        _showStep2Error = false;
      });
      _startBackendJobCreation();
    } else if (_currentStep == 4) {
      Navigator.pop(context);
    }
  }

  void _startBackendJobCreation() async {
    setState(() {
      _currentStep = 3;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final parts = _selectedSubService!.split('-');
      final rateStr = parts.last.replaceAll('₹', '').trim();
      
      // Generate 4-digit OTP
      final otp = (1000 + Random().nextInt(9000)).toString();
      
      await FirebaseFirestore.instance.collection('jobs').add({
        'customer_id': user.uid,
        'service_category': widget.categoryName,
        'service_type': _selectedSubService,
        'service_rate': double.tryParse(rateStr) ?? 299.0,
        'status': 'searching',
        'otp': otp,
        'created_at': FieldValue.serverTimestamp(),
        'location': const GeoPoint(28.6304, 77.2177)
      });
      
      // Wait for AI Match overlay animation to finish
      await Future.delayed(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          _currentStep = 4;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job created! Worker matched!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _currentStep = 2; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  void dispose() {
    _issueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _tr('Book ${widget.categoryName}'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
          if (_currentStep != 3) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentStep == 1
                    ? _tr('Continue to Schedule')
                    : _currentStep == 2
                        ? 'Find Cooperative Worker'
                        : 'Confirm & Book Service',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ]
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return const Center(child: AIMatchingOverlay());
      case 4:
        return _buildStep4();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Service Mode'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'Instant', label: Text(_tr('Instant AI Dispatch (15 Mins)'))),
            ButtonSegment(value: 'Scheduled', label: Text(_tr('Schedule for Later'))),
          ],
          selected: {_serviceMode},
          onSelectionChanged: (val) {
            setState(() {
              _serviceMode = val.first;
            });
          },
        ),
        const SizedBox(height: 16),
        Text(_tr('Select Sub-Service'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._getSubServices().map((sub) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RadioListTile<String>(
              title: Text(sub),
              value: sub,
              groupValue: _selectedSubService,
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _showStep1Error ? Colors.red : Colors.grey.shade300,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _selectedSubService = val;
                  _showStep1Error = false;
                });
              },
            ),
          );
        }),
        if (_showStep1Error)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text('Please select a sub-service to continue.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _issueController,
          decoration: InputDecoration(
            labelText: _tr('Describe your issue (optional)'),
            suffixIcon: IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listening...')),
                );
              },
            ),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_serviceMode == 'Scheduled') ...[
          Text(_tr('Select Date'), style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: _dates.map((date) {
              return ChoiceChip(
                label: Text(date),
                selected: _selectedDate == date,
                onSelected: (val) {
                  setState(() => _selectedDate = val ? date : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(_tr('Select Time Slot'), style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: _times.map((time) {
              return ChoiceChip(
                label: Text(time),
                selected: _selectedTime == time,
                onSelected: (val) {
                  setState(() => _selectedTime = val ? time : null);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        Text(_tr('Service Address'), style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: _tr('Flat / House No / Landmark'),
            border: const OutlineInputBorder(),
            errorText: _showStep2Error && _addressController.text.trim().isEmpty
                ? 'Address is required'
                : null,
          ),
        ),
        if (_showStep2Error && _serviceMode == 'Scheduled' && (_selectedDate == null || _selectedTime == null))
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Please select Date and Time for scheduled service.', style: TextStyle(color: Colors.red)),
          ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Worker Matched!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Ramesh Kumar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('4.9 ⭐ (120+ jobs)'),
                          SizedBox(height: 4),
                          Text('1.4 km away • Arriving in 15 mins', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verified Member • Delhi Urban Workers Cooperative Union #COOP-108',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
        ...['UPI / GPay / PhonePe', 'Cash on Service Delivery', 'Card'].map((method) {
          return RadioListTile<String>(
            title: Text(method),
            value: method,
            groupValue: _paymentMethod,
            onChanged: (val) {
              setState(() {
                _paymentMethod = val!;
              });
            },
          );
        }),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade100,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base Fare'),
                  Text(_selectedSubService?.split('-').last.trim() ?? '₹1299'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Service Charge'),
                  Text('₹149'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Calculated at end', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
