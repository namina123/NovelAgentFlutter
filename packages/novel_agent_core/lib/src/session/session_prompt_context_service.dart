import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'session_compaction_prompt_contracts.dart';
import 'session_context_pressure_contracts.dart';
import 'session_context_renderer_service.dart';
import 'session_message_service.dart';
import 'session_prompt_context.dart';
import 'session_record_constants.dart';
import 'session_record_normalizer_service.dart';

class SessionPromptContextService {
  SessionPromptContextService({
    required SessionRecordNormalizerService normalizerService,
    required SessionMessageService messageService,
    required SessionContextRendererService contextRendererService,
  }) : _normalizerService = normalizerService,
       _messageService = messageService,
       _contextRendererService = contextRendererService;

  final SessionRecordNormalizerService _normalizerService;
  final SessionMessageService _messageService;
  final SessionContextRendererService _contextRendererService;

  SessionPromptContext buildFromSessionRecord(
    JsonMap sessionRecord, {
    String excludeLatestUserContent = '',
    SessionContextPressureSnapshot? pressureSnapshot,
    CompactionGuidanceContract? compactionGuidance,
    CompactionOutputPolicy? compactionOutputPolicy,
    CompactionSourceScope? compactionSourceScope,
    RuntimeContinuationInstructionContract? runtimeContinuationInstruction,
  }) {
    // 中文注释: 模型输入拆成真实历史消息和运行时摘要两轨，避免把历史对话压成一坨说明文。
    final normalized = _normalizerService.normalizeSessionRecord(
      sessionRecord,
      defaultThresholdChars: SessionRecordConstants.defaultThresholdChars,
    );
    final historyMessages = _messageService
        .messagesForContext(
          _messageService.normalizeMessages(
            normalized[SessionRecordConstants.workingContextMessagesField],
          ),
          excludeLatestUserContent: excludeLatestUserContent,
        )
        .where(_isPromptHistoryMessage)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
    final contextMarkdown = _contextRendererService.sessionContextMarkdown(
      normalized,
      options: <String, Object?>{
        'exclude_latest_user_content': excludeLatestUserContent,
        'include_working_messages': false,
        if (pressureSnapshot != null) 'pressure_snapshot': pressureSnapshot,
        if (compactionGuidance != null)
          'compaction_guidance': compactionGuidance,
        if (compactionOutputPolicy != null)
          'compaction_output_policy': compactionOutputPolicy,
        if (compactionSourceScope != null)
          'compaction_source_scope': compactionSourceScope,
        if (runtimeContinuationInstruction != null)
          'runtime_continuation_instruction': runtimeContinuationInstruction,
      },
    );
    return SessionPromptContext(
      contextMarkdown: contextMarkdown,
      historyMessages: historyMessages,
    );
  }

  bool _isPromptHistoryMessage(JsonMap message) {
    final role = ValueReaders.stringValue(message['role']).trim();
    return role == 'user' || role == 'assistant' || role == 'tool';
  }
}
