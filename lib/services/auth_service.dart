import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user_model.dart';

/// Abstract contract for authentication operations ensuring UI never directly depends on Firebase SDK
abstract class IAuthService {
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}

/// Production implementation of IAuthService backed by FirebaseAuth
class FirebaseAuthService implements IAuthService {
  final fb_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthService({fb_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  UserModel? _mapFirebaseUser(fb_auth.User? user) {
    if (user == null) return null;
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName?.isNotEmpty == true
          ? user.displayName!
          : (user.email?.split('@').first ?? 'Spendly User'),
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _mapFirebaseUser(_firebaseAuth.currentUser);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailureException('Failed to create user account. Please try again.');
      }

      // Update profile with display name
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }

      return _mapFirebaseUser(user)!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthFailureException(_mapFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AuthFailureException(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const AuthFailureException('Authentication failed. User record not found.');
      }

      return _mapFirebaseUser(user)!;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthFailureException(_mapFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AuthFailureException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      throw AuthFailureException(_mapFirebaseAuthErrorMessage(e));
    } catch (e) {
      throw AuthFailureException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _mapFirebaseAuthErrorMessage(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please verify your credentials.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Please try again in a few minutes.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      default:
        return e.message ?? 'Authentication error occurred (${e.code}).';
    }
  }
}

/// In-memory mock authentication service for deterministic unit testing and fallback
class MockAuthService implements IAuthService {
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  final Map<String, String> _passwords = {}; // email -> password
  final Map<String, UserModel> _users = {}; // email -> UserModel

  MockAuthService({UserModel? initialUser}) : _currentUser = initialUser {
    if (initialUser != null) {
      _users[initialUser.email.toLowerCase()] = initialUser;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  @override
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_users.containsKey(normalizedEmail)) {
      throw const AuthFailureException('An account already exists with this email address.');
    }
    if (password.length < 6) {
      throw const AuthFailureException('Password must be at least 6 characters long.');
    }

    final newUser = UserModel(
      uid: 'mock_uid_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: displayName.trim().isNotEmpty ? displayName.trim() : 'Spendly User',
      createdAt: DateTime.now(),
    );

    _passwords[normalizedEmail] = password;
    _users[normalizedEmail] = newUser;
    _currentUser = newUser;
    _controller.add(_currentUser);
    return newUser;
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_users.containsKey(normalizedEmail)) {
      throw const AuthFailureException('No user found with this email address. Please register first.');
    }
    if (_passwords[normalizedEmail] != password) {
      throw const AuthFailureException('Invalid email or password. Please verify your credentials.');
    }

    _currentUser = _users[normalizedEmail];
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!_users.containsKey(normalizedEmail)) {
      throw const AuthFailureException('No account found for this email address.');
    }
    // Simulation succeeded
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}

/// Custom exception wrapping authentication failures cleanly
class AuthFailureException implements Exception {
  final String message;
  const AuthFailureException(this.message);

  @override
  String toString() => message;
}
