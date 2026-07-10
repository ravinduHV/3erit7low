import 'package:flutter/foundation.dart';

// ── Compile-time URL overrides (set via --dart-define) ────────────────────────
const String _kNeonAuthUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: '',
);
const String _kProductionApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

class AppConstants {
  // ── Neon Auth Base URL ────────────────────────────────────────────────────
  // Must be provided at build-time using --dart-define=AUTH_BASE_URL=https://...
  static String get authBaseUrl {
    if (_kNeonAuthUrl.isNotEmpty) return _kNeonAuthUrl;
    throw Exception(
      'AUTH_BASE_URL is not set. Please run or compile the app using:\n'
      '  --dart-define=AUTH_BASE_URL=https://<your-neonauth-domain>/neondb/auth'
    );
  }

  // ── Origin header for Neon Auth requests ─────────────────────────────────
  // Neon Auth requires an Origin header on every request.
  // For web this is sent automatically by the browser; for mobile we set it manually.
  static String get authOrigin {
    if (kIsWeb) return ''; // browser sets Origin automatically
    return AppConstants.apiBaseUrl; // use API URL as the trusted origin for mobile
  }

  // ── FastAPI Backend URL ───────────────────────────────────────────────────
  static String get apiBaseUrl {
    if (_kProductionApiUrl.isNotEmpty) return _kProductionApiUrl;
    if (kIsWeb) return 'http://localhost:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
