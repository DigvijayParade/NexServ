import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/searching_worker_screen.dart';
import '../screens/available_workers_screen.dart';

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
  
  final Map<String, List<String>> _subServices = {
    'Electrician': ['Fan Installation - \u20b9299', 'Switch Repair - \u20b9149', 'Wiring - \u20b9499', 'Other Issue'],
    'Plumber': ['Tap Leakage - \u20b9199', 'Pipe Blockage - \u20b9399', 'Tank Cleaning - \u20b9599', 'Other Issue'],
    'Carpenter': ['Door Repair - \u20b9249', 'Furniture Assembly - \u20b9499', 'Lock Change - \u20b9299', 'Other Issue'],
    'Home Cleaner': ['Deep Cleaning - \u20b9999', 'Sofa Cleaning - \u20b9499', 'Bathroom Cleaning - \u20b9399', 'Other Issue'],
    'Appliance Repair': ['AC Service - \u20b9499', 'Washing Machine - \u20b9399', 'Refrigerator - \u20b9499', 'Other Issue'],
    'Painter': ['Wall Painting - \u20b92999', 'Texture Painting - \u20b94999', 'Waterproofing - \u20b91999', 'Other Issue'],
  };

  // Dummy translation function for now
  String _tr(String key) => key;

  @override
  void dispose() {
    _issueController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_currentStep == 1) {
      if (_selectedSubService == null) {
        setState(() => _showStep1Error = true);
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty) {
        setState(() => _showStep2Error = true);
        return;
      }
      if (_serviceMode == 'Scheduled' && (_selectedDate == null || _selectedTime == null)) {
        setState(() => _showStep2Error = true);
        return;
      }
      setState(() => _currentStep = 3);
    } else if (_currentStep == 3) {
      _submitBooking();
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _isBooking = true);
    // Simulate slight delay for UX
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      Navigator.pop(context); // Close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AvailableWorkersScreen(
            categoryName: widget.categoryName,
            subService: _selectedSubService,
            serviceMode: _serviceMode,
            address: _addressController.text,
            issueDescription: _issueController.text,
          ),
        ),
      );
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final step = index + 1;
        return Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _currentStep >= step ? Colors.black : Colors.grey.shade300,
              child: Text('$step', style: TextStyle(color: _currentStep >= step ? Colors.white : Colors.black54, fontSize: 12)),
            ),
            if (index < 2)
              Container(width: 30, height: 2, color: _currentStep > step ? Colors.black : Colors.grey.shade300),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Book ${widget.categoryName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 16),
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
          const SizedBox(height: 16),
          if (_currentStep > 1) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isBooking
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _currentStep == 2 ? 'Review Booking' : 'Find Professionals',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _tr('Continue to Schedule'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                    Flexible(child: Text(_selectedSubService?.split('-').first.trim() ?? '', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
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
          'By clicking "Confirm & Find Professionals", you will see available workers matching your service. Choose the best professional for your job.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        )
      ],
    );
  }
}
