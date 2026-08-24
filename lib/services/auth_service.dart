import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sheets_services.dart';

enum UserRole { admin, guru, unauthorized, none }

class AuthService extends ChangeNotifier {
  final SheetsService _sheetsService = SheetsService();

  static const _kKeyEmail = 'auth_email';
  static const _kKeyPassword = 'auth_password';

  UserCredentials? currentUser;
  UserRole currentRole = UserRole.none;

  /// true selama proses cek sesi tersimpan saat app baru dibuka.
  /// UI (RoleRouter) pakai ini untuk menampilkan splash/loading dulu,
  /// supaya tidak sempat kelihatan LoginScreen sekilas sebelum auto-login.
  bool isRestoring = true;

  /// Dipanggil sekali saat app pertama kali dibuka. Cek apakah ada
  /// email+password tersimpan dari login sebelumnya, kalau ada langsung
  /// coba login ulang otomatis (silent, tanpa user perlu ketik lagi).
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString(_kKeyEmail);
      final savedPassword = prefs.getString(_kKeyPassword);

      if (savedEmail != null && savedPassword != null) {
        final result = await _sheetsService.login(savedEmail, savedPassword);
        if (result != null) {
          currentUser = result;
          currentRole = result.role == 'admin' ? UserRole.admin : UserRole.guru;
        }
        // Kalau login gagal (misal password diganti admin dari sisi lain),
        // biarkan currentRole tetap none -> user diarahkan ke LoginScreen lagi.
      }
    } catch (_) {
      // Tidak ada koneksi internet dsb saat startup -> biarkan user login manual.
    }
    isRestoring = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final result = await _sheetsService.login(email.trim(), password);
    if (result == null) {
      currentUser = null;
      currentRole = UserRole.unauthorized;
      notifyListeners();
      return false;
    }
    currentUser = result;
    currentRole = result.role == 'admin' ? UserRole.admin : UserRole.guru;

    // Simpan supaya login tetap bertahan walau app ditutup/di-kill.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeyEmail, email.trim());
    await prefs.setString(_kKeyPassword, password);

    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    currentUser = null;
    currentRole = UserRole.none;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyEmail);
    await prefs.remove(_kKeyPassword);

    notifyListeners();
  }
}