import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'admin_profile_screen.dart';
import '../theme/app_palette.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String? statusFilter;

  const AdminDashboardScreen({super.key, this.statusFilter});

  Future<void> _updateApplicationStatus(
      BuildContext context, String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('transport_applications')
          .doc(docId)
          .update({'status': newStatus});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application marked as $newStatus'),
          backgroundColor: newStatus == 'Approved'
              ? AppPalette.approved
              : AppPalette.rejected,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _editAdminComment(
      BuildContext context, String docId, String currentComment) async {
    final controller = TextEditingController(text: currentComment);
    var isSaving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Message to student'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Explain what the student needs to update or upload',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        try {
                          await FirebaseFirestore.instance
                              .collection('transport_applications')
                              .doc(docId)
                              .update({
                            'adminComment': controller.text.trim(),
                            'adminCommentUpdatedAt': Timestamp.now(),
                          });
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to save message: $e')),
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save message'),
              ),
            ],
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(statusFilter == null
            ? 'Admin Portal - Applications'
            : '$statusFilter Applications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _AdminMenu(selectedStatus: statusFilter),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transport_applications')
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No transport applications submitted yet.'));
          }

          final applications = snapshot.data!.docs.where((doc) {
            final app = doc.data() as Map<String, dynamic>;
            final status = app['status'] ?? 'Pending';
            return statusFilter == null || status == statusFilter;
          }).toList();

          if (applications.isEmpty) {
            return Center(
              child: Text('No ${statusFilter!.toLowerCase()} applications.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              var doc = applications[index];
              var app = doc.data() as Map<String, dynamic>;
              String status = app['status'] ?? 'Pending';
              final hasLegacyProof = [
                app['proofOfResidenceUrl'],
                app['proofStoragePath'],
                app['fileName'],
              ].every((value) => value is String && value.trim().isNotEmpty);
              final proofSubmitted =
                  app['proofSubmitted'] == true || hasLegacyProof;
              String adminComment = app['adminComment'] ?? '';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            app['fullName'] ?? 'Student Name',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: Text(
                              status,
                              style: const TextStyle(
                                  color: AppPalette.creamLight,
                                  fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: status == 'Approved'
                                ? AppPalette.approved
                                : status == 'Rejected'
                                    ? AppPalette.rejected
                                    : AppPalette.pending,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Student No: ${app['studentNumber'] ?? 'N/A'}'),
                      Text('Residence: ${app['residence'] ?? 'N/A'}'),
                      Text('Email: ${app['email'] ?? 'N/A'}'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            proofSubmitted ? Icons.check_circle : Icons.error,
                            color: proofSubmitted
                                ? AppPalette.approved
                                : AppPalette.rejected,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              proofSubmitted
                                  ? 'Student confirmed proof was submitted in person or through a school-approved channel. The document is not stored in this app.'
                                  : 'Proof submission has not been confirmed.',
                              style: TextStyle(
                                color: proofSubmitted
                                    ? AppPalette.approved
                                    : AppPalette.rejected,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (adminComment.isNotEmpty) ...[
                        Text(
                          'Message to student: $adminComment',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.comment),
                          label: Text(
                            adminComment.isEmpty
                                ? 'Write comment'
                                : 'Edit comment',
                          ),
                          onPressed: () => _editAdminComment(
                            context,
                            doc.id,
                            adminComment,
                          ),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.rejected,
                                foregroundColor: AppPalette.creamLight),
                            icon: const Icon(Icons.close),
                            label: const Text('Reject'),
                            onPressed: status == 'Rejected'
                                ? null
                                : () => _updateApplicationStatus(
                                    context, doc.id, 'Rejected'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppPalette.approved,
                                foregroundColor: AppPalette.creamLight),
                            icon: const Icon(Icons.check),
                            label: const Text('Approve'),
                            onPressed: status == 'Approved' || !proofSubmitted
                                ? null
                                : () => _updateApplicationStatus(
                                    context, doc.id, 'Approved'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminMenu extends StatelessWidget {
  final String? selectedStatus;

  const _AdminMenu({required this.selectedStatus});

  void _openApplications(BuildContext context, String? status) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboardScreen(statusFilter: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: AppPalette.navy),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Admin menu',
                style: TextStyle(
                  color: AppPalette.creamLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminProfileScreen(),
                ),
              );
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('View Applications'),
            initiallyExpanded: selectedStatus != null,
            children: [
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('All applications'),
                selected: selectedStatus == null,
                onTap: () => _openApplications(context, null),
              ),
              for (final status in ['Approved', 'Rejected', 'Pending'])
                ListTile(
                  leading: Icon(
                    status == 'Approved'
                        ? Icons.check_circle_outline
                        : status == 'Rejected'
                            ? Icons.cancel_outlined
                            : Icons.hourglass_empty,
                  ),
                  title: Text(status),
                  selected: selectedStatus == status,
                  onTap: () => _openApplications(context, status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
