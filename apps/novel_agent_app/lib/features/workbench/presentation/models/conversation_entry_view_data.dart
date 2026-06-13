import '../../application/models/conversation_tool_lifecycle_status.dart';

enum ConversationEntryKind { user, assistant, tool, system }

class ConversationEntryViewData {
  const ConversationEntryViewData({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    this.isError = false,
    this.isRetryableFailure = false,
    this.detailTitle = '',
    this.detailSummary = '',
    this.detailBody = '',
    this.detailExpandedByDefault = false,
    this.toolLifecycleStatus,
  });

  final String id;
  final ConversationEntryKind kind;
  final String title;
  final String body;
  final bool isError;
  final bool isRetryableFailure;
  final String detailTitle;
  final String detailSummary;
  final String detailBody;
  final bool detailExpandedByDefault;
  final ConversationToolLifecycleStatus? toolLifecycleStatus;
}
