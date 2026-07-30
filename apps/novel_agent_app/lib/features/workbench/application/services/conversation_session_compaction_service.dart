import 'package:novel_agent_core/novel_agent_core.dart';

class ConversationSessionCompactionService {
  ConversationSessionCompactionService({
    SessionRecordNormalizerService? normalizerService,
    SessionMessageService? messageService,
  }) : _normalizerService =
           normalizerService ??
           SessionRecordNormalizerService(
             modeService: SessionModeService(),
             messageService: messageService ?? SessionMessageService(),
           ),
       _messageService = messageService ?? SessionMessageService();

  final SessionRecordNormalizerService _normalizerService;
  final SessionMessageService _messageService;

  JsonMap compactSessionRecord({
    required JsonMap sessionRecord,
    required SessionCompactionDecision decision,
    required CompactionOutputPolicy outputPolicy,
    String now = '',
  }) {
    // 中文注释: 发送前压缩只重排 working context 与 archive 分段，不碰完整转录，也不在 controller 里手写压缩规则。
    if (!decision.shouldCompact || !decision.plan.hasCompactionCandidates) {
      return _normalizerService.normalizeSessionRecord(
        sessionRecord,
        defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
        now: now,
      );
    }
    final timestamp = now.trim().isEmpty
        ? DateTime.now().toIso8601String()
        : now.trim();
    final normalized = _normalizerService.normalizeSessionRecord(
      sessionRecord,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
      now: timestamp,
    );
    final workingMessages = _messageService.normalizeMessages(
      normalized[SessionRecordConstants.workingContextMessagesField],
    );
    final compactedMessages = <JsonMap>[];
    final retainedMessages = <JsonMap>[];
    final compactedIndices = decision.plan.compactionMessageIndices.toSet();
    for (var index = 0; index < workingMessages.length; index += 1) {
      final message = workingMessages[index];
      if (compactedIndices.contains(index)) {
        compactedMessages.add(message);
      } else {
        retainedMessages.add(message);
      }
    }
    if (compactedMessages.isEmpty) {
      return normalized;
    }
    final nextSegments = List<JsonMap>.from(
      ValueReaders.mapList(
        normalized[SessionRecordConstants.compactionSegmentsField],
      ),
    );
    nextSegments.add(
      _buildCompactionSegment(
        messages: compactedMessages,
        plan: decision.plan,
        outputPolicy: outputPolicy,
        timestamp: timestamp,
      ),
    );
    final nextRecord = ValueReaders.deepCopyMap(normalized)
      ..[SessionRecordConstants.workingContextMessagesField] = retainedMessages
      ..[SessionRecordConstants.legacyContextMessagesField] = retainedMessages
      ..[SessionRecordConstants.compactionSegmentsField] = nextSegments;
    return _normalizerService.normalizeSessionRecord(
      nextRecord,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
      now: timestamp,
    );
  }

  JsonMap _buildCompactionSegment({
    required List<JsonMap> messages,
    required SessionCompactionPlan plan,
    required CompactionOutputPolicy outputPolicy,
    required String timestamp,
  }) {
    // 中文注释: 压缩段只记录来源窗口与可读摘要，不把整个 working context 再塞回 archive。
    final summary = _buildSummary(
      messages: messages,
      plan: plan,
      outputPolicy: outputPolicy,
    );
    return <String, Object?>{
      'kind': 'preflight_compaction',
      'title': '发送前压缩',
      'summary': summary,
      'source_message_count': messages.length,
      'source_message_roles': messages
          .map((message) => ValueReaders.stringValue(message['role'], 'user'))
          .where((role) => role.trim().isNotEmpty)
          .toList(growable: false),
      'created_at': timestamp,
    };
  }

  String _buildSummary({
    required List<JsonMap> messages,
    required SessionCompactionPlan plan,
    required CompactionOutputPolicy outputPolicy,
  }) {
    // 中文注释: 摘要控制在独立输出策略里，避免压缩段本身继续膨胀成第二个长 prompt。
    final maxBulletCount = outputPolicy.maxBulletCount > 0
        ? outputPolicy.maxBulletCount
        : 6;
    final maxCharacters = outputPolicy.maxCharacters > 0
        ? outputPolicy.maxCharacters
        : 1200;
    final lines = <String>[
      '来源 ${messages.length} 条消息，保留最近 ${plan.keepRecentMessageCount} 条工作消息。',
    ];
    final clippedMessages = messages
        .take(maxBulletCount)
        .toList(growable: false);
    for (var index = 0; index < clippedMessages.length; index += 1) {
      final message = clippedMessages[index];
      final role = ValueReaders.stringValue(message['role'], 'user').trim();
      final content = _clipText(
        ValueReaders.stringValue(message['content']),
        240,
      );
      if (content.isEmpty) {
        continue;
      }
      lines.add('- $role: $content');
    }
    final summary = lines.join('\n');
    if (maxCharacters <= 0 || summary.length <= maxCharacters) {
      return summary;
    }
    return summary.substring(0, maxCharacters);
  }

  String _clipText(String value, int maxChars) {
    // 中文注释: 压缩段摘要只保留必要长度，避免少量超长消息把整个 archive 撑爆。
    final clean = value.trim();
    if (clean.length <= maxChars) {
      return clean;
    }
    if (maxChars <= 0) {
      return '';
    }
    if (maxChars <= 1) {
      return clean.substring(0, 1);
    }
    return '${clean.substring(0, maxChars - 1)}...';
  }
}
