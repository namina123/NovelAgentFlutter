import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectInformationResearchCoordinatorResult {
  const ProjectInformationResearchCoordinatorResult({
    required this.requestId,
    required this.requestState,
    this.executedNetwork = false,
    this.executedImport = false,
    this.awaitUserConfirmation = false,
    this.blocked = false,
    this.summary = '',
    this.changedPaths = const <String>[],
    this.blockedReason = '',
    this.gatewaySummary = const <String, Object?>{},
    this.importSummary = const <String, Object?>{},
    this.executionDecision = const <String, Object?>{},
    this.generatedResearchNoteIds = const <String>[],
  });

  final String requestId;
  final String requestState;
  final bool executedNetwork;
  final bool executedImport;
  final bool awaitUserConfirmation;
  final bool blocked;
  final String summary;
  final List<String> changedPaths;
  final String blockedReason;
  final JsonMap gatewaySummary;
  final JsonMap importSummary;
  final JsonMap executionDecision;
  final List<String> generatedResearchNoteIds;
}
