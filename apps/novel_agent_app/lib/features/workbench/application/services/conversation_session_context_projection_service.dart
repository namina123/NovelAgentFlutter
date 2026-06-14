import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/conversation_context_compaction_segment_view_data.dart';
import '../../presentation/models/conversation_context_projection_view_data.dart';
import '../models/conversation_session_state.dart';

class ConversationSessionContextProjectionService {
  ConversationSessionContextProjectionService({
    SessionContextPressureService? pressureService,
    SessionMessageService? messageService,
  }) : _pressureService =
           pressureService ?? const SessionContextPressureService(),
       _messageService = messageService ?? SessionMessageService();

  final SessionContextPressureService _pressureService;
  final SessionMessageService _messageService;

  ConversationContextProjectionViewData build({
    required ConversationSessionState state,
    JsonMap runtimeProfile = const <String, Object?>{},
  }) {
    // 中文注释: 这层只负责把 session record 投影成 GUI 需要的稳定上下文事实，不做任何压缩决策。
    final normalizedRecord = ValueReaders.deepCopyMap(state.sessionRecord);
    final pressureSnapshot = _pressureSnapshotFrom(
      sessionRecord: normalizedRecord,
      runtimeProfile: runtimeProfile,
    );
    final transcriptMessages = _messageService.normalizeMessages(
      normalizedRecord[SessionRecordConstants.transcriptMessagesField],
    );
    final workingMessages = _messageService.normalizeMessages(
      normalizedRecord[SessionRecordConstants.workingContextMessagesField],
    );
    final compactionSegments = _segmentViewDataFrom(
      normalizedRecord[SessionRecordConstants.compactionSegmentsField],
    );
    return ConversationContextProjectionViewData(
      pressureSnapshot: pressureSnapshot,
      transcriptMessageCount: transcriptMessages.length,
      workingContextMessageCount: workingMessages.length,
      compactionSegments: compactionSegments,
    );
  }

  SessionContextPressureSnapshot _pressureSnapshotFrom({
    required JsonMap sessionRecord,
    required JsonMap runtimeProfile,
  }) {
    // 中文注释: GUI 只消费压力快照结果，不在这里直接复刻 controller 里的发送决策逻辑。
    final settings = _budgetSettingsFrom(runtimeProfile);
    return _pressureService.snapshotFromSessionRecord(
      sessionRecord,
      settings: settings,
      baseFramingTokens: _baseFramingTokens(runtimeProfile),
    );
  }

  SessionTokenBudgetSettings _budgetSettingsFrom(JsonMap runtimeProfile) {
    // 中文注释: 预算设置优先从模型执行 profile 取窗口与输出保留量，保持和发送前预检同源。
    final modelContextWindowTokens = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    final reservedOutputTokens = _reservedOutputTokensFrom(runtimeProfile);
    return SessionTokenBudgetSettings(
      modelContextWindowTokens: modelContextWindowTokens <= 0
          ? 100000
          : modelContextWindowTokens,
      reservedOutputTokens: reservedOutputTokens,
      warningThresholdRatio: 0.8,
      criticalThresholdRatio: 0.95,
    );
  }

  int _reservedOutputTokensFrom(JsonMap runtimeProfile) {
    // 中文注释: 输出保留量只做保守近似，避免 GUI 压力投影和发送前预检出现两套不同的窗口口径。
    final maxOutputTokens = ValueReaders.intValue(
      runtimeProfile['max_output_tokens'],
      2048,
    );
    final contextWindow = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    final fallbackReserve = contextWindow <= 0
        ? 2048
        : ((contextWindow / 10).round().clamp(1024, 16384)).toInt();
    final reserve = maxOutputTokens < fallbackReserve
        ? maxOutputTokens
        : fallbackReserve;
    return reserve < 0 ? 0 : reserve;
  }

  int _baseFramingTokens(JsonMap runtimeProfile) {
    // 中文注释: 这里保守预留一点 framing 开销，覆盖系统提示和 prompt 外壳，不把 GUI 压力投影算得过满。
    final contextWindow = ValueReaders.intValue(
      runtimeProfile['context_length'],
      ValueReaders.intValue(runtimeProfile['compression_context_length'], 0),
    );
    if (contextWindow <= 0) {
      return 128;
    }
    final framed = (contextWindow / 100).round();
    return framed.clamp(64, 512).toInt();
  }

  List<ConversationContextCompactionSegmentViewData> _segmentViewDataFrom(
    Object? rawSegments,
  ) {
    // 中文注释: 压缩段在 GUI 中只投影为稳定的折叠卡，不把原始 Map 继续泄漏到 widget 层。
    final segments = ValueReaders.mapList(rawSegments);
    if (segments.isEmpty) {
      return const <ConversationContextCompactionSegmentViewData>[];
    }
    return segments
        .asMap()
        .entries
        .map((entry) {
          final segment = entry.value;
          final title = ValueReaders.stringValue(segment['title']).trim();
          final summary = ValueReaders.stringValue(segment['summary']).trim();
          final sourceMessageCount = ValueReaders.intValue(
            segment['source_message_count'],
          );
          final createdAt = ValueReaders.stringValue(
            segment['created_at'],
          ).trim();
          final roles = ValueReaders.stringList(
            segment['source_message_roles'],
          );
          return ConversationContextCompactionSegmentViewData(
            id: 'segment_${entry.key}',
            title: title.isEmpty ? '归档段' : title,
            summary: summary,
            sourceMessageCount: sourceMessageCount,
            createdAt: createdAt,
            sourceMessageRoles: List<String>.unmodifiable(roles),
          );
        })
        .toList(growable: false);
  }
}
