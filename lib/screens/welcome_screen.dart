import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../theme/app_palette.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/welcome_bus.png',
                      width: 360,
                      height: 220,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  Positioned(
                    right: 34,
                    top: 90,
                    child: Container(
                      width: 128,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppPalette.card.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Campus Transit',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.navy),
              ),
              const Text(
                'Skip the Lines. Secure Your Ride',
                style: TextStyle(fontSize: 16, color: AppPalette.mutedText),
              ),
              const SizedBox(height: 48),

              const Text(
                'Continue as:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              // Student Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.navy,
                    foregroundColor: AppPalette.creamLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.school, size: 26),
                  label: const Text('Student', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(isAdminLogin: false)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Admin Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.navy,
                    side: const BorderSide(color: AppPalette.navy, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.admin_panel_settings, size: 26),
                  label: const Text('Admin', style: TextStyle(fontSize: 18)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(isAdminLogin: true)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
