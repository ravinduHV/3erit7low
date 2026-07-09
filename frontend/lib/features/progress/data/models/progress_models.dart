import '../../domain/entities/progress_entities.dart';

class RequirementProgressModel extends RequirementProgressEntity {
  const RequirementProgressModel({
    required String id,
    required String name,
    String? description,
    required bool isMandatory,
    required bool evidenceRequired,
    double? minAge,
    double? maxAge,
    int? minServiceMonths,
    required String status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? earliestFinishDate,
    String? notes,
    required bool isEligible,
    String? reasonIneligible,
  }) : super(
          id: id,
          name: name,
          description: description,
          isMandatory: isMandatory,
          evidenceRequired: evidenceRequired,
          minAge: minAge,
          maxAge: maxAge,
          minServiceMonths: minServiceMonths,
          status: status,
          startedAt: startedAt,
          completedAt: completedAt,
          earliestFinishDate: earliestFinishDate,
          notes: notes,
          isEligible: isEligible,
          reasonIneligible: reasonIneligible,
        );

  factory RequirementProgressModel.fromJson(Map<String, dynamic> json) {
    return RequirementProgressModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isMandatory: (json['is_mandatory'] as bool?) ?? true,
      evidenceRequired: (json['evidence_required'] as bool?) ?? false,
      minAge: json['min_age'] != null ? (json['min_age'] as num).toDouble() : null,
      maxAge: json['max_age'] != null ? (json['max_age'] as num).toDouble() : null,
      minServiceMonths: json['min_service_months'] as int?,
      status: (json['status'] as String?) ?? 'not_started',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      earliestFinishDate: json['earliest_finish_date'] != null ? DateTime.parse(json['earliest_finish_date'] as String) : null,
      notes: json['notes'] as String?,
      isEligible: (json['is_eligible'] as bool?) ?? true,
      reasonIneligible: json['reason_ineligible'] as String?,
    );
  }
}

class RequirementGroupProgressModel extends RequirementGroupProgressEntity {
  const RequirementGroupProgressModel({
    required String id,
    required String name,
    String? description,
    required bool isPool,
    required int minSelect,
    int? maxSelect,
    required List<RequirementProgressModel> requirements,
    required int selectedCount,
    required int completedCount,
  }) : super(
          id: id,
          name: name,
          description: description,
          isPool: isPool,
          minSelect: minSelect,
          maxSelect: maxSelect,
          requirements: requirements,
          selectedCount: selectedCount,
          completedCount: completedCount,
        );

  factory RequirementGroupProgressModel.fromJson(Map<String, dynamic> json) {
    final reqsList = (json['requirements'] as List<dynamic>?) ?? [];
    final requirements = reqsList
        .map((r) => RequirementProgressModel.fromJson(r as Map<String, dynamic>))
        .toList();

    return RequirementGroupProgressModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPool: (json['is_pool'] as bool?) ?? false,
      minSelect: (json['min_select'] as int?) ?? 1,
      maxSelect: json['max_select'] as int?,
      requirements: requirements,
      selectedCount: (json['selected_count'] as int?) ?? 0,
      completedCount: (json['completed_count'] as int?) ?? 0,
    );
  }
}

class AwardProgressModel extends AwardProgressEntity {
  const AwardProgressModel({
    required String id,
    required String name,
    String? description,
    String? badgeImageUrl,
    double? minAge,
    double? maxAge,
    int? minServiceMonths,
    required List<RequirementGroupProgressModel> groups,
    required double percentCompleted,
    required bool isCompleted,
  }) : super(
          id: id,
          name: name,
          description: description,
          badgeImageUrl: badgeImageUrl,
          minAge: minAge,
          maxAge: maxAge,
          minServiceMonths: minServiceMonths,
          groups: groups,
          percentCompleted: percentCompleted,
          isCompleted: isCompleted,
        );

  factory AwardProgressModel.fromJson(Map<String, dynamic> json) {
    final groupsList = (json['groups'] as List<dynamic>?) ?? [];
    final groups = groupsList
        .map((g) => RequirementGroupProgressModel.fromJson(g as Map<String, dynamic>))
        .toList();

    return AwardProgressModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      badgeImageUrl: json['badge_image_url'] as String?,
      minAge: json['min_age'] != null ? (json['min_age'] as num).toDouble() : null,
      maxAge: json['max_age'] != null ? (json['max_age'] as num).toDouble() : null,
      minServiceMonths: json['min_service_months'] as int?,
      groups: groups,
      percentCompleted: (json['percent_completed'] as num?)?.toDouble() ?? 0.0,
      isCompleted: (json['is_completed'] as bool?) ?? false,
    );
  }
}

class SectionProgressSummaryModel extends SectionProgressSummaryEntity {
  const SectionProgressSummaryModel({
    required String id,
    required String name,
    required String colorHex,
    String? iconName,
    required List<AwardProgressModel> awards,
  }) : super(
          id: id,
          name: name,
          colorHex: colorHex,
          iconName: iconName,
          awards: awards,
        );

  factory SectionProgressSummaryModel.fromJson(Map<String, dynamic> json) {
    final awardsList = (json['awards'] as List<dynamic>?) ?? [];
    final awards = awardsList
        .map((a) => AwardProgressModel.fromJson(a as Map<String, dynamic>))
        .toList();

    return SectionProgressSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: (json['color_hex'] as String?) ?? '#1B4332',
      iconName: json['icon_name'] as String?,
      awards: awards,
    );
  }
}
