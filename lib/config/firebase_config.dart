import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Safe Firebase initialization manager that binds DefaultFirebaseOptions
/// while preserving explicit development mock fallback and visible error reporting.
class FirebaseConfig {
  FirebaseConfig._();

  static bool _isInitialized = false;
  static String? _initializationError;

  /// Whether Firebase SDK was successfully initialized on a supported platform
  static bool get isInitialized => _isInitialized;

  /// Human-readable initialization error or unconfigured warning (if any)
  static String? get initializationError => _initializationError;

  /// Optional development override to test offline/mock mode even when Firebase is initialized
  static bool forceMockMode = false;

  /// Returns true only when real Firebase is active and mock mode is not forced
  static bool get isRealFirebaseActive => _isInitialized && !forceMockMode;

  /// Active Firebase project ID (spendly-18e90) or null if unconfigured
  static String? get activeProjectId {
    if (!_isInitialized) return null;
    return 'spendly-18e90';
  }

  /// Initializes Firebase safely with try/catch to ensure the app continues working
  /// even when Firebase configuration or network credentials have not yet been provided.
  static Future<bool> initializeSafely() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _isInitialized = true;
        _initializationError = null;
        return true;
      }

      // Check if current platform is configured in DefaultFirebaseOptions
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        _isInitialized = true;
        _initializationError = null;
        debugPrint(
          '[FirebaseConfig] Real Firebase initialized successfully for platform '
          'using project: $activeProjectId',
        );
        return true;
      } else {
        _isInitialized = false;
        _initializationError =
            'Platform ($defaultTargetPlatform) is not configured in FlutterFire CLI. '
            'Spendly will operate in explicit development mock fallback.';
        debugPrint('[FirebaseConfig] $_initializationError');
        return false;
      }
    } catch (e) {
      _isInitialized = false;
      _initializationError = e.toString();
      debugPrint(
        '[FirebaseConfig] Firebase initialization failed: $e.\n'
        'Spendly will operate in local development mock fallback mode.',
      );
      return false;
    }
  }
}
