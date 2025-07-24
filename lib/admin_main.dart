import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_login_screen.dart';

void main() {
  runApp(const VMUruganAdminApp());
}

class VMUruganAdminApp extends StatelessWidget {
  const VMUruganAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VMUrugan Admin Portal',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AdminLoginScreen(),
    );
  }
}
