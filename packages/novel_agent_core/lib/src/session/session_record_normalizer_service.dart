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
      'transcript_messages': <Object?>[],
      'working_context_messages': <Object?>[],
      'compaction_segments': <Object?>[],
      'pinned_context_refs': <Object?>[],
      'context_messages': <Object?>[],
      'compressed_context': '',
      'compression_count': 0,
      'compression_threshold_chars': _modeService.clampThreshold(
        defaultThresholdChars,
      ),
      'transcript_context_chars': 0,
      'working_context_chars': 0,
      'compaction_archive_chars': 0,
      'total_context_chars': 0,
      SessionRecordConstants.conversationGoalField: '',
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
    final timestamp = now.trim();
    if (needsGoalSelection) {
      mode = SessionRecordConstants.modeUnselected;
      stage = 'pending_goal';
      creative = false;
    }
    final transcriptMessages = _normalizeTranscriptMessages(session);
    final workingMessages = _normalizeWorkingMessages(
      session,
      transcriptMessages,
    );
    final compactionSegments = _normalizeCompactionSegments(
      session,
      now: timestamp,
    );
    final compressedContext = _renderCompactionSegments(compactionSegments);
    final pinnedContextRefs = ValueReaders.stringList(
      session[SessionRecordConstants.pinnedContextRefsField],
    );
    final transcriptChars = _messageService.messagesChars(transcriptMessages);
    final workingChars = _messageService.messagesChars(workingMessages);
    final archiveChars = compressedContext.length;
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
      'transcript_messages': transcriptMessages,
      'working_context_messages': workingMessages,
      'compaction_segments': compactionSegments,
      'pinned_context_refs': pinnedContextRefs,
      'context_messages': workingMessages,
      'compressed_context': compressedContext,
      'compression_count': _normalizeCompressionCount(
        session,
        compactionSegments,
      ),
      'compression_threshold_chars': _modeService.clampThreshold(
        ValueReaders.intValue(
          session['compression_threshold_chars'],
          defaultThresholdChars,
        ),
      ),
      'transcript_context_chars': transcriptChars,
      'working_context_chars': workingChars,
      'compaction_archive_chars': archiveChars,
      'total_context_chars': workingChars + archiveChars,
      SessionRecordConstants.conversationGoalField: ValueReaders.stringValue(
        session[SessionRecordConstants.conversationGoalField],
      ),
      'created_at': ValueReaders.stringValue(session['created_at'], timestamp),
      'updated_at': ValueReaders.stringValue(session['updated_at'], timestamp),
    };
  }

  List<JsonMap> _normalizeTranscriptMessages(JsonMap session) {
    // 中文注释: transcript 代表完整历史转录，优先读取新字段，旧记录则回落到旧 context 消息。
    final explicit = _messageService.normalizeMessages(
      session[SessionRecordConstants.transcriptMessagesField],
    );
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return _messageService.normalizeMessages(
      session[SessionRecordConstants.legacyContextMessagesField],
    );
  }

  List<JsonMap> _normalizeWorkingMessages(
    JsonMap session,
    List<JsonMap> transcriptMessages,
  ) {
    // 中文注释: working context 代表当前送入模型的窗口，优先读新字段，旧字段再作为兼容桥。
    if (session.containsKey(
      SessionRecordConstants.workingContextMessagesField,
    )) {
      return _messageService.normalizeMessages(
        session[SessionRecordConstants.workingContextMessagesField],
      );
    }
    if (session.containsKey(SessionRecordConstants.legacyContextMessagesField)) {
      return _messageService.normalizeMessages(
        session[SessionRecordConstants.legacyContextMessagesField],
      );
    }
    return transcriptMessages;
  }

  List<JsonMap> _normalizeCompactionSegments(
    JsonMap session, {
    required String now,
  }) {
    // 中文注释: compaction archive 优先保留结构化分段；旧 compressed_context 作为单段兼容桥接入。
    final segments = <JsonMap>[];
    final rawSegments = ValueReaders.mapList(
      session[SessionRecordConstants.compactionSegmentsField],
    );
    for (var index = 0; index < rawSegments.length; index += 1) {
      final normalized = _normalizeCompactionSegment(
        rawSegments[index],
        index: index,
        now: now,
      );
      if (normalized.isNotEmpty) {
        segments.add(normalized);
      }
    }
    if (segments.isNotEmpty) {
      return segments;
    }
    final legacyCompressed = ValueReaders.stringValue(
      session[SessionRecordConstants.legacyCompressedContextField],
    ).trim();
    if (legacyCompressed.isEmpty) {
      return segments;
    }
    return <JsonMap>[
      <String, Object?>{
        'id': _segmentId(index: 0, legacy: true),
        'kind': 'legacy_compaction',
        'title': '',
        'summary': legacyCompressed,
        'source_message_count': ValueReaders.intValue(
          session['compression_count'],
        ),
        'source_message_roles': <String>[],
        'legacy_compression_count_hint': ValueReaders.intValue(
          session['compression_count'],
        ),
        'created_at': now,
      },
    ];
  }

  JsonMap _normalizeCompactionSegment(
    JsonMap raw, {
    required int index,
    required String now,
  }) {
    // 中文注释: 单个压缩段只保留稳定的标题、摘要和来源计数，避免 archive 结构被临时字段污染。
    final title = ValueReaders.stringValue(raw['title']).trim();
    final summary = ValueReaders.stringValue(
      raw['summary'],
      ValueReaders.stringValue(raw['content']),
    ).trim();
    if (title.isEmpty && summary.isEmpty) {
      return <String, Object?>{};
    }
    return <String, Object?>{
      'id': _segmentId(
        index: index,
        rawId: ValueReaders.stringValue(raw['id']),
      ),
      'kind': ValueReaders.stringValue(raw['kind'], 'summary'),
      'title': title,
      'summary': summary,
      'source_message_count': ValueReaders.intValue(
        raw['source_message_count'],
      ),
      'source_message_roles': ValueReaders.stringList(
        raw['source_message_roles'],
      ),
      'legacy_compression_count_hint': ValueReaders.intValue(
        raw['legacy_compression_count_hint'],
      ),
      'created_at': ValueReaders.stringValue(raw['created_at'], now),
    };
  }

  String _renderCompactionSegments(List<JsonMap> segments) {
    // 中文注释: 兼容旧 compressed_context 时，继续把结构化 archive 渲染成可读摘要字符串。
    final parts = <String>[];
    for (final segment in segments) {
      final title = ValueReaders.stringValue(segment['title']).trim();
      final summary = ValueReaders.stringValue(segment['summary']).trim();
      if (title.isEmpty) {
        if (summary.isNotEmpty) {
          parts.add(summary);
        }
        continue;
      }
      if (summary.isEmpty) {
        parts.add(title);
        continue;
      }
      parts.add('$title：\n$summary');
    }
    return parts.join('\n\n');
  }

  int _normalizeCompressionCount(JsonMap session, List<JsonMap> segments) {
    // 中文注释: 压缩计数优先跟随结构化 archive 段数；旧记录若已有更大计数，则保留兼容值。
    final legacyCount = ValueReaders.intValue(session['compression_count']);
    if (legacyCount > segments.length) {
      return legacyCount;
    }
    return segments.length;
  }

  String _segmentId({
    required int index,
    String rawId = '',
    bool legacy = false,
  }) {
    // 中文注释: 压缩段 ID 允许沿用原始 ID，否则按结构化分段顺序生成稳定标识。
    final cleanRawId = rawId.trim();
    if (cleanRawId.isNotEmpty) {
      return cleanRawId;
    }
    final prefix = legacy ? 'legacy_compaction' : 'compaction_segment';
    return '${prefix}_${index + 1}';
  }
}
