import 'package:flutter/foundation.dart';

// Production URLs — set these when you deploy your backend services.
// For local development the app falls back to localhost automatically.
const String _kProductionAuthUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: '', // set via --dart-define=AUTH_BASE_URL=https://your-auth.vercel.app
);
const String _kProductionApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '', // set via --dart-define=API_BASE_URL=https://your-api.railway.app
);

class AppConstants {
  // ── Auth Service URL ──────────────────────────────────────────────────────
  static String get authBaseUrl {
    // 1. Use compile-time override if provided (production builds via --dart-define)
    if (_kProductionAuthUrl.isNotEmpty) return _kProductionAuthUrl;
    // 2. Local development fallback
    if (kIsWeb) return 'http://localhost:3000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  // ── FastAPI Backend URL ───────────────────────────────────────────────────
  static String get apiBaseUrl {
    // 1. Use compile-time override if provided (production builds via --dart-define)
    if (_kProductionApiUrl.isNotEmpty) return _kProductionApiUrl;
    // 2. Local development fallback
    if (kIsWeb) return 'http://localhost:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
