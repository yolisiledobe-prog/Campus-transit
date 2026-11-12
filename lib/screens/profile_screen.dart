import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/student_bottom_navigation_bar.dart';
import 'application_form_screen.dart';
import 'application_history_screen.dart';
import 'dashboard_screen.dart';
import 'schedule_screen.dart';
import '../theme/app_palette.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _isPasswordVisible = false;
  String? _emailNotice;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.userData['firstName'] ?? '';
    _lastNameController.text = widget.userData['lastName'] ?? '';
    _phoneController.text = widget.userData['phone'] ?? '';
    _emailController.text = FirebaseAuth.instance.currentUser?.email ??
        widget.userData['email'] ??
        '';
    _firstNameController.addListener(_refreshProfileName);
    _lastNameController.addListener(_refreshProfileName);
    _syncVerifiedEmail();
  }

  void _refreshProfileName() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _syncVerifiedEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;
      if (refreshedUser == null || refreshedUser.email == null) return;
      await refreshedUser.getIdToken(true);

      if (refreshedUser.email != widget.userData['email']) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(refreshedUser.uid)
            .update({'email': refreshedUser.email});
      }

      if (mounted) {
        setState(() {
          _emailController.text = refreshedUser.email!;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not refresh account email: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be signed in to edit your profile.')),
      );
      return;
    }

    final newEmail = _emailController.text.trim();
    final emailChanged =
        newEmail.toLowerCase() != (user.email ?? '').toLowerCase();
    if (emailChanged && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your current password to change your email.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (emailChanged) {
        final currentEmail = user.email;
        if (currentEmail == null) {
          throw StateError('The signed-in account has no email address.');
        }
        final credential = EmailAuthProvider.credential(
          email: currentEmail,
          password: _passwordController.text,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(newEmail);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });

      if (!mounted) return;
      _passwordController.clear();
      setState(() {
        _emailNotice = emailChanged
            ? 'Check $newEmail and verify the address before it becomes your sign-in email.'
            : null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailChanged
              ? 'Profile saved. Verification email sent to $newEmail.'
              : 'Profile updated successfully.'),
          backgroundColor: AppPalette.approved,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _navigate(int destination) {
    if (destination == 4) return;
    if (destination == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final residence = widget.userData['residence'] ?? 'Not selected';
    final campus = widget.userData['campus'] ?? 'Buffalo City Campus';
    final screen = switch (destination) {
      1 => ApplicationHistoryScreen(
          userId: user.uid,
          userData: widget.userData,
        ),
      2 => ApplicationFormScreen(userData: widget.userData),
      3 => ScheduleScreen(
          residence: residence,
          campus: campus,
          userId: user.uid,
          userData: widget.userData,
        ),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final studentNumber = widget.userData['studentNumber'] ?? 'N/A';
    final residence = widget.userData['residence'] ?? 'Not selected';
    final campus = widget.userData['campus'] ?? 'Buffalo City Campus';

    return Scaffold(
      backgroundColor: AppPalette.creamLight,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: AppPalette.cream,
        foregroundColor: AppPalette.navy,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppPalette.beige,
                    child: Icon(
                      Icons.person,
                      size: 54,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_firstNameController.text} ${_lastNameController.text}'
                        .trim(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student No. $studentNumber',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppPalette.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('Personal information'),
            const SizedBox(height: 10),
            _sectionCard(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _fieldDecoration('First name', Icons.person_outline),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your first name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _fieldDecoration('Last name', Icons.person_outline),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your last name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _fieldDecoration('Phone number', Icons.phone_outlined),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your cellphone number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      _fieldDecoration('Email address', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter your email address';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                        .hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                if (_emailNotice != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _emailNotice!,
                    style: const TextStyle(color: AppPalette.rejected),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            _sectionTitle('Campus details'),
            const SizedBox(height: 10),
            _sectionCard(
              children: [
                _detailRow(
                    Icons.badge_outlined, 'Student number', studentNumber),
                const Divider(height: 24),
                _detailRow(Icons.location_on_outlined, 'Residence', residence),
                const Divider(height: 24),
                _detailRow(Icons.school_outlined, 'Campus', campus),
              ],
            ),
            const SizedBox(height: 22),
            _sectionTitle('Account security'),
            const SizedBox(height: 10),
            _sectionCard(
              children: [
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: _fieldDecoration(
                    'Current password (needed to change email)',
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      tooltip: _isPasswordVisible
                          ? 'Hide password'
                          : 'Show password',
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
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.navy,
                foregroundColor: AppPalette.creamLight,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(
                      color: AppPalette.creamLight)
                  : const Text(
                      'Save profile',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create transport application',
        onPressed: () => _navigate(2),
        backgroundColor: AppPalette.navy,
        foregroundColor: AppPalette.creamLight,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: StudentBottomNavigationBar(
        currentIndex: 4,
        onDestinationSelected: _navigate,
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppPalette.navyDeep,
        ),
      );

  Widget _sectionCard({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        child: Column(children: children),
      );

  InputDecoration _fieldDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppPalette.creamLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  Widget _detailRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: AppPalette.slate, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppPalette.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppPalette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
