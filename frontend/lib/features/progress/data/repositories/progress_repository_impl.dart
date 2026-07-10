import 'package:dio/dio.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/entities/progress_entities.dart';
import '../models/progress_models.dart';
import '../../../../core/constants/app_constants.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final Dio _dio;

  ProgressRepositoryImpl(this._dio);

  @override
  Future<SectionProgressSummaryEntity> getProgressSummary() async {
    final response = await _dio.get('${AppConstants.apiBaseUrl}/v1/progress/summary');
    return SectionProgressSummaryModel.fromJson(response.data);
  }

  @override
  Future<PredictionEntity> getPredictions() async {
    final response = await _dio.get('${AppConstants.apiBaseUrl}/v1/progress/predictions');
    return PredictionModel.fromJson(response.data);
  }

  @override
  Future<void> startRequirement(String reqId, {DateTime? startedAt}) async {
    final data = startedAt != null
        ? {
            'started_at':
                '${startedAt.year}-${startedAt.month.toString().padLeft(2, '0')}-${startedAt.day.toString().padLeft(2, '0')}'
          }
        : null;
    await _dio.post(
      '${AppConstants.apiBaseUrl}/v1/progress/requirements/$reqId/start',
      data: data,
    );
  }

  @override
  Future<void> completeRequirement(String reqId, {DateTime? completedAt}) async {
    final data = completedAt != null
        ? {
            'completed_at':
                '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}'
          }
        : null;
    await _dio.post(
      '${AppConstants.apiBaseUrl}/v1/progress/requirements/$reqId/complete',
      data: data,
    );
  }

  @override
  Future<void> selectPoolRequirement(String groupId, String reqId) async {
    await _dio.post(
      '${AppConstants.apiBaseUrl}/v1/progress/pool-selections',
      data: {
        'requirement_group_id': groupId,
        'requirement_id': reqId,
      },
    );
  }

  @override
  Future<void> removePoolRequirement(String groupId, String reqId) async {
    await _dio.delete('${AppConstants.apiBaseUrl}/v1/progress/pool-selections/$groupId/$reqId');
  }
}
