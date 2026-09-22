import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/searching_worker_screen.dart';

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
  bool _isBooking = false;

  final List<String> _dates = ['Today', 'Tomorrow', 'Day After'];
  final List<String> _times = ['Morning', 'Afternoon', 'Evening'];
  
  Map<String, List<String>> _subServices = {
    'Electrician': ['Fan Installation - ,1299', 'Switch Repair - ,1149', 'Wiring - ,1499', 'Other Issue'],
    'Plumber': ['Tap Leakage - ,1199', 'Pipe Blockage - ,1399', 'Tank Cleaning - ,1599', 'Other Issue'],
    'Carpenter': ['Door Repair - ,1249', 'Furniture Assembly - ,1499', 'Lock Change - ,1299', 'Other Issue'],
    'Home Cleaner': ['Deep Cleaning - ,1999', 'Sofa Cleaning - ,1499', 'Bathroom Cleaning - ,1399', 'Other Issue'],
    'Appliance Repair': ['AC Service - ,1499', 'Washing Machine - ,1399', 'Refrigerator - ,1499', 'Other Issue'],
  };

  // Dummy translation function for now
  String _tr(String key) => key;

  @override
  void dispose() {
    _issueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _createJob() async {
    setState(() => _isBooking = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create a job document in Firestore
      final jobRef = await FirebaseFirestore.instance.collection('jobs').add({
        'customer_id': user.uid,
        'service_category': widget.categoryName,
        'sub_service': _selectedSubService,
        'service_mode': _serviceMode,
        'address': _addressController.text.trim(),
        'date': _serviceMode == 'Scheduled' ? _selectedDate : 'ASAP',
        'time': _serviceMode == 'Scheduled' ? _selectedTime : 'ASAP',
        'issue_description': _issueController.text.trim(),
        'status': 'open',
        'created_at': FieldValue.serverTimestamp(),
        'assigned_worker_id': null,
      });

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SearchingWorkerScreen(jobId: jobRef.id),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create job: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_selectedSubService == null) {
        setState(() => _showStep1Error = true);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty || (_serviceMode == 'Scheduled' && (_selectedDate == null || _selectedTime == null))) {
        setState(() => _showStep2Error = true);
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      _createJob();
    }
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
        top: 24,
        left: 24,
        right: 24,
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
          Expanded(child: SingleChildScrollView(child: _buildCurrentStep())),
          
          if (_currentStep == 1 || _currentStep == 2 || _currentStep == 3) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isBooking ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isBooking
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentStep == 1
                          ? _tr('Continue to Schedule')
                          : _currentStep == 2
                              ? 'Review Booking'
                              : 'Confirm & Broadcast Request',
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
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    final subServices = _subServices[widget.categoryName] ?? ['General Service', 'Inspection', 'Other Issue'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What do you need help with?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: subServices.map((sub) => ChoiceChip(
            label: Text(sub),
            selected: _selectedSubService == sub,
            selectedColor: Colors.black,
            labelStyle: TextStyle(color: _selectedSubService == sub ? Colors.white : Colors.black),
            onSelected: (val) {
              setState(() {
                _selectedSubService = val ? sub : null;
                if (_selectedSubService != null) _showStep1Error = false;
              });
            },
          )).toList(),
        ),
        if (_showStep1Error)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Please select a service type', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 24),
        const Text('Describe your issue (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _issueController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'E.g., The fan is making a weird noise...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('When do you need it?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Instantly'),
                subtitle: const Text('Within 30 mins'),
                value: 'Instant',
                groupValue: _serviceMode,
                onChanged: (val) => setState(() => _serviceMode = val!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Schedule'),
                subtitle: const Text('Pick a slot'),
                value: 'Scheduled',
                groupValue: _serviceMode,
                onChanged: (val) => setState(() => _serviceMode = val!),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_serviceMode == 'Scheduled') ...[
          const SizedBox(height: 16),
          const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: _dates.map((date) => ChoiceChip(
              label: Text(date),
              selected: _selectedDate == date,
              onSelected: (val) => setState(() => _selectedDate = val ? date : null),
            )).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: _times.map((time) => ChoiceChip(
              label: Text(time),
              selected: _selectedTime == time,
              onSelected: (val) => setState(() => _selectedTime = val ? time : null),
            )).toList(),
          ),
          if (_showStep2Error && (_selectedDate == null || _selectedTime == null))
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text('Please select date and time', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          const SizedBox(height: 24),
        ],
        const SizedBox(height: 16),
        const Text('Service Address', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Flat / House No / Landmark',
            border: const OutlineInputBorder(),
            errorText: _showStep2Error && _addressController.text.trim().isEmpty ? 'Address is required' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service:', style: TextStyle(color: Colors.grey)),
                    Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sub-Service:', style: TextStyle(color: Colors.grey)),
                    Text(_selectedSubService?.split('-').first.trim() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Base Fare:', style: TextStyle(color: Colors.grey)),
                    Text(_selectedSubService?.split('-').last.trim() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mode:', style: TextStyle(color: Colors.grey)),
                    Text(_serviceMode, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'By clicking "Confirm & Broadcast Request", your job will be sent to all available workers in your area. The first worker to accept will be assigned to you.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        )
      ],
    );
  }
}
