import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  
  String _role = 'customer';
  String _name = '';
  String _phone = '';
  String _serviceCategory = 'Electrician';
  String? _base64Image;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyController = TextEditingController();
  final _addressController = TextEditingController();
  
  final List<String> _professions = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Home Cleaner',
    'Appliance Repair',
    'Painter',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Try to get from users collection
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _role = data['role'] ?? 'customer';
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emergencyController.text = data['emergency_contact'] ?? '';
        _addressController.text = data['address'] ?? '';
        _base64Image = data['profile_image_base64'];
        
        if (_role == 'worker') {
          _serviceCategory = data['service_category'] ?? 'Electrician';
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 50,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(() {
        _base64Image = base64String;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_role == 'worker' && _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture is mandatory for workers')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'emergency_contact': _emergencyController.text,
        'address': _addressController.text,
        'profile_image_base64': _base64Image,
      };

      if (_role == 'worker') {
        data['service_category'] = _serviceCategory;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(data);
      
      if (_role == 'worker') {
        // Update in workers collection too just in case
        await FirebaseFirestore.instance.collection('workers').doc(user.uid).set(data, SetOptions(merge: true));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  
  Widget _buildAvatar() {
    Uint8List? imageBytes;
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      try {
        imageBytes = base64Decode(_base64Image!);
      } catch(e) {
        debugPrint('Error decoding image');
      }
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
              child: imageBytes == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter your phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    if (_role == 'customer') ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emergencyController,
                        decoration: const InputDecoration(
                          labelText: 'Family/Friends (SOS)', 
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.contact_emergency),
                          hintText: 'Comma separated numbers',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_role == 'worker') ...[
                      DropdownButtonFormField<String>(
                        value: _serviceCategory,
                        decoration: const InputDecoration(labelText: 'Service Category', border: OutlineInputBorder()),
                        items: _professions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _serviceCategory = v!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
