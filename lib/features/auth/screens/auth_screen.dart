import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/state/app_state.dart';
import '../../../core/utils/validators.dart';
import '../models/enums.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/role_selector.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  AuthMode _authMode = AuthMode.signIn;
  UserRole _selectedRole = UserRole.customer;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _em1Controller = TextEditingController();
  final _em2Controller = TextEditingController();
  final _em3Controller = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _aadhaarController = TextEditingController();

  String? _selectedProfession;
  bool _termsAccepted = false;
  bool _rememberMe = false;
  bool _showTermsError = false;
  bool _isLoading = false;

  final List<String> _professions = [
    "Electrician",
    "Plumber",
    "Carpenter",
    "Home & Community Cleaner",
    "Appliance Repair Specialist"
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _em1Controller.dispose();
    _em2Controller.dispose();
    _em3Controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<bool> _showAdminPinDialog() async {
    bool isAuthorized = false;
    final TextEditingController pinController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cooperative Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter Admin PIN to continue:'),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              obscureText: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == 'NEXSERV2026') {
                isAuthorized = true;
                Navigator.of(ctx).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN'), backgroundColor: Colors.red),
                );
                pinController.clear();
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
    return isAuthorized;
  }

  void _submit() async {
    if (_selectedRole == UserRole.admin) {
      bool pinValid = await _showAdminPinDialog();
      if (!pinValid) return;
    }
    
    setState(() => _isLoading = true);
    setState(() {
      _showTermsError = _authMode == AuthMode.createAccount && !_termsAccepted;
    });

    if (_formKey.currentState!.validate() && !_showTermsError) {
      if (_authMode == AuthMode.createAccount && _selectedRole == UserRole.worker && _selectedProfession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your primary profession.'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      final appState = Provider.of<AppState>(context, listen: false);
      try {
        await appState.authenticate(
          isLogin: _authMode == AuthMode.signIn,
          email: _emailController.text,
          password: _passwordController.text,
          role: _selectedRole.displayName,
          name: _fullNameController.text.isNotEmpty ? _fullNameController.text : null,
          phone: _mobileController.text.isNotEmpty ? _mobileController.text : null,
          profession: _selectedProfession,
          address: _addressController.text.trim(),
            emergencyContact: '${_em1Controller.text.trim()}, ${_em2Controller.text.trim()}, ${_em3Controller.text.trim()}',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_authMode == AuthMode.signIn ? "Logged in" : "Registered"} successfully as ${_selectedRole.displayName}'),
              backgroundColor: Colors.green,
            ),
          );

          switch (_selectedRole) {
            case UserRole.customer:
              Navigator.pushReplacementNamed(context, '/customerHome');
              break;
            case UserRole.worker:
              Navigator.pushReplacementNamed(context, '/workerHome');
              break;
            case UserRole.admin:
              Navigator.pushReplacementNamed(context, '/adminDashboard');
              break;
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('A password reset link will be sent to your email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _authMode == AuthMode.signIn;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('NexServ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/premium_dark_bg.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                  ]
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset('assets/images/app_logo.jpg', width: 80, height: 80),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(child: Text('NexServ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                      const Center(child: Text('AI-Powered Cooperative Services', style: TextStyle(fontSize: 12, color: Colors.grey))),
                      const SizedBox(height: 24),
                      SegmentedButton<AuthMode>(
                        segments: const [
                          ButtonSegment(value: AuthMode.signIn, label: Text('Sign In'), icon: Icon(Icons.login)),
                          ButtonSegment(value: AuthMode.createAccount, label: Text('Create Account'), icon: Icon(Icons.person_add)),
                        ],
                        selected: {_authMode},
                        onSelectionChanged: (Set<AuthMode> newSelection) {
                          setState(() => _authMode = newSelection.first);
                        },
                      ),
                      const SizedBox(height: 24),
                      RoleSelector(
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) => setState(() => _selectedRole = role),
                      ),
                      const SizedBox(height: 24),
                      if (!isLogin) ...[
                        CustomTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.validateFullName,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _mobileController,
                          label: 'Mobile Number',
                          prefixIcon: const Icon(Icons.phone_android),
                          keyboardType: TextInputType.phone,
                          validator: Validators.validateMobileNumber,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedRole == UserRole.worker) ...[
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedProfession,
                            decoration: const InputDecoration(
                              labelText: 'Primary Profession',
                              prefixIcon: Icon(Icons.handyman),
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                            ),
                            items: _professions.map((prof) => DropdownMenuItem(value: prof, child: Text(prof))).toList(),
                            onChanged: (val) => setState(() => _selectedProfession = val),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _aadhaarController,
                            label: 'e-Shram ID (UAN)',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                        ],
                        CustomTextField(
                          controller: _addressController,
                          label: 'Service Address',
                          prefixIcon: const Icon(Icons.home_outlined),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        if (_selectedRole == UserRole.customer) ...[
                          const Text('Family/Close Friends (For SOS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _em1Controller,
                              label: 'Emergency Contact 1',
                              prefixIcon: const Icon(Icons.contact_emergency),
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                final res = Validators.validateMobileNumber(val);
                                if (res != null) return res;
                                if (val == _mobileController.text) return 'Cannot be your own number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _em2Controller,
                              label: 'Emergency Contact 2',
                              prefixIcon: const Icon(Icons.contact_emergency),
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                final res = Validators.validateMobileNumber(val);
                                if (res != null) return res;
                                if (val == _mobileController.text) return 'Cannot be your own number';
                                if (val == _em1Controller.text) return 'Must be unique';
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: _em3Controller,
                              label: 'Emergency Contact 3',
                              prefixIcon: const Icon(Icons.contact_emergency),
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                final res = Validators.validateMobileNumber(val);
                                if (res != null) return res;
                                if (val == _mobileController.text) return 'Cannot be your own number';
                                if (val == _em1Controller.text || val == _em2Controller.text) return 'Must be unique';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                      ],
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      PasswordField(controller: _passwordController, label: 'Password'),
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                        ),
                      ],
                      if (!isLogin) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (val) => setState(() {
                                _termsAccepted = val ?? false;
                                if (_termsAccepted) _showTermsError = false;
                              }),
                            ),
                            const Expanded(child: Text('I agree to the Terms & Conditions and Privacy Policy', style: TextStyle(fontSize: 12))),
                          ],
                        ),
                        if (_showTermsError)
                          const Padding(padding: EdgeInsets.only(left: 12.0), child: Text('Please accept the terms to continue', style: TextStyle(color: Colors.red, fontSize: 12))),
                      ],
                      if (isLogin) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(() => _rememberMe = val ?? false),
                                  ),
                                  const Text('Remember me', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text('Forgot Password?'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
