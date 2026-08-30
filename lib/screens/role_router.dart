import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'guru/onboarding_screen.dart';
import 'login_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    switch (auth.currentRole) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.guru:
        return const OnboardingKelasMapelScreen();
      case UserRole.unauthorized:
      case UserRole.none:
        return const LoginScreen();
    }
  }
}