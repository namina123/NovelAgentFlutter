import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectInformationDomainToolExecutor', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectDescriptor project;
    late ProjectInformationDomainToolExecutor executor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-information-domain-executor-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      executor = ProjectInformationDomainToolExecutor(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'propose_design_element persists design card and refreshes projection',
      () async {
        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-design-1',
            toolName: NarrativeDomainToolNames.proposeDesignElement,
            source: _source(NarrativeSourceTypes.user),
            requestPayload: <String, Object?>{
              'design_id': 'design-1',
              'design_namespace': 'project.structure',
              'design_label': '潮声回扣',
              'design_payload': <String, Object?>{'pattern': '章末潮声回扣章首镜面'},
              'source_refs': <Object?>[_sourceRefJson()],
              'activation_policy': _activationPolicyJson(
                priority: InformationActivationPriorities.pinned,
              ),
              'usage_policy': _usagePolicyJson(),
              'confidence': 0.81,
              'lifecycle_status': InformationLifecycleStatuses.proposed,
            },
            toolRoundEvidence: ToolRoundEvidence(
              toolRoundRef: const NarrativeRef(
                refType: NarrativeRefTypes.toolRound,
                refId: 'round-design-1',
              ),
              toolCallIds: const <String>['call-design-1'],
            ),
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        final designFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}design_elements${Platform.pathSeparator}design-1.json',
        );
        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}设计元素摘要.md',
        );
        final eventLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}events${Platform.pathSeparator}events.jsonl',
        );
        expect(await designFile.exists(), isTrue);
        expect(await projectionFile.exists(), isTrue);
        expect(await projectionFile.readAsString(), contains('潮声回扣'));
        expect(await eventLog.readAsString(), contains('"ref_id":"design-1"'));
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              outcome.metadata['adapter_persistence'],
            )['changed_paths'],
          ),
          containsAll(<String>[
            '.novel_agent/information/design_elements/design-1.json',
            'knowledge/设计元素摘要.md',
            '.novel_agent/information/events/events.jsonl',
          ]),
        );
      },
    );

    test('submit_research_note persists note and refreshes projection', () async {
      final outcome = await executor.execute(
        project,
        DomainToolRequest(
          callId: 'call-research-1',
          toolName: NarrativeDomainToolNames.submitResearchNote,
          source: _source(NarrativeSourceTypes.reviewer),
          requestPayload: <String, Object?>{
            'research_id': 'research-1',
            'query': '镜潮母题',
            'source_kind': 'web_article',
            'source_url_or_ref': 'https://example.com/mirror-tide',
            'citation': 'Mirror Tide',
            'summary': '整理出镜与潮的并置用法。',
            'usable_facts': <Object?>['镜与潮常共同承担身份映照'],
            'creative_suggestions': <Object?>['可用于章节标题'],
            'created_by': 'researcher-agent',
            'usage_policy': _usagePolicyJson(
              usageMode: InformationUsageModes.referenceOnly,
            ),
          },
        ),
      );

      expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
      final researchFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}research-1.json',
      );
      final projectionFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}research${Platform.pathSeparator}资料研究摘要.md',
      );
      expect(await researchFile.exists(), isTrue);
      expect(await projectionFile.exists(), isTrue);
      expect(await projectionFile.readAsString(), contains('镜潮母题'));
    });

    test(
      'high risk reference work persists record and stays pending confirmation',
      () async {
        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-reference-1',
            toolName: NarrativeDomainToolNames.proposeReferenceWork,
            source: _source(NarrativeSourceTypes.user),
            requestPayload: <String, Object?>{
              'reference_work_id': 'reference-1',
              'title': '雾海镜宫',
              'source_refs': <Object?>[_sourceRefJson()],
              'relationship_to_project': 'fanfic_reference',
              'declared_usage_intent': '同人练习',
              'requires_confirmation': true,
            },
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        final referenceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}reference_works${Platform.pathSeparator}reference-1.json',
        );
        final eventLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}events${Platform.pathSeparator}events.jsonl',
        );
        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}references${Platform.pathSeparator}引用作品边界.md',
        );
        expect(await referenceFile.exists(), isTrue);
        expect(await projectionFile.exists(), isTrue);
        expect(
          await eventLog.readAsString(),
          contains('"outcome_status":"needs_user_confirmation"'),
        );
      },
    );

    test(
      'request_external_research only registers pending request record',
      () async {
        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-request-1',
            toolName: NarrativeDomainToolNames.requestExternalResearch,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'query': '镜潮互文',
              'purpose': '补充卷末资料',
              'requested_depth': InformationResearchDepths.standard,
              'target_refs': <Object?>[
                <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapter-01',
                },
              ],
              'user_granted_network_access': false,
            },
          ),
        );

        expect(
          outcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        final requestFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_requests${Platform.pathSeparator}research_request_call-request-1.json',
        );
        final researchFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}index.json',
        );
        expect(await requestFile.exists(), isTrue);
        expect(
          await requestFile.readAsString(),
          contains('"network_execution_performed": false'),
        );
        expect(
          await requestFile.readAsString(),
          contains('"request_state": "awaiting_user_confirmation"'),
        );
        expect(await researchFile.exists(), isFalse);
      },
    );

    test(
      'link_information_evidence persists jsonl link log and audit event',
      () async {
        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-link-1',
            toolName: NarrativeDomainToolNames.linkInformationEvidence,
            source: _source(NarrativeSourceTypes.reviewer),
            requestPayload: <String, Object?>{
              'link_id': 'link-1',
              'link_type': 'supports',
              'source_ref': <String, Object?>{
                'ref_type': InformationLinkedRefTypes.researchNote,
                'ref_id': 'research-1',
              },
              'target_ref': <String, Object?>{
                'ref_type': InformationLinkedRefTypes.knowledgeCard,
                'ref_id': 'knowledge-1',
              },
              'summary': '研究支持知识卡',
              'created_by': 'reviewer-agent',
            },
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        final linkLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}links${Platform.pathSeparator}links.jsonl',
        );
        final eventLog = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}events${Platform.pathSeparator}events.jsonl',
        );
        final knowledgeProjection = File(
          '${tempDirectory.path}${Platform.pathSeparator}knowledge${Platform.pathSeparator}项目知识摘要.md',
        );
        expect(await linkLog.exists(), isTrue);
        expect(await linkLog.readAsString(), contains('"link_id":"link-1"'));
        expect(
          await eventLog.readAsString(),
          contains('"related_link_ids":["link-1"]'),
        );
        expect(await knowledgeProjection.exists(), isTrue);
      },
    );
  });
}

NarrativeSourceRef _source(String sourceType) {
  return NarrativeSourceRef(
    sourceType: sourceType,
    sourceId: 'source-$sourceType',
    label: sourceType,
  );
}

Map<String, Object?> _sourceRefJson({
  String sourceType = NarrativeSourceTypes.user,
  String sourceId = 'source-1',
  String sourceAuthority = InformationSourceAuthorities.userDeclared,
  String roleAuthority = InformationRoleAuthorities.user,
  String researchDepth = InformationResearchDepths.none,
}) {
  return <String, Object?>{
    'source_ref': <String, Object?>{
      'source_type': sourceType,
      'source_id': sourceId,
    },
    'source_authority': sourceAuthority,
    'role_authority': roleAuthority,
    'research_depth': researchDepth,
  };
}

Map<String, Object?> _activationPolicyJson({
  String priority = InformationActivationPriorities.required,
}) {
  return <String, Object?>{
    'activation_priority': priority,
    'preferred_budget_chars': 240,
  };
}

Map<String, Object?> _usagePolicyJson({
  String usageMode = InformationUsageModes.normal,
}) {
  return <String, Object?>{
    'usage_mode': usageMode,
    'citation_risk_level': InformationCitationRiskLevels.low,
    'allows_derivative_use': true,
  };
}
