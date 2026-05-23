enum ConversationEntryKind { user, assistant, tool, system }

class ConversationEntryViewData {
  const ConversationEntryViewData({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.isError = false,
  });

  final String id;
  final ConversationEntryKind kind;
  final String title;
  final String body;
  final bool isError;
}
