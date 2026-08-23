import 'package:flutter/material.dart';

import 'sheets_services.dart';

enum UserRole { admin, guru, unauthorized, none }

class AuthService extends ChangeNotifier {
  final SheetsService _sheetsService = SheetsService();

  UserCredentials? currentUser;
  UserRole currentRole = UserRole.none;

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
    notifyListeners();
    return true;
  }

  void signOut() {
    currentUser = null;
    currentRole = UserRole.none;
    notifyListeners();
  }
}