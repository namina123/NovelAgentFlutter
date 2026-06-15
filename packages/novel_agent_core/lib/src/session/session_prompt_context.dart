import '../common/json_types.dart';

class SessionPromptContext {
  const SessionPromptContext({
    this.contextMarkdown = '',
    this.historyMessages = const <JsonMap>[],
  });

  final String contextMarkdown;
  final List<JsonMap> historyMessages;

  bool get hasContextMarkdown => contextMarkdown.trim().isNotEmpty;
  bool get hasHistoryMessages => historyMessages.isNotEmpty;

  SessionPromptContext copyWith({
    String? contextMarkdown,
    List<JsonMap>? historyMessages,
  }) {
    return SessionPromptContext(
      contextMarkdown: contextMarkdown ?? this.contextMarkdown,
      historyMessages: historyMessages ?? this.historyMessages,
    );
  }
}
