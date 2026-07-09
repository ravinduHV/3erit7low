import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/network/error_handler.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<SignInSubmitted>(_onSignInSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<SignOutPressed>(_onSignOutPressed);
    on<ProfileSetupCompleted>(_onProfileSetupCompleted);
    on<IdentityModeToggled>(_onIdentityModeToggled);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getSession();
      if (user.sectionId == null) {
        emit(OnboardingRequired(user));
      } else {
        emit(Authenticated(user));
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSignInSubmitted(
    SignInSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signIn(event.email, event.password);
      if (user.sectionId == null) {
        emit(OnboardingRequired(user));
      } else {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.signUp(
        event.email,
        event.password,
        fullName: event.fullName,
        isAnonymous: event.isAnonymous,
      );
      if (user.sectionId == null) {
        emit(OnboardingRequired(user));
      } else {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onSignOutPressed(
    SignOutPressed event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onProfileSetupCompleted(
    ProfileSetupCompleted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateProfile(
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
        sectionId: event.sectionId,
        joinedSectionAt: event.joinedSectionAt,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onIdentityModeToggled(
    IdentityModeToggled event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.updateIdentityMode(
        isAnonymous: event.isAnonymous,
        fullName: event.fullName,
        schoolName: event.schoolName,
        troopNumber: event.troopNumber,
        district: event.district,
        province: event.province,
        registrationNumber: event.registrationNumber,
      );
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(ErrorHandler.handle(e)));
    }
  }
}
