import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationPermissionSettingsResolverService', () {
    const service = ProjectInformationPermissionSettingsResolverService();

    test('defaults to safe host context when settings are missing', () {
      final context = service.resolve(const <String, Object?>{});

      expect(context.allowNetwork, isFalse);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.safe);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.userConfirmationRequired,
      );
      expect(context.source, 'app_settings.permission_settings');
    });

    test('maps open mode into automatic network-enabled host context', () {
      final context = service.resolve(const <String, Object?>{
        'mode': 'all',
        'allow_network': true,
      });

      expect(context.allowNetwork, isTrue);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.open);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.automatic,
      );
    });

    test('maps import_only mode without granting network access', () {
      final context = service.resolve(const <String, Object?>{
        'information_permission_mode': 'import_only',
      });

      expect(context.allowNetwork, isFalse);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.importOnly);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.automatic,
      );
    });

    test('custom mode derives import allowance from local read write capability', () {
      final context = service.resolve(const <String, Object?>{
        'mode': 'custom',
        'allow_read': true,
        'allow_write': true,
        'allow_network': false,
      });

      expect(context.allowNetwork, isFalse);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.custom);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.userConfirmationRequired,
      );
    });

    test('future compatible fields override inferred defaults', () {
      final context = service.resolve(
        const <String, Object?>{
          'permission_mode': 'custom',
          'allow_network': true,
          'allow_import_collection': false,
          'information_confirmation_mode': 'never',
        },
        source: 'settings_repository.future_permissions',
      );

      expect(context.allowNetwork, isTrue);
      expect(context.allowImportCollection, isFalse);
      expect(context.permissionMode, HostInformationPermissionModes.custom);
      expect(context.confirmationMode, HostInformationConfirmationModes.never);
      expect(context.source, 'settings_repository.future_permissions');
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(context.metadata['raw_permission_settings'])[
              'allow_import_collection'],
        ),
        isFalse,
      );
    });

    test('unknown mode keeps safe default for missing network flag', () {
      final context = service.resolveFromAppSettings(
        const AppSettings(
          defaultProviderId: '',
          defaultAgentId: '',
          defaultModelId: '',
          defaultProjectPath: '',
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[],
          permissionSettings: <String, Object?>{
            'mode': 'proposal_required',
          },
        ),
      );

      expect(context.allowNetwork, isFalse);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.unknown);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.userConfirmationRequired,
      );
    });
  });
}
