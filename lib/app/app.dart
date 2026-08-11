import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../theme/app_theme.dart';
import 'app_info.dart';

class HelmRcApp extends StatelessWidget {
  const HelmRcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
