import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_session_state.dart';
import '../../presentation/models/conversation_entry_view_data.dart';
import 'conversation_session_state_service.dart';

class ConversationStreamingStateService {
  ConversationStreamingStateService({
    required ConversationSessionStateService sessionStateService,
    ToolEventPresenterService? toolEventPresenterService,
  }) : _sessionStateService = sessionStateService,
       _toolEventPresenterService =
           toolEventPresenterService ?? ToolEventPresenterService();

  final ConversationSessionStateService _sessionStateService;
  final ToolEventPresenterService _toolEventPresenterService;

  ConversationSessionState stateWithProgress(
    ConversationSessionState baseState,
    DraftGenerationProgress progress,
  ) {
    // 中文注释: 流式过程只投影临时展示条目，不改写真实会话上下文记录，避免半成品内容污染下一轮请求。
    final entries = <ConversationEntryViewData>[
      ...baseState.entries,
      ..._sessionStateService.toolEntriesFromExecutedTools(
        progress.executedTools,
      ),
      ..._pendingToolEntries(progress.pendingToolCalls),
    ];
    final assistantEntry = _sessionStateService.assistantEntryFromContent(
      content: progress.draftMarkdown,
      reasoning: progress.reasoningContent,
      entryId: 'assistant_streaming',
    );
    if (assistantEntry != null) {
      entries.add(assistantEntry);
    }
    return baseState.copyWith(
      entries: entries,
      pendingOptions: const [],
    );
  }

  List<ConversationEntryViewData> _pendingToolEntries(List<JsonMap> toolCalls) {
    // 中文注释: 模型刚决定调用但尚未执行的工具在这里做成轻量单行提示，帮助用户理解当前正在发生什么。
    return toolCalls
        .map((call) {
          final id = ValueReaders.stringValue(
            call['id'],
            ValueReaders.stringValue(call['name']),
          ).trim();
          final name = ValueReaders.stringValue(call['name'], '工具').trim();
          if (id.isEmpty && name.isEmpty) {
            return null;
          }
          return ConversationEntryViewData(
            id: 'tool_pending_${id.isEmpty ? name : id}',
            kind: ConversationEntryKind.tool,
            title: name.isEmpty ? '工具' : name,
            body: _toolEventPresenterService.textForEvent(<String, Object?>{
              'phase': 'started',
              'ok': true,
              'name': name,
              'arguments': ValueReaders.deepCopyMap(
                ValueReaders.mapValue(call['arguments']),
              ),
              'result': const <String, Object?>{},
            }),
          );
        })
        .whereType<ConversationEntryViewData>()
        .toList(growable: false);
  }
}
