import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectConversationDraftRuntimeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectWorkspaceToolHostAdapter hostPort;
    late ProjectTaskRepository taskRepository;
    late LocalKnowledgeCardRepository knowledgeCardRepository;
    late LocalDesignElementRepository designElementRepository;
    late ProjectToolDispatcher dispatcher;
    late ProjectConversationDraftRuntimeService service;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-conversation-runtime-',
      );
      workspacePort = LocalProjectWorkspacePort();
      hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      knowledgeCardRepository = LocalKnowledgeCardRepository(
        workspacePort: workspacePort,
      );
      designElementRepository = LocalDesignElementRepository(
        workspacePort: workspacePort,
      );
      dispatcher = ProjectToolDispatcher(hostPort: hostPort);
      service = ProjectConversationDraftRuntimeService(
        workspacePort: workspacePort,
        hostPort: hostPort,
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'conversation_runtime_project',
        name: '普通会话项目',
        rootPath: tempDirectory.path,
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outline/总纲.md',
        '# 总纲\n第一章是回京夜雨。',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'styles/default.md',
        '# 风格\n保持冷峻，少解释。',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'prepareDraftRun builds activation context and prioritizes submit_chapter_delivery',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );

        expect(preparation.activationReportPath, contains('conversation_draft'));
        expect(preparation.sessionContextMarkdown, contains('Activation Report'));
        expect(preparation.exposedToolIds.first, 'submit_chapter_delivery');
        expect(preparation.exposedToolIds, isNot(contains('set_agent_tasks')));
        expect(preparation.exposedToolIds, isNot(contains('call_sub_agent')));
      },
    );

    test(
      'prepareDraftRun injects information activation and exposes safe information tools for chapter flow',
      () async {
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-loop-rule',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '轮回规则',
            summary: '钟楼轮回会在午夜前十五分钟重置。',
            contentPayload: const <String, Object?>{
              'fact': '主角会保留轮回前一轮的短时记忆',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.required,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.92,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-night-rain',
            designNamespace: 'project.structure',
            designLabel: '夜雨回扣',
            designPayload: const <String, Object?>{
              'pattern': '每章夜雨都回扣角色是否选择回头',
            },
            sourceRefs: <InformationSourceRef>[_sourceRef()],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.81,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
        );

        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final selectedSections = ValueReaders.mapList(
          ValueReaders.mapValue(preparation.activationReport['metadata'])['selected_context_sections'],
        );
        final selectedKinds = selectedSections
            .map((item) => ValueReaders.stringValue(item['source_kind']))
            .toSet();

        expect(preparation.sessionContextMarkdown, contains('轮回规则'));
        expect(preparation.sessionContextMarkdown, contains('夜雨回扣'));
        expect(selectedKinds, contains('project_knowledge_card'));
        expect(selectedKinds, contains('project_design_element'));
        expect(
          preparation.exposedToolIds,
          containsAll(<String>[
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ]),
        );
        expect(
          preparation.exposedToolIds,
          isNot(contains(NarrativeDomainToolNames.requestExternalResearch)),
        );
      },
    );

    test(
      'finalizeDraftRun backfills submit_chapter_delivery for ordinary write_project_file chapter output',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '章节已保存。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_write_1',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第01章',
                'content': '# 第01章\n\n夜雨沿着宫墙流下，回京的人没有回头。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/chapter_01.md',
                'changed_paths': <Object?>['chapters/chapter_01.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/chapter_01.md'],
          changedPaths: const <String>['chapters/chapter_01.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章',
        );

        final activationReportFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${preparation.activationReportPath.replaceAll('/', Platform.pathSeparator)}',
        );
        final deliveryRecordFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}deliveries${Platform.pathSeparator}conversation_submission_${preparation.runId}.json',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}chapter_01.md',
        );

        expect(artifacts.outputPath, 'chapters/chapter_01.md');
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['tool_name']),
          'submit_chapter_delivery',
        );
        expect(await activationReportFile.exists(), isTrue);
        expect(await deliveryRecordFile.exists(), isTrue);
        expect(await chapterFile.exists(), isTrue);
        expect(
          await chapterFile.readAsString(),
          contains('夜雨沿着宫墙流下'),
        );
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            'chapters/chapter_01.md',
            '.novel_agent/continuity/deliveries/conversation_submission_${preparation.runId}.json',
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun keeps information changed paths when ordinary chapter flow submits knowledge and design delta',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final knowledgeArguments = <String, Object?>{
          'card_id': 'knowledge-night-rain',
          'card_namespace': 'project.rules',
          'card_type': 'world_rule',
          'title': '夜雨归京规则',
          'summary': '归京相关章节必须让夜雨承担迟疑与回望。',
          'content_payload': const <String, Object?>{
            'rule': '归京章节里的夜雨应回扣主角是否回头',
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-agent',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': const <String, Object?>{
            'activation_priority': InformationActivationPriorities.required,
            'preferred_budget_chars': 180,
          },
          'usage_policy': const <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.89,
        };
        final designArguments = <String, Object?>{
          'design_id': 'design-night-rain',
          'design_namespace': 'project.structure',
          'design_label': '夜雨回扣',
          'design_payload': const <String, Object?>{
            'pattern': '章末夜雨解释章首回京动作里的迟疑',
          },
          'source_refs': <Object?>[
            <String, Object?>{
              'source_ref': <String, Object?>{
                'source_type': NarrativeSourceTypes.writer,
                'source_id': 'writer-agent',
              },
              'source_authority': InformationSourceAuthorities.aiInferred,
              'role_authority': InformationRoleAuthorities.writer,
              'research_depth': InformationResearchDepths.quick,
            },
          ],
          'activation_policy': const <String, Object?>{
            'activation_priority': InformationActivationPriorities.pinned,
            'preferred_budget_chars': 180,
          },
          'usage_policy': const <String, Object?>{
            'usage_mode': InformationUsageModes.normal,
            'citation_risk_level': InformationCitationRiskLevels.low,
          },
          'confidence': 0.78,
          'uncertainty': '后续章节还要继续验证回扣强度。',
        };
        final knowledgeResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'call_knowledge_1',
            'name': NarrativeDomainToolNames.proposeKnowledgeCard,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': knowledgeArguments,
          },
        );
        final designResult = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'call_design_1',
            'name': NarrativeDomainToolNames.proposeDesignElement,
            'source_type': NarrativeSourceTypes.writer,
            'arguments': designArguments,
          },
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '章节已保存。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_knowledge_1',
              'name': NarrativeDomainToolNames.proposeKnowledgeCard,
              'arguments': knowledgeArguments,
              'result': knowledgeResult,
              'ok': ValueReaders.boolValue(knowledgeResult['ok']),
            },
            <String, Object?>{
              'id': 'call_design_1',
              'name': NarrativeDomainToolNames.proposeDesignElement,
              'arguments': designArguments,
              'result': designResult,
              'ok': ValueReaders.boolValue(designResult['ok']),
            },
            <String, Object?>{
              'id': 'call_write_1',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'content_type': 'chapter',
                'title': '第01章',
                'content': '# 第01章\n\n夜雨沿着宫墙流下，回京的人还是回头了。',
              },
              'result': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/chapter_01.md',
                'changed_paths': <Object?>['chapters/chapter_01.md'],
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/chapter_01.md'],
          changedPaths: _mergeChangedPaths(<String>[
            'chapters/chapter_01.md',
            ...ValueReaders.stringList(knowledgeResult['changed_paths']),
            ...ValueReaders.stringList(designResult['changed_paths']),
          ]),
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章',
        );

        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['tool_name']),
          NarrativeDomainToolNames.submitChapterDelivery,
        );
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            '.novel_agent/information/knowledge_cards/knowledge-night-rain.json',
            '.novel_agent/information/design_elements/design-night-rain.json',
            'knowledge/项目知识摘要.md',
            'knowledge/设计元素摘要.md',
            'chapters/chapter_01.md',
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun recovers invalid submit_chapter_delivery attempt when chapter payload is still salvageable',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第四章',
          prompt: '继续写第四章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_delivery_invalid_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第04章.md',
                'content':
                    '# 第04章 第二层频道\n\n沈临川在静电噪声里听见第二个频道慢慢抬头。',
                'submission': <String, Object?>{
                  'submission_id': '',
                },
              },
              'result': <String, Object?>{
                'ok': false,
                'error': '领域工具参数不合法。',
                'tool_result_summary': '领域工具参数不合法，需要修正后重试。',
              },
              'ok': false,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: true,
          toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第04章《第二层频道》',
        );

        final deliveryRecordFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}deliveries${Platform.pathSeparator}conversation_submission_${preparation.runId}.json',
        );
        final chapterFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}chapters${Platform.pathSeparator}第04章.md',
        );

        expect(artifacts.outputPath, 'chapters/第04章.md');
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['delivery_state']),
          'delivered',
        );
        expect(await deliveryRecordFile.exists(), isTrue);
        expect(await chapterFile.exists(), isTrue);
        expect(await chapterFile.readAsString(), contains('第二个频道慢慢抬头'));
        expect(
          artifacts.changedPaths,
          containsAll(<String>[
            preparation.activationReportPath,
            'chapters/第04章.md',
            '.novel_agent/continuity/deliveries/conversation_submission_${preparation.runId}.json',
          ]),
        );
      },
    );

    test(
      'finalizeDraftRun supplements accepted delivery that is missing submission sidecar',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第一章',
          prompt: '继续写第一章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_delivery_invalid_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第01章.md',
                'chapter_content': '# 第01章\n\n夜雨沿着宫墙流下。',
                'submission': <String, Object?>{
                  'submission_id': '',
                },
              },
              'result': <String, Object?>{
                'ok': false,
                'error': '领域工具参数不合法。',
                'tool_result_summary': '领域工具参数不合法，需要修正后重试。',
              },
              'ok': false,
            },
            <String, Object?>{
              'id': 'call_delivery_repairable_1',
              'name': 'submit_chapter_delivery',
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第01章.md',
                'chapter_content': '# 第01章\n\n夜雨沿着宫墙流下。',
              },
              'result': <String, Object?>{
                'ok': true,
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'delivery_id':
                        'delivery:call_delivery_repairable_1:chapters/第01章.md',
                    'chapter_path': 'chapters/第01章.md',
                    'delivery_state': 'delivered_needs_repair',
                    'chapter_body_state': 'delivered',
                    'sidecar_state': 'missing',
                    'state_result': <String, Object?>{
                      'chapter_body_delivered': true,
                      'submission_accepted': false,
                    },
                  },
                },
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>['chapters/第01章.md'],
          changedPaths: const <String>['chapters/第01章.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: true,
          toolErrorSummary: 'submit_chapter_delivery：领域工具参数不合法。',
        );

        final artifacts = await service.finalizeDraftRun(
          project: project,
          preparation: preparation,
          result: result,
          title: '第01章《午夜热线》',
        );

        expect(artifacts.outputPath, 'chapters/第01章.md');
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['delivery_state']),
          'delivered',
        );
        expect(
          ValueReaders.stringValue(artifacts.chapterDelivery['sidecar_state']),
          'accepted',
        );
        expect(
          artifacts.changedPaths,
          contains('.novel_agent/continuity/deliveries/conversation_submission_${preparation.runId}.json'),
        );
      },
    );

    test(
      'finalizeDraftRun rejects chapter task that only planned or delegated without formal delivery',
      () async {
        final preparation = await service.prepareDraftRun(
          project,
          taskType: 'chapter',
          pinnedRelativePaths: const <String>['outline/总纲.md'],
        );
        final result = DraftGenerationResult(
          project: project,
          projectInfo: <String, Object?>{
            'id': project.id,
            'title': project.name,
            'path': project.rootPath,
            'project_type': project.projectType,
          },
          userPrompt: '继续写第四章',
          prompt: '继续写第四章',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>['outline/总纲.md'],
          executedTools: <Object?>[
            <String, Object?>{
              'id': 'call_plan_1',
              'name': 'set_agent_tasks',
              'arguments': <String, Object?>{
                'tasks': <Object?>[
                  <String, Object?>{'title': '先列提纲'},
                ],
              },
              'result': <String, Object?>{
                'ok': true,
                'changed_paths': <Object?>['tasks/写作第04章正文.task.json'],
              },
              'ok': true,
            },
            <String, Object?>{
              'id': 'call_sub_1',
              'name': 'call_sub_agent',
              'arguments': <String, Object?>{
                'agent_id': 'story_writer',
                'task': '先整理第04章思路',
              },
              'result': <String, Object?>{
                'ok': true,
                'result_markdown': '先做了章节计划。',
              },
              'ok': true,
            },
          ],
          writtenPaths: const <String>[],
          changedPaths: const <String>['tasks/写作第04章正文.task.json'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        );

        expect(
          () => service.finalizeDraftRun(
            project: project,
            preparation: preparation,
            result: result,
            title: '第04章《第二层频道》',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('只执行了计划/委派/读取类工具'),
            ),
          ),
        );
      },
    );
  });
}

InformationSourceRef _sourceRef() {
  return const InformationSourceRef(
    sourceRef: NarrativeSourceRef(
      sourceType: NarrativeSourceTypes.user,
      sourceId: 'user-seed',
    ),
    sourceAuthority: InformationSourceAuthorities.userDeclared,
    roleAuthority: InformationRoleAuthorities.user,
    researchDepth: InformationResearchDepths.none,
  );
}

List<String> _mergeChangedPaths(List<String> paths) {
  final result = <String>[];
  for (final rawPath in paths) {
    final path = rawPath.trim();
    if (path.isEmpty || result.contains(path)) {
      continue;
    }
    result.add(path);
  }
  return result;
}
