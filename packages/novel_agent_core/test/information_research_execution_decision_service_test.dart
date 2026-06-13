import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Information research execution decision service', () {
    test('open network request auto executes network', () {
      const service = InformationResearchExecutionDecisionService();
      const request = InformationCollectionRequest(
        query: '唐代藩镇制度资料',
        collectionMode: InformationCollectionModes.network,
        informationDomain: InformationDomains.history,
        userGrantedNetworkAccess: false,
      );
      const hostContext = HostInformationPermissionContext(
        allowNetwork: true,
        allowImportCollection: true,
        permissionMode: HostInformationPermissionModes.open,
        confirmationMode: HostInformationConfirmationModes.automatic,
        source: 'host.open_profile',
      );
      const permissionDecision = InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
      );

      final decision = service.decide(
        request: request,
        hostPermissionContext: hostContext,
        permissionDecision: permissionDecision,
      );

      expect(decision.autoExecuteNetwork, isTrue);
      expect(decision.autoExecuteImport, isFalse);
      expect(decision.awaitUserConfirmation, isFalse);
      expect(decision.blocked, isFalse);
      expect(decision.effectiveRequest.userGrantedNetworkAccess, isTrue);
    });

    test('restricted network request waits for user confirmation', () {
      const service = InformationResearchExecutionDecisionService();
      const request = InformationCollectionRequest(
        query: '古代海图资料',
        collectionMode: InformationCollectionModes.network,
        userGrantedNetworkAccess: true,
      );
      const hostContext = HostInformationPermissionContext(
        allowNetwork: false,
        allowImportCollection: true,
        permissionMode: HostInformationPermissionModes.safe,
        confirmationMode:
            HostInformationConfirmationModes.userConfirmationRequired,
        source: 'host.safe_profile',
      );
      const permissionDecision = InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
      );

      final decision = service.decide(
        request: request,
        hostPermissionContext: hostContext,
        permissionDecision: permissionDecision,
      );

      expect(decision.autoExecuteNetwork, isFalse);
      expect(decision.autoExecuteImport, isFalse);
      expect(decision.awaitUserConfirmation, isTrue);
      expect(decision.blocked, isFalse);
      expect(decision.reason, contains('宿主授权'));
    });

    test('import request auto executes import without network', () {
      const service = InformationResearchExecutionDecisionService();
      const request = InformationCollectionRequest(
        query: '导入资料中的命名暗线',
        collectionMode: InformationCollectionModes.import,
        userGrantedNetworkAccess: true,
        metadata: <String, Object?>{
          'import_relative_path': 'research/imported-notes.md',
        },
      );
      const hostContext = HostInformationPermissionContext(
        allowNetwork: false,
        allowImportCollection: true,
        permissionMode: HostInformationPermissionModes.importOnly,
        confirmationMode: HostInformationConfirmationModes.automatic,
        source: 'host.import_profile',
      );
      const permissionDecision = InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
      );

      final decision = service.decide(
        request: request,
        hostPermissionContext: hostContext,
        permissionDecision: permissionDecision,
      );

      expect(decision.autoExecuteImport, isTrue);
      expect(decision.autoExecuteNetwork, isFalse);
      expect(decision.awaitUserConfirmation, isFalse);
      expect(decision.blocked, isFalse);
      expect(decision.hostPermissionResolution.requiresNetwork, isFalse);
    });

    test('hybrid request imports first and waits for network confirmation', () {
      const service = InformationResearchExecutionDecisionService();
      const request = InformationCollectionRequest(
        query: '神话映射与导入札记交叉核对',
        collectionMode: InformationCollectionModes.hybrid,
        userGrantedNetworkAccess: false,
        metadata: <String, Object?>{
          'import_relative_path': 'research/hybrid-notes.md',
        },
      );
      const hostContext = HostInformationPermissionContext(
        allowNetwork: false,
        allowImportCollection: true,
        permissionMode: HostInformationPermissionModes.custom,
        confirmationMode:
            HostInformationConfirmationModes.userConfirmationRequired,
        source: 'host.hybrid_profile',
      );
      const permissionDecision = InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
      );

      final decision = service.decide(
        request: request,
        hostPermissionContext: hostContext,
        permissionDecision: permissionDecision,
      );

      expect(decision.autoExecuteImport, isTrue);
      expect(decision.autoExecuteNetwork, isFalse);
      expect(decision.awaitUserConfirmation, isTrue);
      expect(decision.blocked, isFalse);
      expect(decision.reason, contains('导入收集'));
      expect(decision.reason, contains('联网研究'));
    });

    test(
      'high risk reference request waits for user confirmation even when open',
      () {
        const service = InformationResearchExecutionDecisionService();
        const request = InformationCollectionRequest(
          query: '同人引用边界资料',
          collectionMode: InformationCollectionModes.network,
          referenceRelationship: 'fanfic_reference',
          userGrantedNetworkAccess: true,
        );
        const hostContext = HostInformationPermissionContext(
          allowNetwork: true,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.open,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'host.open_profile',
        );
        const permissionDecision = InformationPermissionDecision(
          disposition: InformationPermissionDispositions.needsUserConfirmation,
          reason: '涉及高风险外部作品或同人/穿书边界的研究请求仍需用户确认。',
        );

        final decision = service.decide(
          request: request,
          hostPermissionContext: hostContext,
          permissionDecision: permissionDecision,
        );

        expect(decision.autoExecuteNetwork, isFalse);
        expect(decision.autoExecuteImport, isFalse);
        expect(decision.awaitUserConfirmation, isTrue);
        expect(decision.blocked, isFalse);
        expect(decision.reason, contains('高风险外部作品'));
      },
    );

    test('forbidden payload request is blocked immediately', () {
      const service = InformationResearchExecutionDecisionService();
      const request = InformationCollectionRequest(
        query: '执行脚本型资料收集',
        collectionMode: InformationCollectionModes.network,
        userGrantedNetworkAccess: true,
      );
      const hostContext = HostInformationPermissionContext(
        allowNetwork: true,
        allowImportCollection: true,
        permissionMode: HostInformationPermissionModes.open,
        confirmationMode: HostInformationConfirmationModes.automatic,
        source: 'host.open_profile',
      );
      const permissionDecision = InformationPermissionDecision(
        disposition: InformationPermissionDispositions.forbiddenAutoApply,
        reason: '禁止自动执行带有脚本型 payload 的外部研究请求。',
      );

      final decision = service.decide(
        request: request,
        hostPermissionContext: hostContext,
        permissionDecision: permissionDecision,
      );

      expect(decision.autoExecuteImport, isFalse);
      expect(decision.autoExecuteNetwork, isFalse);
      expect(decision.awaitUserConfirmation, isFalse);
      expect(decision.blocked, isTrue);
      expect(decision.reason, contains('脚本型 payload'));
    });
  });
}
