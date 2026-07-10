import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/progress_repository.dart';
import 'progress_event.dart';
import 'progress_state.dart';
import '../../../../core/network/error_handler.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final ProgressRepository _progressRepository;

  ProgressBloc(this._progressRepository) : super(ProgressInitial()) {
    on<ProgressFetchRequested>(_onProgressFetchRequested);
    on<RequirementStarted>(_onRequirementStarted);
    on<RequirementCompleted>(_onRequirementCompleted);
    on<RequirementReset>(_onRequirementReset);
    on<PoolRequirementSelected>(_onPoolRequirementSelected);
    on<PoolRequirementRemoved>(_onPoolRequirementRemoved);
  }

  Future<void> _onProgressFetchRequested(
    ProgressFetchRequested event,
    Emitter<ProgressState> emit,
  ) async {
    emit(ProgressLoading());
    try {
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onRequirementStarted(
    RequirementStarted event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _progressRepository.startRequirement(event.reqId, startedAt: event.startedAt);
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onRequirementCompleted(
    RequirementCompleted event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _progressRepository.completeRequirement(event.reqId, completedAt: event.completedAt);
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onPoolRequirementSelected(
    PoolRequirementSelected event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _progressRepository.selectPoolRequirement(event.groupId, event.reqId);
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onPoolRequirementRemoved(
    PoolRequirementRemoved event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _progressRepository.removePoolRequirement(event.groupId, event.reqId);
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onRequirementReset(
    RequirementReset event,
    Emitter<ProgressState> emit,
  ) async {
    try {
      await _progressRepository.deleteRequirement(event.reqId);
      final summary = await _progressRepository.getProgressSummary();
      emit(ProgressLoaded(summary));
    } catch (e) {
      emit(ProgressError(ErrorHandler.handle(e)));
    }
  }
}
