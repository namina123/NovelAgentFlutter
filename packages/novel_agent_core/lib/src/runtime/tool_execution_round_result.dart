import '../common/json_types.dart';

class ToolExecutionRoundResult {
  const ToolExecutionRoundResult({
    required this.executedTools,
    required this.writtenPaths,
    required this.changedPaths,
    required this.transcriptMessages,
    required this.waitingForUserChoice,
    required this.stoppedByToolError,
    required this.hadPlanTool,
  });

  final List<Object?> executedTools;
  final List<String> writtenPaths;
  final List<String> changedPaths;
  final List<JsonMap> transcriptMessages;
  final bool waitingForUserChoice;
  final bool stoppedByToolError;
  final bool hadPlanTool;
}
