import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_message_service.dart';
import 'session_mode_service.dart';
import 'session_record_constants.dart';
import 'session_record_normalizer_service.dart';

class SessionRecordMutationService {
  SessionRecordMutationService({
    required SessionRecordNormalizerService normalizerService,
    required SessionModeService modeService,
    required SessionMessageService messageService,
  }) : _normalizerService = normalizerService,
       _modeService = modeService,
       _messageService = messageService;

  final SessionRecordNormalizerService _normalizerService;
  final SessionModeService _modeService;
  final SessionMessageService _messageService;

  JsonMap sessionWithGoal(JsonMap session, String mode, {String now = ''}) {
    // 中文注释: 选择会话目标时只切换模式与阶段，不自动塞入任何上下文消息。
    final timestamp = now.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : now;
    final result = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
      now: timestamp,
    );
    final normalizedMode = mode.trim().isEmpty
        ? SessionRecordConstants.modeSmartOpening
        : mode.trim();
    result['mode'] = normalizedMode;
    result['workflow_stage'] = _modeService.initialStage(normalizedMode);
    result['needs_goal_selection'] = false;
    result['is_creative'] =
        normalizedMode == SessionRecordConstants.modeChapterDraft ||
        normalizedMode == SessionRecordConstants.modeContinueWriting;
    result['public_status'] = _modeService.publicStatus(
      normalizedMode,
      ValueReaders.stringValue(result['workflow_stage'], 'opening'),
      ValueReaders.boolValue(result['is_creative']),
    );
    final currentTitle = ValueReaders.stringValue(result['title']).trim();
    if (currentTitle.isEmpty ||
        currentTitle ==
            _modeService.defaultTitle(SessionRecordConstants.modeUnselected)) {
      result['title'] = _modeService.defaultTitle(normalizedMode);
    }
    result['updated_at'] = timestamp;
    return result;
  }

  JsonMap sessionWithMessage(
    JsonMap session,
    String role,
    String content, {
    String createdAt = '',
  }) {
    // 中文注释: 添加消息时会同时推进公开状态并在超阈值时触发自动压缩。
    final timestamp = createdAt.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    final result = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
      now: timestamp,
    );
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      return result;
    }
    final messages = List<JsonMap>.from(
      _messageService.normalizeMessages(result['context_messages']),
    );
    messages.add(<String, Object?>{
      'role': role,
      'content': cleanContent,
      'created_at': timestamp,
    });
    result['context_messages'] = messages;
    _updateProgress(result, cleanContent);
    _maybeCompress(result);
    result['updated_at'] = timestamp;
    return result;
  }

  void _updateProgress(JsonMap session, String content) {
    // 中文注释: 会话阶段推进只看当前模式和新增内容信号，不读取外部宿主状态。
    var stage = ValueReaders.stringValue(session['workflow_stage'], 'opening');
    final mode = ValueReaders.stringValue(
      session['mode'],
      SessionRecordConstants.modeSmartOpening,
    );
    final text = content.toLowerCase();
    var creative = ValueReaders.boolValue(session['is_creative']);

    if (mode == SessionRecordConstants.modeSummarizeBook) {
      stage = 'summary';
    } else if (mode == SessionRecordConstants.modeImportArticle) {
      stage = 'ingest';
    } else if (text.contains('大纲') ||
        text.contains('卷纲') ||
        text.contains('章纲')) {
      stage = 'outline';
      creative = true;
    } else if (text.contains('正文') ||
        text.contains('第一章') ||
        text.contains('开始写') ||
        text.contains('续写')) {
      stage = 'draft';
      creative = true;
    } else if (mode == SessionRecordConstants.modeChapterDraft ||
        mode == SessionRecordConstants.modeContinueWriting) {
      stage = 'draft';
      creative = true;
    }

    session['workflow_stage'] = stage;
    session['is_creative'] = creative;
    session['public_status'] = _modeService.publicStatus(mode, stage, creative);
  }

  void _maybeCompress(JsonMap session) {
    // 中文注释: 自动压缩只保留后半段消息，把前半段折叠成可读摘要，避免上下文无限增长。
    final messages = _messageService.normalizeMessages(
      session['context_messages'],
    );
    final compressed = ValueReaders.stringValue(session['compressed_context']);
    final threshold = _modeService.clampThreshold(
      ValueReaders.intValue(
        session['compression_threshold_chars'],
        SessionRecordConstants.defaultThresholdChars,
      ),
    );
    final totalChars =
        _messageService.messagesChars(messages) + compressed.length;
    session['total_context_chars'] = totalChars;
    if (totalChars <= threshold || messages.length < 4) {
      return;
    }
    var keepCount = messages.length ~/ 2;
    if (keepCount < 2) {
      keepCount = 2;
    }
    final compressCount = messages.length - keepCount;
    final compressedLines = <String>[];
    for (var index = 0; index < compressCount; index += 1) {
      final message = messages[index];
      compressedLines.add(
        '${ValueReaders.stringValue(message['role'], 'user')}：${_modeService.clip(ValueReaders.stringValue(message['content']), 180)}',
      );
    }
    final header =
        '压缩片段 ${ValueReaders.intValue(session['compression_count']) + 1}（自动）：\n${compressedLines.join('\n')}';
    final oldCompressed = compressed.trim();
    session['compressed_context'] = oldCompressed.isEmpty
        ? header
        : '$oldCompressed\n\n$header';
    session['context_messages'] = messages.sublist(compressCount);
    session['compression_count'] =
        ValueReaders.intValue(session['compression_count']) + 1;
    session['total_context_chars'] =
        _messageService.messagesChars(
          _messageService.normalizeMessages(session['context_messages']),
        ) +
        ValueReaders.stringValue(session['compressed_context']).length;
  }
}
