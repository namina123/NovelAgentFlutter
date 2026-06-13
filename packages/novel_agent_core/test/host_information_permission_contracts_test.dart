import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Host information permission contracts', () {
    test('context codec preserves known fields and unknown metadata', () {
      final context = HostInformationPermissionContext.fromJson(
        <String, Object?>{
          'allow_network': true,
          'allow_import_collection': true,
          'permission_mode': HostInformationPermissionModes.open,
          'confirmation_mode': HostInformationConfirmationModes.automatic,
          'source': 'settings_repository',
          'future_permission_flag': <String, Object?>{'retain': true},
        },
      );

      final encoded = context.toJson();

      expect(context.validateBasics(), isEmpty);
      expect(context.allowNetwork, isTrue);
      expect(context.allowImportCollection, isTrue);
      expect(context.permissionMode, HostInformationPermissionModes.open);
      expect(
        context.confirmationMode,
        HostInformationConfirmationModes.automatic,
      );
      expect(context.source, 'settings_repository');
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(encoded['future_permission_flag'])['retain'],
        ),
        isTrue,
      );
    });

    test('validation reports missing permission context fields', () {
      const context = HostInformationPermissionContext();

      expect(
        context.validateBasics(),
        containsAll(<String>[
          InformationValidationCodes.missingHostInformationPermissionMode,
          InformationValidationCodes.missingHostInformationConfirmationMode,
          InformationValidationCodes.missingHostInformationPermissionSource,
        ]),
      );
    });

    test(
      'open host context overrides model false into effective network access',
      () {
        const resolver = HostInformationPermissionResolverService();
        const context = HostInformationPermissionContext(
          allowNetwork: true,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.open,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'host.open_profile',
        );
        const request = InformationCollectionRequest(
          query: '晚唐礼制资料',
          collectionMode: InformationCollectionModes.network,
          userGrantedNetworkAccess: false,
        );

        final resolution = resolver.resolve(
          request: request,
          hostContext: context,
        );

        expect(resolution.rawModelUserGrantedNetworkAccess, isFalse);
        expect(resolution.effectiveUserGrantedNetworkAccess, isTrue);
        expect(resolution.effectiveRequest.userGrantedNetworkAccess, isTrue);
        expect(
          ValueReaders.boolValue(
            resolution
                .effectiveRequest
                .metadata['raw_model_user_granted_network_access'],
          ),
          isFalse,
        );
      },
    );

    test(
      'safe host context overrides model true into denied network access',
      () {
        const resolver = HostInformationPermissionResolverService();
        const context = HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.safe,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'host.safe_profile',
        );
        const request = InformationCollectionRequest(
          query: '古代海图资料',
          collectionMode: InformationCollectionModes.network,
          userGrantedNetworkAccess: true,
        );

        final resolution = resolver.resolve(
          request: request,
          hostContext: context,
        );

        expect(resolution.rawModelUserGrantedNetworkAccess, isTrue);
        expect(resolution.effectiveUserGrantedNetworkAccess, isFalse);
        expect(resolution.effectiveRequest.userGrantedNetworkAccess, isFalse);
        expect(
          ValueReaders.stringValue(
            resolution.effectiveRequest.metadata['host_permission_mode'],
          ),
          HostInformationPermissionModes.safe,
        );
      },
    );

    test(
      'import request does not require network and respects import allowance',
      () {
        const resolver = HostInformationPermissionResolverService();
        const context = HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.importOnly,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'host.import_profile',
        );
        const request = InformationCollectionRequest(
          query: '从导入资料中抽取命名线索',
          collectionMode: InformationCollectionModes.import,
          userGrantedNetworkAccess: true,
          metadata: <String, Object?>{
            'import_relative_path': 'research/imported-notes.md',
          },
        );

        final resolution = resolver.resolve(
          request: request,
          hostContext: context,
        );

        expect(resolution.requiresNetwork, isFalse);
        expect(resolution.requestsImportCollection, isTrue);
        expect(resolution.importCollectionAllowed, isTrue);
        expect(resolution.effectiveUserGrantedNetworkAccess, isFalse);
        expect(resolution.effectiveRequest.userGrantedNetworkAccess, isFalse);
      },
    );

    test(
      'unknown mode still resolves by explicit host booleans and keeps metadata',
      () {
        const resolver = HostInformationPermissionResolverService();
        final context =
            HostInformationPermissionContext.fromJson(<String, Object?>{
              'allow_network': true,
              'allow_import_collection': false,
              'permission_mode': HostInformationPermissionModes.unknown,
              'confirmation_mode': HostInformationConfirmationModes.unknown,
              'source': 'host.experimental_profile',
              'future_mode_label': 'mystery',
            });
        const request = InformationCollectionRequest(
          query: '世界树意象资料',
          collectionMode: InformationCollectionModes.hybrid,
          userGrantedNetworkAccess: false,
          metadata: <String, Object?>{
            'import_relative_path': 'research/world-tree-notes.md',
          },
        );

        final resolution = resolver.resolve(
          request: request,
          hostContext: context,
        );
        final encoded = resolution.toJson();

        expect(resolution.requiresNetwork, isTrue);
        expect(resolution.requestsImportCollection, isTrue);
        expect(resolution.importCollectionAllowed, isFalse);
        expect(resolution.effectiveUserGrantedNetworkAccess, isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(encoded['host_context'])['future_mode_label'],
          ),
          'mystery',
        );
      },
    );
  });
}
