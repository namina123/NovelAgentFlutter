import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectResearchGatewayRunResult {
  const ProjectResearchGatewayRunResult({
    required this.requestId,
    required this.executed,
    this.generatedResearchNote,
    this.requestState = '',
    this.summary = '',
    this.changedPaths = const <String>[],
    this.gatewaySummary = const <String, Object?>{},
    this.blockedReason = '',
  });

  final String requestId;
  final bool executed;
  final ResearchNote? generatedResearchNote;
  final String requestState;
  final String summary;
  final List<String> changedPaths;
  final JsonMap gatewaySummary;
  final String blockedReason;
}
