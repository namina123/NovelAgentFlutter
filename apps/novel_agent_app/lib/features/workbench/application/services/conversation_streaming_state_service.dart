import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_session_state.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import 'conversation_session_state_service.dart';

class ConversationStreamingStateService {
  ConversationStreamingStateService({
    required ConversationSessionStateService sessionStateService,
  }) : _sessionStateService = sessionStateService;

  final ConversationSessionStateService _sessionStateService;

  ConversationSessionState stateWithProgress(
    ConversationSessionState baseState,
    DraftGenerationProgress progress,
  ) {
    // 中文注释: 流式过程只覆盖临时展示层；执行中工具状态通过独立状态条提示，不再把短暂 pending 工具挤进正文时间线。
    final entries = <ConversationEntryViewData>[
      ..._stableEntries(baseState.entries),
      ..._sessionStateService.toolEntriesFromExecutedTools(
        progress.executedTools,
        includeDetailBodies: false,
      ),
    ];
    final assistantEntry = _sessionStateService.assistantEntryFromContent(
      content: progress.draftMarkdown,
      reasoning: progress.reasoningContent,
      entryId: 'assistant_streaming',
    );
    final resolvedAssistantEntry =
        assistantEntry ?? _existingStreamingAssistantEntry(baseState.entries);
    if (resolvedAssistantEntry != null) {
      entries.add(resolvedAssistantEntry);
    }
    return baseState.copyWith(
      entries: entries,
      pendingOptions: const [],
      subAgentRuns: _sessionStateService.mergeSubAgentRunsFromExecutedTools(
        baseState.subAgentRuns,
        progress.executedTools,
      ),
    );
  }

  List<ConversationEntryViewData> _stableEntries(
    List<ConversationEntryViewData> entries,
  ) {
    // 中文注释: 当前轮的流式附加区只保留到“最新用户输入”为止，避免累计 executedTools 在多帧刷新时重复堆叠。
    var end = entries.length;
    while (end > 0) {
      final entry = entries[end - 1];
      if (entry.id == 'assistant_streaming' ||
          entry.id.startsWith('tool_pending_') ||
          entry.kind == ConversationEntryKind.tool) {
        end -= 1;
        continue;
      }
      break;
    }
    return entries.take(end).toList(growable: false);
  }

  ConversationEntryViewData? _existingStreamingAssistantEntry(
    List<ConversationEntryViewData> entries,
  ) {
    // 中文注释: 工具轮期间如果当前 SSE 分片没有正文增量，也保留上一帧已出现的助手内容，避免阅读时“出字框”被顶掉。
    for (final entry in entries.reversed) {
      if (entry.id == 'assistant_streaming') {
        return entry;
      }
    }
    return null;
  }
}
