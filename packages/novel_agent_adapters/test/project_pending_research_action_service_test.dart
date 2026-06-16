import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPendingResearchActionService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectInformationDomainToolExecutor informationExecutor;
    late ProjectPendingResearchActionService actionService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-pending-research-action-',
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
      actionService = ProjectPendingResearchActionService(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('list returns only actionable pending research requests', () async {
      await _registerAwaitingRequest(
        informationExecutor,
        project,
        callId: 'awaiting-1',
        query: '北境钟楼象征',
      );
      await _registerOpenPendingRequest(
        informationExecutor,
        project,
        callId: 'pending-1',
        query: '港口潮汐资料',
      );
      await _registerAwaitingRequest(
        informationExecutor,
        project,
        callId: 'rejected-1',
        query: '废弃请求',
      );
      await actionService.reject(
        project,
        requestId: 'research_request_rejected-1',
        actorId: 'user-1',
        note: '当前卷暂不需要',
      );

      final result = await actionService.list(project);

      expect(
        result.map((entry) => ValueReaders.stringValue(entry['request_id'])),
        containsAll(<String>[
          'research_request_awaiting-1',
          'research_request_pending-1',
        ]),
      );
      expect(
        result.map((entry) => ValueReaders.stringValue(entry['request_id'])),
        isNot(contains('research_request_rejected-1')),
      );
    });

    test(
      'load returns the stored pending research record with relative path',
      () async {
        await _registerAwaitingRequest(
          informationExecutor,
          project,
          callId: 'load-1',
          query: '北境钟楼象征',
        );

        final record = await actionService.load(
          project,
          requestId: 'research_request_load-1',
        );

        expect(
          ValueReaders.stringValue(record['request_id']),
          'research_request_load-1',
        );
        expect(
          ValueReaders.stringValue(record['relative_path']),
          '.novel_agent/information/research_requests/research_request_load-1.json',
        );
      },
    );

    test(
      'approve moves awaiting request back to pending gateway execution and appends audit event',
      () async {
        await _registerAwaitingRequest(
          informationExecutor,
          project,
          callId: 'approve-1',
          query: '海港贸易风俗',
        );

        final result = await actionService.approve(
          project,
          requestId: 'research_request_approve-1',
          actorId: 'user-approve',
          note: '允许继续研究',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['request_state']),
          'pending_gateway_execution',
        );
        expect(
          ValueReaders.stringList(result['changed_paths']),
          containsAll(<String>[
            '.novel_agent/information/research_requests/research_request_approve-1.json',
            '.novel_agent/information/research_requests/index.json',
            '.novel_agent/information/events/events.jsonl',
          ]),
        );
        final record = await _readRequestRecord(
          tempDirectory,
          'research_request_approve-1',
        );
        expect(
          ValueReaders.stringValue(record['request_state']),
          'pending_gateway_execution',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(record['permission_decision'])['disposition'],
          ),
          DomainToolPermissionDispositions.accepted,
        );
        expect(ValueReaders.stringValue(record['resolved_by']), 'user-approve');
        expect(ValueReaders.stringValue(record['resolution_note']), '允许继续研究');
        final metadata = ValueReaders.mapValue(record['metadata']);
        final latestAction = ValueReaders.mapValue(
          metadata['latest_pending_research_action'],
        );
        expect(ValueReaders.stringValue(latestAction['command']), 'approve');
        final eventLog = await _readEventLog(tempDirectory);
        expect(eventLog, contains('"event_type":"research_request_approved"'));
        expect(eventLog, contains('允许继续研究'));
      },
    );

    test(
      'reject keeps request record and marks it rejected without pretending research completed',
      () async {
        await _registerAwaitingRequest(
          informationExecutor,
          project,
          callId: 'reject-1',
          query: '边境祭典谱系',
        );

        final result = await actionService.reject(
          project,
          requestId: 'research_request_reject-1',
          actorId: 'user-reject',
          note: '先保持证据缺口',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['request_state']), 'rejected');
        final record = await _readRequestRecord(
          tempDirectory,
          'research_request_reject-1',
        );
        expect(ValueReaders.stringValue(record['request_state']), 'rejected');
        expect(
          ValueReaders.boolValue(record['network_execution_performed']),
          isFalse,
        );
        expect(record.containsKey('generated_research_note_id'), isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(record['permission_decision'])['disposition'],
          ),
          DomainToolPermissionDispositions.rejected,
        );
      },
    );

    test(
      'markNeedsUserInfo leaves request pending but signals more user info is needed',
      () async {
        await _registerAwaitingRequest(
          informationExecutor,
          project,
          callId: 'needs-info-1',
          query: '北海航线资料',
        );

        final result = await actionService.markNeedsUserInfo(
          project,
          requestId: 'research_request_needs-info-1',
          actorId: 'user-info',
          note: '请先补充年代范围',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['request_state']),
          'needs_user_info',
        );
        final record = await _readRequestRecord(
          tempDirectory,
          'research_request_needs-info-1',
        );
        expect(
          ValueReaders.stringValue(record['request_state']),
          'needs_user_info',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(record['permission_decision'])['disposition'],
          ),
          DomainToolPermissionDispositions.needsUserConfirmation,
        );
        final eventLog = await _readEventLog(tempDirectory);
        expect(
          eventLog,
          contains('"event_type":"research_request_needs_user_info"'),
        );
      },
    );

    test(
      'missing request returns structured error and no changed paths',
      () async {
        final result = await actionService.approve(
          project,
          requestId: 'research_request_missing',
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          'Pending research request not found.',
        );
        expect(ValueReaders.stringList(result['changed_paths']), isEmpty);
      },
    );

    test(
      'repeating reject on already rejected request is idempotent',
      () async {
        await _registerAwaitingRequest(
          informationExecutor,
          project,
          callId: 'repeat-reject-1',
          query: '海图纹样',
        );
        await actionService.reject(
          project,
          requestId: 'research_request_repeat-reject-1',
          actorId: 'user-repeat',
        );

        final result = await actionService.reject(
          project,
          requestId: 'research_request_repeat-reject-1',
          actorId: 'user-repeat',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['action_status']),
          'already_applied',
        );
        expect(ValueReaders.stringList(result['changed_paths']), isEmpty);
      },
    );
  });
}

Future<void> _registerAwaitingRequest(
  ProjectInformationDomainToolExecutor executor,
  ProjectDescriptor project, {
  required String callId,
  required String query,
}) {
  return executor.execute(
    project,
    DomainToolRequest(
      callId: callId,
      toolName: NarrativeDomainToolNames.requestExternalResearch,
      source: _source(NarrativeSourceTypes.writer),
      requestPayload: <String, Object?>{
        'query': query,
        'purpose': '补充资料',
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
}

Future<void> _registerOpenPendingRequest(
  ProjectInformationDomainToolExecutor executor,
  ProjectDescriptor project, {
  required String callId,
  required String query,
}) {
  return executor.execute(
    project,
    DomainToolRequest(
      callId: callId,
      toolName: NarrativeDomainToolNames.requestExternalResearch,
      source: _source(NarrativeSourceTypes.writer),
      requestPayload: <String, Object?>{
        'query': query,
        'purpose': '补充资料',
        'requested_depth': InformationResearchDepths.standard,
        'collection_mode': InformationCollectionModes.network,
        'user_granted_network_access': false,
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

Future<String> _readEventLog(Directory rootDirectory) {
  final file = File(
    '${rootDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}events${Platform.pathSeparator}events.jsonl',
  );
  return file.readAsString();
}

NarrativeSourceRef _source(String sourceType) {
  return NarrativeSourceRef(
    sourceType: sourceType,
    sourceId: 'source-$sourceType',
    label: sourceType,
  );
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
