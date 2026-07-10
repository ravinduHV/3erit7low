import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._dio, this._secureStorage);

  // ── Helper to build headers safely for Neon Auth ──────────────────────────
  Map<String, dynamic> _getAuthHeaders({String? token}) {
    final headers = <String, dynamic>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    // Only set Origin on mobile/desktop (browsers automatically handle and restrict it)
    if (!kIsWeb && AppConstants.authOrigin.isNotEmpty) {
      headers['Origin'] = AppConstants.authOrigin;
    }
    return headers;
  }

  // ── Sign In ───────────────────────────────────────────────────────────────
  @override
  Future<UserEntity> signIn(String email, String password) async {
    // 1. Sign in → Neon Auth returns an opaque session token
    final response = await _dio.post(
      '${AppConstants.authBaseUrl}/sign-in/email',
      options: Options(
        headers: _getAuthHeaders(),
        extra: {'withCredentials': true}, // Enable cross-origin cookies on Web
      ),
      data: {'email': email, 'password': password},
    );

    final sessionToken = response.data['token'] as String;

    // 2. Exchange session token for a signed JWT (EdDSA)
    final jwt = await _exchangeForJwt(sessionToken);

    // 3. Persist the JWT (used as Bearer for all FastAPI calls)
    await _secureStorage.write(key: AppConstants.tokenKey, value: jwt);

    // 4. Sync user into local FastAPI DB
    return await _syncToBackend(
      jwt: jwt,
      fullName: response.data['user']?['name'] as String?,
      isAnonymous: false,
    );
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────
  @override
  Future<UserEntity> signUp(
    String email,
    String password, {
    String? fullName,
    bool isAnonymous = false,
  }) async {
    // 1. Sign up → Neon Auth returns an opaque session token
    final name = isAnonymous ? 'Scout' : (fullName ?? 'Scout');
    final response = await _dio.post(
      '${AppConstants.authBaseUrl}/sign-up/email',
      options: Options(
        headers: _getAuthHeaders(),
        extra: {'withCredentials': true}, // Enable cross-origin cookies on Web
      ),
      data: {'email': email, 'password': password, 'name': name},
    );

    final sessionToken = response.data['token'] as String;

    // 2. Exchange session token for a signed JWT
    final jwt = await _exchangeForJwt(sessionToken);

    // 3. Persist JWT
    await _secureStorage.write(key: AppConstants.tokenKey, value: jwt);

    // 4. Sync to FastAPI
    return await _syncToBackend(
      jwt: jwt,
      fullName: fullName,
      isAnonymous: isAnonymous,
    );
  }

  // ── Public syncUser (called externally if needed) ─────────────────────────
  @override
  Future<UserEntity> syncUser(
    String token, {
    String? fullName,
    bool isAnonymous = false,
  }) async {
    return await _syncToBackend(
      jwt: token,
      fullName: fullName,
      isAnonymous: isAnonymous,
    );
  }

  // ── Get Session ───────────────────────────────────────────────────────────
  @override
  Future<UserEntity> getSession() async {
    final jwt = await _secureStorage.read(key: AppConstants.tokenKey);
    if (jwt == null) throw Exception('No active session token found');

    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/v1/users/me',
      options: Options(headers: {'Authorization': 'Bearer $jwt'}),
    );
    return UserModel.fromJson(response.data);
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────
  @override
  Future<void> signOut() async {
    final jwt = await _secureStorage.read(key: AppConstants.tokenKey);
    if (jwt != null) {
      try {
        await _dio.post(
          '${AppConstants.authBaseUrl}/sign-out',
          options: Options(headers: _getAuthHeaders(token: jwt)),
        );
      } catch (_) {
        // Best-effort — always clear local token
      }
    }
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  // ── Update Profile ────────────────────────────────────────────────────────
  @override
  Future<UserEntity> updateProfile({
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    String? sectionId,
    DateTime? joinedSectionAt,
  }) async {
    final data = <String, dynamic>{};
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
    }
    if (gender != null) data['gender'] = gender;
    if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;
    if (sectionId != null) data['section_id'] = sectionId;
    if (joinedSectionAt != null) {
      data['joined_section_at'] = joinedSectionAt.toIso8601String().split('T')[0];
    }

    final response = await _dio.patch(
      '${AppConstants.apiBaseUrl}/v1/users/me',
      data: data,
    );
    return UserModel.fromJson(response.data);
  }

  // ── Update Identity Mode ──────────────────────────────────────────────────
  @override
  Future<UserEntity> updateIdentityMode({
    required bool isAnonymous,
    String? fullName,
    String? schoolName,
    String? troopNumber,
    String? district,
    String? province,
    String? registrationNumber,
  }) async {
    final response = await _dio.patch(
      '${AppConstants.apiBaseUrl}/v1/users/me/identity',
      data: {
        'is_anonymous': isAnonymous,
        'full_name': fullName,
        'school_name': schoolName,
        'troop_number': troopNumber,
        'district': district,
        'province': province,
        'registration_number': registrationNumber,
      },
    );
    return UserModel.fromJson(response.data);
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Exchanges a Neon Auth opaque session token for a signed EdDSA JWT.
  ///
  /// Neon Auth flow:
  ///   POST /sign-up or /sign-in → returns opaque session token (plain string)
  ///   GET  /token with "Authorization: Bearer SESSION_TOKEN" → returns [token] (JWT)
  Future<String> _exchangeForJwt(String sessionToken) async {
    try {
      final headers = _getAuthHeaders(token: sessionToken);

      final response = await _dio.get(
        '${AppConstants.authBaseUrl}/token',
        options: Options(
          headers: headers,
          // on web, this forces the browser to send the Set-Cookie session token
          extra: {'withCredentials': true},
        ),
      );

      final jwt = response.data['token'];
      if (jwt is! String || jwt.isEmpty) {
        throw Exception('Failed to retrieve JWT from Neon Auth /token endpoint');
      }
      return jwt;
    } on DioException {
      rethrow;
    }
  }

  /// POST /v1/auth/sync — JWT in Authorization header, not in body.
  Future<UserEntity> _syncToBackend({
    required String jwt,
    String? fullName,
    bool isAnonymous = false,
  }) async {
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/v1/auth/sync',
      options: Options(headers: {'Authorization': 'Bearer $jwt'}),
      data: {
        'is_anonymous': isAnonymous,
        'full_name': fullName,
      },
    );
    return UserModel.fromJson(response.data);
  }
}
