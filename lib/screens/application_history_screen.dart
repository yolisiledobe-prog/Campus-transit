import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/student_bottom_navigation_bar.dart';
import 'application_form_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import '../theme/app_palette.dart';

class ApplicationHistoryScreen extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const ApplicationHistoryScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  void _navigate(BuildContext context, int destination) {
    if (destination == 1) return;
    if (destination == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
      return;
    }

    final screen = switch (destination) {
      2 => ApplicationFormScreen(userData: userData),
      3 => ScheduleScreen(
          residence: userData['residence'] ?? 'Not selected',
          campus: userData['campus'] ?? 'Buffalo City Campus',
          userId: userId,
          userData: userData,
        ),
      4 => ProfileScreen(userData: userData),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Application History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transport_applications')
            .where('uid', isEqualTo: userId)
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
                    'Could not load application history: ${snapshot.error}'),
              ),
            );
          }

          final applications = snapshot.data?.docs.toList() ?? [];
          applications.sort((a, b) {
            final aDate =
                (a.data() as Map<String, dynamic>)['appliedAt'] as Timestamp?;
            final bDate =
                (b.data() as Map<String, dynamic>)['appliedAt'] as Timestamp?;
            if (aDate == null || bDate == null) return 0;
            return bDate.compareTo(aDate);
          });

          if (applications.isEmpty) {
            return const Center(child: Text('No past applications found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final data = applications[index].data() as Map<String, dynamic>;
              final timestamp = data['appliedAt'] as Timestamp?;
              final date = timestamp == null
                  ? 'Recent'
                  : timestamp.toDate().toString().split(' ')[0];
              final status = data['status'] as String? ?? 'Pending';
              final adminComment = data['adminComment'] as String? ?? '';
              final proofSubmitted = data['proofSubmitted'] == true ||
                  (data['proofOfResidenceUrl'] as String?)?.isNotEmpty == true;
              final statusColor = switch (status) {
                'Approved' => AppPalette.approved,
                'Rejected' => AppPalette.rejected,
                _ => AppPalette.pending,
              };

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.history,
                    color: AppPalette.navy,
                  ),
                  title: Text(
                    'Residence: ${data['residence'] ?? 'Off-campus'}',
                  ),
                  subtitle: Text(
                    'Applied on: $date\n'
                    'Proof of residence: ${proofSubmitted ? 'Submitted (not stored in app)' : 'Not submitted'}'
                    '${adminComment.isNotEmpty ? '\nAdmin: $adminComment' : ''}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              );
            },
          );
        },
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
        currentIndex: 1,
        onDestinationSelected: (destination) => _navigate(context, destination),
      ),
    );
  }
}
