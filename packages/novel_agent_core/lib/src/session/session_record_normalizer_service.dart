import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_message_service.dart';
import 'session_mode_service.dart';
import 'session_record_constants.dart';

class SessionRecordNormalizerService {
  SessionRecordNormalizerService({
    required SessionModeService modeService,
    required SessionMessageService messageService,
  }) : _modeService = modeService,
       _messageService = messageService;

  final SessionModeService _modeService;
  final SessionMessageService _messageService;

  JsonMap makeSessionRecord({
    required String mode,
    required String title,
    required String sessionId,
    required String createdAt,
    required int defaultThresholdChars,
  }) {
    // 中文注释: 新会话记录的创建只负责产出稳定骨架，不在这里插入任何业务消息。
    final normalizedMode = _modeService.cleanMode(mode);
    final stage = _modeService.initialStage(normalizedMode);
    final needsGoalSelection =
        normalizedMode == SessionRecordConstants.modeUnselected;
    final cleanTitle = title.trim();
    return <String, Object?>{
      'id': sessionId.trim().isEmpty ? 'session_pending' : sessionId.trim(),
      'title': cleanTitle.isEmpty
          ? _modeService.defaultTitle(normalizedMode)
          : cleanTitle,
      'mode': normalizedMode,
      'workflow_stage': stage,
      'public_status': _modeService.publicStatus(normalizedMode, stage, false),
      'needs_goal_selection': needsGoalSelection,
      'is_creative': false,
      'context_messages': <Object?>[],
      'compressed_context': '',
      'compression_count': 0,
      'compression_threshold_chars': _modeService.clampThreshold(
        defaultThresholdChars,
      ),
      'total_context_chars': 0,
      'created_at': createdAt,
      'updated_at': createdAt,
    };
  }

  JsonMap normalizeSessionRecord(
    JsonMap session, {
    required int defaultThresholdChars,
    String now = '',
  }) {
    // 中文注释: 会话记录归一化统一修复模式、阶段、消息数组和压缩阈值，供所有会话操作复用。
    var mode = _modeService.cleanMode(
      ValueReaders.stringValue(
        session['mode'],
        SessionRecordConstants.modeSmartOpening,
      ),
    );
    var stage = ValueReaders.stringValue(
      session['workflow_stage'],
      _modeService.initialStage(mode),
    );
    var needsGoalSelection = ValueReaders.boolValue(
      session['needs_goal_selection'],
      mode == SessionRecordConstants.modeUnselected,
    );
    var creative = ValueReaders.boolValue(session['is_creative']);
    if (needsGoalSelection) {
      mode = SessionRecordConstants.modeUnselected;
      stage = 'pending_goal';
      creative = false;
    }
    final messages = _messageService.normalizeMessages(
      session['context_messages'],
    );
    final timestamp = now.trim();
    final compressedContext = ValueReaders.stringValue(
      session['compressed_context'],
    );
    return <String, Object?>{
      'id': ValueReaders.stringValue(session['id']),
      'title': ValueReaders.stringValue(
        session['title'],
        _modeService.defaultTitle(mode),
      ),
      'mode': mode,
      'workflow_stage': stage,
      'public_status': _modeService.publicStatus(mode, stage, creative),
      'needs_goal_selection': needsGoalSelection,
      'is_creative': creative,
      'context_messages': messages,
      'compressed_context': compressedContext,
      'compression_count': ValueReaders.intValue(session['compression_count']),
      'compression_threshold_chars': _modeService.clampThreshold(
        ValueReaders.intValue(
          session['compression_threshold_chars'],
          defaultThresholdChars,
        ),
      ),
      'total_context_chars':
          _messageService.messagesChars(messages) + compressedContext.length,
      'created_at': ValueReaders.stringValue(session['created_at'], timestamp),
      'updated_at': ValueReaders.stringValue(session['updated_at'], timestamp),
    };
  }
}
