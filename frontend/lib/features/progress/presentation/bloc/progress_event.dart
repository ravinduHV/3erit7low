import 'package:equatable/equatable.dart';

abstract class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

class ProgressFetchRequested extends ProgressEvent {}

class RequirementStarted extends ProgressEvent {
  final String reqId;
  final DateTime? startedAt;
  const RequirementStarted(this.reqId, {this.startedAt});

  @override
  List<Object?> get props => [reqId, startedAt];
}

class RequirementCompleted extends ProgressEvent {
  final String reqId;
  final DateTime? completedAt;
  const RequirementCompleted(this.reqId, {this.completedAt});

  @override
  List<Object?> get props => [reqId, completedAt];
}

class PoolRequirementSelected extends ProgressEvent {
  final String groupId;
  final String reqId;

  const PoolRequirementSelected({required this.groupId, required this.reqId});

  @override
  List<Object?> get props => [groupId, reqId];
}

class PoolRequirementRemoved extends ProgressEvent {
  final String groupId;
  final String reqId;

  const PoolRequirementRemoved({required this.groupId, required this.reqId});

  @override
  List<Object?> get props => [groupId, reqId];
}
