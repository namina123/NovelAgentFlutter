import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_message_service.dart';

class SessionHistoryService {
  SessionHistoryService({required SessionMessageService messageService})
    : _messageService = messageService;

  final SessionMessageService _messageService;

  JsonMap sessionIndexFromSessions(
    List<Object?> sessions, {
    String currentSessionId = '',
    int limit = 200,
  }) {
    // 中文注释: 会话索引只保留列表展示需要的轻量字段，不把整段上下文消息带上来。
    final entries = sessions
        .map(ValueReaders.mapValue)
        .where(
          (session) =>
              ValueReaders.stringValue(session['id']).trim().isNotEmpty,
        )
        .map(_sessionIndexEntry)
        .toList(growable: true);
    entries.sort((a, b) {
      return ValueReaders.stringValue(
        b['updated_at'],
      ).compareTo(ValueReaders.stringValue(a['updated_at']));
    });
    final maxCount = limit <= 0 ? 200 : limit;
    final resultEntries = entries
        .take(maxCount)
        .map(ValueReaders.deepCopyMap)
        .toList();
    var selected = currentSessionId.trim();
    if (selected.isEmpty && resultEntries.isNotEmpty) {
      selected = ValueReaders.stringValue(resultEntries.first['id']);
    }
    return <String, Object?>{
      'schema_version': 1,
      'current_session_id': selected,
      'sessions': resultEntries,
      'total_count': entries.length,
      'omitted_count': entries.length - resultEntries.length,
    };
  }

  JsonMap sessionHistoryWindow(
    JsonMap session, {
    int maxMessages = 80,
    int maxChars = 60000,
  }) {
    // 中文注释: 历史窗口从尾部倒着取消息，保证最近对话优先保留下来。
    final messages = _messageService.normalizeMessages(
      session['context_messages'],
    );
    final kept = <JsonMap>[];
    var chars = 0;
    final messageLimit = maxMessages <= 0 ? 80 : maxMessages;
    final charLimit = maxChars <= 0 ? 60000 : maxChars;
    for (var index = messages.length - 1; index >= 0; index -= 1) {
      final message = messages[index];
      final nextChars = chars + _messageChars(message);
      if (kept.length >= messageLimit || (chars > 0 && nextChars > charLimit)) {
        break;
      }
      kept.insert(0, ValueReaders.deepCopyMap(message));
      chars = nextChars;
    }
    return <String, Object?>{
      'messages': kept,
      'kept_count': kept.length,
      'omitted_count': messages.length - kept.length,
      'used_chars': chars,
      'max_messages': messageLimit,
      'max_chars': charLimit,
      'has_omitted_history': messages.length > kept.length,
    };
  }

  List<JsonMap> sessionJsonlEntries(
    JsonMap session, {
    int maxMessages = 0,
    int maxChars = 0,
  }) {
    // 中文注释: JSONL 导出先写 meta，再按窗口顺序附上消息，方便后续落盘或上传。
    final window = sessionHistoryWindow(
      session,
      maxMessages: maxMessages <= 0 ? 1000000 : maxMessages,
      maxChars: maxChars <= 0 ? 1000000000 : maxChars,
    );
    final meta = ValueReaders.deepCopyMap(session)..remove('context_messages');
    meta['jsonl_omitted_message_count'] = ValueReaders.intValue(
      window['omitted_count'],
    );
    final entries = <JsonMap>[
      <String, Object?>{'type': 'meta', 'session': meta},
    ];
    for (final raw in ValueReaders.objectList(window['messages'])) {
      entries.add(<String, Object?>{
        'type': 'message',
        'message': ValueReaders.deepCopyMap(ValueReaders.mapValue(raw)),
      });
    }
    return entries;
  }

  JsonMap _sessionIndexEntry(JsonMap session) {
    // 中文注释: 索引条目集中在这里投影，避免列表页和历史导出各自裁字段。
    return <String, Object?>{
      'id': session['id'],
      'title': ValueReaders.stringValue(session['title'], '未命名会话'),
      'mode': session['mode'],
      'workflow_stage': session['workflow_stage'],
      'public_status': session['public_status'],
      'needs_goal_selection': ValueReaders.boolValue(
        session['needs_goal_selection'],
      ),
      'updated_at': session['updated_at'],
      'created_at': session['created_at'],
    };
  }

  int _messageChars(JsonMap message) {
    // 中文注释: 消息字数统计单独封装，避免窗口裁剪逻辑反复拆 message 字典。
    return ValueReaders.stringValue(message['content']).length;
  }
}
