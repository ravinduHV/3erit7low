import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required String id,
    required String email,
    required bool isAnonymous,
    String? displayName,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    String? registrationNumber,
    String? schoolName,
    String? troopNumber,
    String? district,
    String? province,
    String? sectionId,
    required String role,
    DateTime? joinedSectionAt,
  }) : super(
          id: id,
          email: email,
          isAnonymous: isAnonymous,
          displayName: displayName,
          fullName: fullName,
          dateOfBirth: dateOfBirth,
          gender: gender,
          profileImageUrl: profileImageUrl,
          registrationNumber: registrationNumber,
          schoolName: schoolName,
          troopNumber: troopNumber,
          district: district,
          province: province,
          sectionId: sectionId,
          role: role,
          joinedSectionAt: joinedSectionAt,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      isAnonymous: (json['is_anonymous'] as bool?) ?? false,
      displayName: json['display_name'] as String?,
      fullName: json['full_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      registrationNumber: json['registration_number'] as String?,
      schoolName: json['school_name'] as String?,
      troopNumber: json['troop_number'] as String?,
      district: json['district'] as String?,
      province: json['province'] as String?,
      sectionId: json['section_id'] as String?,
      role: (json['role'] as String?) ?? 'scout',
      joinedSectionAt: json['joined_section_at'] != null
          ? DateTime.parse(json['joined_section_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'is_anonymous': isAnonymous,
      'display_name': displayName,
      'full_name': fullName,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'profile_image_url': profileImageUrl,
      'registration_number': registrationNumber,
      'school_name': schoolName,
      'troop_number': troopNumber,
      'district': district,
      'province': province,
      'section_id': sectionId,
      'role': role,
      'joined_section_at': joinedSectionAt?.toIso8601String().split('T')[0],
    };
  }
}
