import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthRepositoryImpl(this._dio, this._secureStorage);

  @override
  Future<UserEntity> signIn(String email, String password) async {
    // 1. Call Node.js Auth proxy sign-in
    final response = await _dio.post(
      '${AppConstants.authBaseUrl}/api/auth/sign-in/email',
      data: {
        'email': email,
        'password': password,
      },
    );

    // 2. Extract token and user details from Better Auth response
    final sessionData = response.data['session'];
    final userData = response.data['user'];
    final token = sessionData['token'] as String;

    // 3. Save token locally
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);

    // 4. Sync session with the FastAPI Backend (local DB)
    return await syncUser(token, fullName: userData['name'], isAnonymous: false);
  }

  @override
  Future<UserEntity> signUp(
    String email,
    String password, {
    String? fullName,
    bool isAnonymous = false,
  }) async {
    // 1. Call Node.js Auth proxy sign-up
    final name = isAnonymous ? 'Scout' : (fullName ?? 'Scout');
    final response = await _dio.post(
      '${AppConstants.authBaseUrl}/api/auth/sign-up/email',
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );

    final sessionData = response.data['session'];
    final token = sessionData['token'] as String;

    // 2. Save token locally
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);

    // 3. Sync user with FastAPI Backend (specifying anonymous/known flag)
    return await syncUser(token, fullName: fullName, isAnonymous: isAnonymous);
  }

  @override
  Future<UserEntity> syncUser(
    String token, {
    String? fullName,
    bool isAnonymous = false,
  }) async {
    // Call FastAPI Backend /v1/auth/sync
    final response = await _dio.post(
      '${AppConstants.apiBaseUrl}/v1/auth/sync',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
      data: {
        'token': token,
        'is_anonymous': isAnonymous,
        'full_name': fullName,
      },
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserEntity> getSession() async {
    // 1. Read local token
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null) {
      throw Exception("No active session token found");
    }

    // 2. Retrieve session info from FastAPI backend
    final response = await _dio.get(
      '${AppConstants.apiBaseUrl}/v1/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> signOut() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token != null) {
      try {
        // Log out from Auth Proxy
        await _dio.post(
          '${AppConstants.authBaseUrl}/api/auth/sign-out',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } catch (_) {}
    }
    // Delete local tokens
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

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
    if (gender != null) {
      data['gender'] = gender;
    }
    if (profileImageUrl != null) {
      data['profile_image_url'] = profileImageUrl;
    }
    if (sectionId != null) {
      data['section_id'] = sectionId;
    }
    if (joinedSectionAt != null) {
      data['joined_section_at'] = joinedSectionAt.toIso8601String().split('T')[0];
    }

    final response = await _dio.patch(
      '${AppConstants.apiBaseUrl}/v1/users/me',
      data: data,
    );

    return UserModel.fromJson(response.data);
  }

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
}
