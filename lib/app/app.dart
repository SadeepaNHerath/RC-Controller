import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../theme/app_theme.dart';

class RCControllerApp extends StatelessWidget {
  const RCControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RC Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
