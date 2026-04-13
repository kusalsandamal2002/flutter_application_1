import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/ovens/presentation/pages/oven_tracker_home_page.dart';

class LaugfsSmartTrackerApp extends StatelessWidget {
  const LaugfsSmartTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laugfs Smart Tracker Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OvenTrackerHomePage(),
    );
  }
}