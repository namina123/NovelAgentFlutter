import '../common/json_types.dart';
import 'draft_generation_stop_phase.dart';

class DraftGenerationProgress {
  const DraftGenerationProgress({
    required this.phase,
    required this.roundIndex,
    this.draftMarkdown = '',
    this.reasoningContent = '',
    this.pendingToolCalls = const <JsonMap>[],
    this.executedTools = const <Object?>[],
    this.cancelledByUser = false,
    this.stopPhase = DraftGenerationStopPhase.none,
    this.partialContentAccepted = false,
  });

  final String phase;
  final int roundIndex;
  final String draftMarkdown;
  final String reasoningContent;
  final List<JsonMap> pendingToolCalls;
  final List<Object?> executedTools;
  final bool cancelledByUser;
  final DraftGenerationStopPhase stopPhase;
  final bool partialContentAccepted;
}
