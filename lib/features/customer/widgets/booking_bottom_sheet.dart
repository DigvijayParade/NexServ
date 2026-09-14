import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _serviceMode = 'Instant'; // Instant or Scheduled
  String? _selectedSubService;
  final _issueController = TextEditingController();

  // Step 2 State
  String? _selectedDate;
  String? _selectedTime;
  final _addressController = TextEditingController();
  bool _showStep2Error = false;

  // Step 4 State
  String _paymentMethod = 'UPI / GPay / PhonePe';

  final List<String> _dates = ['Today', 'Tomorrow', 'Select Custom Date'];
  final List<String> _times = ['09:00 AM', '11:30 AM', '02:00 PM', '05:00 PM'];

  List<String> _getSubServices() {
    switch (widget.categoryName) {
      case 'Electrician':
        return ['Fan Repair - ₹299', 'Switchboard Fixing - ₹199', 'Full Wiring Inspection - ₹499'];
      case 'Plumber':
        return ['Leakage Fix - ₹249', 'Pipe Replacement - ₹399', 'Tap Fitting - ₹149'];
      case 'Carpenter':
        return ['Furniture Assembly - ₹499', 'Door Hinge Fix - ₹199', 'Custom Woodwork - ₹999'];
      case 'Cleaning':
      case 'Home & Community Cleaner':
        return ['Deep Cleaning - ₹999', 'Sofa Dry Cleaning - ₹499', 'Kitchen Cleaning - ₹599'];
      case 'Repair':
      case 'Appliance Repair Specialist':
        return ['AC Servicing - ₹599', 'Washing Machine Repair - ₹499', 'Refrigerator Check - ₹399'];
      default:
        return ['General Service - ₹299'];
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedSubService == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a sub-service')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if ((_serviceMode == 'Scheduled' && (_selectedDate == null || _selectedTime == null)) ||
          _addressController.text.trim().isEmpty) {
        setState(() => _showStep2Error = true);
        return;
      }
      setState(() {
        _showStep2Error = false;
        _currentStep = 3;
      });
      _startAIMatching();
    } else if (_currentStep == 4) {
      Provider.of<AppState>(context, listen: false).addBooking();
      Navigator.pop(context); // Close bottom sheet
      Navigator.pushNamed(context, '/liveTracking');
    }
  }

  void _startAIMatching() async {
    await Future.delayed(const Duration(seconds: 6));
    if (mounted) {
      setState(() {
        _currentStep = 4;
      });
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
            'Book ${widget.categoryName}',
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
                backgroundColor: Colors.black, // Uber-style black button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _currentStep == 1
                    ? 'Continue to Schedule'
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
        const Text('Service Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Instant', label: Text('Instant AI Dispatch (15 Mins)')),
            ButtonSegment(value: 'Scheduled', label: Text('Schedule for Later')),
          ],
          selected: {_serviceMode},
          onSelectionChanged: (val) {
            setState(() {
              _serviceMode = val.first;
            });
          },
        ),
        const SizedBox(height: 24),
        const Text('Select Sub-Service', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._getSubServices().map((service) {
          return RadioListTile<String>(
            title: Text(service),
            value: service,
            // ignore: deprecated_member_use
            groupValue: _selectedSubService,
            // ignore: deprecated_member_use
            onChanged: (val) {
              setState(() {
                _selectedSubService = val;
              });
            },
          );
        }),
        const SizedBox(height: 16),
        TextField(
          controller: _issueController,
          decoration: InputDecoration(
            labelText: 'Describe your issue (optional)',
            hintText: 'e.g., main switchboard sparking',
            suffixIcon: IconButton(
              icon: const Icon(Icons.mic),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listening... Say your service requirement.')),
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
          const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
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
        const Text('Service Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Flat / House No / Landmark',
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
                          Text('4.9 ★ (120+ jobs)'),
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
            // ignore: deprecated_member_use
            groupValue: _paymentMethod,
            // ignore: deprecated_member_use
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
                  Text(_selectedSubService?.split('-').last.trim() ?? '₹299'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Service Charge'),
                  Text('₹49'),
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
