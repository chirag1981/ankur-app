import 'package:flutter/material.dart';
import '../features/customers/customer_list_screen.dart';
import 'theme/app_theme.dart';

class InvisibleGrillsApp extends StatelessWidget {
  const InvisibleGrillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invisible Grills',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const CustomerListScreen(),
    );
  }
}
