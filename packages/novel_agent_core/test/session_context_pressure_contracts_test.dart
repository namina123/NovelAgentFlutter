import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session context pressure contracts', () {
    test('round-trips token budget settings and estimate through JSON', () {
      // 中文注释: 这里验证 settings 和 estimate 都只依赖 token 口径字段，并且可稳定往返 JSON。
      final settings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 128000,
        reservedOutputTokens: 8000,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );
      final estimate = SessionTokenBudgetEstimate(
        systemPromptTokens: 1200,
        messageTokens: 3456,
        framingTokens: 128,
        providerExactCountHintTokens: 4096,
        countSource: SessionTokenCountSource.providerExactCount,
      );

      expect(settings.inputBudgetTokens, 120000);
      expect(settings.warningThresholdTokens, 90000);
      expect(settings.criticalThresholdTokens, 108000);
      expect(settings.toJson(), <String, Object?>{
        'model_context_window_tokens': 128000,
        'reserved_output_tokens': 8000,
        'warning_threshold_ratio': 0.75,
        'critical_threshold_ratio': 0.9,
      });
      expect(SessionTokenBudgetSettings.fromJson(settings.toJson()), settings);

      expect(estimate.totalInputTokens, 4784);
      expect(estimate.toJson(), <String, Object?>{
        'system_prompt_tokens': 1200,
        'message_tokens': 3456,
        'framing_tokens': 128,
        'total_input_tokens': 4784,
        'token_count_source': 'provider_exact_count',
        'provider_exact_count_hint_tokens': 4096,
      });
      expect(SessionTokenBudgetEstimate.fromJson(estimate.toJson()), estimate);
    });

    test('derives pressure snapshot levels from budget and input usage', () {
      // 中文注释: 这里验证 snapshot 会把 settings 与 estimate 合成唯一压力事实，并推导出 warning/critical。
      final warningSettings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 10000,
        reservedOutputTokens: 1000,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );
      final warningEstimate = SessionTokenBudgetEstimate(
        systemPromptTokens: 1000,
        messageTokens: 7000,
        framingTokens: 500,
        countSource: SessionTokenCountSource.conservativeEstimate,
      );
      final warningSnapshot = SessionContextPressureSnapshot(
        settings: warningSettings,
        estimate: warningEstimate,
      );

      expect(warningSnapshot.inputBudgetTokens, 9000);
      expect(warningSnapshot.remainingInputTokens, 500);
      expect(warningSnapshot.overflowTokens, 0);
      expect(warningSnapshot.usedContextRatio, closeTo(0.944444, 0.000001));
      expect(
        warningSnapshot.pressureLevel,
        SessionContextPressureLevel.critical,
      );
      expect(warningSnapshot.hasOverflow, isFalse);

      final overLimitSettings = SessionTokenBudgetSettings(
        modelContextWindowTokens: 8000,
        reservedOutputTokens: 1000,
        warningThresholdRatio: 0.75,
        criticalThresholdRatio: 0.9,
      );
      final overLimitEstimate = SessionTokenBudgetEstimate(
        systemPromptTokens: 1200,
        messageTokens: 6200,
        framingTokens: 800,
        countSource: SessionTokenCountSource.fallbackEstimate,
      );
      final overLimitSnapshot = SessionContextPressureSnapshot(
        settings: overLimitSettings,
        estimate: overLimitEstimate,
      );

      expect(overLimitSnapshot.inputBudgetTokens, 7000);
      expect(overLimitSnapshot.remainingInputTokens, -1200);
      expect(overLimitSnapshot.overflowTokens, 1200);
      expect(
        overLimitSnapshot.pressureLevel,
        SessionContextPressureLevel.overLimit,
      );
      expect(overLimitSnapshot.hasOverflow, isTrue);
    });

    test('keeps source and level enums stable as JSON strings', () {
      // 中文注释: 这里确认两个枚举的字符串合同固定下来，避免后续协议升级时意外改名。
      expect(
        SessionTokenCountSource.providerExactCount.toJsonValue(),
        'provider_exact_count',
      );
      expect(
        SessionTokenCountSource.fromJsonValue('fallback_estimate'),
        SessionTokenCountSource.fallbackEstimate,
      );
      expect(SessionContextPressureLevel.warning.toJsonValue(), 'warning');
      expect(
        SessionContextPressureLevel.fromJsonValue('over_limit'),
        SessionContextPressureLevel.overLimit,
      );
    });
  });
}
