import 'dart:convert';
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
        final claimsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}claims${Platform.pathSeparator}claims.jsonl',
        );
        final projectionFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}continuity${Platform.pathSeparator}最近状态变化.md',
        );
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('风从高墙之外吹进来'));
        expect(await submissionFile.exists(), isTrue);
        expect(await claimsFile.exists(), isTrue);
        expect(
          await claimsFile.readAsString(),
          contains('"claim_id":"claim-1"'),
        );
        expect(await projectionFile.exists(), isTrue);
        expect(await projectionFile.readAsString(), contains('claim-1'));
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
            '.novel_agent/continuity/claims/claims.jsonl',
          ]),
        );
      },
    );

    test(
      'submit_chapter_delivery persists resolved chapter path and normalized submission record',
      () async {
        final request = DomainToolRequest(
          callId: 'call-upgrade-1',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'chapter_path': 'chapters/第01章.md',
            'chapter_content': '# 第01章 醒在败家子床上\n\n风从窗缝里吹进来。',
            'title': '第01章',
            'submission': <String, Object?>{
              'submission_id': 'submission:chapters/第01章.md',
              'chapter_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapters/第01章.md',
                'relative_path': 'chapters/第01章.md',
              },
              'title': '第01章',
              'summary': '完成本章交付',
              'segments': <Object?>[
                <String, Object?>{
                  'segment_id': 'segment-1',
                  'order_index': 0,
                  'summary': '主角在陌生处境醒来。',
                },
              ],
            },
          },
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final resolvedPath = 'chapters/第01章_醒在败家子床上.md';
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第01章_醒在败家子床上.md',
        );
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('风从窗缝里吹进来'));

        final payload = ValueReaders.mapValue(outcome.outcomePayload);
        final submission = ValueReaders.mapValue(payload['submission']);
        final chapterRef = ValueReaders.mapValue(submission['chapter_ref']);
        final deliveryResultPath = OpenNarrativeStatePathService().deliveryPath(
          'submission:$resolvedPath',
        );
        final deliveryFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${deliveryResultPath.replaceAll('/', Platform.pathSeparator)}',
        );
        expect(await deliveryFile.exists(), isTrue);

        final deliveryRecord = ValueReaders.mapValue(
          jsonDecode(await deliveryFile.readAsString()),
        );
        final deliveryResult = ValueReaders.mapValue(
          deliveryRecord['delivery_result'],
        );
        final recordedSubmission = ValueReaders.mapValue(
          deliveryRecord['submission'],
        );
        final recordedChapterRef = ValueReaders.mapValue(
          recordedSubmission['chapter_ref'],
        );

        expect(payload['requested_chapter_path'], 'chapters/第01章.md');
        expect(payload['resolved_chapter_path'], resolvedPath);
        expect(submission['submission_id'], 'submission:$resolvedPath');
        expect(chapterRef['relative_path'], resolvedPath);
        expect(deliveryResult['requested_chapter_path'], 'chapters/第01章.md');
        expect(deliveryResult['resolved_chapter_path'], resolvedPath);
        expect(recordedSubmission['submission_id'], 'submission:$resolvedPath');
        expect(recordedChapterRef['relative_path'], resolvedPath);
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              outcome.metadata['adapter_persistence'],
            )['changed_paths'],
          ),
          containsAll(<String>[resolvedPath, deliveryResultPath]),
        );
      },
    );

    test(
      'submit_chapter_delivery persists synthesized continuity handoff for empty chapter submission shell',
      () async {
        final request = DomainToolRequest(
          callId: 'call-continuity-1',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'chapter_path': 'chapters/第02章.md',
            'chapter_content':
                '# 第02章\n\n陆安顺着巷子走到镇东头，槐树下那户青砖院子就是王保正家。\n\n他站定后抬手敲门，门内很快传来一声“谁啊？”。',
            'title': '第02章',
            'submission': <String, Object?>{
              'submission_id': 'submission:chapters/第02章.md',
              'chapter_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapters/第02章.md',
                'relative_path': 'chapters/第02章.md',
              },
              'title': '第02章',
              'summary': '',
              'final_state_summary': <String, Object?>{},
            },
          },
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final deliveryPath = OpenNarrativeStatePathService().deliveryPath(
          'submission:chapters/第02章.md',
        );
        final deliveryFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${deliveryPath.replaceAll('/', Platform.pathSeparator)}',
        );
        expect(await deliveryFile.exists(), isTrue);
        final record = ValueReaders.mapValue(
          jsonDecode(await deliveryFile.readAsString()),
        );
        final submission = ValueReaders.mapValue(record['submission']);
        final finalState = ValueReaders.mapValue(
          submission['final_state_summary'],
        );

        expect(
          ValueReaders.stringValue(submission['summary']),
          contains('章末落点'),
        );
        expect(
          ValueReaders.stringValue(finalState['next_chapter_handoff']),
          contains('不要回退重演'),
        );
        expect(
          ValueReaders.stringValue(finalState['chapter_end_excerpt']),
          contains('门内很快传来'),
        );
      },
    );

    test(
      'submit_chapter_delivery rejects chapter openings that replay the previous tail',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '''
# 第02章

他走到门口，犹豫了一下，敲了敲门。

过了一会儿，门开了。开门的是一个四十来岁的男人。

“你找谁？”

“请问是王保正吗？”
''',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          jsonEncode(<String, Object?>{
            'submission': <String, Object?>{
              'summary': '第02章交付：章末已经完成敲门、开门和开场询问。',
              'final_state_summary': <String, Object?>{
                'chapter_end_excerpt':
                    '他走到门口，犹豫了一下，敲了敲门。过了一会儿，门开了。开门的是一个四十来岁的男人。“你找谁？”“请问是王保正吗？”',
                'next_chapter_handoff': '直接从王保正的回应继续，不要回退重演敲门前。',
              },
            },
          }),
        );

        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-replay-guard-1',
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'chapter_path': 'chapters/第03章.md',
              'chapter_content': '''
# 第03章

王保正家的门是木头的，门环泛着暗黑的油光。陆安在门口站了大概十息，抬手敲了三下，铁环磕在门板上，发出闷闷的声响。

门里有人应了一声，又过了几息，门才从里面开了条缝。
''',
              'title': '第03章',
              'submission': <String, Object?>{
                'submission_id': 'submission:chapters/第03章.md',
                'chapter_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapters/第03章.md',
                  'relative_path': 'chapters/第03章.md',
                },
                'title': '第03章',
                'summary': '继续推进。',
              },
            },
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        expect(
          ValueReaders.stringValue(outcome.error?.message),
          contains('疑似回退重演'),
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第03章.md',
        );
        expect(await chapterFile.exists(), isFalse);
      },
    );

    test(
      'submit_chapter_delivery accepts chapter openings that directly advance from previous response',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'chapters/第02章.md',
          '''
# 第02章

他站定后抬手敲门，门内很快传来一声“谁啊？”。
''',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          '.novel_agent/continuity/deliveries/submission_chapters_第02章.md.json',
          jsonEncode(<String, Object?>{
            'submission': <String, Object?>{
              'final_state_summary': <String, Object?>{
                'chapter_end_excerpt': '他站定后抬手敲门，门内很快传来一声“谁啊？”。',
                'next_chapter_handoff': '直接从对方的回应继续。',
              },
            },
          }),
        );

        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-replay-guard-2',
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'chapter_path': 'chapters/第03章.md',
              'chapter_content': '''
# 第03章

屋里静了一瞬，随后门闩被人抽开，王保正隔着门缝先把他从头到脚打量了一遍。

“你姓什么？”对方没有让开门口，只先把问题问了出来。
''',
              'title': '第03章',
              'submission': <String, Object?>{
                'submission_id': 'submission:chapters/第03章.md',
                'chapter_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapters/第03章.md',
                  'relative_path': 'chapters/第03章.md',
                },
                'title': '第03章',
                'summary': '继续推进。',
              },
            },
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第03章.md',
        );
        expect(await chapterFile.exists(), isTrue);
      },
    );

    test(
      'submit_chapter_delivery rejects chapter delivery below shared length gate from task execution constraints',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'tasks/task_chapter_length_guard.json',
          jsonEncode(<String, Object?>{
            'id': 'task_chapter_length_guard',
            'title': '第03章',
            'task_type': 'chapter',
            'status': TaskRuntimeConstants.statusRunning,
            'output_paths': <String>['chapters/第03章.md'],
            'metadata': <String, Object?>{'stage': 'draft', 'sort_order': 3},
            'atomic_execution_path':
                'tracking/chapter_atomic/guard.execution.json',
            'updated_at': '2026-06-13T10:00:00.000000',
          }),
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'tracking/chapter_atomic/guard.execution.json',
          jsonEncode(<String, Object?>{
            'execution_constraints': <String, Object?>{
              'chapter_length_metadata': <String, Object?>{
                'chapter_length_profile': <String, Object?>{
                  'enabled': true,
                  'target_length': 2200,
                  'preferred_min': 1800,
                  'preferred_max': 2600,
                  'stage': 'draft',
                  'metric_unit': 'visible_characters',
                },
              },
            },
          }),
        );

        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-length-guard-task',
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'chapter_path': 'chapters/第03章.md',
              'chapter_content': '# 第03章\n\n太短了，明显没有达到要求。',
              'title': '第03章',
              'submission': <String, Object?>{
                'submission_id': 'submission:chapters/第03章.md',
                'chapter_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapters/第03章.md',
                  'relative_path': 'chapters/第03章.md',
                },
                'title': '第03章',
                'summary': '继续推进。',
              },
            },
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        expect(
          ValueReaders.stringValue(outcome.error?.message),
          contains('低于最小要求 1800'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              outcome.metadata['chapter_length_guard'],
            )['source'],
          ),
          'task_atomic_execution',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第03章.md',
        );
        expect(await chapterFile.exists(), isFalse);
      },
    );

    test(
      'submit_chapter_delivery rejects chapter delivery above shared length gate from request metadata',
      () async {
        final chapterBody = List<String>.filled(3200, '字').join();
        final outcome = await executor.execute(
          project,
          DomainToolRequest(
            callId: 'call-length-guard-metadata',
            toolName: NarrativeDomainToolNames.submitChapterDelivery,
            source: _source(NarrativeSourceTypes.writer),
            requestPayload: <String, Object?>{
              'chapter_path': 'chapters/第04章.md',
              'chapter_content': '# 第04章\n\n$chapterBody',
              'title': '第04章',
              'submission': <String, Object?>{
                'submission_id': 'submission:chapters/第04章.md',
                'chapter_ref': <String, Object?>{
                  'ref_type': NarrativeRefTypes.chapter,
                  'ref_id': 'chapters/第04章.md',
                  'relative_path': 'chapters/第04章.md',
                },
                'title': '第04章',
                'summary': '继续推进。',
              },
              'metadata': <String, Object?>{
                'chapter_length_metadata': <String, Object?>{
                  'chapter_length_profile': <String, Object?>{
                    'enabled': true,
                    'target_length': 2200,
                    'preferred_min': 1800,
                    'preferred_max': 2600,
                    'stage': 'draft',
                    'metric_unit': 'visible_characters',
                  },
                },
              },
            },
          ),
        );

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.invalidPayload);
        expect(
          ValueReaders.stringValue(outcome.error?.message),
          contains('高于最大要求 2600'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              outcome.metadata['chapter_length_guard'],
            )['source'],
          ),
          'request_metadata',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第04章.md',
        );
        expect(await chapterFile.exists(), isFalse);
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
      'submit_chapter_delivery persists chapter file with normalized heading title',
      () async {
        final request = DomainToolRequest(
          callId: 'call-heading-1',
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          source: _source(NarrativeSourceTypes.writer),
          requestPayload: <String, Object?>{
            'chapter_path': 'chapters/第06章.md',
            'chapter_content': '# 第06章\n\n雪夜里第一辆马车进了城。',
            'title': '第06章 雪夜入城',
            'submission': <String, Object?>{
              'submission_id': 'submission:chapters/第06章.md',
              'chapter_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapters/第06章.md',
                'relative_path': 'chapters/第06章.md',
              },
            },
          },
        );

        final outcome = await executor.execute(project, request);

        expect(outcome.outcomeStatus, DomainToolOutcomeStatuses.accepted);
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第06章_雪夜入城.md',
        );
        expect(await chapterFile.exists(), isTrue);
        final content = await chapterFile.readAsString();
        expect(content, startsWith('# 第06章 雪夜入城'));
        expect(content, contains('雪夜里第一辆马车进了城'));
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
