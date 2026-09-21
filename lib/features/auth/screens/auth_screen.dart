import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

  // Controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _aadhaarController = TextEditingController();

  // State
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isLoading = true);
    setState(() {
      _showTermsError = _authMode == AuthMode.createAccount && !_termsAccepted;
    });

    if (_formKey.currentState!.validate() && !_showTermsError) {
      if (_authMode == AuthMode.createAccount && _selectedRole == UserRole.worker && _selectedProfession == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your primary profession.'), backgroundColor: Colors.red),
        );
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
          address: _addressController.text.isNotEmpty ? _addressController.text : null,
        );

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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
      appBar: AppBar(
        title: const Text('NexServ'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_logo.jpg',
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'NexServ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Center(
                  child: Text(
                    'AI-Powered Cooperative Services',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                // Auth Mode Switcher
                SegmentedButton<AuthMode>(
                  segments: const [
                    ButtonSegment(
                      value: AuthMode.signIn,
                      label: Text('Sign In'),
                      icon: Icon(Icons.login),
                    ),
                    ButtonSegment(
                      value: AuthMode.createAccount,
                      label: Text('Create Account'),
                      icon: Icon(Icons.person_add),
                    ),
                  ],
                  selected: {_authMode},
                  onSelectionChanged: (Set<AuthMode> newSelection) {
                    setState(() {
                      _authMode = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                ),
                
                const SizedBox(height: 16),

                if (!isLogin)
                  CustomTextField(
                    label: 'Full Name',
                    controller: _fullNameController,
                    prefixIcon: const Icon(Icons.person),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    validator: Validators.validateFullName,
                  ),

                CustomTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),

                if (!isLogin)
                  CustomTextField(
                    label: 'Mobile Number',
                    controller: _mobileController,
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: Validators.validateMobileNumber,
                  ),

                if (!isLogin)
                  CustomTextField(
                    label: 'Address (Flat, Street, City)',
                    controller: _addressController,
                    prefixIcon: const Icon(Icons.location_on),
                    validator: (val) => val == null || val.isEmpty ? 'Address is required' : null,
                  ),

                if (!isLogin && _selectedRole == UserRole.worker) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Profession',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedProfession,
                      items: _professions.map((p) {
                        return DropdownMenuItem(value: p, child: Text(p));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedProfession = val;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Please select your primary profession.' : null,
                    ),
                  ),
                  CustomTextField(
                    label: 'Worker Verification ID (Aadhaar)',
                    controller: _aadhaarController,
                    prefixIcon: const Icon(Icons.badge),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    validator: Validators.validateAadhaar,
                  ),
                ],

                PasswordField(
                  label: 'Password',
                  controller: _passwordController,
                  validator: (val) => Validators.validatePassword(val, isRegistration: !isLogin),
                ),

                if (!isLogin)
                  PasswordField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                  ),

                if (isLogin) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                ],

                if (!isLogin) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        isError: _showTermsError,
                        onChanged: (val) {
                          setState(() {
                            _termsAccepted = val ?? false;
                            if (_termsAccepted) _showTermsError = false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I accept the Terms and Conditions',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_showTermsError)
                    const Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: Text(
                        'You must accept the terms and conditions.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          isLogin ? 'Sign In' : 'Create Account',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
