import 'dart:async';
import 'package:flutter/material.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication state provider managing user session, login, registration, and logout
class AuthProvider with ChangeNotifier {
  final IAuthService _authService;
  StreamSubscription<UserModel?>? _authSubscription;

  UserModel? _user;
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _errorMessage;

  AuthProvider({IAuthService? authService})
      : _authService = authService ??
            (FirebaseConfig.isRealFirebaseActive
                ? FirebaseAuthService()
                : MockAuthService()) {
    _initAuthListener();
  }

  // Getters
  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _user != null && _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;
  String? get errorMessage => _errorMessage;

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _status = AuthStatus.error;
      notifyListeners();
    });

    // Check initial user
    _authService.getCurrentUser().then((user) {
      if (_status == AuthStatus.initial) {
        _user = user;
        _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthFailureException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthFailureException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _errorMessage = null;
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthFailureException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
