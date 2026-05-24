import '../common/json_types.dart';

class LlmStreamUpdate {
  const LlmStreamUpdate({
    this.contentDelta = '',
    this.content = '',
    this.reasoningDelta = '',
    this.reasoningContent = '',
    this.toolCalls = const <JsonMap>[],
    this.isCompleted = false,
  });

  final String contentDelta;
  final String content;
  final String reasoningDelta;
  final String reasoningContent;
  final List<JsonMap> toolCalls;
  final bool isCompleted;
}
