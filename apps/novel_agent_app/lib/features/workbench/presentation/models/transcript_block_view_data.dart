import 'package:flutter/foundation.dart';

import 'conversation_entry_view_data.dart';
import 'retry_request_view_data.dart';
import 'sub_agent_run_view_data.dart';
import 'user_option_view_data.dart';

enum TranscriptBlockKind {
  messageUser,
  messageAssistantStreaming,
  messageAssistantFinal,
  toolCompact,
  choiceGroup,
  runtimeNotice,
  retryBanner,
  checkpointCard,
  subAgentPreview,
}

@immutable
abstract class TranscriptBlockViewData {
  const TranscriptBlockViewData({
    required this.id,
    required this.kind,
  });

  final String id;
  final TranscriptBlockKind kind;
}

@immutable
class TranscriptMessageBlockViewData extends TranscriptBlockViewData {
  const TranscriptMessageBlockViewData({
    required super.id,
    required super.kind,
    required this.entry,
    this.isPlaceholder = false,
  });

  final ConversationEntryViewData entry;
  final bool isPlaceholder;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptMessageBlockViewData &&
            other.id == id &&
            other.kind == kind &&
            other.entry == entry &&
            other.isPlaceholder == isPlaceholder;
  }

  @override
  int get hashCode => Object.hash(id, kind, entry, isPlaceholder);
}

@immutable
class TranscriptToolBlockViewData extends TranscriptBlockViewData {
  const TranscriptToolBlockViewData({
    required super.id,
    required this.entry,
  }) : super(kind: TranscriptBlockKind.toolCompact);

  final ConversationEntryViewData entry;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptToolBlockViewData &&
            other.id == id &&
            other.entry == entry;
  }

  @override
  int get hashCode => Object.hash(id, entry);
}

@immutable
class TranscriptChoiceGroupBlockViewData extends TranscriptBlockViewData {
  const TranscriptChoiceGroupBlockViewData({
    required super.id,
    required this.options,
  }) : super(kind: TranscriptBlockKind.choiceGroup);

  final List<UserOptionViewData> options;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptChoiceGroupBlockViewData &&
            other.id == id &&
            listEquals(other.options, options);
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(options));
}

@immutable
class TranscriptRuntimeNoticeBlockViewData extends TranscriptBlockViewData {
  const TranscriptRuntimeNoticeBlockViewData({
    required super.id,
    required this.entry,
  }) : super(kind: TranscriptBlockKind.runtimeNotice);

  final ConversationEntryViewData entry;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptRuntimeNoticeBlockViewData &&
            other.id == id &&
            other.entry == entry;
  }

  @override
  int get hashCode => Object.hash(id, entry);
}

@immutable
class TranscriptRetryBannerBlockViewData extends TranscriptBlockViewData {
  const TranscriptRetryBannerBlockViewData({
    required super.id,
    required this.retryRequest,
  }) : super(kind: TranscriptBlockKind.retryBanner);

  final RetryRequestViewData retryRequest;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptRetryBannerBlockViewData &&
            other.id == id &&
            other.retryRequest == retryRequest;
  }

  @override
  int get hashCode => Object.hash(id, retryRequest);
}

@immutable
class TranscriptCheckpointCardBlockViewData extends TranscriptBlockViewData {
  const TranscriptCheckpointCardBlockViewData({
    required super.id,
    required this.title,
    required this.summary,
    required this.status,
  }) : super(kind: TranscriptBlockKind.checkpointCard);

  final String title;
  final String summary;
  final String status;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptCheckpointCardBlockViewData &&
            other.id == id &&
            other.title == title &&
            other.summary == summary &&
            other.status == status;
  }

  @override
  int get hashCode => Object.hash(id, title, summary, status);
}

@immutable
class TranscriptSubAgentPreviewBlockViewData extends TranscriptBlockViewData {
  const TranscriptSubAgentPreviewBlockViewData({
    required super.id,
    required this.runs,
  }) : super(kind: TranscriptBlockKind.subAgentPreview);

  final List<SubAgentRunViewData> runs;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TranscriptSubAgentPreviewBlockViewData &&
            other.id == id &&
            listEquals(other.runs, runs);
  }

  @override
  int get hashCode => Object.hash(id, Object.hashAll(runs));
}
