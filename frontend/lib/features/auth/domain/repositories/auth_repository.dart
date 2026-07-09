import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signIn(String email, String password);
  
  Future<UserEntity> signUp(
    String email,
    String password, {
    String? fullName,
    bool isAnonymous = false,
  });

  Future<UserEntity> syncUser(
    String token, {
    String? fullName,
    bool isAnonymous = false,
  });

  Future<UserEntity> getSession();

  Future<void> signOut();

  Future<UserEntity> updateProfile({
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    String? sectionId,
    DateTime? joinedSectionAt,
  });

  Future<UserEntity> updateIdentityMode({
    required bool isAnonymous,
    String? fullName,
    String? schoolName,
    String? troopNumber,
    String? district,
    String? province,
    String? registrationNumber,
  });
}
