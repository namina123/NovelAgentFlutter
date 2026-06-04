import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectNarrativeDomainToolExecutor', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectDescriptor project;
    late ProjectNarrativeDomainToolExecutor executor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-domain-tool-executor-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      executor = ProjectNarrativeDomainToolExecutor(
        workspacePort: workspacePort,
        hostPort: hostPort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'submit_chapter_delivery writes chapter body and hidden submission record',
      () async {
        final request = DomainToolRequest(
          callId: 'call-1',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'chapter_path': 'chapters/chapter_01.md',
            'chapter_content': '# 第一章\n\n风从高墙之外吹进来。',
            'title': '第一章',
            'submission': <String, Object?>{
              'submission_id': 'delivery-1',
              'chapter_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapters/chapter_01.md',
                'relative_path': 'chapters/chapter_01.md',
              },
              'title': '第一章',
              'summary': '完成本章交付',
              'claims': <Object?>[
                <String, Object?>{
                  'claim_id': 'claim-1',
                  'claim_namespace': 'continuity',
                  'claim_payload': <String, Object?>{'mood': 'cold'},
                  'affected_refs': <Object?>[
                    <String, Object?>{
                      'ref_type': NarrativeRefTypes.chapter,
                      'ref_id': 'chapters/chapter_01.md',
                      'relative_path': 'chapters/chapter_01.md',
                    },
                  ],
                  'evidence_refs': <Object?>[
                    <String, Object?>{
                      'evidence_type': NarrativeEvidenceTypes.toolCall,
                      'evidence_id': 'tool-call-1',
                      'source_ref': _source(
                        NarrativeSourceTypes.writer,
                      ).toJson(),
                    },
                  ],
                  'source': _source(NarrativeSourceTypes.writer).toJson(),
                  'confidence': 0.91,
                },
              ],
              'evidence_refs': <Object?>[
                <String, Object?>{
                  'evidence_type': NarrativeEvidenceTypes.toolCall,
                  'evidence_id': 'tool-call-1',
                  'source_ref': _source(NarrativeSourceTypes.writer).toJson(),
                },
              ],
            },
          },
          toolRoundEvidence: ToolRoundEvidence(
            toolRoundRef: const NarrativeRef(
              refType: NarrativeRefTypes.toolRound,
              refId: 'round-1',
            ),
            toolCallIds: const <String>['call-1'],
          ),
          schemaVersion: '1',
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}chapter_01.md',
        );
        final submissionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}deliveries${Platform.pathSeparator}delivery-1.json',
        );
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('风从高墙之外吹进来'));
        expect(await submissionFile.exists(), isTrue);
        final submissionText = await submissionFile.readAsString();
        expect(submissionText, contains('"delivery_result"'));
        expect(submissionText, contains('"delivery_evidence_refs"'));
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              outcome.metadata['adapter_persistence'],
            )['changed_paths'],
          ),
          containsAll(<String>[
            'chapters/chapter_01.md',
            '.novel_agent/continuity/deliveries/delivery-1.json',
          ]),
        );
      },
    );

    test(
      'submit_chapter_delivery keeps empty content as invalid without writes',
      () async {
        final request = DomainToolRequest(
          callId: 'call-2',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'chapter_path': 'chapters/chapter_02.md',
            'chapter_content': '   ',
          },
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}chapter_02.md',
        );
        final deliveryFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}deliveries${Platform.pathSeparator}index.json',
        );
        expect(await chapterFile.exists(), isFalse);
        expect(await deliveryFile.exists(), isFalse);
      },
    );

    test(
      'submit_narrative_state_claims persists claims and refreshes projection',
      () async {
        final request = DomainToolRequest(
          callId: 'call-3',
          toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'claims': <Object?>[
              <String, Object?>{
                'claim_id': 'claim-2',
                'claim_namespace': 'continuity',
                'claim_label': '天气变化',
                'claim_payload': <String, Object?>{'weather': 'ash'},
                'affected_refs': <Object?>[
                  <String, Object?>{
                    'ref_type': NarrativeRefTypes.chapter,
                    'ref_id': 'chapters/chapter_01.md',
                    'relative_path': 'chapters/chapter_01.md',
                  },
                ],
                'evidence_refs': <Object?>[
                  <String, Object?>{
                    'evidence_type': NarrativeEvidenceTypes.toolCall,
                    'evidence_id': 'tool-call-2',
                    'source_ref': _source(NarrativeSourceTypes.writer).toJson(),
                  },
                ],
                'source': _source(NarrativeSourceTypes.writer).toJson(),
                'confidence': 0.82,
              },
            ],
          },
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final claimsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}claims${Platform.pathSeparator}claims.jsonl',
        );
        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}continuity${Platform.pathSeparator}最近状态变化.md',
        );
        expect(await claimsFile.exists(), isTrue);
        expect(
          await claimsFile.readAsString(),
          contains('"claim_id":"claim-2"'),
        );
        expect(await projectionFile.exists(), isTrue);
        expect(await projectionFile.readAsString(), contains('claim-2'));
      },
    );

    test(
      'profile proposal and clarification persist hidden records without starting next stage',
      () async {
        final profileOutcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-4',
            toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
            source: _source(NarrativeSourceTypes.deconstruction),
            requestPayload: <String, Object?>{
              'proposal_id': 'proposal-1',
              'proposal_status': 'proposed',
              'profile_patch': <String, Object?>{
                'patch_id': 'patch-1',
                'source': _source(NarrativeSourceTypes.deconstruction).toJson(),
                'patch_payload': <String, Object?>{
                  'namespace': 'continuity',
                  'signals': <Object?>['ash_weather'],
                },
              },
              'source': _source(NarrativeSourceTypes.deconstruction).toJson(),
            },
          ),
        );
        final clarificationOutcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-5',
            toolName: NarrativeDomainToolNames.requestProfileClarification,
            source: _source(NarrativeSourceTypes.system),
            requestPayload: <String, Object?>{
              'question': '这个机制是否长期生效？',
              'options': <Object?>[
                <String, Object?>{'option_id': 'yes', 'label': '长期生效'},
                <String, Object?>{'option_id': 'no', 'label': '只限本卷'},
              ],
              'blocking': true,
            },
          ),
        );

        expect(
          profileOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.proposed,
        );
        expect(
          clarificationOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.needsUserConfirmation,
        );
        final profileProposalFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}profile_proposals${Platform.pathSeparator}proposal-1.json',
        );
        final clarificationFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}clarifications${Platform.pathSeparator}clarification_call-5.json',
        );
        expect(await profileProposalFile.exists(), isTrue);
        expect(await clarificationFile.exists(), isTrue);
        expect(
          await clarificationFile.readAsString(),
          contains('"blocking": true'),
        );
      },
    );

    test(
      'semantic review and constraint binding persist facts and refresh projections',
      () async {
        final reviewOutcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-6',
            toolName: NarrativeDomainToolNames.submitSemanticReview,
            source: _source(NarrativeSourceTypes.reviewer),
            requestPayload: <String, Object?>{
              'review_id': 'review-1',
              'source': _source(NarrativeSourceTypes.reviewer).toJson(),
              'recommended_disposition': 'accept_with_note',
              'summary': '需要注意语气收束。',
            },
          ),
        );
        final bindingOutcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-7',
            toolName: NarrativeDomainToolNames.proposeConstraintBinding,
            source: _source(NarrativeSourceTypes.user),
            requestPayload: <String, Object?>{
              'binding_id': 'binding-1',
              'constraint_type': 'plot_rule',
              'constraint_label': '本卷不允许穿越解释',
              'constraint_payload': <String, Object?>{
                'rule': 'no_time_travel_explanation',
              },
              'binding_scope': <String, Object?>{
                'applies_to': <Object?>['draft'],
              },
              'binding_policy': <String, Object?>{'auto_accept': true},
              'source': _source(NarrativeSourceTypes.user).toJson(),
            },
          ),
        );

        expect(reviewOutcome.outcomeStatus, DomainToolOutcomeStatuses.proposed);
        expect(
          bindingOutcome.outcomeStatus,
          DomainToolOutcomeStatuses.accepted,
        );
        final reviewFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}reviews${Platform.pathSeparator}review-1.json',
        );
        final bindingFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}bindings${Platform.pathSeparator}binding-1.json',
        );
        final reviewProjection = File(
          '${tempDirectory.path}${Platform.pathSeparator}reviews${Platform.pathSeparator}语义复核摘要.md',
        );
        final bindingProjection = File(
          '${tempDirectory.path}${Platform.pathSeparator}constraints${Platform.pathSeparator}项目约束摘要.md',
        );
        expect(await reviewFile.exists(), isTrue);
        expect(await bindingFile.exists(), isTrue);
        expect(await reviewProjection.exists(), isTrue);
        expect(await bindingProjection.exists(), isTrue);
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
