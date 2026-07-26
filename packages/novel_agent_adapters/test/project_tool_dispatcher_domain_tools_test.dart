import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolDispatcher domain tools', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectToolDispatcher dispatcher;
    late LocalProjectWorkspacePort workspacePort;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-dispatcher-domain-',
      );
      workspacePort = LocalProjectWorkspacePort();
      final hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'demo',
        name: '示例项目',
        rootPath: tempDirectory.path,
      );
      dispatcher = ProjectToolDispatcher(hostPort: hostPort);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'routes submit_chapter_delivery as domain tool and keeps outcome separate from transcript summary',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'delivery-call-1',
            'name': 'submit_chapter_delivery',
            'source_type': NarrativeSourceTypes.writer,
            'tool_round_evidence': <String, Object?>{
              'tool_round_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.toolRound,
                'ref_id': 'round-1',
              },
              'tool_call_ids': <Object?>['delivery-call-1'],
            },
            'arguments': <String, Object?>{
              'chapter_path': 'chapters/chapter_01.md',
              'chapter_content': '# 第一章\n\n雨水打在旧窗框上。',
              'title': '第一章',
              'submission': <String, Object?>{
                'submission_id': 'delivery-1',
                'summary': '完成本章',
              },
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['interaction_type'], 'domain_tool');
        expect(
          ValueReaders.mapValue(result['tool_capability'])['capability_kind'],
          'narrative_domain_tool',
        );
        expect(result['domain_tool_name'], 'submit_chapter_delivery');
        expect(result['domain_outcome_status'], 'accepted');
        expect(
          ValueReaders.stringList(result['changed_paths']),
          contains('chapters/chapter_01.md'),
        );
        expect(
          ValueReaders.stringValue(result['tool_result_summary']),
          contains('已执行领域工具'),
        );
        expect(result.containsKey('tool_round_evidence'), isFalse);

        final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
        expect(
          ValueReaders.stringValue(domainOutcome['outcome_status']),
          'accepted',
        );
        expect(
          ValueReaders.mapValue(domainOutcome['tool_round_evidence']),
          isNotEmpty,
        );
      },
    );

    test(
      'routes request_profile_clarification into waiting-user domain result',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'clarification-call-1',
            'name': 'request_profile_clarification',
            'arguments': <String, Object?>{
              'question': '该规则是只限本章还是长期生效？',
              'options': <Object?>[
                <String, Object?>{'label': '只限本章'},
                <String, Object?>{'label': '长期生效'},
              ],
              'blocking': true,
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['waiting_for_user_choice'], isTrue);
        expect(result['domain_outcome_status'], 'needs_user_confirmation');
        expect(
          ValueReaders.stringList(result['changed_paths']),
          contains(
            '.novel_agent/continuity/clarifications/clarification_clarification-call-1.json',
          ),
        );
      },
    );

    test(
      'routes propose_design_element into information domain executor with structured outcome',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'design-call-1',
            'name': NarrativeDomainToolNames.proposeDesignElement,
            'source_type': NarrativeSourceTypes.user,
            'arguments': <String, Object?>{
              'design_id': 'design-1',
              'design_namespace': 'project.structure',
              'design_label': '潮声回扣',
              'design_payload': <String, Object?>{'pattern': '章末潮声回扣章首镜面'},
              'source_refs': <Object?>[
                <String, Object?>{
                  'source_ref': <String, Object?>{
                    'source_type': NarrativeSourceTypes.user,
                    'source_id': 'source-user',
                  },
                  'source_authority': InformationSourceAuthorities.userDeclared,
                  'role_authority': InformationRoleAuthorities.user,
                  'research_depth': InformationResearchDepths.none,
                },
              ],
              'activation_policy': <String, Object?>{
                'activation_priority': InformationActivationPriorities.pinned,
                'preferred_budget_chars': 180,
              },
              'usage_policy': <String, Object?>{
                'usage_mode': InformationUsageModes.normal,
                'citation_risk_level': InformationCitationRiskLevels.low,
                'allows_derivative_use': true,
              },
              'confidence': 0.8,
              'lifecycle_status': InformationLifecycleStatuses.proposed,
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['interaction_type'], 'domain_tool');
        expect(
          result['domain_tool_name'],
          NarrativeDomainToolNames.proposeDesignElement,
        );
        expect(
          result['domain_outcome_status'],
          DomainToolOutcomeStatuses.proposed,
        );
        expect(
          ValueReaders.stringList(result['changed_paths']),
          containsAll(<String>[
            '.novel_agent/information/design_elements/design-1.json',
            'knowledge/设计元素摘要.md',
          ]),
        );
        expect(
          ValueReaders.stringValue(result['tool_result_summary']),
          contains('已记录领域提案'),
        );
        final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
        expect(
          ValueReaders.stringValue(domainOutcome['tool_name']),
          NarrativeDomainToolNames.proposeDesignElement,
        );
      },
    );

    test(
      'routes request_external_research as domain tool and keeps it distinct from gateway execution',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'research-call-1',
            'name': NarrativeDomainToolNames.requestExternalResearch,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': <String, Object?>{
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
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(
          result['domain_outcome_status'],
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        expect(result['waiting_for_user_choice'], isTrue);
        expect(
          ValueReaders.stringList(result['changed_paths']),
          contains(
            '.novel_agent/information/research_requests/research_request_research-call-1.json',
          ),
        );
        expect(
          ValueReaders.stringValue(result['tool_result_summary']),
          contains('等待用户确认'),
        );
        final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
        expect(
          ValueReaders.mapValue(
            domainOutcome['outcome_payload'],
          )['network_execution_performed'],
          isFalse,
        );
      },
    );

    test(
      'host permission context overrides request_external_research without affecting other information tools',
      () async {
        final fakeGateway = _FakeGatewayToolExecutor(
          responses: <String, JsonMap>{
            'search_internet': <String, Object?>{
              'ok': true,
              'results': <Object?>[
                <String, Object?>{
                  'title': 'Mirror Tide Notes',
                  'url': 'https://example.com/mirror-tide',
                  'snippet': '镜潮互文外部资料摘要。',
                },
              ],
            },
            'fetch_url_content': <String, Object?>{
              'ok': true,
              'status_code': 200,
              'content_type': 'text/html',
              'content': '镜潮互文可用于卷末资料补充。',
              'truncated': false,
            },
          },
        );
        dispatcher = ProjectToolDispatcher(
          hostPort: ProjectWorkspaceToolHostAdapter(
            workspacePort: workspacePort,
            fileMutationAdapter: LocalProjectFileMutationAdapter(),
          ),
          hostInformationPermissionContext:
              const HostInformationPermissionContext(
                allowNetwork: true,
                allowImportCollection: true,
                permissionMode: HostInformationPermissionModes.open,
                confirmationMode: HostInformationConfirmationModes.automatic,
                source: 'dispatcher.test',
              ),
          informationDomainToolExecutor: ProjectInformationDomainToolExecutor(
            workspacePort: workspacePort,
            researchCoordinatorService:
                ProjectInformationResearchCoordinatorService(
                  workspacePort: workspacePort,
                  gatewayService: ProjectResearchGatewayService(
                    workspacePort: workspacePort,
                    gatewayToolExecutor: fakeGateway,
                  ),
                ),
          ),
        );

        final researchResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'research-call-open-1',
            'name': NarrativeDomainToolNames.requestExternalResearch,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': <String, Object?>{
              'query': '镜潮互文',
              'purpose': '补充卷末资料',
              'requested_depth': InformationResearchDepths.standard,
              'collection_mode': InformationCollectionModes.network,
              'user_granted_network_access': false,
            },
          },
        );

        expect(
          researchResult['domain_outcome_status'],
          DomainToolOutcomeStatuses.proposed,
        );
        final researchOutcome = ValueReaders.mapValue(
          researchResult['domain_outcome'],
        );
        final researchRequest = ValueReaders.mapValue(
          ValueReaders.mapValue(
            researchOutcome['outcome_payload'],
          )['research_request'],
        );
        final metadata = ValueReaders.mapValue(researchRequest['metadata']);
        final permissionDecision = ValueReaders.mapValue(
          researchOutcome['permission_decision'],
        );
        final researchExecution = ValueReaders.mapValue(
          ValueReaders.mapValue(
            researchOutcome['outcome_payload'],
          )['research_execution'],
        );
        expect(
          ValueReaders.boolValue(
            researchRequest['user_granted_network_access'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(permissionDecision['disposition']),
          DomainToolPermissionDispositions.accepted,
        );
        expect(
          ValueReaders.boolValue(
            metadata['raw_model_user_granted_network_access'],
          ),
          isFalse,
        );
        expect(
          ValueReaders.boolValue(
            metadata['effective_user_granted_network_access'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              researchOutcome['outcome_payload'],
            )['network_execution_performed'],
          ),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(researchExecution['executed_network']),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(researchResult['tool_result_summary']),
          contains('自动执行资料研究'),
        );
        expect(fakeGateway.executedGatewayTools, <String>[
          'search_internet',
          'fetch_url_content',
        ]);

        final designResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'design-call-open-2',
            'name': NarrativeDomainToolNames.proposeDesignElement,
            'source_type': NarrativeSourceTypes.user,
            'arguments': <String, Object?>{
              'design_id': 'design-open-1',
              'design_namespace': 'project.structure',
              'design_label': '镜潮回环',
              'design_payload': <String, Object?>{'pattern': '镜与潮双重意象'},
              'source_refs': <Object?>[
                <String, Object?>{
                  'source_ref': <String, Object?>{
                    'source_type': NarrativeSourceTypes.user,
                    'source_id': 'source-user',
                  },
                  'source_authority': InformationSourceAuthorities.userDeclared,
                  'role_authority': InformationRoleAuthorities.user,
                  'research_depth': InformationResearchDepths.none,
                },
              ],
              'activation_policy': <String, Object?>{
                'activation_priority': InformationActivationPriorities.pinned,
                'preferred_budget_chars': 180,
              },
              'usage_policy': <String, Object?>{
                'usage_mode': InformationUsageModes.normal,
                'citation_risk_level': InformationCitationRiskLevels.low,
                'allows_derivative_use': true,
              },
              'confidence': 0.8,
              'lifecycle_status': InformationLifecycleStatuses.proposed,
            },
          },
        );

        expect(
          designResult['domain_outcome_status'],
          DomainToolOutcomeStatuses.proposed,
        );
        final designOutcome = ValueReaders.mapValue(
          designResult['domain_outcome'],
        );
        expect(
          ValueReaders.mapValue(
            designOutcome['metadata'],
          ).containsKey('raw_model_user_granted_network_access'),
          isFalse,
        );
      },
    );

    test(
      'returns structured parse issues for malformed domain tool payloads',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: const <String, Object?>{
            'id': 'claims-call-1',
            'name': 'submit_narrative_state_claims',
            'arguments': <String, Object?>{'claims': 'not-an-array'},
          },
        );

        expect(result['ok'], isFalse);
        expect(result['not_executed'], isTrue);
        expect(result['retryable'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['interaction_type'], 'domain_tool');
        expect(
          ValueReaders.objectList(result['domain_parse_issues']),
          isNotEmpty,
        );
        expect(
          ValueReaders.stringValue(result['tool_result_summary']),
          contains('工具尚未执行'),
        );
        expect(result.containsKey('domain_outcome'), isFalse);
      },
    );

    test(
      'keeps request_gateway_tool separate from information research workflow',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: const <String, Object?>{
            'name': 'request_gateway_tool',
            'arguments': <String, Object?>{'gateway_tool': 'search_internet'},
          },
        );

        expect(result['tool_layer'], 'project');
        expect(result.containsKey('domain_outcome'), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          contains('query is required'),
        );
        final researchRequestIndex = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_requests${Platform.pathSeparator}index.json',
        );
        final researchNoteIndex = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}information${Platform.pathSeparator}research_notes${Platform.pathSeparator}index.json',
        );
        expect(await researchRequestIndex.exists(), isFalse);
        expect(await researchNoteIndex.exists(), isFalse);
      },
    );

    test('keeps write_project_file as low-level tool', () async {
      final result = await dispatcher.execute(
        project: project,
        toolCall: const <String, Object?>{
          'name': 'write_project_file',
          'arguments': <String, Object?>{
            'content_type': 'chapter',
            'title': '第二章',
            'relative_path': 'chapters/chapter_02.md',
            'content': '# 第二章\n\n正文',
            'overwrite': true,
          },
        },
      );

      expect(result['ok'], isTrue);
      expect(result['tool_layer'], 'low_level');
      expect(
        ValueReaders.mapValue(result['tool_capability'])['capability_kind'],
        'project_low_level_tool',
      );
      expect(result['relative_path'], 'chapters/chapter_02.md');
      expect(result.containsKey('domain_outcome'), isFalse);
    });

    test(
      'write_project_file uses chapter title path when relative path is omitted',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: const <String, Object?>{
            'name': 'write_project_file',
            'arguments': <String, Object?>{
              'content_type': 'chapter',
              'content': '# 第02章 雨夜入城\n\n正文',
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'low_level');
        expect(result['relative_path'], 'chapters/第02章_雨夜入城.md');
      },
    );
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
