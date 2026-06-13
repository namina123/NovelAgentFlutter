import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationResearchCoordinatorService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectInformationDomainToolExecutor informationExecutor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-research-coordinator-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      informationExecutor = ProjectInformationDomainToolExecutor(
        workspacePort: workspacePort,
        researchCoordinatorService: _NoopResearchCoordinatorService(
          workspacePort: workspacePort,
        ),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('approved network request can execute gateway even under safe host', () async {
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'approved-safe-network',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '镜潮互文',
            'purpose': '补充卷末资料',
            'requested_depth': InformationResearchDepths.standard,
            'collection_mode': InformationCollectionModes.network,
            'user_granted_network_access': true,
          },
        ),
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.safe,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'test.safe',
        ),
      );
      final actionService = ProjectPendingResearchActionService(
        workspacePort: workspacePort,
      );
      await actionService.approve(
        project,
        requestId: 'research_request_approved-safe-network',
        actorId: 'user-1',
        note: '允许继续执行联网研究',
      );
      final fakeGateway = _FakeGatewayToolExecutor(
        responses: <String, JsonMap>{
          'search_internet': <String, Object?>{
            'ok': true,
            'results': <Object?>[
              <String, Object?>{
                'title': 'Mirror Tide Motif',
                'url': 'https://example.com/mirror-tide',
                'snippet': '镜与潮承担身份映照。',
              },
            ],
          },
          'fetch_url_content': <String, Object?>{
            'ok': true,
            'status_code': 200,
            'content_type': 'text/html',
            'content': '镜潮互文通常承担身份错位与回声命运提示。',
            'truncated': false,
          },
        },
      );
      final coordinator = ProjectInformationResearchCoordinatorService(
        workspacePort: workspacePort,
        gatewayService: ProjectResearchGatewayService(
          workspacePort: workspacePort,
          gatewayToolExecutor: fakeGateway,
        ),
      );

      final result = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_approved-safe-network',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.safe,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'test.safe',
        ),
        budget: const ProjectInformationResearchExecutionBudget(
          allowGatewayExecution: true,
        ),
      );

      expect(result.executedNetwork, isTrue);
      expect(result.requestState, 'completed');
      expect(fakeGateway.executedGatewayTools, <String>[
        'search_internet',
        'fetch_url_content',
      ]);
      final record = await _readRequestRecord(
        tempDirectory,
        'research_request_approved-safe-network',
      );
      expect(ValueReaders.stringValue(record['request_state']), 'completed');
      expect(ValueReaders.boolValue(record['network_execution_performed']), isTrue);
      expect(
        ValueReaders.stringValue(record['generated_research_note_id']),
        'gateway_research_request_approved-safe-network',
      );
    });

    test('import request saves imported research note and completes request', () async {
      await workspacePort.writeTextFile(
        project.rootPath,
        'research/source.md',
        '第一段：星象命名规则。\n\n第二段：北境潮汐传说。',
      );
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'import-request',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '导入资料里的命名线索',
            'purpose': '整理设定',
            'requested_depth': InformationResearchDepths.standard,
            'collection_mode': InformationCollectionModes.import,
            'import_relative_path': 'research/source.md',
          },
        ),
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.importOnly,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'test.import_only',
        ),
      );
      final coordinator = ProjectInformationResearchCoordinatorService(
        workspacePort: workspacePort,
      );

      final result = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_import-request',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.importOnly,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'test.import_only',
        ),
      );

      expect(result.executedImport, isTrue);
      expect(result.executedNetwork, isFalse);
      expect(result.requestState, 'completed');
      expect(result.generatedResearchNoteIds, hasLength(1));
      final record = await _readRequestRecord(
        tempDirectory,
        'research_request_import-request',
      );
      expect(ValueReaders.stringValue(record['request_state']), 'completed');
      expect(ValueReaders.boolValue(record['import_execution_performed']), isTrue);
      expect(
        ValueReaders.stringValue(record['generated_import_research_note_id']),
        startsWith('import_research_source_md_'),
      );
    });

    test('hybrid request imports first, waits for confirmation, and does not re-import', () async {
      await workspacePort.writeTextFile(
        project.rootPath,
        'research/hybrid.md',
        '第一段：祖灵命名由潮汐与风向共同决定。\n\n第二段：还有地方性俗信待核查。',
      );
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'hybrid-request',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '结合导入札记与外部资料核查命名规则',
            'purpose': '交叉核对',
            'requested_depth': InformationResearchDepths.standard,
            'collection_mode': InformationCollectionModes.hybrid,
            'import_relative_path': 'research/hybrid.md',
            'user_granted_network_access': false,
          },
        ),
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.custom,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'test.hybrid',
        ),
      );
      final coordinator = ProjectInformationResearchCoordinatorService(
        workspacePort: workspacePort,
      );

      final firstRun = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_hybrid-request',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.custom,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'test.hybrid',
        ),
      );
      final secondRun = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_hybrid-request',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.custom,
          confirmationMode:
              HostInformationConfirmationModes.userConfirmationRequired,
          source: 'test.hybrid',
        ),
      );

      expect(firstRun.executedImport, isTrue);
      expect(firstRun.executedNetwork, isFalse);
      expect(firstRun.awaitUserConfirmation, isTrue);
      expect(firstRun.requestState, 'awaiting_user_confirmation');
      expect(secondRun.executedImport, isFalse);
      expect(secondRun.awaitUserConfirmation, isTrue);
      final record = await _readRequestRecord(
        tempDirectory,
        'research_request_hybrid-request',
      );
      expect(ValueReaders.boolValue(record['import_execution_performed']), isTrue);
      expect(
        ValueReaders.stringValue(record['request_state']),
        'awaiting_user_confirmation',
      );
    });

    test('permission blocked request returns structured blocked state', () async {
      await workspacePort.writeTextFile(
        project.rootPath,
        'research/blocked.md',
        '只允许在导入开放时才能读取。',
      );
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'blocked-request',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '受限导入资料',
            'collection_mode': InformationCollectionModes.import,
            'import_relative_path': 'research/blocked.md',
          },
        ),
      );
      final coordinator = ProjectInformationResearchCoordinatorService(
        workspacePort: workspacePort,
      );

      final result = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_blocked-request',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: false,
          allowImportCollection: false,
          permissionMode: HostInformationPermissionModes.custom,
          confirmationMode: HostInformationConfirmationModes.never,
          source: 'test.never',
        ),
      );

      expect(result.blocked, isTrue);
      expect(result.executedImport, isFalse);
      expect(result.executedNetwork, isFalse);
      expect(result.blockedReason, contains('宿主当前禁止导入收集'));
    });

    test('gateway failure is preserved as structured request state', () async {
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'gateway-failure',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '失败的联网研究',
            'purpose': '测试错误路径',
            'requested_depth': InformationResearchDepths.standard,
            'collection_mode': InformationCollectionModes.network,
            'user_granted_network_access': true,
          },
        ),
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: true,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.open,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'test.open',
        ),
      );
      final fakeGateway = _FakeGatewayToolExecutor(
        responses: <String, JsonMap>{
          'search_internet': <String, Object?>{
            'ok': false,
            'error': 'simulated gateway outage',
          },
        },
      );
      final coordinator = ProjectInformationResearchCoordinatorService(
        workspacePort: workspacePort,
        gatewayService: ProjectResearchGatewayService(
          workspacePort: workspacePort,
          gatewayToolExecutor: fakeGateway,
        ),
      );

      final result = await coordinator.processPendingRequest(
        project,
        requestId: 'research_request_gateway-failure',
        hostPermissionContext: const HostInformationPermissionContext(
          allowNetwork: true,
          allowImportCollection: true,
          permissionMode: HostInformationPermissionModes.open,
          confirmationMode: HostInformationConfirmationModes.automatic,
          source: 'test.open',
        ),
        budget: const ProjectInformationResearchExecutionBudget(
          allowGatewayExecution: true,
        ),
      );

      expect(result.executedNetwork, isFalse);
      expect(result.requestState, 'gateway_failed');
      expect(result.blockedReason, 'simulated gateway outage');
      final record = await _readRequestRecord(
        tempDirectory,
        'research_request_gateway-failure',
      );
      expect(ValueReaders.stringValue(record['request_state']), 'gateway_failed');
    });
  });
}

Future<Map<String, Object?>> _readRequestRecord(
  Directory rootDirectory,
  String requestId,
) async {
  final file = File(
    '${rootDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_requests${Platform.pathSeparator}$requestId.json',
  );
  return ValueReaders.mapValue(jsonDecode(await file.readAsString()));
}

class _FakeGatewayToolExecutor extends ProjectGatewayToolExecutor {
  _FakeGatewayToolExecutor({Map<String, JsonMap>? responses})
    : _responses = responses ?? <String, JsonMap>{};

  final Map<String, JsonMap> _responses;
  final List<String> executedGatewayTools = <String>[];

  @override
  Future<JsonMap> execute(ProjectDescriptor project, JsonMap arguments) async {
    final gatewayTool = ValueReaders.stringValue(
      arguments['gateway_tool'],
    ).trim();
    executedGatewayTools.add(gatewayTool);
    return ValueReaders.deepCopyMap(
      _responses[gatewayTool] ??
          <String, Object?>{
            'ok': false,
            'error': 'fake gateway missing response',
          },
    );
  }
}

class _NoopResearchCoordinatorService
    extends ProjectInformationResearchCoordinatorService {
  _NoopResearchCoordinatorService({required super.workspacePort});

  @override
  Future<ProjectInformationResearchCoordinatorResult> processPendingRequest(
    ProjectDescriptor project, {
    required String requestId,
    required HostInformationPermissionContext hostPermissionContext,
    ProjectInformationResearchExecutionBudget budget =
        const ProjectInformationResearchExecutionBudget(),
  }) async {
    return const ProjectInformationResearchCoordinatorResult(
      requestId: '',
      requestState: '',
      summary: 'test noop coordinator',
    );
  }
}

NarrativeSourceRef _source(String sourceType) {
  return NarrativeSourceRef(
    sourceType: sourceType,
    sourceId: 'source-$sourceType',
    label: sourceType,
  );
}
