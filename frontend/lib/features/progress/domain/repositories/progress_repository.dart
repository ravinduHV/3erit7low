import '../entities/progress_entities.dart';

abstract class ProgressRepository {
  Future<SectionProgressSummaryEntity> getProgressSummary();
  Future<PredictionEntity> getPredictions();
  Future<void> startRequirement(String reqId, {DateTime? startedAt});
  Future<void> completeRequirement(String reqId, {DateTime? completedAt});
  Future<void> selectPoolRequirement(String groupId, String reqId);
  Future<void> removePoolRequirement(String groupId, String reqId);
}
