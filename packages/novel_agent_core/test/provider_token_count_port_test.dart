import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Provider token count port contracts', () {
    test('round-trips exact count results and keeps usage auxiliary', () {
      // 中文注释: exact count 结果必须稳定往返，并把 reported usage 只保留为辅助信息。
      final result = ProviderTokenCountResult(
        providerId: 'openai',
        modelId: 'gpt-4.1',
        exactInputTokens: 1234,
        reportedUsage: <String, Object?>{
          'input_tokens': 1200,
          'output_tokens': 256,
        },
        metadata: <String, Object?>{'request_id': 'req-1'},
      );

      expect(result.validateBasics(), isEmpty);
      expect(result.hasExactInputTokens, isTrue);
      expect(result.toJson(), containsPair('exact_input_tokens', 1234));
      expect(
        result.toJson(),
        containsPair('count_source', 'provider_exact_count'),
      );

      final decoded = ProviderTokenCountResult.fromJson(result.toJson());
      expect(decoded.providerId, 'openai');
      expect(decoded.modelId, 'gpt-4.1');
      expect(decoded.exactInputTokens, 1234);
      expect(decoded.countSource, SessionTokenCountSource.providerExactCount);
      expect(decoded.reportedUsage, containsPair('input_tokens', 1200));
    });

    test('pressure service uses provider exact hint when available', () {
      // 中文注释: exact count 只作为 hint 进入现有 pressure snapshot，不替代 core 的工作上下文分层。
      final service = SessionContextPressureService();
      final settings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 10000,
        reservedOutputTokens: 1000,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );
      final sessionRecord = <String, Object?>{
        SessionRecordConstants.workingContextMessagesField: <Object?>[
          <String, Object?>{'role': 'user', 'content': '工作窗口内容'},
        ],
      };
      final snapshot = service.snapshotFromProviderTokenCountResult(
        sessionRecord,
        settings: settings,
        providerTokenCountResult: ProviderTokenCountResult(
          providerId: 'openai',
          modelId: 'gpt-4.1',
          exactInputTokens: 4321,
        ),
      );

      expect(
        snapshot.estimate.countSource,
        SessionTokenCountSource.providerExactCount,
      );
      expect(snapshot.estimate.providerExactCountHintTokens, 4321);
      expect(snapshot.pressureLevel, SessionContextPressureLevel.safe);
    });
  });
}
