import '../common/json_types.dart';

class DraftGenerationProgress {
  const DraftGenerationProgress({
    required this.phase,
    required this.roundIndex,
    this.draftMarkdown = '',
    this.reasoningContent = '',
    this.pendingToolCalls = const <JsonMap>[],
    this.executedTools = const <Object?>[],
  });

  final String phase;
  final int roundIndex;
  final String draftMarkdown;
  final String reasoningContent;
  final List<JsonMap> pendingToolCalls;
  final List<Object?> executedTools;
}
