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

    switch (auth.currentRole) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.guru:
        return const OnboardingKelasMapelScreen();
      case UserRole.unauthorized:
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Login gagal. Cek kembali email/password.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        );
      case UserRole.none:
        return const LoginScreen();
    }
  }
}