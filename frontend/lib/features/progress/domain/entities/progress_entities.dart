import 'package:equatable/equatable.dart';

class RequirementProgressEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isMandatory;
  final bool evidenceRequired;
  final double? minAge;
  final double? maxAge;
  final int? minServiceMonths;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? earliestFinishDate;
  final String? notes;
  final bool isEligible;
  final String? reasonIneligible;

  const RequirementProgressEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isMandatory,
    required this.evidenceRequired,
    this.minAge,
    this.maxAge,
    this.minServiceMonths,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.earliestFinishDate,
    this.notes,
    required this.isEligible,
    this.reasonIneligible,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isMandatory,
        evidenceRequired,
        minAge,
        maxAge,
        minServiceMonths,
        status,
        startedAt,
        completedAt,
        earliestFinishDate,
        notes,
        isEligible,
        reasonIneligible,
      ];
}

class RequirementGroupProgressEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final bool isPool;
  final int minSelect;
  final int? maxSelect;
  final List<RequirementProgressEntity> requirements;
  final int selectedCount;
  final int completedCount;

  const RequirementGroupProgressEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isPool,
    required this.minSelect,
    this.maxSelect,
    required this.requirements,
    required this.selectedCount,
    required this.completedCount,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        isPool,
        minSelect,
        maxSelect,
        requirements,
        selectedCount,
        completedCount,
      ];
}

class AwardProgressEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? badgeImageUrl;
  final double? minAge;
  final double? maxAge;
  final int? minServiceMonths;
  final String? prerequisiteAwardId;
  final bool isOptional;
  final int? minMonthsAfterPrereqStarted;
  final bool startDateFollowsPrereq;
  final DateTime? startedAt;    // member's actual ScoutAward start date
  final DateTime? completedAt;  // member's actual ScoutAward completion date
  final List<RequirementGroupProgressEntity> groups;
  final double percentCompleted;
  final bool isCompleted;

  const AwardProgressEntity({
    required this.id,
    required this.name,
    this.description,
    this.badgeImageUrl,
    this.minAge,
    this.maxAge,
    this.minServiceMonths,
    this.prerequisiteAwardId,
    this.isOptional = false,
    this.minMonthsAfterPrereqStarted,
    this.startDateFollowsPrereq = true,
    this.startedAt,
    this.completedAt,
    required this.groups,
    required this.percentCompleted,
    required this.isCompleted,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        badgeImageUrl,
        minAge,
        maxAge,
        minServiceMonths,
        prerequisiteAwardId,
        isOptional,
        minMonthsAfterPrereqStarted,
        startDateFollowsPrereq,
        startedAt,
        completedAt,
        groups,
        percentCompleted,
        isCompleted,
      ];
}

class SectionProgressSummaryEntity extends Equatable {
  final String id;
  final String name;
  final String colorHex;
  final String? iconName;
  final List<AwardProgressEntity> awards;

  const SectionProgressSummaryEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    this.iconName,
    required this.awards,
  });

  @override
  List<Object?> get props => [id, name, colorHex, iconName, awards];
}

class RecommendationItemEntity extends Equatable {
  final String awardId;
  final String awardName;
  final String status;
  final String reason;
  final DateTime? targetCompletionDate;

  const RecommendationItemEntity({
    required this.awardId,
    required this.awardName,
    required this.status,
    required this.reason,
    this.targetCompletionDate,
  });

  @override
  List<Object?> get props => [awardId, awardName, status, reason, targetCompletionDate];
}

class PredictionEntity extends Equatable {
  final double currentAge;
  final int remainingDaysInSection;
  final String? highestAchievableAwardId;
  final String? highestAchievableAwardName;
  final bool isAgingOutWarning;
  final List<RecommendationItemEntity> recommendations;

  const PredictionEntity({
    required this.currentAge,
    required this.remainingDaysInSection,
    this.highestAchievableAwardId,
    this.highestAchievableAwardName,
    required this.isAgingOutWarning,
    required this.recommendations,
  });

  @override
  List<Object?> get props => [
        currentAge,
        remainingDaysInSection,
        highestAchievableAwardId,
        highestAchievableAwardName,
        isAgingOutWarning,
        recommendations,
      ];
}
