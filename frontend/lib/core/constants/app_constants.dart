import 'package:flutter/foundation.dart';

class AppConstants {
  // If running on Android emulator, localhost is 10.0.2.2. If iOS or Web, it's localhost.
  static String get authBaseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
  }

  static String get apiBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8000'
        : 'http://localhost:8000';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
