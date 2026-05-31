import '../models/conversation_transcript_lane_view_data.dart';
import '../models/transcript_block_view_data.dart';

class ConversationTranscriptLaneProjectionService {
  const ConversationTranscriptLaneProjectionService();

  ConversationTranscriptLaneViewData build(
    List<TranscriptBlockViewData> blocks, {
    required bool isGenerating,
  }) {
    final footerStart = _footerStartIndex(blocks);
    final footerBlocks = footerStart >= 0
        ? blocks.sublist(footerStart)
        : const <TranscriptBlockViewData>[];
    final coreBlocks = footerStart >= 0 ? blocks.sublist(0, footerStart) : blocks;

    final streamingStart = isGenerating
        ? _streamingAppendixStartIndex(coreBlocks)
        : -1;
    final streamingAppendixBlocks = streamingStart >= 0
        ? coreBlocks.sublist(streamingStart)
        : const <TranscriptBlockViewData>[];
    final beforeStreaming = streamingStart >= 0
        ? coreBlocks.sublist(0, streamingStart)
        : coreBlocks;

    final toolStart = isGenerating
        ? _currentRoundToolStartIndex(beforeStreaming)
        : -1;
    final currentRoundToolBlocks = toolStart >= 0
        ? beforeStreaming.sublist(toolStart)
        : const <TranscriptBlockViewData>[];
    final stableHistoryBlocks = toolStart >= 0
        ? beforeStreaming.sublist(0, toolStart)
        : beforeStreaming;

    return ConversationTranscriptLaneViewData(
      stableHistoryBlocks: stableHistoryBlocks,
      currentRoundToolBlocks: currentRoundToolBlocks,
      streamingAppendixBlocks: streamingAppendixBlocks,
      footerBlocks: footerBlocks,
    );
  }

  int _footerStartIndex(List<TranscriptBlockViewData> blocks) {
    var index = blocks.length;
    while (index > 0 && _isFooterBlock(blocks[index - 1])) {
      index -= 1;
    }
    return index == blocks.length ? -1 : index;
  }

  int _streamingAppendixStartIndex(List<TranscriptBlockViewData> blocks) {
    var index = blocks.length;
    while (index > 0 && _isStreamingAppendixBlock(blocks[index - 1])) {
      index -= 1;
    }
    return index == blocks.length ? -1 : index;
  }

  int _currentRoundToolStartIndex(List<TranscriptBlockViewData> blocks) {
    var index = blocks.length;
    while (index > 0 && blocks[index - 1].kind == TranscriptBlockKind.toolCompact) {
      index -= 1;
    }
    return index == blocks.length ? -1 : index;
  }

  bool _isFooterBlock(TranscriptBlockViewData block) {
    switch (block.kind) {
      case TranscriptBlockKind.choiceGroup:
      case TranscriptBlockKind.retryBanner:
      case TranscriptBlockKind.checkpointCard:
      case TranscriptBlockKind.subAgentPreview:
        return true;
      case TranscriptBlockKind.messageUser:
      case TranscriptBlockKind.messageAssistantStreaming:
      case TranscriptBlockKind.messageAssistantFinal:
      case TranscriptBlockKind.toolCompact:
      case TranscriptBlockKind.runtimeNotice:
        return false;
    }
  }

  bool _isStreamingAppendixBlock(TranscriptBlockViewData block) {
    return block.kind == TranscriptBlockKind.messageAssistantStreaming;
  }
}
