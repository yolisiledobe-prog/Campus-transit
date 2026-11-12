import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/student_bottom_navigation_bar.dart';
import 'application_history_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import '../theme/app_palette.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? applicationId;
  final Map<String, dynamic>? existingApplication;

  const ApplicationFormScreen({
    super.key,
    required this.userData,
    this.applicationId,
    this.existingApplication,
  });

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  String? _selectedResidence;
  bool _isSubmitting = false;
  bool _proofSubmitted = false;
  String? _submissionProgress;
  String? _newApplicationId;

  final List<String> _residences = [
    'Ocean View',
    'Langham House',
    'Alba&Bala',
    'Jacaranda',
    'Amajwarha',
    'Seabro',
    'Amalinda',
  ];

  void _navigate(BuildContext context, int destination) {
    if (destination == 2) return;
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
    final screen = switch (destination) {
      1 => ApplicationHistoryScreen(
          userId: user.uid,
          userData: widget.userData,
        ),
      3 => ScheduleScreen(
          residence: widget.userData['residence'] ?? 'Not selected',
          campus: widget.userData['campus'] ?? 'Buffalo City Campus',
          userId: user.uid,
          userData: widget.userData,
        ),
      4 => ProfileScreen(userData: widget.userData),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void initState() {
    super.initState();
    final residence = widget.existingApplication?['residence'] ??
        widget.userData['residence'];
    if (residence != null && _residences.contains(residence)) {
      _selectedResidence = residence;
    }
    final existing = widget.existingApplication;
    _proofSubmitted = existing?['proofSubmitted'] == true ||
        (existing?['proofOfResidenceUrl'] as String?)?.isNotEmpty == true;
  }

  Future<void> _submitApplication() async {
    if (_selectedResidence == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your residence.')),
      );
      return;
    }

    if (!_proofSubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm that you have submitted proof of residence.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _setSubmissionProgress('Preparing your application...');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionProgress = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before applying.')),
      );
      return;
    }

    var activeStage = 'preparing your application';
    var applicationSaved = false;
    try {
      final applications =
          FirebaseFirestore.instance.collection('transport_applications');
      final applicationId =
          widget.applicationId ?? (_newApplicationId ??= applications.doc().id);
      final applicationData = <String, dynamic>{
        'uid': user.uid,
        'studentNumber': widget.userData['studentNumber'] ?? '',
        'fullName':
            '${widget.userData['firstName']} ${widget.userData['lastName']}',
        'email': widget.userData['email'] ?? user.email,
        'residence': _selectedResidence,
        'proofSubmitted': true,
        'proofSubmissionMethod': 'in_person_or_school_approved_channel',
        'proofSubmittedAt': Timestamp.now(),
        'status': 'Pending',
        'appliedAt': Timestamp.now(),
      };

      activeStage = 'saving your application to Firestore';
      _setSubmissionProgress('Saving your application...');
      if (widget.applicationId == null) {
        await _withSubmissionTimeout(
          applications.doc(applicationId).set(applicationData),
          'Application save',
        );
      } else {
        await _withSubmissionTimeout(
          applications.doc(applicationId).update({
            ...applicationData,
            'adminComment': FieldValue.delete(),
            'adminCommentUpdatedAt': FieldValue.delete(),
          }),
          'Application save',
        );
      }
      applicationSaved = true;

      if (!mounted) return;
      var profileWarning = '';
      activeStage = 'updating your profile';
      _setSubmissionProgress('Updating your profile...');
      try {
        await _withSubmissionTimeout(
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'residence': _selectedResidence}),
          'Profile update',
        );
      } catch (e) {
        profileWarning =
            ' Your application was saved, but your profile residence could not be updated: $e';
      }
      if (!mounted) return;
      _setSubmissionProgress(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Transport application saved and sent for review.$profileWarning',
          ),
          backgroundColor: AppPalette.approved,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Application submission failed while $activeStage: $e');
      var errorMessage = applicationSaved
          ? 'Application saved, but updating your profile failed: $e'
          : 'Submission failed: $e';
      if (e is FirebaseException) {
        final firebaseError = e.message ?? e.code;
        if (e.code == 'permission-denied') {
          errorMessage =
              'Firebase denied the request while $activeStage. Deploy the updated firestore.rules, then try again. Details: $firebaseError';
        } else {
          errorMessage = applicationSaved
              ? 'Application saved, but Firebase failed while $activeStage (${e.code}): $firebaseError'
              : 'Firebase failed while $activeStage (${e.code}): $firebaseError';
        }
      } else if (e is TimeoutException) {
        errorMessage =
            'Timed out while $activeStage. ${e.message ?? 'Check your connection and try again.'}';
      }
      if (!mounted) return;
      _setSubmissionProgress(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionProgress = null;
        });
      }
    }
  }

  void _setSubmissionProgress(String? progress) {
    if (!mounted) return;
    setState(() => _submissionProgress = progress);
  }

  Future<T> _withSubmissionTimeout<T>(
    Future<T> operation,
    String stage, {
    Duration timeout = const Duration(seconds: 45),
  }) {
    return operation.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        '$stage is taking too long.',
        timeout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transport Application')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            if (widget.applicationId != null) ...[
              const Text(
                'Editing your application will send it back for review. Any previous admin comment will be cleared.',
                style: TextStyle(color: AppPalette.mutedText),
              ),
              const SizedBox(height: 16),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Student Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${widget.userData['firstName']} ${widget.userData['lastName']}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Student Number',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.userData['studentNumber'] ?? 'N/A'),
            ),
            const SizedBox(height: 16),

            // Dropdown for Residence
            DropdownButtonFormField<String>(
              initialValue: _selectedResidence,
              decoration: const InputDecoration(
                labelText: 'Select Residence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              hint: const Text('Select your residence'),
              items: _residences
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedResidence = v),
            ),
            const SizedBox(height: 20),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _proofSubmitted,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Proof of residence submitted'),
              subtitle: const Text(
                'I confirm I have given my proof to the admin in person or '
                'submitted it through a school-approved channel. This app '
                'records the confirmation only; it does not upload or store '
                'the document.',
              ),
              onChanged: _isSubmitting
                  ? null
                  : (submitted) => setState(
                        () => _proofSubmitted = submitted ?? false,
                      ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.navy,
                foregroundColor: AppPalette.creamLight,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSubmitting ? null : _submitApplication,
              child: _isSubmitting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppPalette.creamLight,
                            strokeWidth: 2,
                          ),
                        ),
                        if (_submissionProgress != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _submissionProgress!,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: AppPalette.creamLight),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      widget.applicationId == null
                          ? 'Submit Application'
                          : 'Save Changes',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create transport application',
        onPressed: () => _navigate(context, 2),
        backgroundColor: AppPalette.navy,
        foregroundColor: AppPalette.creamLight,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: StudentBottomNavigationBar(
        currentIndex: 2,
        onDestinationSelected: (destination) => _navigate(context, destination),
      ),
    );
  }
}
