import '../../presentation/models/conversation_entry_view_data.dart';
import '../../presentation/models/conversation_context_projection_view_data.dart';
import '../../presentation/models/retry_request_view_data.dart';
import '../../presentation/models/sub_agent_run_view_data.dart';
import '../../presentation/models/transcript_block_view_data.dart';
import '../../presentation/models/user_option_view_data.dart';

class ConversationTranscriptBlockProjectionService {
  const ConversationTranscriptBlockProjectionService();

  List<TranscriptBlockViewData> build({
    required List<ConversationEntryViewData> entries,
    required bool isGenerating,
    required List<UserOptionViewData> pendingOptions,
    required List<SubAgentRunViewData> subAgentRuns,
    required RetryRequestViewData? retryRequest,
    ConversationContextProjectionViewData? contextProjection,
  }) {
    final blocks = <TranscriptBlockViewData>[
      ..._archiveBlocksFrom(contextProjection),
      ...entries.map(_blockFromEntry).whereType<TranscriptBlockViewData>(),
    ];
    if (isGenerating && !_hasStreamingAssistant(entries)) {
      blocks.add(
        TranscriptMessageBlockViewData(
          id: 'assistant_streaming_placeholder',
          kind: TranscriptBlockKind.messageAssistantStreaming,
          entry: const ConversationEntryViewData(
            id: 'assistant_streaming_placeholder',
            kind: ConversationEntryKind.assistant,
            title: '综合创作智能体',
            body: '',
          ),
          isPlaceholder: true,
        ),
      );
    }
    if (retryRequest != null) {
      blocks.add(
        TranscriptRetryBannerBlockViewData(
          id: 'retry_${retryRequest.label.hashCode}_${retryRequest.errorMessage.hashCode}',
          retryRequest: retryRequest,
        ),
      );
    }
    if (pendingOptions.isNotEmpty) {
      blocks.add(
        TranscriptChoiceGroupBlockViewData(
          id: 'choice_group_${pendingOptions.length}',
          options: pendingOptions,
        ),
      );
    }
    if (subAgentRuns.isNotEmpty) {
      blocks.add(
        TranscriptSubAgentPreviewBlockViewData(
          id: 'sub_agent_preview_${subAgentRuns.length}',
          runs: subAgentRuns,
        ),
      );
    }
    return blocks;
  }

  List<TranscriptBlockViewData> _archiveBlocksFrom(
    ConversationContextProjectionViewData? contextProjection,
  ) {
    // 中文注释: 归档段在时间线上以折叠系统记录回放，保留 archive 事实，但不把压缩段展开成第二份正文。
    if (contextProjection == null || !contextProjection.hasArchive) {
      return const <TranscriptBlockViewData>[];
    }
    return contextProjection.compactionSegments
        .map(
          (segment) => TranscriptRuntimeNoticeBlockViewData(
            id: 'archive_${segment.id}',
            entry: ConversationEntryViewData(
              id: 'archive_${segment.id}',
              kind: ConversationEntryKind.system,
              title: segment.title,
              body: segment.foldedSummary,
              detailTitle: '压缩段',
              detailSummary: segment.sourceSummary,
              detailBody: segment.summary.trim(),
              detailExpandedByDefault: false,
            ),
          ),
        )
        .toList(growable: false);
  }

  TranscriptBlockViewData? _blockFromEntry(ConversationEntryViewData entry) {
    switch (entry.kind) {
      case ConversationEntryKind.user:
        return TranscriptMessageBlockViewData(
          id: entry.id,
          kind: TranscriptBlockKind.messageUser,
          entry: entry,
        );
      case ConversationEntryKind.assistant:
        return TranscriptMessageBlockViewData(
          id: entry.id,
          kind: entry.id == 'assistant_streaming'
              ? TranscriptBlockKind.messageAssistantStreaming
              : TranscriptBlockKind.messageAssistantFinal,
          entry: entry,
        );
      case ConversationEntryKind.tool:
        return TranscriptToolBlockViewData(id: entry.id, entry: entry);
      case ConversationEntryKind.system:
        return TranscriptRuntimeNoticeBlockViewData(id: entry.id, entry: entry);
    }
  }

  bool _hasStreamingAssistant(List<ConversationEntryViewData> entries) {
    for (final entry in entries.reversed) {
      if (entry.id == 'assistant_streaming' &&
          entry.kind == ConversationEntryKind.assistant) {
        return true;
      }
    }
    return false;
  }
}
