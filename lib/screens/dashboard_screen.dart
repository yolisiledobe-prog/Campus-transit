import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'application_form_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'application_history_screen.dart';
import '../widgets/student_bottom_navigation_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../theme/app_palette.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _downloadSticker(
    BuildContext context, {
    required String firstName,
    required String lastName,
    required String studentNumber,
    required String residence,
    required String campus,
  }) async {
    try {
      final document = pw.Document();
      const navy = PdfColor.fromInt(0xFFA77BD0);
      const greenBackground = PdfColor.fromInt(0xFFE8D8F0);
      const greenText = PdfColor.fromInt(0xFF718D70);

      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: navy, width: 3),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 18),
                  color: navy,
                  child: pw.Text(
                    'STUDENT BUS',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColor.fromInt(0xFFFAF4FC),
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'OFFICIAL BUS STICKER',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: navy,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Text(
                  '$firstName $lastName',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.Text(
                  'STUDENT NUMBER',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF857390),
                    fontSize: 11,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  studentNumber,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Route: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: residence),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Campus: ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.TextSpan(text: campus),
                    ],
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 16),
                  color: greenBackground,
                  child: pw.Text(
                    'APPLICATION APPROVED',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: greenText,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 28),
                pw.Text(
                  'Student Transportation System',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColor.fromInt(0xFF857390),
                    fontSize: 11,
                  ),
                ),
                pw.Spacer(),
              ],
            ),
          ),
        ),
      );

      final safeStudentNumber =
          studentNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      await Printing.sharePdf(
        bytes: await document.save(),
        filename: 'student_bus_sticker_$safeStudentNumber.pdf',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create sticker PDF: $e')),
      );
    }
  }

  void _openStudentDestination(
    BuildContext context,
    int destination,
    Map<String, dynamic> userData,
    String userId,
  ) {
    if (destination == 0) return;

    final Widget screen = switch (destination) {
      1 => ApplicationHistoryScreen(userId: userId, userData: userData),
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Transit - Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
              );
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('No user logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const Center(
                      child: Text('User profile data not found.'));
                }

                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                String firstName = userData['firstName'] ?? 'Student';
                String lastName = userData['lastName'] ?? '';
                String studentNumber = userData['studentNumber'] ?? 'N/A';
                String residence = userData['residence'] ?? 'Not selected';

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // --- Profile Header Card ---
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: AppPalette.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: AppPalette.creamLight,
                            child: Icon(Icons.person,
                                size: 36, color: AppPalette.navy),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$firstName $lastName',
                                  style: const TextStyle(
                                    color: AppPalette.creamLight,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Student No: $studentNumber',
                                  style: const TextStyle(
                                    color: AppPalette.cream,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Residence: $residence',
                                  style: const TextStyle(
                                    color: AppPalette.beige,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('transport_applications')
                          .where('uid', isEqualTo: currentUser.uid)
                          .snapshots(),
                      builder: (context, appSnapshot) {
                        if (appSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        var docs =
                            appSnapshot.hasData ? appSnapshot.data!.docs : [];
                        if (docs.isNotEmpty) {
                          docs.sort((a, b) {
                            var tA =
                                (a.data() as Map<String, dynamic>)['appliedAt']
                                    as Timestamp?;
                            var tB =
                                (b.data() as Map<String, dynamic>)['appliedAt']
                                    as Timestamp?;
                            if (tA == null || tB == null) return 0;
                            return tB.compareTo(tA);
                          });
                        }

                        var latestDoc = docs.isNotEmpty ? docs.first : null;
                        var latestApp =
                            latestDoc?.data() as Map<String, dynamic>?;
                        String status = latestApp != null
                            ? latestApp['status']
                            : 'Not Applied';
                        String adminComment =
                            latestApp?['adminComment'] as String? ?? '';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Digital Sticker Pass if Approved ---
                            if (status == 'Approved') ...[
                              Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 380),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppPalette.card,
                                      border: Border.all(
                                        color: AppPalette.navy,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppPalette.text.withAlpha(30),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          color: AppPalette.navy,
                                          child: const Text(
                                            'STUDENT BUS',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppPalette.creamLight,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'OFFICIAL BUS STICKER',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppPalette.navy,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Text(
                                          '$firstName $lastName',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                            color: AppPalette.text,
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'STUDENT NUMBER',
                                          style: TextStyle(
                                            color: AppPalette.mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          studentNumber,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: AppPalette.text,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text.rich(
                                            TextSpan(
                                              style: const TextStyle(
                                                color: AppPalette.text,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: 'Route: ',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextSpan(text: residence),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text.rich(
                                            TextSpan(
                                              style: const TextStyle(
                                                color: AppPalette.text,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text: 'Campus: ',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                TextSpan(
                                                  text: userData['campus'] ??
                                                      'Buffalo City Campus',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          color: AppPalette.beige,
                                          child: const Text(
                                            'APPLICATION APPROVED',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppPalette.approved,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Student Transportation System',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppPalette.mutedText,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 36),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: OutlinedButton.icon(
                                    onPressed: () => _downloadSticker(
                                      context,
                                      firstName: firstName,
                                      lastName: lastName,
                                      studentNumber: studentNumber,
                                      residence: residence,
                                      campus: userData['campus'] ??
                                          'Buffalo City Campus',
                                    ),
                                    icon: const Icon(Icons.download),
                                    label:
                                        const Text('Download Sticker as PDF'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // --- Status & Always-Visible Apply Button Card ---
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Transport Pass Status',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppPalette.navy),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Current Status: $status',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500)),
                                        Chip(
                                          label: Text(status,
                                              style: const TextStyle(
                                                  color:
                                                      AppPalette.creamLight)),
                                          backgroundColor: status == 'Approved'
                                              ? AppPalette.approved
                                              : status == 'Pending'
                                                  ? AppPalette.pending
                                                  : AppPalette.rejected,
                                        ),
                                      ],
                                    ),
                                    if (adminComment.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppPalette.cream,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: AppPalette.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Message from the admin',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(adminComment),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppPalette.navy,
                                          foregroundColor:
                                              AppPalette.creamLight,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ApplicationFormScreen(
                                                userData: userData,
                                                applicationId: latestDoc?.id,
                                                existingApplication: latestApp,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          latestDoc == null
                                              ? 'Apply for Transport'
                                              : 'Edit Application',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: currentUser == null
          ? null
          : FloatingActionButton(
              tooltip: 'Create transport application',
              onPressed: () {
                final userId = currentUser.uid;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Apply')),
                            body: Center(
                              child: Text(
                                  'Could not load your profile: ${snapshot.error}'),
                            ),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Scaffold(
                            body: Center(
                                child: Text('User profile data not found.')),
                          );
                        }
                        return ApplicationFormScreen(
                          userData:
                              snapshot.data!.data() as Map<String, dynamic>,
                        );
                      },
                    ),
                  ),
                );
              },
              backgroundColor: AppPalette.navy,
              foregroundColor: AppPalette.creamLight,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: currentUser == null
          ? null
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                return StudentBottomNavigationBar(
                  currentIndex: 0,
                  onDestinationSelected: (destination) =>
                      _openStudentDestination(
                    context,
                    destination,
                    userData,
                    currentUser.uid,
                  ),
                );
              },
            ),
    );
  }
}
