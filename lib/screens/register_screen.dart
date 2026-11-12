import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import '../theme/app_palette.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _residence;
  bool _isPasswordVisible = false;

  final List<String> _residences = [
    'Ocean View',
    'Langham House',
    'Alba&Bala',
    'Jacaranda',
    'Amajwarha',
    'Seabro',
    'Amalinda',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentNumberController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_residence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select your off-campus residence.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user!;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'studentNumber': _studentNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'campus': 'Buffalo City Campus',
        'residence': _residence,
        'role': 'student',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      var verificationMessage =
          'Account created. A verification email was sent to ${_emailController.text.trim()}.';
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        verificationMessage =
            'Account created, but Firebase could not send the verification email: ${e.message ?? e.code}. Check Firebase Authentication email templates and authorized domains.';
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(verificationMessage)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (e is FirebaseException) {
        errorMsg = e.message ?? e.code;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Firebase Error: $errorMsg'),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Student Registration - Buffalo City Campus')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) => v!.isEmpty ? 'Enter first name' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) => v!.isEmpty ? 'Enter last name' : null,
              ),
              TextFormField(
                controller: _studentNumberController,
                decoration: const InputDecoration(labelText: 'Student Number'),
                validator: (v) => v!.isEmpty ? 'Enter student number' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (v) => v!.isEmpty ? 'Enter email' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration:
                    const InputDecoration(labelText: 'Cellphone Number'),
                validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _residence,
                hint: const Text('Select Off-Campus Residence'),
                items: _residences
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _residence = v),
                validator: (v) =>
                    v == null ? 'Please select a residence' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Create Password',
                  suffixIcon: IconButton(
                    tooltip:
                        _isPasswordVisible ? 'Hide password' : 'Show password',
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_isPasswordVisible,
                validator: (v) =>
                    v!.length < 6 ? 'Password must be at least 6 chars' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.navy,
                  foregroundColor: AppPalette.creamLight,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: AppPalette.creamLight)
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
