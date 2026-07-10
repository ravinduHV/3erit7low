import 'package:flutter/foundation.dart';

// ── Compile-time URL overrides (set via --dart-define) ────────────────────────
// Auth now goes directly to the Neon Auth managed service (no local proxy).
// Example production build:
//   flutter build web \
//     --dart-define=AUTH_BASE_URL=https://ep-xxx.neonauth.c-2.ap-southeast-1.aws.neon.tech/neondb/auth \
//     --dart-define=API_BASE_URL=https://your-api.railway.app
const String _kProductionAuthUrl = String.fromEnvironment(
  'AUTH_BASE_URL',
  defaultValue: '',
);
const String _kProductionApiUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

// ── Neon Auth managed base URL (dev fallback) ─────────────────────────────────
// This is the live Neon Auth endpoint — same URL in dev and prod (it's managed).
const String _kNeonAuthDevUrl =
    'https://ep-winter-silence-aofak107.neonauth.c-2.ap-southeast-1.aws.neon.tech/neondb/auth';

class AppConstants {
  // ── Neon Auth Base URL ────────────────────────────────────────────────────
  // Flutter calls this directly for sign-up, sign-in, sign-out.
  // No localhost proxy needed — Neon Auth is a managed cloud service.
  static String get authBaseUrl {
    if (_kProductionAuthUrl.isNotEmpty) return _kProductionAuthUrl;
    return _kNeonAuthDevUrl;
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
