import 'opening_readiness_assessment.dart';
import 'opening_session_state.dart';
import 'opening_suggested_action.dart';

class OpeningOrchestrationResult {
  const OpeningOrchestrationResult({
    required this.state,
    required this.readiness,
    required this.suggestedActions,
  });

  final OpeningSessionState state;
  final OpeningReadinessAssessment readiness;
  final List<OpeningSuggestedAction> suggestedActions;
}
