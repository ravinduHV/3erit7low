import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class SignInSubmitted extends AuthEvent {
  final String email;
  final String password;

  const SignInSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String? fullName;
  final bool isAnonymous;

  const SignUpSubmitted({
    required this.email,
    required this.password,
    this.fullName,
    required this.isAnonymous,
  });

  @override
  List<Object?> get props => [email, password, fullName, isAnonymous];
}

class SignOutPressed extends AuthEvent {}

class ProfileSetupCompleted extends AuthEvent {
  final DateTime dateOfBirth;
  final String gender;
  final String sectionId;
  final DateTime joinedSectionAt;

  const ProfileSetupCompleted({
    required this.dateOfBirth,
    required this.gender,
    required this.sectionId,
    required this.joinedSectionAt,
  });

  @override
  List<Object?> get props => [dateOfBirth, gender, sectionId, joinedSectionAt];
}

class IdentityModeToggled extends AuthEvent {
  final bool isAnonymous;
  final String? fullName;
  final String? schoolName;
  final String? troopNumber;
  final String? district;
  final String? province;
  final String? registrationNumber;

  const IdentityModeToggled({
    required this.isAnonymous,
    this.fullName,
    this.schoolName,
    this.troopNumber,
    this.district,
    this.province,
    this.registrationNumber,
  });

  @override
  List<Object?> get props => [
        isAnonymous,
        fullName,
        schoolName,
        troopNumber,
        district,
        province,
        registrationNumber,
      ];
}
