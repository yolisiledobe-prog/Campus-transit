import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
          ? const Center(
              child: Text('You must be signed in to view your profile.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          'Could not load your profile: ${snapshot.error}'),
                    ),
                  );
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(
                    child: Text('Admin profile data was not found.'),
                  );
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final firstName = data['firstname'] ?? data['firstName'] ?? '';
                final lastName = data['lastname'] ?? data['lastName'] ?? '';
                final fullName = '$firstName $lastName'.trim();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 48,
                            backgroundColor: AppPalette.beige,
                            child: Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 52,
                              color: AppPalette.navy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName.isEmpty ? 'Administrator' : fullName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: AppPalette.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Administrator account',
                            style: TextStyle(color: AppPalette.mutedText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _profileCard([
                      _profileDetail(
                        Icons.person_outline,
                        'First name',
                        firstName,
                      ),
                      const Divider(height: 24),
                      _profileDetail(
                        Icons.person_outline,
                        'Surname',
                        lastName,
                      ),
                      const Divider(height: 24),
                      _profileDetail(
                        Icons.badge_outlined,
                        'Staff number',
                        data['staffNumber'] ?? 'Not provided',
                      ),
                      const Divider(height: 24),
                      _profileDetail(
                        Icons.phone_outlined,
                        'Phone number',
                        data['phoneNumber'] ?? data['phone'] ?? 'Not provided',
                      ),
                      const Divider(height: 24),
                      _profileDetail(
                        Icons.email_outlined,
                        'Email address',
                        data['email'] ?? user.email ?? 'Not provided',
                      ),
                    ]),
                  ],
                );
              },
            ),
    );
  }

  Widget _profileCard(List<Widget> children) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppPalette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppPalette.border),
        ),
        child: Column(children: children),
      );

  Widget _profileDetail(IconData icon, String label, String value) => Row(
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
