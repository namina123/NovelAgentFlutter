import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../ports/provider_token_count_port.dart';
import 'session_context_pressure_contracts.dart';
import 'session_record_constants.dart';
import 'session_token_budget_estimator_service.dart';

class SessionContextPressureService {
  const SessionContextPressureService({
    SessionTokenBudgetEstimatorService? estimatorService,
  }) : _estimatorService =
           estimatorService ?? const SessionTokenBudgetEstimatorService();

  final SessionTokenBudgetEstimatorService _estimatorService;

  SessionContextPressureSnapshot snapshot({
    required SessionTokenBudgetSettings settings,
    String systemPrompt = '',
    List<Object?> messages = const <Object?>[],
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 压力服务只把 settings 和 estimate 合成 snapshot，不再引入第二套 budget 判定逻辑。
    final estimate = _estimatorService.estimate(
      systemPrompt: systemPrompt,
      messages: messages,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    );
    return SessionContextPressureSnapshot(
      settings: settings,
      estimate: estimate,
    );
  }

  SessionContextPressureSnapshot snapshotFromSessionRecord(
    JsonMap sessionRecord, {
    required SessionTokenBudgetSettings settings,
    String systemPrompt = '',
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 这里直接从 session record 生成压力快照，方便发送前/续跑前入口复用同一套预判。
    final messages = _contextMessagesFromRecord(sessionRecord);
    return snapshot(
      settings: settings,
      systemPrompt: systemPrompt,
      messages: messages,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    );
  }

  JsonMap snapshotJson({
    required SessionTokenBudgetSettings settings,
    String systemPrompt = '',
    List<Object?> messages = const <Object?>[],
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: 需要纯 Map 输出时，直接把 snapshot 转成 JSON 形态，避免上层再手写字段投影。
    return snapshot(
      settings: settings,
      systemPrompt: systemPrompt,
      messages: messages,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    ).toJson();
  }

  JsonMap snapshotJsonFromSessionRecord(
    JsonMap sessionRecord, {
    required SessionTokenBudgetSettings settings,
    String systemPrompt = '',
    int baseFramingTokens = 12,
    int? providerExactCountHintTokens,
  }) {
    // 中文注释: session record 的 JSON 快照入口方便测试和未来 runtime preflight 直接拿到稳定压力摘要。
    return snapshotFromSessionRecord(
      sessionRecord,
      settings: settings,
      systemPrompt: systemPrompt,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerExactCountHintTokens,
    ).toJson();
  }

  SessionContextPressureSnapshot snapshotFromProviderTokenCountResult(
    JsonMap sessionRecord, {
    required SessionTokenBudgetSettings settings,
    required ProviderTokenCountResult? providerTokenCountResult,
    String systemPrompt = '',
    int baseFramingTokens = 12,
  }) {
    // 中文注释: exact count 适配口只提供 hint，不取代当前 pressure 估算的分层合同。
    return snapshotFromSessionRecord(
      sessionRecord,
      settings: settings,
      systemPrompt: systemPrompt,
      baseFramingTokens: baseFramingTokens,
      providerExactCountHintTokens: providerTokenCountResult?.exactInputTokens,
    );
  }

  List<Object?> _contextMessagesFromRecord(JsonMap sessionRecord) {
    // 中文注释: 压力判断只消费 working context，旧 context_messages 仅作兼容桥，不让压力服务自己制造第二份历史真相。
    return ValueReaders.objectList(
      sessionRecord[SessionRecordConstants.workingContextMessagesField] ??
          sessionRecord[SessionRecordConstants.legacyContextMessagesField] ??
          sessionRecord[SessionRecordConstants.transcriptMessagesField],
    );
  }
}
