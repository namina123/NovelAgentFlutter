import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/settings/application/services/context_settings_contract_service.dart';

void main() {
  const service = ContextSettingsContractService();

  test('normalizes legacy settings into the token-pressure contract', () {
    final normalized = service.normalizeForStorage(<String, Object?>{
      ContextSettingsContractService.compressionThresholdPercentKey: '60',
      ContextSettingsContractService.contextPackBudgetPercentKey: '55',
      ContextSettingsContractService.maxContextFileCharsKey: '2400',
      ContextSettingsContractService.maxContextFilesPerKindKey: '6',
      ContextSettingsContractService.reservedOutputCharsKey: '20000',
      ContextSettingsContractService.modelContextWindowTokensKey: '120000',
    });

    expect(
      normalized[ContextSettingsContractService.modelContextWindowTokensKey],
      120000,
    );
    expect(
      normalized[ContextSettingsContractService.contextWindowHintTokensKey],
      120000,
    );
    expect(
      normalized[ContextSettingsContractService.warningThresholdRatioKey],
      closeTo(0.6, 0.0001),
    );
    expect(
      normalized[ContextSettingsContractService.criticalThresholdRatioKey],
      closeTo(0.95, 0.0001),
    );
    expect(
      normalized[ContextSettingsContractService.reservedOutputTokensKey],
      20000,
    );
    expect(
      normalized[ContextSettingsContractService.autoCompactPolicyKey],
      'warning_and_critical',
    );
    expect(
      normalized[ContextSettingsContractService.preferExactCountKey],
      isFalse,
    );
    expect(
      normalized[ContextSettingsContractService.compactionOutputPolicyKey],
      'structured_bullets',
    );
    expect(
      normalized[ContextSettingsContractService.compressionThresholdPercentKey],
      60,
    );
  });

  test('runtime strategy exposes token fields and legacy bridge together', () {
    final runtime = service.runtimeStrategySettings(<String, Object?>{
      ContextSettingsContractService.modelContextWindowTokensKey: 150000,
      ContextSettingsContractService.contextWindowHintTokensKey: 120000,
      ContextSettingsContractService.warningThresholdRatioKey: 0.7,
      ContextSettingsContractService.criticalThresholdRatioKey: 0.9,
      ContextSettingsContractService.reservedOutputTokensKey: 4096,
      ContextSettingsContractService.autoCompactPolicyKey: 'warning',
      ContextSettingsContractService.preferExactCountKey: true,
      ContextSettingsContractService.compactionOutputPolicyKey:
          'balanced_bullets',
    });

    expect(
      runtime[ContextSettingsContractService.modelContextWindowTokensKey],
      150000,
    );
    expect(
      runtime[ContextSettingsContractService.contextWindowHintTokensKey],
      120000,
    );
    expect(
      runtime[ContextSettingsContractService.warningThresholdRatioKey],
      0.7,
    );
    expect(
      runtime[ContextSettingsContractService.criticalThresholdRatioKey],
      0.9,
    );
    expect(
      runtime[ContextSettingsContractService.reservedOutputTokensKey],
      4096,
    );
    expect(
      runtime[ContextSettingsContractService.autoCompactPolicyKey],
      'warning',
    );
    expect(runtime[ContextSettingsContractService.preferExactCountKey], isTrue);
    expect(
      runtime[ContextSettingsContractService.compactionOutputPolicyKey],
      'balanced_bullets',
    );
    expect(
      runtime[ContextSettingsContractService.compressionThresholdPercentKey],
      70,
    );
    expect(
      runtime[ContextSettingsContractService.reservedOutputCharsKey],
      4096,
    );
  });
}
