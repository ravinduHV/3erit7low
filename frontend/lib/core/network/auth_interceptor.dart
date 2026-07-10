import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

/// Automatically injects the Bearer token for FastAPI backend requests.
///
/// Neon Auth requests do NOT get the token injected here — they manage
/// their own auth headers (sign-in/sign-up don't need a pre-existing token,
/// and sign-out passes it explicitly in the repository).
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Identify if request is going to Neon Auth managed service.
    // If it contains the auth base URL, it is an auth request.
    final fullUrl = options.uri.toString();
    final isNeonAuth = fullUrl.startsWith(AppConstants.authBaseUrl) || 
                       options.path.startsWith(AppConstants.authBaseUrl);

    // 2. If it is NOT a Neon Auth request, it is a FastAPI backend request.
    if (!isNeonAuth) {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      if (token != null && !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return super.onRequest(options, handler);
  }
}
