import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request(); // 🔥 IMPORTANT

  runApp(const LaugfsSmartTrackerApp());
}