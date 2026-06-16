import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  test('prefers canonical draft fallback protection field', () {
    const settings = AppSettings(
      defaultProviderId: 'provider_1',
      defaultAgentId: 'agent_1',
      defaultModelId: 'model_1',
      defaultProjectPath: 'D:/projects',
      draftFallbackProtectionEnabled: false,
      providers: <ProviderEndpointSettings>[],
    );

    expect(settings.draftFallbackProtectionEnabled, isFalse);
    expect(settings.autoSaveDrafts, isFalse);
  });

  test('keeps legacy autoSaveDrafts constructor and copyWith alias compatible', () {
    const settings = AppSettings(
      defaultProviderId: 'provider_1',
      defaultAgentId: 'agent_1',
      defaultModelId: 'model_1',
      defaultProjectPath: 'D:/projects',
      autoSaveDrafts: true,
      providers: <ProviderEndpointSettings>[],
    );

    final updated = settings.copyWith(
      draftFallbackProtectionEnabled: false,
    );
    final legacyUpdated = updated.copyWith(autoSaveDrafts: true);

    expect(settings.draftFallbackProtectionEnabled, isTrue);
    expect(updated.draftFallbackProtectionEnabled, isFalse);
    expect(legacyUpdated.draftFallbackProtectionEnabled, isTrue);
  });
}
