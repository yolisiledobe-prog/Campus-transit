import 'package:flutter/material.dart';
import '../widgets/student_bottom_navigation_bar.dart';
import 'application_form_screen.dart';
import 'application_history_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import '../theme/app_palette.dart';

class ScheduleScreen extends StatelessWidget {
  final String residence;
  final String campus;
  final String userId;
  final Map<String, dynamic> userData;

  const ScheduleScreen({
    super.key,
    required this.residence,
    required this.campus,
    required this.userId,
    required this.userData,
  });

  void _navigate(BuildContext context, int destination) {
    if (destination == 3) return;
    if (destination == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
      return;
    }

    final screen = switch (destination) {
      1 => ApplicationHistoryScreen(userId: userId, userData: userData),
      2 => ApplicationFormScreen(userData: userData),
      4 => ProfileScreen(userData: userData),
      _ => const SizedBox.shrink(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  static const _navy = AppPalette.navy;
  static const _timesToCampus = ['06:30', '08:00', '11:00'];
  static const _timesToTown = ['11:00', '13:00', '15:00', '17:30'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Schedule'),
        backgroundColor: _navy,
        foregroundColor: AppPalette.creamLight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: AppPalette.cream,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppPalette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _navy,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: AppPalette.creamLight,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time of Buses',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Bus departure times for student transportation.',
                              style: TextStyle(color: AppPalette.mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RouteSummary(residence: residence, campus: campus),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final panelWidth = constraints.maxWidth >= 680
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: panelWidth,
                            child: const _TimePanel(
                              eyebrow: 'TOWN PICKUP LOCATIONS → CAMPUS',
                              title: 'From Town to Campus',
                              times: _timesToCampus,
                            ),
                          ),
                          SizedBox(
                            width: panelWidth,
                            child: const _TimePanel(
                              eyebrow: 'CAMPUS → TOWN PICKUP LOCATIONS',
                              title: 'From Campus to Town',
                              times: _timesToTown,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Please arrive at your pickup point a few minutes before departure.',
              style: TextStyle(color: AppPalette.mutedText),
            ),
          ),
        ],
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
        currentIndex: 3,
        onDestinationSelected: (destination) => _navigate(context, destination),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final String residence;
  final String campus;

  const _RouteSummary({required this.residence, required this.campus});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        children: [
          _RouteDetail(label: 'START', value: residence),
          const _RouteDetail(label: 'PICKUP STOPS', value: '3 Stops'),
          _RouteDetail(label: 'DESTINATION', value: campus),
        ],
      ),
    );
  }
}

class _RouteDetail extends StatelessWidget {
  final String label;
  final String value;

  const _RouteDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppPalette.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppPalette.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimePanel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final List<String> times;

  const _TimePanel({
    required this.eyebrow,
    required this.title,
    required this.times,
  });

  String _periodFor(String time) {
    final hour = int.parse(time.split(':').first);
    return hour < 12 ? 'Morning' : 'Afternoon';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: AppPalette.slate,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppPalette.navy,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: times
                .map(
                  (time) => Container(
                    width: 86,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.creamLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          time,
                          style: const TextStyle(
                            color: AppPalette.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _periodFor(time),
                          style: const TextStyle(
                            color: AppPalette.mutedText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
