import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_message_service.dart';
import 'session_mode_service.dart';
import 'session_record_constants.dart';
import 'session_record_normalizer_service.dart';

class SessionContextRendererService {
  SessionContextRendererService({
    required SessionRecordNormalizerService normalizerService,
    required SessionMessageService messageService,
    required SessionModeService modeService,
  }) : _normalizerService = normalizerService,
       _messageService = messageService,
       _modeService = modeService;

  final SessionRecordNormalizerService _normalizerService;
  final SessionMessageService _messageService;
  final SessionModeService _modeService;

  String sessionContextMarkdown(
    JsonMap session, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 会话上下文渲染只负责把当前状态和最近对话压成模型可读 Markdown。
    final normalized = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
    final lines = <String>[
      '【会话状态】',
      '目标：${ValueReaders.stringValue(normalized['title'], '新会话')}',
      '模式：${ValueReaders.stringValue(normalized['mode'], SessionRecordConstants.modeSmartOpening)}',
      '内部阶段：${ValueReaders.stringValue(normalized['workflow_stage'], 'opening')}',
      '公开状态：${ValueReaders.stringValue(normalized['public_status'], '准备中')}',
    ];
    final compressed = ValueReaders.stringValue(
      normalized['compressed_context'],
    ).trim();
    if (compressed.isNotEmpty) {
      lines.add('');
      lines.add('【会话摘要】');
      lines.add(compressed);
    }
    final messages = _messageService.messagesForContext(
      _messageService.normalizeMessages(normalized['context_messages']),
      excludeLatestUserContent: ValueReaders.stringValue(
        options['exclude_latest_user_content'],
      ),
    );
    if (messages.isNotEmpty) {
      lines.add('');
      lines.add('【最近对话】');
    }
    for (final message in messages) {
      lines.add(
        '${ValueReaders.stringValue(message['role'], 'user')}: ${ValueReaders.stringValue(message['content'])}',
      );
    }
    return lines.join('\n');
  }

  String sessionPublicSummary(
    JsonMap session, {
    int defaultThresholdChars = SessionRecordConstants.defaultThresholdChars,
  }) {
    // 中文注释: 公开摘要只暴露上下文体量、压缩次数和阈值，便于列表快速浏览。
    if (session.isEmpty) {
      return '无会话';
    }
    final normalized = _normalizerService.normalizeSessionRecord(
      session,
      defaultThresholdChars: defaultThresholdChars,
    );
    return '上下文 ${ValueReaders.intValue(normalized['total_context_chars'])} 字｜压缩 ${ValueReaders.intValue(normalized['compression_count'])} 次｜阈值 ${_modeService.clampThreshold(ValueReaders.intValue(normalized['compression_threshold_chars'], defaultThresholdChars))} 字';
  }
}
