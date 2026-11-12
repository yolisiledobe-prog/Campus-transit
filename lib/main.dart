import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_palette.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CampusTransitApp());
}

class CampusTransitApp extends StatelessWidget {
  const CampusTransitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Transit',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppPalette.navy,
          primary: AppPalette.navy,
          secondary: AppPalette.rejected,
          surface: AppPalette.card,
          error: AppPalette.rejected,
        ),
        scaffoldBackgroundColor: AppPalette.creamLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppPalette.cream,
          foregroundColor: AppPalette.navyDeep,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppPalette.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppPalette.border),
          ),
        ),
        dividerColor: AppPalette.border,
        inputDecorationTheme: InputDecorationTheme(
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppPalette.navy, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppPalette.navy,
            foregroundColor: AppPalette.creamLight,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppPalette.navy,
          foregroundColor: AppPalette.creamLight,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppPalette.navyDeep,
          contentTextStyle: TextStyle(color: AppPalette.creamLight),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}
