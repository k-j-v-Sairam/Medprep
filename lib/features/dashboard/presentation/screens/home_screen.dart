// Legacy file — superseded by SyllabusScreen in the MedPrep overhaul.
// Kept as a clean stub so the project compiles.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Text('Home', style: AppTheme.headlineMd()),
      ),
    );
  }
}
