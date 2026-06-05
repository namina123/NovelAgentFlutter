import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectResearchGatewayService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectInformationDomainToolExecutor informationExecutor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-research-gateway-service-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      informationExecutor = ProjectInformationDomainToolExecutor(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'fake gateway search can generate research note from pending request',
      () async {
        await informationExecutor.execute(
          project,
          DomainToolRequest(
            callId: 'allowed-call-1',
            toolName: NarrativeDomainToolNames.requestExternalResearch,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'query': '镜潮互文',
              'purpose': '补充卷末资料',
              'requested_depth': InformationResearchDepths.standard,
              'reference_relationship': 'inspiration',
              'user_granted_network_access': true,
              'target_refs': <Object?>[
                <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapter-01',
                },
              ],
            },
          ),
        );
        final fakeGateway = _FakeGatewayToolExecutor(
          responses: <String, JsonMap>{
            'search_internet': <String, Object?>{
              'ok': true,
              'results': <Object?>[
                <String, Object?>{
                  'title': 'Mirror Tide Motif',
                  'url': 'https://example.com/mirror-tide',
                  'snippet': '镜与潮常共同承担身份映照。',
                },
              ],
            },
            'fetch_url_content': <String, Object?>{
              'ok': true,
              'status_code': 200,
              'content_type': 'text/html',
              'content': '镜潮互文通常承担身份错位与回声式命运提示。',
              'truncated': false,
            },
          },
        );
        final service = ProjectResearchGatewayService(
          workspacePort: workspacePort,
          gatewayToolExecutor: fakeGateway,
        );

        final result = await service.processPendingRequest(
          project,
          requestId: 'research_request_allowed-call-1',
          allowGatewayExecution: true,
        );

        expect(result.executed, isTrue);
        expect(result.requestState, 'completed');
        expect(result.generatedResearchNote, isNotNull);
        expect(result.generatedResearchNote!.citation, 'Mirror Tide Motif');
        expect(
          result.generatedResearchNote!.sourceUrlOrRef,
          'https://example.com/mirror-tide',
        );
        expect(fakeGateway.executedGatewayTools, <String>[
          'search_internet',
          'fetch_url_content',
        ]);
        final requestFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_requests${Platform.pathSeparator}research_request_allowed-call-1.json',
        );
        final researchFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}gateway_research_request_allowed-call-1.json',
        );
        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}research${Platform.pathSeparator}资料研究摘要.md',
        );
        expect(await requestFile.exists(), isTrue);
        expect(
          await requestFile.readAsString(),
          contains('"request_state": "completed"'),
        );
        expect(
          await requestFile.readAsString(),
          contains(
            '"generated_research_note_id": "gateway_research_request_allowed-call-1"',
          ),
        );
        expect(await researchFile.exists(), isTrue);
        expect(await projectionFile.exists(), isTrue);
        expect(await projectionFile.readAsString(), contains('镜潮互文'));
        expect(
          await researchFile.readAsString(),
          isNot(contains('"content":"镜潮互文通常承担身份错位与回声式命运提示。')),
        );
      },
    );

    test('without permission it does not call gateway', () async {
      await informationExecutor.execute(
        project,
        DomainToolRequest(
          callId: 'blocked-call-1',
          toolName: NarrativeDomainToolNames.requestExternalResearch,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'query': '镜潮互文',
            'purpose': '补充卷末资料',
            'requested_depth': InformationResearchDepths.standard,
            'user_granted_network_access': false,
          },
        ),
      );
      final fakeGateway = _FakeGatewayToolExecutor();
      final service = ProjectResearchGatewayService(
        workspacePort: workspacePort,
        gatewayToolExecutor: fakeGateway,
      );

      final result = await service.processPendingRequest(
        project,
        requestId: 'research_request_blocked-call-1',
        allowGatewayExecution: true,
      );

      expect(result.executed, isFalse);
      expect(result.blockedReason, contains('默认不自动联网'));
      expect(fakeGateway.executedGatewayTools, isEmpty);
      final researchIndex = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}index.json',
      );
      expect(await researchIndex.exists(), isFalse);
    });
  });
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

NarrativeSourceRef _source(String sourceType) {
  return NarrativeSourceRef(
    sourceType: sourceType,
    sourceId: 'source-$sourceType',
    label: sourceType,
  );
}
