import 'package:equatable/equatable.dart';
import '../../domain/entities/progress_entities.dart';

abstract class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final SectionProgressSummaryEntity summary;

  const ProgressLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class ProgressError extends ProgressState {
  final String message;

  const ProgressError(this.message);

  @override
  List<Object?> get props => [message];
}
