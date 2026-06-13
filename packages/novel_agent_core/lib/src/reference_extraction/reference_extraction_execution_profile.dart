import '../common/json_types.dart';
import 'reference_extraction_strategy_profile.dart';

class ReferenceExtractionExecutionProfile {
  const ReferenceExtractionExecutionProfile({
    required this.taskFamilyId,
    required this.executionMode,
    required this.instructionProfileId,
    required this.toolPermissionProfileId,
    this.requiresReviewer = true,
    this.strategyProfile = ReferenceExtractionStrategyProfiles.standard,
    this.metadata = const <String, Object?>{},
  });

  final String taskFamilyId;
  final String executionMode;
  final String instructionProfileId;
  final String toolPermissionProfileId;
  final bool requiresReviewer;
  final ReferenceExtractionStrategyProfile strategyProfile;
  final JsonMap metadata;

  ReferenceExtractionExecutionProfile copyWith({
    String? taskFamilyId,
    String? executionMode,
    String? instructionProfileId,
    String? toolPermissionProfileId,
    bool? requiresReviewer,
    ReferenceExtractionStrategyProfile? strategyProfile,
    JsonMap? metadata,
  }) {
    return ReferenceExtractionExecutionProfile(
      taskFamilyId: taskFamilyId ?? this.taskFamilyId,
      executionMode: executionMode ?? this.executionMode,
      instructionProfileId: instructionProfileId ?? this.instructionProfileId,
      toolPermissionProfileId:
          toolPermissionProfileId ?? this.toolPermissionProfileId,
      requiresReviewer: requiresReviewer ?? this.requiresReviewer,
      strategyProfile: strategyProfile ?? this.strategyProfile,
      metadata: metadata ?? this.metadata,
    );
  }
}
