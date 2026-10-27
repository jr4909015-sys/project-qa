import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _restoreSession();
  }

  final AuthService _service;
  UserModel? user;
  bool isLoading = false;
  bool isRestoring = true;
  String? error;

  Future<void> _restoreSession() async {
    try {
      user = await _service.restoreSession();
    } catch (_) {
      await _service.logout();
      user = null;
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      user = await _service.login(username, password);
      return true;
    } catch (exception) {
      error = exception.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(Map<String, Object?> details) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.register(details);
      return true;
    } catch (exception) {
      error = exception.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _service.logout();
    user = null;
    notifyListeners();
  }

  Future<void> reloadProfile() async {
    user = await _service.currentUser();
    notifyListeners();
  }
}