import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> _data = {};

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Which field is currently being edited
  String? _editingField;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final appState = Provider.of<AppState>(context, listen: false);
    final data = await appState.getUserData(user.uid);
    
    if (mounted) {
      setState(() {
        _data = data ?? {};
        _nameController.text = _data['name'] ?? '';
        _phoneController.text = _data['phone'] ?? '';
        _addressController.text = _data['address'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveField(String field, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    if (_data['role'] != null) {
      String roleStr = _data['role'].toString().toLowerCase();
      String roleCollection = 'customers';
      if (roleStr == 'worker') roleCollection = 'workers';
      if (roleStr.contains('cooperative') || roleStr == 'admin') roleCollection = 'admins';
      
      try {
        await FirebaseFirestore.instance.collection(roleCollection).doc(user.uid).update({field: value});
      } catch (e) {
        debugPrint('Profile update failed: $e');
      }
    }
    setState(() {
      _data[field] = value;
      _editingField = null;
      _isSaving = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
      );
    }
  }

  Widget _buildEditableRow(IconData icon, String label, String fieldKey, TextEditingController controller) {
    final isEditing = _editingField == fieldKey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _saveField(fieldKey, controller.text.trim()),
                                ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _editingField = null;
                                // Reset to saved value
                                controller.text = _data[fieldKey] ?? '';
                              });
                            },
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: Text(
                              (_data[fieldKey]?.toString().isNotEmpty == true) ? _data[fieldKey] : 'Not set',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade500),
                            onPressed: () => setState(() => _editingField = fieldKey),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text(value.isNotEmpty ? value : 'Not set',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text(
                          (_data['name']?.isNotEmpty == true) ? _data['name'][0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 40, color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _data['name'] ?? 'User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    (_data['role']?.toString().toUpperCase() ?? 'CUSTOMER'),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
                _buildEditableRow(Icons.person_outline, 'Full Name', 'name', _nameController),
                const Divider(),
                _buildReadOnlyRow(Icons.email_outlined, 'Email', user.email ?? ''),
                const Divider(),
                _buildEditableRow(Icons.phone_outlined, 'Phone Number', 'phone', _phoneController),
                const Divider(),
                _buildEditableRow(Icons.home_outlined, 'Address', 'address', _addressController),
                const Divider(),
                _buildReadOnlyRow(Icons.work_outline, 'Role', _data['role']?.toString().toUpperCase() ?? 'CUSTOMER'),
                if (_data['service_category'] != null && _data['service_category'].toString().isNotEmpty) ...[
                  const Divider(),
                  _buildReadOnlyRow(Icons.build_outlined, 'Profession', _data['service_category']),
                ],
                if (_data['e_shram_id'] != null && _data['e_shram_id'].toString().isNotEmpty) ...[
                  const Divider(),
                  _buildReadOnlyRow(Icons.badge_outlined, 'e-Shram ID (UAN)', _data['e_shram_id']),
                ],
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
