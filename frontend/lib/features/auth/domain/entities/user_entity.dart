import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final bool isAnonymous;
  final String? displayName;
  final String? fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;
  final String? registrationNumber;
  final String? schoolName;
  final String? troopNumber;
  final String? district;
  final String? province;
  final String? sectionId;
  final String role;
  final DateTime? joinedSectionAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.isAnonymous,
    this.displayName,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    this.registrationNumber,
    this.schoolName,
    this.troopNumber,
    this.district,
    this.province,
    this.sectionId,
    required this.role,
    this.joinedSectionAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        isAnonymous,
        displayName,
        fullName,
        dateOfBirth,
        gender,
        profileImageUrl,
        registrationNumber,
        schoolName,
        troopNumber,
        district,
        province,
        sectionId,
        role,
        joinedSectionAt,
      ];
}
