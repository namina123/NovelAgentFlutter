import 'package:flutter/foundation.dart';

import 'conversation_status_summary_item_kind.dart';

@immutable
class ConversationStatusSummaryItemViewData {
  const ConversationStatusSummaryItemViewData({
    required this.id,
    required this.kind,
    required this.label,
    required this.summary,
    required this.detail,
    required this.isHighlighted,
    required this.isInteractive,
    required this.isExpanded,
    required this.isBusy,
  });

  final String id;
  final ConversationStatusSummaryItemKind kind;
  final String label;
  final String summary;
  final String detail;
  final bool isHighlighted;
  final bool isInteractive;
  final bool isExpanded;
  final bool isBusy;
}
