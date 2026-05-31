import 'opening_missing_requirement.dart';

class OpeningReadinessAssessment {
  const OpeningReadinessAssessment({
    required this.canStartLongTask,
    required this.canStartInteractiveSession,
    required this.missingRequirements,
    this.effectiveModeId = '',
    this.effectiveRuntimeBaselineId = '',
  });

  final bool canStartLongTask;
  final bool canStartInteractiveSession;
  final List<OpeningMissingRequirement> missingRequirements;
  final String effectiveModeId;
  final String effectiveRuntimeBaselineId;

  bool get isReady => canStartLongTask || canStartInteractiveSession;
}
