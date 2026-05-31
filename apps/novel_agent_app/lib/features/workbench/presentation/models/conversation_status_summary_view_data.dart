import 'package:flutter/foundation.dart';

import 'conversation_status_summary_item_view_data.dart';

@immutable
class ConversationStatusSummaryViewData {
  const ConversationStatusSummaryViewData({required this.items});

  final List<ConversationStatusSummaryItemViewData> items;

  List<ConversationStatusSummaryItemViewData> get expandedItems => items
      .where((item) => item.isExpanded && item.detail.trim().isNotEmpty)
      .toList(growable: false);
}
