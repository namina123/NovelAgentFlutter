import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/conversation_entry_view_data.dart';

class ConversationSessionRestoreProjectionService {
  ConversationSessionRestoreProjectionService({
    SessionMessageService? messageService,
  }) : _messageService = messageService ?? SessionMessageService();

  final SessionMessageService _messageService;

  List<ConversationEntryViewData> build(JsonMap sessionRecord) {
    // 中文注释: 重载投影只把持久化的 transcript / archive / working window 变成稳定时间线，不在这里重算业务状态。
    final sessionId = ValueReaders.stringValue(sessionRecord['id']).trim();
    final transcriptMessages = _messageService.normalizeMessages(
      sessionRecord[SessionRecordConstants.transcriptMessagesField],
    );
    final workingMessages = _messageService.normalizeMessages(
      sessionRecord[SessionRecordConstants.workingContextMessagesField],
    );
    final compactionSegments = ValueReaders.mapList(
      sessionRecord[SessionRecordConstants.compactionSegmentsField],
    );
    final entries = <ConversationEntryViewData>[
      ..._entriesFromCompactionSegments(
        sessionId: sessionId,
        compactionSegments: compactionSegments,
      ),
    ];
    final transcriptSourceMessages = transcriptMessages.isNotEmpty
        ? transcriptMessages
        : workingMessages;
    entries.addAll(
      _entriesFromMessages(
        sessionId: sessionId,
        messages: transcriptSourceMessages,
      ),
    );
    if (_needsWorkingWindowNotice(
      transcriptMessages: transcriptMessages,
      workingMessages: workingMessages,
    )) {
      entries.add(
        _workingWindowNotice(
          sessionId: sessionId,
          workingMessages: workingMessages,
        ),
      );
    }
    return List<ConversationEntryViewData>.unmodifiable(entries);
  }

  List<ConversationEntryViewData> _entriesFromCompactionSegments({
    required String sessionId,
    required List<JsonMap> compactionSegments,
  }) {
    // 中文注释: 压缩段以折叠系统条目方式回放，保留 archive 事实但不展开成一长串正文。
    if (compactionSegments.isEmpty) {
      return const <ConversationEntryViewData>[];
    }
    final entries = <ConversationEntryViewData>[];
    for (var index = 0; index < compactionSegments.length; index += 1) {
      final segment = compactionSegments[index];
      final title = ValueReaders.stringValue(segment['title']).trim();
      final summary = ValueReaders.stringValue(segment['summary']).trim();
      final sourceCount = ValueReaders.intValue(
        segment['source_message_count'],
      );
      final body = summary.isNotEmpty
          ? summary
          : '本会话较早的上下文已压缩保存，本次重载仅回放当前保留窗口。';
      final foldTitle = title.isNotEmpty ? title : '更早历史';
      entries.add(
        ConversationEntryViewData(
          id: 'restored_${sessionId}_archive_$index',
          kind: ConversationEntryKind.system,
          title: foldTitle,
          body: body,
          detailTitle: '压缩段',
          detailSummary: sourceCount > 0 ? '来源 $sourceCount 条' : '',
          detailBody: summary,
          detailExpandedByDefault: false,
        ),
      );
    }
    return entries;
  }

  List<ConversationEntryViewData> _entriesFromMessages({
    required String sessionId,
    required List<JsonMap> messages,
  }) {
    // 中文注释: transcript 消息按原始角色顺序回放，保证完整历史在恢复后仍能逐条对应。
    if (messages.isEmpty) {
      return const <ConversationEntryViewData>[];
    }
    final entries = <ConversationEntryViewData>[];
    for (var index = 0; index < messages.length; index += 1) {
      final entry = _entryFromMessage(
        sessionId: sessionId,
        index: index,
        message: messages[index],
      );
      if (entry != null) {
        entries.add(entry);
      }
    }
    return entries;
  }

  ConversationEntryViewData? _entryFromMessage({
    required String sessionId,
    required int index,
    required JsonMap message,
  }) {
    // 中文注释: 消息级恢复要把工具调用结果也带回时间线。tool 消息的结果字段可能在
    // content / display_text / tool_result 里（不同 provider 和工具返回路径写法不一），逐个兜底。
    final role = ValueReaders.stringValue(message['role']).trim();
    final content = ValueReaders.stringValue(
      message['content'],
      ValueReaders.stringValue(
        message['display_text'],
        ValueReaders.stringValue(message['tool_result']),
      ),
    ).trim();

    // 中文注释: assistant 消息可能只有 tool_calls 没有 content；提取工具调用名作为摘要，不丢弃。
    if (role == 'assistant' && content.isEmpty) {
      final toolCalls = ValueReaders.objectList(message['tool_calls']);
      if (toolCalls.isNotEmpty) {
        final toolNames = toolCalls
            .map(
              (tc) =>
                  ValueReaders.stringValue(ValueReaders.mapValue(tc)['name']),
            )
            .where((name) => name.isNotEmpty)
            .join('、');
        if (toolNames.isNotEmpty) {
          return ConversationEntryViewData(
            id: 'restored_${sessionId}_transcript_$index',
            kind: ConversationEntryKind.assistant,
            title: '综合创作智能体',
            body: '调用工具：$toolNames',
          );
        }
      }
      return null;
    }

    if (role.isEmpty || content.isEmpty) {
      return null;
    }
    final kind = switch (role) {
      'user' => ConversationEntryKind.user,
      'assistant' => ConversationEntryKind.assistant,
      'tool' => ConversationEntryKind.tool,
      _ => ConversationEntryKind.system,
    };
    final title = switch (kind) {
      ConversationEntryKind.user => '你',
      ConversationEntryKind.assistant => '综合创作智能体',
      ConversationEntryKind.tool => '工具结果',
      _ => '系统记录',
    };
    return ConversationEntryViewData(
      id: 'restored_${sessionId}_transcript_$index',
      kind: kind,
      title: title,
      body: content,
    );
  }

  bool _needsWorkingWindowNotice({
    required List<JsonMap> transcriptMessages,
    required List<JsonMap> workingMessages,
  }) {
    // 中文注释: 只有当工作窗口确实与完整转录存在分层差异时，才补一条工作窗口提示，避免恢复页重复过度。
    if (workingMessages.isEmpty) {
      return false;
    }
    return transcriptMessages.length > workingMessages.length;
  }

  ConversationEntryViewData _workingWindowNotice({
    required String sessionId,
    required List<JsonMap> workingMessages,
  }) {
    // 中文注释: 当前工作窗口只做折叠提示，正文里不重放一遍完整窗口，避免与 transcript 重复。
    final summary = _workingWindowSummary(workingMessages);
    return ConversationEntryViewData(
      id: 'restored_${sessionId}_working_window',
      kind: ConversationEntryKind.system,
      title: '当前工作上下文',
      body: summary,
      detailTitle: '工作窗口',
      detailSummary: '当前保留 ${workingMessages.length} 条消息',
      detailBody: _workingWindowDetailBody(workingMessages),
      detailExpandedByDefault: false,
    );
  }

  String _workingWindowSummary(List<JsonMap> workingMessages) {
    // 中文注释: 工作窗口摘要只给出一个短提示，主时间线读者能知道模型当前看的是哪一层窗口。
    return '当前工作窗口已恢复为最近 ${workingMessages.length} 条消息。';
  }

  String _workingWindowDetailBody(List<JsonMap> workingMessages) {
    // 中文注释: 工作窗口详情保留为可展开文本，方便需要核对时直接看到当前窗口内容。
    if (workingMessages.isEmpty) {
      return '';
    }
    final lines = <String>[];
    for (final message in workingMessages) {
      final role = ValueReaders.stringValue(message['role'], 'user');
      final content = ValueReaders.stringValue(message['content']).trim();
      if (content.isEmpty) {
        continue;
      }
      lines.add('$role: $content');
    }
    return lines.join('\n');
  }
}
