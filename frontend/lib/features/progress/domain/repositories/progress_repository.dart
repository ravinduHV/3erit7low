import '../entities/progress_entities.dart';

abstract class ProgressRepository {
  Future<SectionProgressSummaryEntity> getProgressSummary();
  Future<PredictionEntity> getPredictions();
  Future<void> startRequirement(String reqId, {DateTime? startedAt});
  Future<void> completeRequirement(String reqId, {DateTime? completedAt});
  Future<void> selectPoolRequirement(String groupId, String reqId);
  Future<void> removePoolRequirement(String groupId, String reqId);
  Future<void> deleteRequirement(String reqId);

  /// Mark an award as completed (with optional backdated date).
  /// If [propagateToParents] is true, auto-completes uncompleted prerequisite chain.
  Future<List<String>> completeAward(
    String awardId, {
    DateTime? completedAt,
    bool propagateToParents = true,
  });

  /// Member sets custom start and/or completion dates for an award.
  Future<void> updateAwardDates(
    String awardId, {
    DateTime? startedAt,
    DateTime? completedAt,
  });
}
