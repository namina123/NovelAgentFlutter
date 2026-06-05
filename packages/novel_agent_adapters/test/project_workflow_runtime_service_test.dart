import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWorkflowRuntimeService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectPromptTemplateService promptTemplateService;
    late ProjectWorkflowRuntimeService workflowRuntimeService;
    late ProjectDescriptor project;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_workflow_runtime_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      promptTemplateService = ProjectPromptTemplateService(
        workspacePort: workspacePort,
      );
      workflowRuntimeService = ProjectWorkflowRuntimeService(
        taskRepository: taskRepository,
        promptTemplateService: promptTemplateService,
        generateDraftUseCaseFactory: (_, __) {
          throw UnimplementedError('prepareWorkflowTaskExecution test only');
        },
      );
      project = ProjectDescriptor(
        id: 'workflow_test_project',
        name: '工作流测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      final modeRepository = ProjectModeGuidanceRepository(
        workspacePort: workspacePort,
      );
      final transitionService = ModeGuidanceTransitionService();
      var state = transitionService.initialize('seed_autopilot_novel');
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '黑暗奇幻权谋长篇。',
          'label': '已有种子',
        },
        <String, String>{
          'stage': 'core_promise',
          'field': 'core_promise',
          'value': '持续逆转与高压权谋。',
          'label': '核心承诺',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '誓约体系约束所有高位者，主角不能直接修改誓约。',
          'label': '世界锚点',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '主角长期目标是复仇翻案。',
          'label': '主角驱动',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，偏商业长篇。',
          'label': '风格目标',
        },
        <String, String>{
          'stage': 'autonomy_guardrails',
          'field': 'autonomy_guardrails',
          'value': '先纲后文，跨卷大转折需要人工确认。',
          'label': '托管边界',
        },
        <String, String>{
          'stage': 'review_ready',
          'field': 'review_ready',
          'value': '已确认，可以启动。',
          'label': '确认启动',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
          label: item['label']!,
          source: 'option',
        );
      }
      await modeRepository.save(project, state);
      await workspacePort.writeTextFile(
        project.rootPath,
        'styles/seed_autopilot_style.md',
        '# style\n干净利落，偏商业长篇。\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outline/总纲.md',
        '# outline\n第一卷回京。\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapter_outlines/章节任务清单.md',
        '# chapter tasks\n第一章入局。\n',
      );
      await taskRepository.saveTasks(project, <JsonMap>[
        <String, Object?>{
          'schema_version': 1,
          'id': 'task_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'goal': '按已确认规格、总纲和章纲生成本章正式正文。',
          'brief': '样章测试',
          'depends_on': <Object?>[],
          'source_paths': <Object?>[
            'specs/project_spec.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'styles/seed_autopilot_style.md',
          ],
          'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 1,
            'stage': 'sample',
            'generated_by': 'LongTaskPlanner',
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
              'styles/seed_autopilot_style.md',
            ],
          },
          'tool_hint': '先读取长期约束。',
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/task_001.json',
        },
      ]);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'createLongTaskWorkflow materializes only initial seed window for seed_to_full_novel',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_initial_window',
          name: '长任务初始窗口测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_initial_window',
          projectType: 'long_novel',
        );

        final created = await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '宫廷权谋长篇。',
            'chapter_count': 8,
            'checkpoint_interval': 3,
          },
        );

        expect(ValueReaders.boolValue(created['ok']), isTrue);
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(tasks, hasLength(4));
        expect(
          tasks.map((task) => ValueReaders.stringValue(task['task_type'])),
          orderedEquals(const <String>[
            'planning',
            'checkpoint',
            'chapter',
            'checkpoint',
          ]),
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_002'),
          ),
          isFalse,
        );
        final plan = await taskRepository.loadRecord(
          queueProject,
          ValueReaders.stringValue(created['plan_path']),
        );
        expect(
          ValueReaders.intValue(plan['planned_task_count']),
          greaterThan(4),
        );
        expect(ValueReaders.intValue(plan['materialized_task_count']), 4);
        expect(
          ValueReaders.stringValue(plan['queue_materialization']),
          'incremental',
        );
      },
    );

    test(
      'nextWorkflowTask materializes next seed window after checkpoint confirmation',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_next_window',
          name: '长任务续队列测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_next_window',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '宫廷权谋长篇。',
            'chapter_count': 5,
            'checkpoint_interval': 3,
          },
        );
        final initialTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        for (final task in initialTasks) {
          await taskRepository.transitionTask(
            queueProject,
            <String, Object?>{
              'relative_path': ValueReaders.stringValue(task['relative_path']),
            },
            TaskRuntimeConstants.statusSucceeded,
            note: 'test confirm',
          );
        }

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          contains('chapter_002'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_002'),
          ),
          isTrue,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_003'),
          ),
          isTrue,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('checkpoint_003'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask still materializes next seed window when source tasks remain waiting_user but succeeded checkpoints already cover them',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_checkpoint_covered_waiting_user',
          name: '长任务检查点覆盖测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_checkpoint_covered_waiting_user',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '宫廷权谋长篇。',
            'chapter_count': 5,
            'checkpoint_interval': 3,
          },
        );
        final initialTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        final planningTask = initialTasks.firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
        );
        final outlineCheckpoint = initialTasks.firstWhere(
          (task) =>
              ValueReaders.stringValue(task['task_type']) == 'checkpoint' &&
              ValueReaders.stringValue(
                task['id'],
              ).contains('checkpoint_outline'),
        );
        final sampleTask = initialTasks.firstWhere(
          (task) =>
              ValueReaders.stringValue(task['task_type']) == 'chapter' &&
              ValueReaders.stringValue(
                    ValueReaders.mapValue(task['metadata'])['stage'],
                  ) ==
                  'sample',
        );
        final sampleCheckpoint = initialTasks.firstWhere(
          (task) =>
              ValueReaders.stringValue(task['task_type']) == 'checkpoint' &&
              ValueReaders.stringValue(task['id']).contains('checkpoint_001'),
        );

        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              planningTask['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusWaitingUser,
          note: 'planning review waiting',
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              outlineCheckpoint['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'outline checkpoint confirmed',
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              sampleTask['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusWaitingUser,
          note: 'sample review waiting',
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              sampleCheckpoint['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'sample checkpoint confirmed',
        );

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          contains('chapter_002'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_002'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask materializes one chapter at a time when checkpoint interval is zero',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_zero_checkpoint',
          name: '长任务零检查点测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_zero_checkpoint',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '宫廷权谋长篇。',
            'chapter_count': 4,
            'checkpoint_interval': 0,
          },
        );
        final initialTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        for (final task in initialTasks) {
          await taskRepository.transitionTask(
            queueProject,
            <String, Object?>{
              'relative_path': ValueReaders.stringValue(task['relative_path']),
            },
            TaskRuntimeConstants.statusSucceeded,
            note: 'test confirm',
          );
        }

        final chapterTwo = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );
        expect(
          ValueReaders.stringValue(chapterTwo['id']),
          contains('chapter_002'),
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              chapterTwo['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'test confirm',
        );

        final chapterThree = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );
        expect(
          ValueReaders.stringValue(chapterThree['id']),
          contains('chapter_003'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.where(
            (task) =>
                ValueReaders.stringValue(task['task_type']) == 'checkpoint',
          ),
          hasLength(2),
        );
      },
    );

    test(
      'prepareWorkflowTaskExecution builds planned context sections from task paths',
      () async {
        final result = await workflowRuntimeService
            .prepareWorkflowTaskExecution(project, const <String, Object?>{
              'id': 'task_001',
            });

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final execution = ValueReaders.mapValue(result['execution']);
        final contextPack = ValueReaders.mapValue(execution['context_pack']);
        final sections = ValueReaders.objectList(
          contextPack['sections'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(
          sections.any(
            (section) => ValueReaders.stringValue(section['title']) == '长期约束',
          ),
          isTrue,
        );
        expect(
          sections.any(
            (section) => ValueReaders.stringValue(section['title']) == '任务指定来源',
          ),
          isTrue,
        );
        expect(
          sections.any(
            (section) => ValueReaders.stringValue(section['title']) == '模式引导约束',
          ),
          isTrue,
        );
        expect(
          sections.any(
            (section) => ValueReaders.stringValue(section['title']) == '项目风格规范',
          ),
          isTrue,
        );
      },
    );

    test(
      'prepareWorkflowTaskExecution injects bridged chapter length and expression constraints into long task runtime',
      () async {
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: _RecordingWorkflowGateway(
            scriptedResults: const <JsonMap>[],
          ),
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
          draftExecutionConstraintRuntimeService:
              _FakeProjectDraftExecutionConstraintRuntimeService(
                response: const <String, Object?>{
                  'chapter_length_metadata': <String, Object?>{
                    'chapter_length_profile': <String, Object?>{
                      'enabled': true,
                      'target_length': 1800,
                      'preferred_min': 1500,
                      'preferred_max': 2100,
                      'stage': 'sample',
                      'metric_unit': 'visible_characters',
                    },
                    'chapter_length_distribution_policy': <String, Object?>{
                      'rolling_window': 4,
                      'mild_deviation_ratio': 0.18,
                      'severe_deviation_ratio': 0.35,
                      'mild_adjacent_delta_ratio': 0.22,
                      'severe_adjacent_delta_ratio': 0.45,
                    },
                    'chapter_word_target': 1800,
                    'chapter_word_min': 1500,
                    'chapter_word_max': 2100,
                  },
                  'expression_constraint_profiles': <Object?>[
                    <String, Object?>{
                      'id': 'de_ai',
                      'display_name': '去 AI 风',
                      'summary': '降低模板化表达。',
                      'kind': 'natural_expression',
                      'rules': <Object?>['减少总结句。'],
                    },
                  ],
                  'project_expression_constraint_bindings': <Object?>[
                    <String, Object?>{
                      'id': 'binding_1',
                      'profile_id': 'de_ai',
                      'default_for_project': true,
                    },
                  ],
                  'runtime_report': <String, Object?>{
                    'chapter_length': <String, Object?>{'source': 'binding'},
                  },
                  'session_context_markdown':
                      '## Execution Constraints\n- 字数约束：目标约 1800 字',
                },
              ),
        );

        final result = await workflowService.prepareWorkflowTaskExecution(
          project,
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final execution = ValueReaders.mapValue(result['execution']);
        final effectiveTask = ValueReaders.mapValue(
          execution['effective_task'],
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                effectiveTask['metadata'],
              )['chapter_length_profile'],
            )['target_length'],
          ),
          1800,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                execution['execution_constraint_bridge_report'],
              )['chapter_length'],
            )['source'],
          ),
          'binding',
        );
        expect(
          ValueReaders.stringValue(execution['prompt_preview_markdown']),
          contains('目标约 1800 字'),
        );
        expect(
          ValueReaders.stringValue(execution['prompt_preview_markdown']),
          contains('表达限制细则'),
        );
        expect(
          ValueReaders.mapList(
            ValueReaders.mapValue(execution['context_pack'])['sections'],
          ).any(
            (section) =>
                ValueReaders.stringValue(
                  ValueReaders.mapValue(section)['title'],
                ) ==
                '表达限制规范',
          ),
          isTrue,
        );
      },
    );

    test(
      'createCheckpointReviewTasks materializes review tasks from review record',
      () async {
        await taskRepository.writeTextFile(
          project,
          'chapters/ch01.md',
          '# 第01章\n\n样章正文',
        );
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/rev_1.json',
          const <String, Object?>{
            'id': 'checkpoint_review_1',
            'task_type': 'chapter',
            'stage': 'sample',
            'output_paths': <Object?>['chapters/ch01.md'],
            'drift_watch_items': <Object?>['检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。'],
          },
        );

        final created = await workflowRuntimeService
            .createCheckpointReviewTasks(project, const <String, Object?>{
              'id': 'task_001',
              'checkpoint_review_path':
                  'tracking/checkpoint_reviews/rev_1.json',
            });

        expect(ValueReaders.boolValue(created['ok']), isTrue);
        expect(ValueReaders.mapList(created['tasks']), isNotEmpty);
        expect(
          ValueReaders.mapList(created['tasks']).every(
            (task) => ValueReaders.stringValue(task['task_type']) == 'review',
          ),
          isTrue,
        );
      },
    );

    test(
      'buildCheckpointReviewActionPackage returns checkpoint action contract',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/rev_actions.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'task_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/task_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
            'confirmation_focus': <Object?>['样章入口是否成立。', '主角体验是否成立。'],
            'drift_watch_items': <Object?>[
              '检查文风是否漂移。',
              '检查世界规则是否漂移。',
              '检查角色动机是否漂移。',
            ],
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
          },
        );

        final result = await workflowRuntimeService
            .buildCheckpointReviewActionPackage(
              project,
              'tracking/checkpoint_reviews/rev_actions.json',
            );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['severity']), 'high');
        expect(
          ValueReaders.mapList(result['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'request_revision_followup' &&
                ValueReaders.boolValue(item['enabled']),
          ),
          isTrue,
        );
      },
    );

    test(
      'createWorkflowReviewRepairTask materializes revision task from review report',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'reviews/continuity/ch01.md',
          '# 连续性检查：ch01\n\n- 范围：第01章\n',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'reviews/continuity/ch01.json',
          '''
{
  "id": "review_001",
  "title": "连续性检查：ch01",
  "review_type": "continuity",
  "scope": "第01章",
  "summary": "存在连续性问题。",
  "issues": [
    {
      "title": "设定前后矛盾",
      "suggestion": "统一誓约代价描述。"
    }
  ],
  "suggestions": ["统一世界规则。"]
}
''',
        );
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_001',
          'title': '连续性检查：ch01',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>[
            'reviews/continuity/ch01.md',
            'reviews/continuity/ch01.json',
          ],
          'relative_path': 'tasks/review_task_001.json',
        });

        final created = await workflowRuntimeService
            .createWorkflowReviewRepairTask(project, const <String, Object?>{
              'id': 'review_task_001',
            });

        expect(ValueReaders.boolValue(created['ok']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(created['task'])['task_type'],
          ),
          'revision',
        );
      },
    );

    test(
      'buildRevisionResolution exposes shared repair closure contract',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'revision_task_001',
          'title': '修复第01章',
          'task_type': 'revision',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'revision_diff_path': 'tracking/revision_diffs/revision_task_001.md',
          'postprocess_checkpoint_review_path':
              'tracking/checkpoint_reviews/revision_task_001.json',
          'metadata': <String, Object?>{
            'review_report_path': 'reviews/continuity/ch01.md',
          },
          'relative_path': 'tasks/revision_task_001.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/revision_task_001.json',
          const <String, Object?>{
            'id': 'checkpoint_revision_task_001',
            'summary': '建议确认是否继续返工。',
            'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          },
        );

        final result = await workflowRuntimeService.buildRevisionResolution(
          project,
          const <String, Object?>{'id': 'revision_task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['checkpoint_review_path']),
          'tracking/checkpoint_reviews/revision_task_001.json',
        );
        expect(
          ValueReaders.mapList(result['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'return_to_checkpoint' &&
                ValueReaders.boolValue(item['enabled']),
          ),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskQueue reads runtime profile initial run options before starting long run',
      () async {
        final emptyRoot = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}runtime_profile_case',
        )..createSync(recursive: true);
        final emptyProject = ProjectDescriptor(
          id: 'runtime_profile_case',
          name: '运行画像读取测试',
          rootPath: emptyRoot.path,
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          emptyProject.rootPath,
          ProjectRuntimeProfileDocumentService.profileRelativePath,
          '''
{
  "schema_version": 1,
  "project_type": "long_novel",
  "runtime_baseline_id": "chapter_collaboration_autorun",
  "runtime_mode": "human_outline_ai_draft",
  "initial_run_options": {
    "runtime_baseline_id": "chapter_collaboration_autorun",
    "runtime_mode": "human_outline_ai_draft",
    "max_steps": 2,
    "unattended": true
  }
}
''',
        );

        final result = await workflowRuntimeService.runWorkflowTaskQueue(
          emptyProject,
          const AppSettings(
            defaultProviderId: '',
            defaultAgentId: '',
            defaultModelId: '',
            defaultProjectPath: '',
            autoSaveDrafts: false,
            providers: <ProviderEndpointSettings>[],
          ),
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['stop_reason']),
          'no_runnable_task',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['long_task_record'],
            )['runtime_baseline_id'],
          ),
          'chapter_collaboration_autorun',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(result['record'])['options'],
            )['runtime_mode'],
          ),
          'human_outline_ai_draft',
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(result['long_task_record'])['options'],
            )['max_steps'],
          ),
          2,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['long_task_run_center_contract'],
            )['run_id'],
          ),
          isNotEmpty,
        );
        expect(
          ValueReaders.mapValue(
            result['long_task_run_center_contract'],
          ).containsKey('phase'),
          isTrue,
        );
      },
    );

    test(
      'loadLongTaskRun appends scheduler snapshot and run center contract',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/long_task_runs/run_load_test.json',
          const <String, Object?>{
            'id': 'run_load_test',
            'mode': 'human_outline_ai_draft',
            'status': 'running',
            'options': <String, Object?>{
              'mode': 'human_outline_ai_draft',
              'max_steps': 2,
            },
            'updated_at': '2026-05-31T12:00:00Z',
            'relative_path': 'tracking/long_task_runs/run_load_test.json',
          },
        );

        final result = await workflowRuntimeService.loadLongTaskRun(
          project,
          'tracking/long_task_runs/run_load_test.json',
        );

        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['run_center_contract'])['run_id'],
          ),
          'run_load_test',
        );
        expect(
          ValueReaders.mapValue(
            result['scheduler_snapshot'],
          ).containsKey('run_center_contract'),
          isTrue,
        );
      },
    );

    test(
      'pauseLongTaskRun returns run center contract for paused record',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/long_task_runs/run_pause_test.json',
          const <String, Object?>{
            'id': 'run_pause_test',
            'mode': 'human_outline_ai_draft',
            'status': 'running',
            'options': <String, Object?>{
              'mode': 'human_outline_ai_draft',
              'max_steps': 2,
            },
            'updated_at': '2026-05-31T12:00:00Z',
            'relative_path': 'tracking/long_task_runs/run_pause_test.json',
          },
        );

        final result = await workflowRuntimeService.pauseLongTaskRun(
          project,
          'tracking/long_task_runs/run_pause_test.json',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['run_center_contract'])['phase'],
          ),
          'paused',
        );
        expect(
          ValueReaders.mapValue(
            result['scheduler_snapshot'],
          ).containsKey('run_center_contract'),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskQueue records activation report and delivery outcome in long task run steps',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-test-1',
                      'title': '第01章',
                      'summary': '完成章节交付',
                    },
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '章节交付已完成。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节交付已完成。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskQueue(
          project,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final longTaskRecord = ValueReaders.mapValue(
          result['long_task_record'],
        );
        final steps = ValueReaders.mapList(longTaskRecord['steps']);
        expect(steps, hasLength(1));
        final step = steps.first;
        expect(
          ValueReaders.stringValue(step['chapter_delivery_state']),
          'delivered',
        );
        expect(
          ValueReaders.stringValue(step['chapter_delivery_path']),
          'chapters/第01章_seed_to_full.md',
        );
        expect(
          ValueReaders.stringValue(step['activation_report_path']),
          isNotEmpty,
        );
      },
    );

    test(
      'runWorkflowTaskOnce exposes chapter delivery schema records activation report and writes delivery outcome back to execution',
      () async {
        final knowledgeCardRepository = LocalKnowledgeCardRepository(
          workspacePort: workspacePort,
        );
        final designElementRepository = LocalDesignElementRepository(
          workspacePort: workspacePort,
        );
        final researchNoteRepository = LocalResearchNoteRepository(
          workspacePort: workspacePort,
        );
        final referenceWorkRepository = LocalReferenceWorkRepository(
          workspacePort: workspacePort,
        );
        const sourceRef = InformationSourceRef(
          sourceRef: NarrativeSourceRef(
            sourceType: NarrativeSourceTypes.user,
            sourceId: 'workflow-user-seed',
          ),
          sourceAuthority: InformationSourceAuthorities.userDeclared,
          roleAuthority: InformationRoleAuthorities.user,
          researchDepth: InformationResearchDepths.none,
        );
        await knowledgeCardRepository.appendKnowledgeCard(
          project,
          ProjectKnowledgeCard(
            cardId: 'knowledge-oath-cost',
            cardNamespace: 'project.rules',
            cardType: 'world_rule',
            title: '誓约代价',
            summary: '誓约代价会跨章累积，违反后会立即失声。',
            contentPayload: const <String, Object?>{
              'rule': '高位者一旦违约会被誓约体系立即收束',
            },
            sourceRefs: <InformationSourceRef>[sourceRef],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.required,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.91,
            lifecycleStatus: InformationLifecycleStatuses.accepted,
          ),
        );
        await designElementRepository.appendDesignElement(
          project,
          DesignElementCard(
            designId: 'design-tide-oath',
            designNamespace: 'project.structure',
            designLabel: '潮镜誓约回扣',
            designPayload: const <String, Object?>{
              'pattern': '每次誓约被触发时都让潮镜意象先行出现',
            },
            sourceRefs: <InformationSourceRef>[sourceRef],
            activationPolicy: const InformationActivationPolicy(
              activationPriority: InformationActivationPriorities.pinned,
              preferredBudgetChars: 220,
            ),
            usagePolicy: const InformationUsagePolicy(
              usageMode: InformationUsageModes.normal,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
            confidence: 0.83,
            lifecycleStatus: InformationLifecycleStatuses.proposed,
          ),
        );
        await researchNoteRepository.appendResearchNote(
          project,
          const ResearchNote(
            researchId: 'research-oath-ledger',
            query: '誓约账本意象',
            sourceKind: 'manual_note',
            sourceUrlOrRef: 'notes/oath_ledger.md',
            citation: '项目内部整理',
            summary: '账本意象适合承担誓约代价可视化与追责感。',
            usableFacts: <Object?>['账本可承载誓约历史与代价累积'],
            creativeSuggestions: <Object?>['可用于章节收尾的视觉回扣'],
            createdBy: 'workflow-runtime-test',
            usagePolicy: InformationUsagePolicy(
              usageMode: InformationUsageModes.referenceOnly,
              citationRiskLevel: InformationCitationRiskLevels.low,
            ),
          ),
        );
        await referenceWorkRepository.appendReferenceWork(
          project,
          ReferenceWorkRecord(
            referenceWorkId: 'reference-oath-boundary',
            title: '誓约边界样本',
            creator: '测试作者',
            version: '1',
            sourceRefs: <InformationSourceRef>[sourceRef],
            relationshipToProject: 'boundary_reference',
            declaredUsageIntent: '只保留誓约气质，不直接复写情节',
            allowedUsageSummary: '允许参考约束氛围，不允许挪用原文桥段。',
            riskNotes: const <Object?>['仅保留边界提醒'],
            requiresConfirmation: true,
          ),
        );
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-test-1',
                      'title': '第01章',
                      'summary': '完成章节交付',
                    },
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '章节交付已完成。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节交付已完成。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final toolNames = gateway.lastToolNames;
        expect(toolNames, contains('submit_chapter_delivery'));
        expect(
          toolNames.indexOf('submit_chapter_delivery') <
              toolNames.indexOf('write_project_file'),
          isTrue,
        );
        expect(
          ValueReaders.stringList(result['output_paths']),
          contains('chapters/第01章_seed_to_full.md'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.userActionRequired,
        );

        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        final execution = await taskRepository.loadRecord(
          project,
          ValueReaders.stringValue(task['atomic_execution_path']),
        );
        expect(
          ValueReaders.stringValue(execution['activation_report_path']),
          isNotEmpty,
        );
        expect(
          ValueReaders.stringValue(execution['chapter_delivery_state']),
          'delivered',
        );
        expect(
          ValueReaders.stringValue(execution['chapter_delivery_path']),
          'chapters/第01章_seed_to_full.md',
        );
        expect(
          ValueReaders.stringList(execution['output_paths']),
          contains('chapters/第01章_seed_to_full.md'),
        );

        final activationReport = await taskRepository.loadRecord(
          project,
          ValueReaders.stringValue(task['activation_report_path']),
        );
        expect(
          ValueReaders.mapList(
            ValueReaders.mapValue(
              activationReport['metadata'],
            )['selected_context_sections'],
          ),
          isNotEmpty,
        );
        expect(
          toolNames,
          containsAll(<String>[
            NarrativeDomainToolNames.proposeKnowledgeCard,
            NarrativeDomainToolNames.proposeDesignElement,
            NarrativeDomainToolNames.submitResearchNote,
            NarrativeDomainToolNames.linkInformationEvidence,
            NarrativeDomainToolNames.proposeReferenceWork,
          ]),
        );
        final selectedSections = ValueReaders.mapList(
          ValueReaders.mapValue(
            activationReport['metadata'],
          )['selected_context_sections'],
        );
        final selectedKinds = selectedSections
            .map((item) => ValueReaders.stringValue(item['source_kind']))
            .toSet();
        expect(
          selectedKinds,
          containsAll(<String>[
            'project_knowledge_card',
            'project_design_element',
            'project_research_note',
            'project_reference_work',
          ]),
        );
        final informationMetadata = ValueReaders.mapValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['information'],
          )['metadata'],
        );
        expect(
          ValueReaders.stringList(informationMetadata['selected_item_ids']),
          containsAll(<String>[
            'knowledge:knowledge-oath-cost',
            'design:design-tide-oath',
            'research:research-oath-ledger',
            'reference:reference-oath-boundary',
          ]),
        );
      },
    );

    test(
      'runWorkflowTaskOnce keeps low level write path compatible when model still chooses write_project_file',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_write_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'content_type': 'chapter',
                    'relative_path': 'chapters/第01章_seed_to_full.md',
                    'title': '第01章',
                    'content': '# 第01章\n\n兼容旧写入路径。',
                    'overwrite': true,
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '章节已写入。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节已写入。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringList(result['output_paths']),
          contains('chapters/第01章_seed_to_full.md'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        final execution = await taskRepository.loadRecord(
          project,
          ValueReaders.stringValue(task['atomic_execution_path']),
        );
        expect(
          ValueReaders.stringList(execution['output_paths']),
          contains('chapters/第01章_seed_to_full.md'),
        );
        expect(
          ValueReaders.mapValue(execution['chapter_delivery']).isEmpty,
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskOnce keeps formal workflow chapter at waiting_user when model asks user to choose instead of delivering chapter body',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_options_1',
                  'name': 'present_user_options',
                  'arguments': <String, Object?>{
                    'question': '当前总纲对第01章的冲突入口存在两种方向，先确认再继续？',
                    'options': <Object?>[
                      <String, Object?>{
                        'id': 'option_a',
                        'label': '保留旧入口',
                        'prompt': '保留旧入口',
                      },
                    ],
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.boolValue(result['waiting_for_user_choice']),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.userActionRequired,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['next_action'],
          ),
          'resume_when_user_confirms',
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusWaitingUser,
        );
        expect(
          ValueReaders.stringValue(task['checkpoint_review_summary']),
          isNotEmpty,
        );
      },
    );

    test(
      'runWorkflowTaskOnce fails formal workflow chapter when no chapter body or delivery is produced',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_skill_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'novel-control-station',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          contains('长任务正式章节任务未形成正式交付'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.contentQualityIssue,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['next_action'],
          ),
          'pause_for_repair',
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
      },
    );

    test(
      'runWorkflowTaskOnce skips reviewer and creates recovery task when chapter body is missing',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'gate_review_task_001',
          'title': '章级审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'depends_on': <Object?>['task_001'],
          'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': <Object?>[
            'reviews/general/ch01_gate.md',
            'reviews/general/ch01_gate.json',
          ],
          'metadata': <String, Object?>{
            'origin': 'chapter_gate_review',
            'runtime_baseline_id': 'chapter_collaboration_autorun',
            'review_type': 'general',
            'gate_source_task_id': 'task_001',
            'gate_source_task_path': 'tasks/task_001.json',
          },
          'relative_path': 'tasks/gate_review_task_001.json',
        });
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'chapter_002',
          'title': '第02章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['gate_review_task_001'],
          'output_paths': <Object?>['chapters/ch02.md'],
          'relative_path': 'tasks/chapter_002.json',
        });
        final gateway = _RecordingWorkflowGateway(scriptedResults: <JsonMap>[]);
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'gate_review_task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.boolValue(result['skipped_review']), isTrue);
        expect(gateway.requestCount, 0);
        final recoveryTask = ValueReaders.mapValue(result['recovery_task']);
        expect(ValueReaders.stringValue(recoveryTask['task_type']), 'revision');

        final chapterTwo = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002'},
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          contains(ValueReaders.stringValue(recoveryTask['id'])),
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          isNot(contains('gate_review_task_001')),
        );
      },
    );

    test(
      'runWorkflowTaskOnce carries information repair signal into writing execution result',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-test-1',
                      'title': '第01章',
                      'summary': '完成章节交付',
                    },
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '章节交付已完成。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节交付已完成。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
          checkpointReviewService: _FakeProjectLongTaskCheckpointReviewService(
            response: <String, Object?>{
              'ok': true,
              'relative_path': 'tracking/checkpoint_reviews/info_repair.json',
              'changed_paths': <Object?>[
                'tracking/checkpoint_reviews/info_repair.json',
              ],
              'review': <String, Object?>{
                'summary': 'required 信息省略 1 项，建议先补上下文。',
                'information_signal': <String, Object?>{
                  'present': true,
                  'category': 'repair',
                  'reason': 'information_missing_required',
                  'summary': 'required 信息省略 1 项，建议先补上下文。',
                  'requires_repair': true,
                  'changed_paths': <Object?>['knowledge/项目知识摘要.md'],
                },
                'expression_constraint_review': const <String, Object?>{},
              },
            },
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        final information = ValueReaders.mapValue(
          writingExecutionResult['information'],
        );
        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(information['summary']),
          contains('required 信息省略 1 项'),
        );
        expect(ValueReaders.boolValue(information['requires_repair']), isTrue);
        expect(
          ValueReaders.stringValue(writingExecutionResult['overall_status']),
          WritingExecutionOutcomeStatuses.userActionRequired,
        );
      },
    );

    test(
      'runWorkflowTaskOnce applies child-specific model and tool policy in workflow runtime',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_sub_1',
                  'name': 'call_sub_agent',
                  'arguments': <String, Object?>{
                    'agent_id': 'reviewer',
                    'task': '请先审稿，再返回结构化建议。',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '建议先强化第一段冲突，再补一处动机承接。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '建议先强化第一段冲突，再补一处动机承接。',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n已整合审稿建议后的正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-test-1',
                      'title': '第01章',
                      'summary': '完成章节交付',
                    },
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '已整合审稿建议并完成本轮任务。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已整合审稿建议并完成本轮任务。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'reviewer',
              'name': '审稿智能体',
              'model_id': 'reviewer-child-model',
              'tool_policy': const <String, Object?>{
                'allowed_tools': <String>[
                  'read_project_file',
                  'list_project_files',
                  'submit_semantic_review',
                ],
              },
            },
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿组',
              'agents': <String>['reviewer'],
            },
          ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          containsAllInOrder(<String>[
            'test-model',
            'reviewer-child-model',
            'test-model',
            'test-model',
          ]),
        );
        expect(
          gateway.requests[1].toolNames,
          containsAll(<String>['submit_semantic_review', 'read_project_file']),
        );
        expect(
          gateway.requests[1].toolNames,
          isNot(contains('write_project_file')),
        );
      },
    );

    test(
      'runWorkflowTaskOnce carries the project-selected collaboration group into child run packages',
      () async {
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_sub_1',
                  'name': 'call_sub_agent',
                  'arguments': <String, Object?>{
                    'agent_id': 'reviewer',
                    'task': '请先审稿，再返回结构化建议。',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '建议先强化第一段冲突，再补一处动机承接。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '建议先强化第一段冲突，再补一处动机承接。',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n已整合审稿建议后的正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-test-1',
                      'title': '第01章',
                      'summary': '完成章节交付',
                    },
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '已整合审稿建议并完成本轮任务。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已整合审稿建议并完成本轮任务。',
              },
            },
          ],
        );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
          loadAvailableAgents: (_) async => <JsonMap>[
            <String, Object?>{'id': 'writer', 'name': '正文智能体', 'role': '负责主写'},
            <String, Object?>{
              'id': 'reviewer',
              'name': '审稿智能体',
              'role': '负责审稿',
            },
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿组',
              'agents': <String>['reviewer'],
            },
            <String, Object?>{
              'id': 'starter_story_room',
              'name': '正文协作组',
              'agents': <String>['writer', 'reviewer'],
              'primary_agent_id': 'writer',
            },
          ],
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'starter_story_room',
                  displayName: '正文协作组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final response = ValueReaders.mapValue(result['response']);
        final toolCalls = ValueReaders.objectList(
          response['tool_calls'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        final subAgentTool = toolCalls.firstWhere(
          (tool) => ValueReaders.stringValue(tool['name']) == 'call_sub_agent',
        );
        final subAgentResult = ValueReaders.mapValue(subAgentTool['result']);
        expect(
          ValueReaders.stringValue(subAgentResult['group_id']),
          'starter_story_room',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              subAgentResult['child_run_package'],
            )['group_id'],
          ),
          'starter_story_room',
        );
        expect(
          ValueReaders.objectList(subAgentResult['available_children']),
          hasLength(2),
        );
      },
    );
  });
}

ProjectWorkflowRuntimeService _buildRuntimeService({
  required ProjectTaskRepository taskRepository,
  required ProjectPromptTemplateService promptTemplateService,
  required LocalProjectWorkspacePort workspacePort,
  required LlmGateway gateway,
  required ToolExecutionPort toolExecutionPort,
  Future<List<JsonMap>> Function(ProjectDescriptor project)?
  loadAvailableAgents,
  Future<List<JsonMap>> Function(ProjectDescriptor project)?
  loadAvailableAgentGroups,
  Future<List<ProjectAgentGroupSelection>> Function(ProjectDescriptor project)?
  loadProjectAgentGroupSelections,
  ProjectDraftExecutionConstraintRuntimeService?
  draftExecutionConstraintRuntimeService,
  ProjectLongTaskCheckpointReviewService? checkpointReviewService,
}) {
  return ProjectWorkflowRuntimeService(
    taskRepository: taskRepository,
    promptTemplateService: promptTemplateService,
    loadProjectAgentGroupSelections: loadProjectAgentGroupSelections,
    draftExecutionConstraintRuntimeService:
        draftExecutionConstraintRuntimeService,
    checkpointReviewService: checkpointReviewService,
    generateDraftUseCaseFactory: (_, __) => GenerateDraftUseCase(
      projectWorkspacePort: workspacePort,
      llmGateway: gateway,
      toolExecutionPort: toolExecutionPort,
      contextAssemblerService: ContextAssemblerService(
        budgetService: ContextBudgetService(),
        staticSectionService: ContextStaticSectionService(
          projectPromptContract: ProjectPromptContract(),
        ),
        projectFileSectionService: ContextProjectFileSectionService(),
      ),
      projectPromptContract: ProjectPromptContract(),
      loadAvailableAgents: loadAvailableAgents,
      loadAvailableAgentGroups: loadAvailableAgentGroups,
    ),
  );
}

AppSettings _testSettings() {
  return const AppSettings(
    defaultProviderId: 'test-provider',
    defaultAgentId: '',
    defaultModelId: 'test-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'test-provider',
        title: 'Test Provider',
        protocol: 'openai',
        baseUrl: 'https://example.invalid',
        apiKey: 'test-key',
        modelId: 'test-model',
        description: 'workflow runtime test provider',
      ),
    ],
  );
}

class _RecordingWorkflowGateway extends LlmGateway {
  _RecordingWorkflowGateway({required List<JsonMap> scriptedResults})
    : _scriptedResults = List<JsonMap>.from(scriptedResults);

  final List<JsonMap> _scriptedResults;
  final List<_RecordedWorkflowRequest> requests = <_RecordedWorkflowRequest>[];
  List<String> lastToolNames = const <String>[];
  int requestCount = 0;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    requestCount += 1;
    lastToolNames = request.tools
        .map(
          (schema) => ValueReaders.stringValue(
            ValueReaders.mapValue(schema['function'])['name'],
          ),
        )
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    requests.add(
      _RecordedWorkflowRequest(
        modelId: request.modelId,
        toolNames: lastToolNames,
      ),
    );
    if (_scriptedResults.isEmpty) {
      return const <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[],
        'message': <String, Object?>{'role': 'assistant', 'content': ''},
      };
    }
    return _scriptedResults.removeAt(0);
  }
}

class _RecordedWorkflowRequest {
  const _RecordedWorkflowRequest({
    required this.modelId,
    required this.toolNames,
  });

  final String modelId;
  final List<String> toolNames;
}

class _FakeProjectDraftExecutionConstraintRuntimeService
    extends ProjectDraftExecutionConstraintRuntimeService {
  _FakeProjectDraftExecutionConstraintRuntimeService({required this.response})
    : super(
        expressionConstraintProfileRepository:
            ExpressionConstraintProfileRepository(
              workspacePort: LocalProjectWorkspacePort(),
            ),
        projectExpressionConstraintBindingRepository:
            ProjectExpressionConstraintBindingRepository(
              workspacePort: LocalProjectWorkspacePort(),
            ),
        constraintBindingRepository: LocalConstraintBindingRepository(
          workspacePort: LocalProjectWorkspacePort(),
        ),
      );

  final JsonMap response;

  @override
  Future<JsonMap> resolve(
    ProjectDescriptor project, {
    required String appliesTo,
    String agentId = '',
    String modeId = '',
    String stageId = '',
    String intent = 'draft',
    String taskType = '',
    String phase = '',
    String expressionConstraintInjectionMode = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
  }) async {
    return ValueReaders.deepCopyMap(response);
  }
}

class _WorkflowToolExecutionPort implements ToolExecutionPort {
  _WorkflowToolExecutionPort({
    required LocalProjectWorkspacePort workspacePort,
    this.subAgentFailure = false,
  }) : _workspacePort = workspacePort;

  final LocalProjectWorkspacePort _workspacePort;
  final bool subAgentFailure;

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    final name = ValueReaders.stringValue(toolCall['name']);
    final arguments = ValueReaders.mapValue(toolCall['arguments']);
    if (name == 'submit_chapter_delivery') {
      final chapterPath = ValueReaders.stringValue(arguments['chapter_path']);
      final chapterContent = ValueReaders.stringValue(
        arguments['chapter_content'],
      );
      await _workspacePort.writeTextFile(
        project.rootPath,
        chapterPath,
        chapterContent,
      );
      return <String, Object?>{
        'ok': true,
        'display_text': '已提交章节交付。',
        'changed_paths': <Object?>[
          chapterPath,
          '.novel_agent/continuity/deliveries/delivery-test-1.json',
        ],
        'interaction_type': 'domain_tool',
        'tool_layer': 'domain',
        'domain_tool_name': 'submit_chapter_delivery',
        'domain_outcome_status': 'accepted',
        'domain_outcome': <String, Object?>{
          'outcome_status': 'accepted',
          'outcome_payload': <String, Object?>{
            'delivery_id': 'delivery-test-1',
            'chapter_path': chapterPath,
            'delivery_state': 'delivered',
            'chapter_body_state': 'delivered',
            'sidecar_state': 'accepted',
            'state_result': <String, Object?>{
              'state': 'delivered',
              'chapter_body_delivered': true,
              'submission_accepted': true,
            },
          },
        },
      };
    }
    if (name == 'write_project_file') {
      final relativePath = ValueReaders.stringValue(
        arguments['relative_path'],
        'chapters/generated.md',
      );
      await _workspacePort.writeTextFile(
        project.rootPath,
        relativePath,
        ValueReaders.stringValue(arguments['content']),
      );
      return <String, Object?>{
        'ok': true,
        'relative_path': relativePath,
        'changed_paths': <Object?>[relativePath],
      };
    }
    if (name == 'load_agent_skill') {
      return <String, Object?>{
        'ok': true,
        'changed_paths': const <Object?>[],
        'display_text': '已加载技能。',
      };
    }
    if (name == 'call_sub_agent') {
      if (!subAgentFailure) {
        return <String, Object?>{
          'ok': true,
          'agent_id': ValueReaders.stringValue(arguments['agent_id']),
          'agent_name': '审稿员',
          'task': ValueReaders.stringValue(arguments['task']),
          'summary': '子智能体已返回结果。',
          'result_markdown': '建议强化第一章冲突入口。',
          'changed_paths': const <Object?>[],
        };
      }
      return <String, Object?>{
        'ok': false,
        'cancelled': false,
        'error': 'Sub-agent model call failed: reviewer timeout',
        'agent_id': ValueReaders.stringValue(arguments['agent_id']),
        'agent_name': '审稿员',
        'task': ValueReaders.stringValue(arguments['task']),
        'retryable': true,
        'changed_paths': const <Object?>[],
      };
    }
    if (name == 'present_user_options') {
      return <String, Object?>{
        'ok': true,
        'waiting_for_user_choice': true,
        'question': ValueReaders.stringValue(arguments['question']),
        'options': ValueReaders.objectList(arguments['options']),
        'changed_paths': const <Object?>[],
      };
    }
    throw UnimplementedError('Unexpected tool call: $name');
  }
}

class _FakeProjectLongTaskCheckpointReviewService
    extends ProjectLongTaskCheckpointReviewService {
  _FakeProjectLongTaskCheckpointReviewService({required this.response})
    : super(
        taskRepository: ProjectTaskRepository(
          workspacePort: LocalProjectWorkspacePort(),
        ),
      );

  final JsonMap response;

  @override
  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    return ValueReaders.deepCopyMap(response);
  }
}
