enum ConversationEntryKind { user, assistant, tool, system }

class ConversationEntryViewData {
  const ConversationEntryViewData({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.isError = false,
    this.detailTitle = '',
    this.detailSummary = '',
    this.detailBody = '',
    this.detailExpandedByDefault = false,
  });

  final String id;
  final ConversationEntryKind kind;
  final String title;
  final String body;
  final bool isError;
  final String detailTitle;
  final String detailSummary;
  final String detailBody;
  final bool detailExpandedByDefault;
}
