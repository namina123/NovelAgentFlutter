import 'package:flutter/foundation.dart';

import 'transcript_block_view_data.dart';

@immutable
class ConversationTranscriptLaneViewData {
  const ConversationTranscriptLaneViewData({
    required this.stableHistoryBlocks,
    required this.currentRoundToolBlocks,
    required this.streamingAppendixBlocks,
    required this.footerBlocks,
  });

  final List<TranscriptBlockViewData> stableHistoryBlocks;
  final List<TranscriptBlockViewData> currentRoundToolBlocks;
  final List<TranscriptBlockViewData> streamingAppendixBlocks;
  final List<TranscriptBlockViewData> footerBlocks;

  List<TranscriptBlockViewData> flattenedBlocks() {
    return <TranscriptBlockViewData>[
      ...stableHistoryBlocks,
      ...currentRoundToolBlocks,
      ...streamingAppendixBlocks,
      ...footerBlocks,
    ];
  }

  bool get isEmpty =>
      stableHistoryBlocks.isEmpty &&
      currentRoundToolBlocks.isEmpty &&
      streamingAppendixBlocks.isEmpty &&
      footerBlocks.isEmpty;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ConversationTranscriptLaneViewData &&
            listEquals(other.stableHistoryBlocks, stableHistoryBlocks) &&
            listEquals(other.currentRoundToolBlocks, currentRoundToolBlocks) &&
            listEquals(other.streamingAppendixBlocks, streamingAppendixBlocks) &&
            listEquals(other.footerBlocks, footerBlocks);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(stableHistoryBlocks),
    Object.hashAll(currentRoundToolBlocks),
    Object.hashAll(streamingAppendixBlocks),
    Object.hashAll(footerBlocks),
  );
}
