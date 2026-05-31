import 'conversation_transcript_lane_view_data.dart';
import 'transcript_block_view_data.dart';

class ConversationTimelineSnapshot {
  const ConversationTimelineSnapshot({
    required this.blockCount,
    required this.lastBlockId,
    required this.lastBlockContentLength,
    required this.lastBlockDetailLength,
  });

  factory ConversationTimelineSnapshot.fromViewData({
    required ConversationTranscriptLaneViewData lanes,
  }) {
    final blocks = lanes.flattenedBlocks();
    final lastBlock = blocks.isEmpty ? null : blocks.last;
    return ConversationTimelineSnapshot(
      blockCount: blocks.length,
      lastBlockId: lastBlock?.id ?? '',
      lastBlockContentLength: _contentLengthOf(lastBlock),
      lastBlockDetailLength: _detailLengthOf(lastBlock),
    );
  }

  final int blockCount;
  final String lastBlockId;
  final int lastBlockContentLength;
  final int lastBlockDetailLength;

  static int _contentLengthOf(TranscriptBlockViewData? block) {
    switch (block) {
      case TranscriptMessageBlockViewData():
        return block.entry.body.length;
      case TranscriptToolBlockViewData():
        return block.entry.body.length;
      case TranscriptRuntimeNoticeBlockViewData():
        return block.entry.body.length;
      case TranscriptChoiceGroupBlockViewData():
        return block.options.length;
      case TranscriptRetryBannerBlockViewData():
        return block.retryRequest.errorMessage.length;
      case TranscriptCheckpointCardBlockViewData():
        return block.summary.length;
      case TranscriptSubAgentPreviewBlockViewData():
        return block.runs.length;
      case null:
        return 0;
    }
    return 0;
  }

  static int _detailLengthOf(TranscriptBlockViewData? block) {
    switch (block) {
      case TranscriptMessageBlockViewData():
        return block.entry.detailBody.length;
      case TranscriptToolBlockViewData():
        return block.entry.detailBody.length;
      case TranscriptRuntimeNoticeBlockViewData():
        return block.entry.detailBody.length;
      case TranscriptChoiceGroupBlockViewData():
      case TranscriptRetryBannerBlockViewData():
      case TranscriptCheckpointCardBlockViewData():
      case TranscriptSubAgentPreviewBlockViewData():
      case null:
        return 0;
    }
    return 0;
  }
}
