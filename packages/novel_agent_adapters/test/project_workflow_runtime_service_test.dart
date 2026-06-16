import 'dart:async';
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
    late LongTaskSupervisor longTaskSupervisor;
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
      longTaskSupervisor = LongTaskSupervisor(
        runRegistry: LocalLongTaskRunRegistry(
          settingsRootPath: tempDirectory.path,
        ),
      );
      workflowRuntimeService = ProjectWorkflowRuntimeService(
        taskRepository: taskRepository,
        promptTemplateService: promptTemplateService,
        generateDraftUseCaseFactory: (_, __) {
          throw UnimplementedError('prepareWorkflowTaskExecution test only');
        },
        longTaskSupervisor: longTaskSupervisor,
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
          contains('chapter_001'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_001'),
          ),
          isTrue,
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
                ValueReaders.stringValue(task['id']).contains('checkpoint_003'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask materializes next seed window even when planning sidecar proposal remains waiting user',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_ignores_planning_sidecar_waiting_user',
          name: '长任务忽略规划 sidecar 等待确认测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_ignores_planning_sidecar_waiting_user',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '都市悬疑长篇。',
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
        final planId = ValueReaders.stringValue(
          ValueReaders.mapValue(initialTasks.first['metadata'])['plan_id'],
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 't_planning_sidecar_waiting_user',
          'title': '提交 narrative profile 更新提案',
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'goal': '补充项目级 narrative profile 提案。',
          'brief': 'sidecar 提案不应阻塞主链扩窗。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[],
          'output_paths': const <Object?>[],
          'metadata': <String, Object?>{
            'plan_id': planId,
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'stage': 'planning',
          },
          'created_at': '2026-06-12T00:00:00Z',
          'updated_at': '2026-06-12T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusWaitingUser,
              'note': 'created',
              'created_at': '2026-06-12T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/提交_narrative_profile_更新提案.task.json',
        });

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          contains('chapter_001'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_001'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask materializes next seed window before deferred checkpoint followup reviews',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_prefers_primary_over_followup_reviews',
          name: '长任务主链优先测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_prefers_primary_over_followup_reviews',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '都市悬疑长篇。',
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
        final planId = ValueReaders.stringValue(
          ValueReaders.mapValue(initialTasks.first['metadata'])['plan_id'],
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'task_followup_review_001',
          'title': '文风审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '补一轮 checkpoint follow-up 审稿。',
          'brief': '这是检查点自动衍生的 follow-up review。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': const <Object?>['reviews/style/第01章_seed_to_full.md'],
          'metadata': <String, Object?>{
            'plan_id': planId,
            'origin': 'checkpoint_review_suggestion',
            'checkpoint_review_id': 'checkpoint_review_test_001',
            'review_type': 'style',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/task_followup_review_001.json',
        });

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          contains('chapter_001'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_001'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask ignores non-plan running tasks when workflow plan tasks exist',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_ignores_non_plan_running',
          name: '长任务忽略非计划任务测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_ignores_non_plan_running',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '都市悬疑长篇。',
            'chapter_count': 3,
            'checkpoint_interval': 2,
          },
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'write_chapter_01',
          'title': '撰写第01章样章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusRunning,
          'chapter': '第01章',
          'goal': '手工遗留任务',
          'brief': '不属于当前 workflow plan',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>['specs/project_spec.md'],
          'output_paths': const <Object?>['chapters/第01章.md'],
          'metadata': const <String, Object?>{},
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusRunning,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/撰写第01章样章.task.json',
        });

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          isNot('write_chapter_01'),
        );
        expect(ValueReaders.stringValue(nextTask['id']), contains('planning'));
      },
    );

    test(
      'nextWorkflowTask ignores pseudo workflow task files emitted outside managed plan generation',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_ignores_pseudo_plan_task_file',
          name: '长任务忽略伪计划任务文件测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_ignores_pseudo_plan_task_file',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '历史长篇。',
            'chapter_count': 3,
            'checkpoint_interval': 2,
          },
        );
        final initialTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        final planningTask = initialTasks.firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
        );
        final planId = ValueReaders.stringValue(
          ValueReaders.mapValue(planningTask['metadata'])['plan_id'],
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              planningTask['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'planning completed',
          extra: const <String, Object?>{
            'output_paths': <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
          },
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'task_generated_001',
          'title': '第1章：醒来',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '001',
          'goal': '伪任务，不应进入正式 workflow 调度。',
          'brief': '由模型直接写出的任务 JSON。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'output_paths': const <Object?>['chapters/001_醒来.md'],
          'metadata': <String, Object?>{
            'plan_id': planId,
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 1,
            'stage': 'draft',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/${planId}_chapter_001_task.json',
        });

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          isNot('task_generated_001'),
        );
        expect(
          ValueReaders.stringValue(nextTask['id']),
          contains('checkpoint_outline'),
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
              ValueReaders.stringValue(
                task['id'],
              ).contains('checkpoint_sample'),
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
          contains('chapter_001'),
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        expect(
          tasks.any(
            (task) =>
                ValueReaders.stringValue(task['id']).contains('chapter_001'),
          ),
          isTrue,
        );
      },
    );

    test(
      'nextWorkflowTask falls back to deferred checkpoint review tasks when no new primary task is materialized',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_deferred_checkpoint_followup',
          name: '长任务检查点跟进审稿回退测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_deferred_checkpoint_followup',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '宫廷权谋长篇。',
            'chapter_count': 1,
            'checkpoint_interval': 1,
          },
        );
        final initialTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        final planId = ValueReaders.stringValue(
          ValueReaders.mapValue(initialTasks.first['metadata'])['plan_id'],
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
              ValueReaders.stringValue(
                task['id'],
              ).contains('checkpoint_sample'),
        );

        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              planningTask['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'planning completed',
          extra: const <String, Object?>{
            'output_paths': <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
          },
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
          TaskRuntimeConstants.statusSucceeded,
          note: 'sample chapter delivered',
          extra: const <String, Object?>{
            'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          },
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              sampleCheckpoint['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusWaitingUser,
          note: 'checkpoint surfaced before deferred reviews finished',
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'task_followup_review_sample_style',
          'title': '文风审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '补一轮 checkpoint follow-up 文风审稿。',
          'brief': '这是样章 checkpoint 自动衍生的 follow-up review。',
          'depends_on': <Object?>[ValueReaders.stringValue(sampleTask['id'])],
          'source_paths': const <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': const <Object?>['reviews/style/第01章_seed_to_full.md'],
          'metadata': <String, Object?>{
            'plan_id': planId,
            'origin': 'checkpoint_review_suggestion',
            'checkpoint_review_id': 'checkpoint_review_sample_001',
            'review_type': 'style',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/task_followup_review_sample_style.json',
        });

        final nextTask = await workflowRuntimeService.nextWorkflowTask(
          queueProject,
        );

        expect(
          ValueReaders.stringValue(nextTask['id']),
          'task_followup_review_sample_style',
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
          contains('chapter_001'),
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
          contains('chapter_002'),
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
      'seed_to_full sample task uses canonical outline paths and mounts real planning files',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'seed_queue_canonical_outline_paths',
          name: '长任务规划路径测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}seed_queue_canonical_outline_paths',
          projectType: 'long_novel',
        );

        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '历史科技轻喜剧长篇。',
            'chapter_count': 4,
          },
        );

        final tasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        final planningTask = tasks.firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
        );
        final outlineCheckpoint = tasks.firstWhere(
          (task) =>
              ValueReaders.stringValue(task['task_type']) == 'checkpoint' &&
              ValueReaders.stringValue(
                task['id'],
              ).contains('checkpoint_outline'),
        );
        final sampleTask = tasks.firstWhere(
          (task) =>
              ValueReaders.stringValue(task['task_type']) == 'chapter' &&
              ValueReaders.stringValue(
                    ValueReaders.mapValue(task['metadata'])['stage'],
                  ) ==
                  'sample',
        );

        expect(
          ValueReaders.stringList(sampleTask['source_paths']),
          containsAll(<String>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ]),
        );
        expect(
          ValueReaders.stringList(sampleTask['source_paths']),
          isNot(contains('outline/总纲.md')),
        );
        expect(
          ValueReaders.stringList(sampleTask['source_paths']),
          isNot(contains('chapter_outlines/章节任务清单.md')),
        );

        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n历史科技轻喜剧。\n',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n主角先活下来，再靠小改良慢慢改变镇子。\n',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务清单\n\n## 第01章\n- 醒来\n- 找到落脚点\n',
        );
        await taskRepository.transitionTask(
          queueProject,
          <String, Object?>{
            'relative_path': ValueReaders.stringValue(
              planningTask['relative_path'],
            ),
          },
          TaskRuntimeConstants.statusSucceeded,
          note: 'planning completed',
          extra: const <String, Object?>{
            'output_paths': <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
              'outlines/chapters/章节任务清单.md',
            ],
          },
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

        final prepared = await workflowRuntimeService
            .prepareWorkflowTaskExecution(queueProject, <String, Object?>{
              'id': ValueReaders.stringValue(sampleTask['id']),
            });

        expect(ValueReaders.boolValue(prepared['ok']), isTrue);
        final execution = ValueReaders.mapValue(prepared['execution']);
        final activationReport = ValueReaders.mapValue(
          execution['activation_report'],
        );
        final selectedSections = ValueReaders.mapList(
          ValueReaders.mapValue(
            activationReport['metadata'],
          )['selected_context_sections'],
        );
        final selectedPaths = selectedSections
            .map((item) => ValueReaders.stringValue(item['target_path']))
            .where((path) => path.trim().isNotEmpty)
            .toList(growable: false);
        expect(selectedPaths, contains('outlines/story/总纲.md'));
        expect(selectedPaths, contains('outlines/chapters/章节任务清单.md'));
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
                  'expression_constraint_policy_mode': 'adaptive',
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
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['execution_constraints'],
            )['expression_constraint_policy_mode'],
          ),
          isNotEmpty,
        );
      },
    );

    test(
      'prepareWorkflowTaskExecution normalizes planning-stage agent task semantics before exposing tools and contracts',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'task_planning_agent',
          'title': '读取现有种子材料',
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '根据种子扩展为可执行的作品规格、总纲和章节任务清单',
          'brief': '读取并整合当前种子材料。',
          'output_paths': <Object?>['outlines/story/读取现有种子材料.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 3,
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'relative_path': 'tasks/task_planning_agent.json',
        });
        final fakeRuntimeService =
            _FakeProjectDraftExecutionConstraintRuntimeService(
              response: const <String, Object?>{
                'runtime_report': <String, Object?>{
                  'expression_constraints': <String, Object?>{
                    'policy_applied': false,
                  },
                },
                'session_context_markdown':
                    '## Execution Constraints\n- planning',
              },
            );
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
          draftExecutionConstraintRuntimeService: fakeRuntimeService,
        );

        final result = await workflowService.prepareWorkflowTaskExecution(
          project,
          const <String, Object?>{'id': 'task_planning_agent'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(fakeRuntimeService.calls, hasLength(1));
        expect(fakeRuntimeService.calls.single.taskType, 'planning');
        final execution = ValueReaders.mapValue(result['execution']);
        final effectiveTask = ValueReaders.mapValue(
          execution['effective_task'],
        );
        expect(
          ValueReaders.stringValue(effectiveTask['task_type']),
          'planning',
        );
        expect(
          ValueReaders.stringList(execution['workflow_tool_ids']),
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
        expect(
          ValueReaders.stringValue(execution['prompt_preview_markdown']),
          contains('这是长篇规划任务'),
        );
      },
    );

    test(
      'prepareWorkflowTaskExecution passes recent long task constraint summaries into runtime resolve',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'task_000',
          'title': '正文：第00章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusSucceeded,
          'chapter': '第00章',
          'goal': '上一章',
          'brief': '上一章',
          'output_paths': <Object?>['chapters/第00章_seed_to_full.md'],
          'atomic_execution_path': 'tracking/chapter_atomic/task_000.json',
          'metadata': <String, Object?>{
            'plan_id': 'plan_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 0,
            'stage': 'draft',
          },
          'created_at': '2026-05-24T00:00:00Z',
          'updated_at': '2026-05-24T00:30:00Z',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/chapter_atomic/task_000.json',
          <String, Object?>{
            'writing_execution_result': <String, Object?>{
              'execution_id': 'task_000_exec',
              'workflow_kind': 'workflow_task',
              'overall_status': WritingExecutionOutcomeStatuses.success,
              'summary': '上一章已完成。',
              'delivery': const <String, Object?>{},
              'constraints': <String, Object?>{
                'present': true,
                'expression_constraint_policy_mode': 'adaptive',
                'expression_constraint_injection_strength': 'sections',
                'expression_constraint_review_requirement': 'when_applied',
                'expression_constraint_violation_disposition': 'adjust_next',
                'expression_constraint_applied': true,
                'expression_constraint_review_required': true,
                'expression_constraint_review_provided': true,
                'expression_constraint_runtime_escalated': true,
                'expression_constraint_gate': <String, Object?>{
                  'present': true,
                  'recommended_disposition': 'adjust_next',
                  'adjust_next_chapter': true,
                  'risk_signals': <Object?>['视角泄漏'],
                },
              },
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{},
              'schema_version': 1,
            },
          },
        );
        final fakeRuntimeService =
            _FakeProjectDraftExecutionConstraintRuntimeService(
              response: const <String, Object?>{
                'expression_constraint_policy_mode': 'adaptive',
                'expression_constraint_injection_strength': 'sections',
                'expression_constraint_review_requirement': 'when_applied',
                'expression_constraint_violation_disposition': 'adjust_next',
                'expression_constraint_applied': true,
                'expression_constraint_injection_mode': 'brief_and_sections',
                'expression_constraint_review_required': true,
                'runtime_report': const <String, Object?>{},
              },
            );
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
          draftExecutionConstraintRuntimeService: fakeRuntimeService,
        );

        final result = await workflowService.prepareWorkflowTaskExecution(
          project,
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(fakeRuntimeService.calls, hasLength(1));
        expect(
          fakeRuntimeService.calls.single.recentExpressionConstraintSummaries,
          hasLength(1),
        );
        expect(
          fakeRuntimeService
              .calls
              .single
              .recentExpressionConstraintSummaries
              .single
              .expressionConstraintRuntimeEscalated,
          isTrue,
        );
        expect(
          ValueReaders.mapValue(
            ValueReaders.mapValue(result['execution'])['execution_constraints'],
          ).isNotEmpty,
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
      'runWorkflowTaskOnce auto schedules long-task checkpoint followup reviews without rewiring downstream dependencies',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'task_002',
          'title': '正文：第02章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['task_001'],
          'output_paths': <Object?>['chapters/第02章_seed_to_full.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 2,
            'stage': 'draft',
          },
          'relative_path': 'tasks/task_002.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_auto_followup',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章_seed_to_full.md',
                    'chapter_content': '# 第01章\n\n正式正文。',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-auto-followup',
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
            persistentTaskRepository: taskRepository,
            response: <String, Object?>{
              'ok': true,
              'relative_path':
                  'tracking/checkpoint_reviews/auto_followup_medium.json',
              'changed_paths': <Object?>[
                'tracking/checkpoint_reviews/auto_followup_medium.json',
              ],
              'review': <String, Object?>{
                'id': 'checkpoint_review_auto_followup_medium',
                'task': <String, Object?>{
                  'id': 'task_001',
                  'title': '样章：第01章',
                  'task_type': 'chapter',
                  'relative_path': 'tasks/task_001.json',
                },
                'task_type': 'chapter',
                'stage': 'sample',
                'summary': '当前节点建议先过一轮补充审视，再决定是否继续推进。',
                'result_ok': true,
                'severity': 'medium',
                'severity_label': '中',
                'severity_reasons': <Object?>['样章阶段建议补一轮审稿。'],
                'output_paths': <Object?>['chapters/第01章_seed_to_full.md'],
                'changed_paths': <Object?>['chapters/第01章_seed_to_full.md'],
                'confirmation_focus': <Object?>['样章入口是否成立。'],
                'drift_watch_items': <Object?>['检查文风是否漂移。'],
                'persistent_context_paths': <Object?>[
                  'tracking/modes/seed_autopilot_novel/guidance.md',
                ],
                'continuation_disposition': 'blocked_wait_user',
                'disposition': <String, Object?>{
                  'disposition': 'blocked_wait_user',
                  'reason': 'medium_risk_needs_review',
                  'create_followup_review_tasks': true,
                  'request_revision_followup': false,
                },
                'information_signal': const <String, Object?>{
                  'present': false,
                  'category': 'accept',
                },
                'collaboration_signal': const <String, Object?>{
                  'present': false,
                  'category': 'accept',
                },
                'expression_constraint_signal': const <String, Object?>{
                  'present': false,
                  'category': 'suggest_strengthen',
                },
              },
            },
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              result['checkpoint_followup'],
            )['auto_scheduled'],
          ),
          isTrue,
        );
        final sourceTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(sourceTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        final reviewTasks = (await taskRepository.listTasks(project))
            .where(
              (task) =>
                  ValueReaders.stringValue(task['task_type']) == 'review' &&
                  ValueReaders.stringValue(
                        ValueReaders.mapValue(task['metadata'])['origin'],
                      ) ==
                      'checkpoint_review_suggestion',
            )
            .toList(growable: false);
        expect(reviewTasks, isNotEmpty);
        final downstreamTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_002'},
        );
        expect(
          ValueReaders.stringList(downstreamTask['depends_on']),
          contains('task_001'),
        );
        expect(
          ValueReaders.mapList(
            ValueReaders.mapValue(
              result['checkpoint_followup'],
            )['rewired_tasks'],
          ),
          isEmpty,
        );
        final nextRunnable = TaskSelectionService(
          taskDefinitionService: TaskDefinitionService(),
        ).nextRunnableTaskFromTasks(await taskRepository.listTasks(project));
        expect(ValueReaders.stringValue(nextRunnable['task_type']), 'review');
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
        expect(ValueReaders.stringValue(result['severity']), 'medium');
        expect(
          ValueReaders.mapList(result['actions']).any(
            (item) =>
                ValueReaders.stringValue(item['id']) ==
                    'create_followup_review_tasks' &&
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
        final synced = await longTaskSupervisor.loadRun(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['long_task_record'])['id'],
          ),
        );
        expect(synced, isNotNull);
        expect(synced!.project.rootPath, emptyProject.rootPath);
      },
    );

    test(
      'runWorkflowTaskQueue resumes inferred long run instead of overwriting it with mixed task pool state',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'resume_inferred_long_run_case',
          name: '恢复推断长任务运行记录测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}resume_inferred_long_run_case',
          projectType: 'long_novel',
        );
        await workflowRuntimeService.createLongTaskWorkflow(
          queueProject,
          TaskRuntimeConstants.modeSeedToFullNovel,
          options: const <String, Object?>{
            'seed_prompt': '历史长篇。',
            'chapter_count': 3,
            'checkpoint_interval': 2,
          },
        );
        final workflowTasks = await workflowRuntimeService.listWorkflowTasks(
          queueProject,
        );
        final planningTask = workflowTasks.firstWhere(
          (task) => ValueReaders.stringValue(task['task_type']) == 'planning',
        );
        final planId = ValueReaders.stringValue(
          ValueReaders.mapValue(planningTask['metadata'])['plan_id'],
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
        await taskRepository.saveTask(queueProject, const <String, Object?>{
          'schema_version': 1,
          'id': 'write_project_spec',
          'title': '写入项目规格',
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>[],
          'source_paths': <Object?>[],
          'output_paths': <Object?>['specs/project_spec.md'],
          'created_at': '2026-05-31T12:00:00Z',
          'updated_at': '2026-05-31T12:00:00Z',
          'history': <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-31T12:00:00Z',
            },
          ],
          'relative_path': 'tasks/写入项目规格.task.json',
        });
        final existingRunPath = 'tracking/long_task_runs/${planId}_run.json';
        await taskRepository.saveRecord(
          queueProject,
          existingRunPath,
          <String, Object?>{
            'schema_version': 1,
            'kind': 'long_task_run',
            'id': '${planId}_run',
            'plan_id': planId,
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusPaused,
            'options': const <String, Object?>{
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'max_steps': 1,
            },
            'task_count': 4,
            'tasks_snapshot': <Object?>[
              <String, Object?>{
                'id': ValueReaders.stringValue(planningTask['id']),
                'title': ValueReaders.stringValue(planningTask['title']),
                'task_type': 'planning',
                'mode': TaskRuntimeConstants.modeSeedToFullNovel,
                'status': TaskRuntimeConstants.statusWaitingUser,
                'depends_on': <Object?>[],
                'output_paths': <Object?>['specs/project_spec.md'],
                'sort_order': 1,
                'relative_path': ValueReaders.stringValue(
                  planningTask['relative_path'],
                ),
              },
            ],
            'steps': <Object?>[
              <String, Object?>{
                'index': 1,
                'phase': 'model_step',
                'task': <String, Object?>{
                  'id': 'seed_step_1',
                  'title': '规划',
                  'task_type': 'planning',
                },
                'ok': true,
              },
            ],
            'completed_steps': 1,
            'failed_steps': 0,
            'pause_requested': false,
            'stop_reason': 'manual_pause',
            'stop_note': 'paused',
            'guidance_queue': <Object?>[],
            'created_at': '2026-05-31T12:00:00Z',
            'updated_at': '2026-05-31T12:00:00Z',
            'relative_path': existingRunPath,
            'summary_path': 'tracking/long_task_runs/${planId}_run.md',
          },
        );

        final result = await workflowRuntimeService.runWorkflowTaskQueue(
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['long_task_run_path']),
          existingRunPath,
        );
        final resumedRun = await taskRepository.loadRecord(
          queueProject,
          existingRunPath,
        );
        expect(
          ValueReaders.stringValue(resumedRun['mode']),
          TaskRuntimeConstants.modeSeedToFullNovel,
        );
        expect(ValueReaders.intValue(resumedRun['completed_steps']), 1);
        expect(
          ValueReaders.mapList(resumedRun['tasks_snapshot']).any(
            (task) =>
                ValueReaders.stringValue(task['id']) == 'write_project_spec',
          ),
          isFalse,
        );
      },
    );

    test(
      'resumeLongTaskRun auto confirms resumable checkpoint before restarting queue',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'resume_checkpoint_before_queue_case',
          name: '恢复前自动确认检查点测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}resume_checkpoint_before_queue_case',
          projectType: 'long_novel',
        );
        await taskRepository.saveTasks(queueProject, <JsonMap>[
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_resume_checkpoint_outline',
            'title': '检查点：确认总纲与章节任务',
            'task_type': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'goal': '确认当前检查点后继续。',
            'brief': '显式检查点。',
            'depends_on': const <Object?>[],
            'source_paths': const <Object?>[
              'specs/project_spec.md',
              'outlines/story/总纲.md',
            ],
            'output_paths': const <Object?>['outlines/story/总纲.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_resume_checkpoint',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 2,
              'stage': 'checkpoint',
              'runtime_baseline_id': 'continuous_autonomous',
              'manual_checkpoint': true,
              LongTaskSampleReadinessService.readinessCheckpointFlag: true,
            },
            'last_writing_execution_result': const <String, Object?>{
              'overall_status': WritingExecutionOutcomeStatuses.success,
              'blocks_progress': false,
            },
            'created_at': '2026-06-12T00:00:00Z',
            'updated_at': '2026-06-12T00:00:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusWaitingUser,
                'note': 'checkpoint waiting',
                'created_at': '2026-06-12T00:00:00Z',
              },
            ],
            'relative_path': 'tasks/plan_resume_checkpoint_outline.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_resume_checkpoint_chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '继续写样章。',
            'brief': '后续主链章节。',
            'depends_on': const <Object?>['plan_resume_checkpoint_outline'],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['chapters/第01章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_resume_checkpoint',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 3,
              'stage': 'sample',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:01Z',
            'updated_at': '2026-06-12T00:00:01Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:01Z',
              },
            ],
            'relative_path': 'tasks/plan_resume_checkpoint_chapter_001.json',
          },
        ]);
        await taskRepository.saveRecord(
          queueProject,
          'tracking/checkpoint_reviews/plan_resume_checkpoint_outline.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'plan_resume_checkpoint_outline',
              'title': '检查点：确认总纲与章节任务',
              'task_type': 'checkpoint',
              'relative_path': 'tasks/plan_resume_checkpoint_outline.json',
            },
            'task_type': 'checkpoint',
            'stage': 'checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['outlines/story/总纲.md'],
            'confirmation_focus': <Object?>['当前检查点可确认后继续主链。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
            'narrative_supervisor_risk': <String, Object?>{
              'overall': <String, Object?>{
                'category': 'accept',
                'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
              },
            },
          },
        );
        await taskRepository.saveRecord(
          queueProject,
          'tracking/long_task_runs/plan_resume_checkpoint_run.json',
          const <String, Object?>{
            'schema_version': 1,
            'kind': 'long_task_run',
            'id': 'plan_resume_checkpoint_run',
            'plan_id': 'plan_resume_checkpoint',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusPaused,
            'options': <String, Object?>{
              'runtime_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'runtime_baseline_id': 'continuous_autonomous',
              'max_steps': 1,
            },
            'task_count': 2,
            'tasks_snapshot': <Object?>[],
            'steps': <Object?>[],
            'completed_steps': 0,
            'failed_steps': 0,
            'pause_requested': true,
            'last_task_id': 'plan_resume_checkpoint_outline',
            'last_task_path': 'tasks/plan_resume_checkpoint_outline.json',
            'last_checkpoint_review_path':
                'tracking/checkpoint_reviews/plan_resume_checkpoint_outline.json',
            'last_writing_execution_next_action': 'resume_when_user_confirms',
            'created_at': '2026-06-12T00:00:00Z',
            'updated_at': '2026-06-12T00:00:00Z',
            'relative_path':
                'tracking/long_task_runs/plan_resume_checkpoint_run.json',
            'summary_path':
                'tracking/long_task_runs/plan_resume_checkpoint_run.md',
          },
        );
        final workflowService = _QueueSelectionBoundaryWorkflowRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
        );

        final result = await workflowService.resumeLongTaskRun(
          queueProject,
          _testSettings(),
          'tracking/long_task_runs/plan_resume_checkpoint_run.json',
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(workflowService.executedTaskIds, <String>[
          'plan_resume_checkpoint_chapter_001',
        ]);
        final checkpointTask = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'plan_resume_checkpoint_outline'},
        );
        expect(
          ValueReaders.stringValue(checkpointTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(
            checkpointTask['continued_checkpoint_review_path'],
          ),
          'tracking/checkpoint_reviews/plan_resume_checkpoint_outline.json',
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
        final synced = await longTaskSupervisor.loadRun('run_pause_test');
        expect(synced, isNotNull);
        expect(synced!.status, LongTaskRunStatus.paused);
        expect(
          ValueReaders.mapValue(
            result['scheduler_snapshot'],
          ).containsKey('run_center_contract'),
          isTrue,
        );
      },
    );

    test(
      'stopLongTaskRun finishes record with manual stop and run center contract',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/long_task_runs/run_stop_test.json',
          const <String, Object?>{
            'id': 'run_stop_test',
            'mode': 'human_outline_ai_draft',
            'status': 'paused',
            'options': <String, Object?>{
              'mode': 'human_outline_ai_draft',
              'max_steps': 2,
            },
            'updated_at': '2026-05-31T12:00:00Z',
            'relative_path': 'tracking/long_task_runs/run_stop_test.json',
          },
        );

        final result = await workflowRuntimeService.stopLongTaskRun(
          project,
          'tracking/long_task_runs/run_stop_test.json',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['record'])['status'],
          ),
          TaskRuntimeConstants.statusCancelled,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['record'])['stop_reason'],
          ),
          'manual_stop',
        );
        final synced = await longTaskSupervisor.loadRun('run_stop_test');
        expect(synced, isNotNull);
        expect(synced!.status, LongTaskRunStatus.stopped);
        expect(
          ValueReaders.mapValue(
            result['scheduler_snapshot'],
          ).containsKey('run_center_contract'),
          isTrue,
        );
      },
    );

    test(
      'applyLongTaskFailureAction retries failed task through runtime entry',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'schema_version': 1,
          'id': 'failed_planning',
          'title': '规划：扩展作品规格与总纲',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusFailed,
          'depends_on': <Object?>[],
          'source_paths': <Object?>[],
          'output_paths': <Object?>['specs/project_spec.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_failed_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 1,
          },
          'created_at': '2026-05-31T12:00:00Z',
          'updated_at': '2026-05-31T12:00:00Z',
          'history': <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusFailed,
              'note': 'failed',
              'created_at': '2026-05-31T12:00:00Z',
            },
          ],
          'relative_path': 'tasks/failed_planning.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/long_task_runs/run_failed_test.json',
          const <String, Object?>{
            'id': 'run_failed_test',
            'mode': 'seed_to_full_novel',
            'status': 'paused',
            'options': <String, Object?>{
              'mode': 'seed_to_full_novel',
              'max_steps': 2,
              'stop_on_failed_task': true,
            },
            'updated_at': '2026-05-31T12:00:00Z',
            'relative_path': 'tracking/long_task_runs/run_failed_test.json',
          },
        );

        final result = await workflowRuntimeService.applyLongTaskFailureAction(
          project,
          selector: const <String, Object?>{
            'relative_path': 'tasks/failed_planning.json',
            'task_id': 'failed_planning',
          },
          command: 'retry',
          runPath: 'tracking/long_task_runs/run_failed_test.json',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(result['task'])['status'],
          ),
          TaskRuntimeConstants.statusQueued,
        );
        expect(
          ValueReaders.mapValue(
            result['run_center_contract'],
          ).containsKey('phase'),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskQueue records activation report and delivery outcome in long task run steps',
      () async {
        final baseTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        await taskRepository.saveTask(project, <String, Object?>{
          ...baseTask,
          'metadata': <String, Object?>{
            ...ValueReaders.mapValue(baseTask['metadata']),
            'stage': 'draft',
          },
        });
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
          'chapters/第01章.md',
        );
        expect(
          ValueReaders.stringValue(step['activation_report_path']),
          isNotEmpty,
        );
      },
    );

    test(
      'runWorkflowTaskQueue finalizes when only deferred checkpoint followup summary tasks remain after a primary step',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'queue_deferred_followup_summary_case',
          name: '队列 deferred summary 收束测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}queue_deferred_followup_summary_case',
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n测试规格。\n',
        );
        await taskRepository.saveTasks(queueProject, <JsonMap>[
          <String, Object?>{
            'schema_version': 1,
            'id': 'primary_planning_001',
            'title': '规划：补充项目规格',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '补充项目规格。',
            'brief': '这是主链 planning task。',
            'depends_on': const <Object?>[],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['specs/project_spec.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_followup_summary',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 1,
              'stage': 'planning',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:00Z',
            'updated_at': '2026-06-12T00:00:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:00Z',
              },
            ],
            'relative_path': 'tasks/primary_planning_001.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'followup_summary_001',
            'title': '连续性检查：第01章摘要',
            'task_type': 'summary',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '补充 checkpoint follow-up 摘要检查。',
            'brief': '这是检查点自动衍生的 follow-up summary。',
            'depends_on': const <Object?>['primary_planning_001'],
            'source_paths': const <Object?>['summaries/第01章.summary.md'],
            'output_paths': const <Object?>[
              'reviews/continuity/第01章.summary.md',
            ],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_followup_summary',
              'origin': 'checkpoint_review_suggestion',
              'checkpoint_review_id': 'checkpoint_review_summary_001',
              'task_id': 'primary_planning_001',
              'task_type': 'planning',
              'stage': 'summary',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:01Z',
            'updated_at': '2026-06-12T00:00:01Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:01Z',
              },
            ],
            'relative_path': 'tasks/followup_summary_001.json',
          },
        ]);
        final workflowService = _QueueSelectionBoundaryWorkflowRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
        );

        final result = await workflowService.runWorkflowTaskQueue(
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 2},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(workflowService.executedTaskIds, <String>[
          'primary_planning_001',
        ]);
        expect(ValueReaders.intValue(result['steps_run']), 1);
        expect(
          ValueReaders.stringValue(result['stop_reason']),
          'no_runnable_task',
        );
        final queueRecord = ValueReaders.mapValue(result['record']);
        expect(ValueReaders.stringValue(queueRecord['status']), 'completed');
        expect(ValueReaders.intValue(queueRecord['completed_steps']), 1);
        final deferredTask = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'followup_summary_001'},
        );
        expect(
          ValueReaders.stringValue(deferredTask['status']),
          TaskRuntimeConstants.statusQueued,
        );
      },
    );

    test(
      'runWorkflowTaskQueue executes deferred checkpoint followup when it blocks the next primary chapter',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'queue_deferred_followup_blocks_primary',
          name: '队列 deferred followup 解锁主链测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}queue_deferred_followup_blocks_primary',
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'chapters/第05章.md',
          '# 第05章\n\n测试正文。\n',
        );
        await taskRepository.saveTasks(queueProject, <JsonMap>[
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_queue_followup_blocking_chapter_005',
            'title': '第05章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'goal': '第05章已完成。',
            'brief': '来源章节任务。',
            'depends_on': const <Object?>[],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['chapters/第05章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_followup_blocking',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 27,
              'stage': 'draft',
              'runtime_baseline_id': 'continuous_autonomous',
              'generated_by': 'LongTaskRevision',
            },
            'created_at': '2026-06-12T00:00:00Z',
            'updated_at': '2026-06-12T00:00:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusSucceeded,
                'note': 'completed',
                'created_at': '2026-06-12T00:00:00Z',
              },
            ],
            'relative_path':
                'tasks/plan_queue_followup_blocking_chapter_005.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'followup_review_005_style',
            'title': '文风审稿：第05章',
            'task_type': 'review',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '补跑 followup 审稿。',
            'brief': '这是检查点自动衍生的 follow-up review。',
            'depends_on': const <Object?>[
              'plan_queue_followup_blocking_chapter_005',
            ],
            'source_paths': const <Object?>['chapters/第05章.md'],
            'output_paths': const <Object?>['reviews/style/第05章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_followup_blocking',
              'origin': 'checkpoint_review_suggestion',
              'checkpoint_review_id': 'checkpoint_review_chapter_005',
              'review_type': 'style',
              'task_id': 'plan_queue_followup_blocking_chapter_005',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:01Z',
            'updated_at': '2026-06-12T00:00:01Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:01Z',
              },
            ],
            'relative_path': 'tasks/followup_review_005_style.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_queue_followup_blocking_chapter_006',
            'title': '第06章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '第06章待写。',
            'brief': '下一章主链任务。',
            'depends_on': const <Object?>['followup_review_005_style'],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['chapters/第06章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_followup_blocking',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 28,
              'stage': 'draft',
              'runtime_baseline_id': 'continuous_autonomous',
              'generated_by': 'LongTaskRevision',
            },
            'created_at': '2026-06-12T00:00:02Z',
            'updated_at': '2026-06-12T00:00:02Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:02Z',
              },
            ],
            'relative_path':
                'tasks/plan_queue_followup_blocking_chapter_006.json',
          },
        ]);
        final workflowService = _QueueSelectionBoundaryWorkflowRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
        );

        final result = await workflowService.runWorkflowTaskQueue(
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(workflowService.executedTaskIds, <String>[
          'followup_review_005_style',
        ]);
        expect(ValueReaders.intValue(result['steps_run']), 1);
        expect(ValueReaders.stringValue(result['stop_reason']), 'max_steps');
        final followupTask = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'followup_review_005_style'},
        );
        expect(
          ValueReaders.stringValue(followupTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        final downstreamTask = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{
            'id': 'plan_queue_followup_blocking_chapter_006',
          },
        );
        expect(
          ValueReaders.stringValue(downstreamTask['status']),
          TaskRuntimeConstants.statusQueued,
        );
      },
    );

    test(
      'runWorkflowTaskQueue keeps succeeded deferred followup dependencies when selecting a runnable primary revision',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'queue_primary_revision_depends_on_succeeded_followup',
          name: '队列 primary revision 依赖已成功 followup 测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}queue_primary_revision_depends_on_succeeded_followup',
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'chapters/第02章.md',
          '# 第02章\n\n测试正文。\n',
        );
        await taskRepository.saveTasks(queueProject, <JsonMap>[
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_queue_revision_followup_chapter_002',
            'title': '第02章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'goal': '第02章已完成。',
            'brief': '来源章节任务。',
            'depends_on': const <Object?>[],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['chapters/第02章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_revision_followup',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 8,
              'stage': 'draft',
              'runtime_baseline_id': 'continuous_autonomous',
              'generated_by': 'LongTaskRevision',
            },
            'created_at': '2026-06-12T00:00:00Z',
            'updated_at': '2026-06-12T00:00:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusSucceeded,
                'note': 'completed',
                'created_at': '2026-06-12T00:00:00Z',
              },
            ],
            'relative_path':
                'tasks/plan_queue_revision_followup_chapter_002.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'followup_review_002_plot',
            'title': '剧情检查：第02章',
            'task_type': 'review',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusSucceeded,
            'goal': 'checkpoint follow-up 审稿已完成。',
            'brief': '已成功的 deferred follow-up review。',
            'depends_on': const <Object?>[
              'plan_queue_revision_followup_chapter_002',
            ],
            'source_paths': const <Object?>['chapters/第02章.md'],
            'output_paths': const <Object?>['reviews/plot/第02章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_revision_followup',
              'origin': 'checkpoint_review_suggestion',
              'checkpoint_review_id': 'checkpoint_review_chapter_002',
              'review_type': 'plot',
              'task_id': 'plan_queue_revision_followup_chapter_002',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:01Z',
            'updated_at': '2026-06-12T00:00:01Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusSucceeded,
                'note': 'completed',
                'created_at': '2026-06-12T00:00:01Z',
              },
            ],
            'relative_path': 'tasks/followup_review_002_plot.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'followup_summary_002',
            'title': '连续性检查：第02章摘要',
            'task_type': 'summary',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '未阻塞主链的 deferred summary。',
            'brief': '不应在 revision 前被队列优先执行。',
            'depends_on': const <Object?>[
              'plan_queue_revision_followup_chapter_002',
            ],
            'source_paths': const <Object?>['summaries/第02章.summary.md'],
            'output_paths': const <Object?>[
              'reviews/continuity/第02章.summary.md',
            ],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_revision_followup',
              'origin': 'checkpoint_review_suggestion',
              'checkpoint_review_id': 'checkpoint_review_chapter_002',
              'task_id': 'plan_queue_revision_followup_chapter_002',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:02Z',
            'updated_at': '2026-06-12T00:00:02Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:02Z',
              },
            ],
            'relative_path': 'tasks/followup_summary_002.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'revision_fix_002_plot',
            'title': '修复审稿问题：第02章',
            'task_type': 'revision',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '根据已完成审稿修复第02章。',
            'brief': '这是主链 revision task。',
            'depends_on': const <Object?>['followup_review_002_plot'],
            'source_paths': const <Object?>[
              'chapters/第02章.md',
              'reviews/plot/第02章.md',
            ],
            'output_paths': const <Object?>['chapters/第02章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_revision_followup',
              'origin': 'review_report',
              'review_type': 'plot',
              'runtime_baseline_id': 'continuous_autonomous',
            },
            'created_at': '2026-06-12T00:00:03Z',
            'updated_at': '2026-06-12T00:00:03Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:03Z',
              },
            ],
            'relative_path': 'tasks/revision_fix_002_plot.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_queue_revision_followup_chapter_003',
            'title': '第03章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'goal': '第03章待写。',
            'brief': '下一章主链任务。',
            'depends_on': const <Object?>['revision_fix_002_plot'],
            'source_paths': const <Object?>['specs/project_spec.md'],
            'output_paths': const <Object?>['chapters/第03章.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_queue_revision_followup',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'sort_order': 9,
              'stage': 'draft',
              'runtime_baseline_id': 'continuous_autonomous',
              'generated_by': 'LongTaskRevision',
            },
            'created_at': '2026-06-12T00:00:04Z',
            'updated_at': '2026-06-12T00:00:04Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-12T00:00:04Z',
              },
            ],
            'relative_path':
                'tasks/plan_queue_revision_followup_chapter_003.json',
          },
        ]);
        final workflowService = _QueueSelectionBoundaryWorkflowRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
        );

        final result = await workflowService.runWorkflowTaskQueue(
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(workflowService.executedTaskIds, <String>[
          'revision_fix_002_plot',
        ]);
        expect(ValueReaders.intValue(result['steps_run']), 1);
        expect(ValueReaders.stringValue(result['stop_reason']), 'max_steps');
        final revisionTask = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'revision_fix_002_plot'},
        );
        expect(
          ValueReaders.stringValue(revisionTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        final deferredSummary = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'followup_summary_002'},
        );
        expect(
          ValueReaders.stringValue(deferredSummary['status']),
          TaskRuntimeConstants.statusQueued,
        );
      },
    );

    test(
      'runWorkflowTaskOnce exposes chapter delivery schema records activation report and writes delivery outcome back to execution',
      () async {
        final knowledgeCardRepository = SqliteKnowledgeCardRepository();
        final designElementRepository = SqliteDesignElementRepository();
        final researchNoteRepository = SqliteResearchNoteRepository();
        final referenceWorkRepository = SqliteReferenceWorkRepository();
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
          contains('chapters/第01章.md'),
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
          'chapters/第01章.md',
        );
        expect(
          ValueReaders.stringList(execution['output_paths']),
          contains('chapters/第01章.md'),
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
      'runWorkflowTaskOnce allows non-chapter revision outputs without submit_chapter_delivery',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'revision_spec_001',
          'title': '修复审稿问题：project_spec',
          'task_type': 'revision',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': 'specs/project_spec.md',
          'goal': '修复规格文件中的审稿问题。',
          'brief': '只修规格文件。',
          'depends_on': const <Object?>[],
          'source_paths': <Object?>['reviews/plot/剧情检查：project_spec.md'],
          'output_paths': <Object?>['specs/project_spec.md'],
          'metadata': <String, Object?>{
            'origin': 'review_repair_handoff',
            'review_type': 'plot',
          },
          'relative_path': 'tasks/revision_spec_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_backup_spec',
                  'name': 'create_backup',
                  'arguments': <String, Object?>{
                    'target_path': 'specs/project_spec.md',
                  },
                },
                <String, Object?>{
                  'id': 'call_write_spec_revision',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'specs/project_spec.md',
                    'content': '# 项目规格\n\n已补充主角职业背景与风格边界。\n',
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
              'content': '规格修订已完成。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '规格修订已完成。',
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
          const <String, Object?>{'id': 'revision_spec_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringList(result['output_paths']),
          contains('specs/project_spec.md'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'revision_spec_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['overall_status']),
          isNot(WritingExecutionOutcomeStatuses.recoverableFailure),
        );
      },
    );

    test(
      'runWorkflowTaskOnce treats summary-like task file as summary instead of formal chapter',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'save_summary',
          'title': '保存章节摘要',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '将本章摘要写入 summaries/',
          'brief': '只收口当前章节摘要。',
          'depends_on': const <Object?>['task_001'],
          'source_paths': const <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': const <Object?>['summaries/保存章节摘要.summary.md'],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_test',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
            'stage': 'sample',
          },
          'relative_path': 'tasks/save_summary.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'summary_skill_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'summarize_chapter',
                  },
                },
                <String, Object?>{
                  'id': 'summary_write_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'summaries/保存章节摘要.summary.md',
                    'content': '# 保存章节摘要\n\n本章状态已收口。',
                  },
                },
                <String, Object?>{
                  'id': 'summary_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'summaries/保存章节摘要.summary.md',
                    'chapter_content': '# 保存章节摘要\n\n本章状态已收口。',
                    'submission': <String, Object?>{
                      'submission_id': 'summary-delivery-1',
                      'title': '保存章节摘要',
                      'summary': '提交章节摘要收口。',
                    },
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
          const <String, Object?>{'id': 'save_summary'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.boolValue(result['retry_scheduled']), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          isNot(contains('长任务正式章节任务未形成正式交付')),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['next_action'],
          ),
          isNot('pause_for_failure'),
        );

        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'save_summary'},
        );
        expect(ValueReaders.stringValue(task['task_type']), 'summary');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(task['metadata'])['stage'],
          ),
          'summary',
        );

        final execution = await taskRepository.loadRecord(
          project,
          ValueReaders.stringValue(task['atomic_execution_path']),
        );
        expect(ValueReaders.stringValue(execution['task_type']), 'summary');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(execution['context_pack'])['intent'],
          ),
          'summary',
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
        final execution = await taskRepository.loadRecord(
          project,
          ValueReaders.stringValue(task['atomic_execution_path']),
        );
        expect(ValueReaders.mapValue(execution['response']).isNotEmpty, isTrue);
        expect(
          ValueReaders.objectList(execution['executed_tools']),
          isNotEmpty,
        );
        expect(
          ValueReaders.mapList(
            execution['pending_user_options'],
          ).single['label'],
          '保留旧入口',
        );
      },
    );

    test(
      'applyWorkflowTaskUserChoice requeues waiting task and injects selected prompt into next run',
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
                    'question': '第一章先走哪个冲突入口？',
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
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章.md',
                    'chapter_content': '正文内容',
                    'summary': '章节摘要',
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
          taskQueueOptionService: _ShortTimeoutTaskQueueOptionService(),
        );

        final firstResult = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.boolValue(firstResult['waiting_for_user_choice']),
          isTrue,
        );

        final choiceResult = await workflowService.applyWorkflowTaskUserChoice(
          project,
          const <String, Object?>{'id': 'task_001'},
          prompt: '保留旧入口',
          label: '保留旧入口',
          sourceQuestion: '第一章先走哪个冲突入口？',
        );
        expect(ValueReaders.boolValue(choiceResult['ok']), isTrue);
        final queuedTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(queuedTask['status']),
          TaskRuntimeConstants.statusQueued,
        );

        await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        final secondPrompt = gateway.requests.last.messages
            .map((message) => ValueReaders.stringValue(message['content']))
            .join('\n');
        expect(secondPrompt, contains('用户所选方向：保留旧入口'));
        expect(secondPrompt, contains('不要重复提出同一选择'));
      },
    );

    test(
      'applyWorkflowTaskUserChoice auto confirms explicit checkpoint tasks',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'checkpoint_user_choice_001',
          'title': '检查点确认',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusPaused,
          'goal': '等待用户确认后继续当前长任务。',
          'brief': '当前检查点需要用户明确选择继续。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'output_paths': const <Object?>[],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_test',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'stage': 'checkpoint',
            'generated_by': 'LongTaskPlanner',
            'manual_checkpoint': true,
          },
          'atomic_execution_path':
              'tracking/chapter_atomic/checkpoint_user_choice_001.execution.json',
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusPaused,
              'note': 'checkpoint paused for user choice',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/checkpoint_user_choice_001.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/chapter_atomic/checkpoint_user_choice_001.execution.json',
          const <String, Object?>{
            'task_id': 'checkpoint_user_choice_001',
            'pending_user_options': <Object?>[
              <String, Object?>{'label': '确认继续', 'prompt': '确认继续'},
            ],
          },
        );

        final choiceResult = await workflowRuntimeService
            .applyWorkflowTaskUserChoice(
              project,
              const <String, Object?>{'id': 'checkpoint_user_choice_001'},
              prompt: '确认继续',
              label: '确认继续',
              sourceQuestion: '是否通过当前检查点并继续？',
            );

        expect(ValueReaders.boolValue(choiceResult['ok']), isTrue);
        expect(
          ValueReaders.boolValue(choiceResult['auto_confirmed_checkpoint']),
          isTrue,
        );

        final updatedTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'checkpoint_user_choice_001'},
        );
        expect(
          ValueReaders.stringValue(updatedTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.boolValue(
            updatedTask['auto_confirmed_from_user_option'],
          ),
          isTrue,
        );

        final execution = await taskRepository.loadRecord(
          project,
          'tracking/chapter_atomic/checkpoint_user_choice_001.execution.json',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(execution['selected_user_option'])['label'],
          ),
          '确认继续',
        );
      },
    );

    test(
      'applyWorkflowTaskUserChoice consumes persisted permission approval and passes allow-once host tool context into next run',
      () async {
        HostToolPermissionContext? capturedHostToolContext;
        final approvalService = ProjectToolPermissionApprovalRecordService(
          taskRepository: taskRepository,
        );
        final seededApproval = await approvalService
            .persistPendingApprovalsForExecutedTools(
              project,
              scopeType: ProjectToolPermissionApprovalScopes.workflowTask,
              taskPath: 'tasks/task_001.json',
              executedTools: <Object?>[
                <String, Object?>{
                  'name': 'request_gateway_tool',
                  'call_id': 'call_permission_1',
                  'result': <String, Object?>{
                    'waiting_for_user_choice': true,
                    'question': '是否允许联网搜索？',
                    'options': <Object?>[
                      <String, Object?>{
                        'id': 'allow_once',
                        'label': '允许这次',
                        'prompt': '允许这次网络研究',
                      },
                      <String, Object?>{
                        'id': 'deny_and_continue',
                        'label': '保持禁止',
                        'prompt': '保持禁止并换路继续',
                      },
                    ],
                    'permission_decision': <String, Object?>{
                      'disposition':
                          HostToolPermissionDispositions.needsUserConfirmation,
                      'required_capability':
                          HostToolPermissionPolicyService.capabilityNetwork,
                    },
                    'permission_capability':
                        HostToolPermissionPolicyService.capabilityNetwork,
                    'permission_context': const HostToolPermissionContext(
                      allowRead: true,
                      allowWrite: true,
                      allowNetwork: false,
                      permissionMode: HostToolPermissionModes.safe,
                      confirmationMode:
                          HostToolConfirmationModes.userConfirmationRequired,
                      source: 'test.permission',
                    ).toJson(),
                  },
                },
              ],
            );
        final seededTool = ValueReaders.mapValue(
          ValueReaders.objectList(seededApproval['executed_tools']).single,
        );
        final seededResult = ValueReaders.mapValue(seededTool['result']);
        final pendingOption = ValueReaders.mapList(
          seededResult['options'],
        ).first;
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_2',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章.md',
                    'chapter_content': '正文内容',
                    'summary': '章节摘要',
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
          taskQueueOptionService: _ShortTimeoutTaskQueueOptionService(),
          onHostToolPermissionContext: (context) {
            capturedHostToolContext = context;
          },
        );
        expect(
          ValueReaders.stringValue(pendingOption['approval_record_id']).trim(),
          isNotEmpty,
        );

        final choiceResult = await workflowService.applyWorkflowTaskUserChoice(
          project,
          const <String, Object?>{'id': 'task_001'},
          prompt: ValueReaders.stringValue(pendingOption['prompt']),
          label: ValueReaders.stringValue(pendingOption['label']),
          sourceQuestion: ValueReaders.stringValue(
            pendingOption['source_question'],
          ),
          permissionApprovalId: ValueReaders.stringValue(
            pendingOption['approval_record_id'],
          ),
          permissionApprovalOptionId: ValueReaders.stringValue(
            pendingOption['approval_option_id'],
          ),
        );
        expect(ValueReaders.boolValue(choiceResult['ok']), isTrue);

        await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(capturedHostToolContext, isNotNull);
        expect(capturedHostToolContext!.allowNetwork, isTrue);
        expect(
          capturedHostToolContext!.source,
          'tool_permission_approval:network',
        );
      },
    );

    test(
      'runWorkflowTaskOnce does not expose formal chapter delivery tool for planning task',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_tools_001',
          'title': '规划长篇开局',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '完善规格、总纲与章节任务清单。',
          'brief': '只做规划，不写正文。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'tool_hint': '不要写正文。优先保存规格与大纲。',
          'metadata': const <String, Object?>{
            'plan_id': 'plan_seed',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_tools_001.json',
        });
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
                    'question': '要先补哪一部分？',
                    'options': <Object?>[
                      <String, Object?>{
                        'label': '先补主角背景',
                        'description': '补足人物出身与知识边界。',
                        'prompt': '先补主角背景',
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
          const <String, Object?>{'id': 'planning_tools_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.lastToolNames,
          isNot(contains(NarrativeDomainToolNames.submitChapterDelivery)),
        );
      },
    );

    test(
      'runWorkflowTaskOnce fails planning task when model writes chapter body artifacts',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_001',
          'title': '规划长篇开局',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '完善规格、总纲与章节任务清单。',
          'brief': '只做规划，不写正文。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'tool_hint': '不要写正文。优先保存规格与大纲。',
          'metadata': const <String, Object?>{
            'plan_id': 'plan_seed',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_001.json',
        });
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
                    'relative_path': 'chapters/第01章_落水.md',
                    'content': '# 第01章\n\n越界正文',
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
          const <String, Object?>{'id': 'planning_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(ValueReaders.stringValue(result['error']), contains('规划任务越界'));
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
        expect(
          ValueReaders.stringValue(task['checkpoint_followup_action']),
          isEmpty,
        );
        final tasks = await workflowRuntimeService.listWorkflowTasks(project);
        expect(
          tasks.where(
            (item) =>
                ValueReaders.stringValue(item['task_type']).trim() == 'review',
          ),
          isEmpty,
        );
      },
    );

    test(
      'runWorkflowTaskOnce fails planning task when model writes task json artifacts',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_task_json_001',
          'title': '规划长篇开局',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '完善规格、总纲与章节任务清单。',
          'brief': '只做规划，不写正文，也不写任务文件。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outline/总纲.md',
            'chapter_outlines/章节任务清单.md',
          ],
          'tool_hint': '不要写正文，也不要写 tasks/*.json。',
          'metadata': const <String, Object?>{
            'plan_id': 'plan_seed',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
          },
          'created_at': '2026-05-25T00:00:00Z',
          'updated_at': '2026-05-25T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-05-25T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_task_json_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_write_task_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'tasks/plan_seed_chapter_001_task.json',
                    'content':
                        '{"id":"task_generated_001","task_type":"chapter"}',
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
          const <String, Object?>{'id': 'planning_task_json_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(ValueReaders.stringValue(result['error']), contains('规划任务越界'));
        expect(
          ValueReaders.stringValue(result['error']),
          contains('tasks/plan_seed_chapter_001_task.json'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_task_json_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
      },
    );

    test(
      'runWorkflowTaskOnce fails planning-stage workflow subtask when model writes chapter body artifacts',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_agent_task_001',
          'title': '更新主角状态',
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '完善设定资料，不写正文。',
          'brief': '当前仍处于 planning 阶段，只允许补充规划材料。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
          ],
          'output_paths': const <Object?>['assets/characters/主角.md'],
          'tool_hint': '不要写 chapters/ 正文。',
          'metadata': const <String, Object?>{
            'plan_id': 'plan_seed',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-11T00:00:00Z',
          'updated_at': '2026-06-11T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-11T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/更新主角状态.task.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_write_character',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'assets/characters/主角.md',
                    'content': '# 主角状态\n\n补充设定。',
                  },
                },
                <String, Object?>{
                  'id': 'call_write_chapter_forbidden',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'chapters/更新主角状态.md',
                    'content': '# 假章节\n\n这里不该出现在 planning 阶段。',
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
              'content': '已完成写入。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成写入。',
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
          const <String, Object?>{'id': 'planning_agent_task_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(ValueReaders.stringValue(result['error']), contains('规划任务越界'));
        expect(
          ValueReaders.stringValue(result['error']),
          contains('chapters/更新主角状态.md'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_agent_task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
      },
    );

    test(
      'runWorkflowTaskOnce auto-retries continuous autonomous planning when waiting user arrives before canonical planning artifacts are complete',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_autonomous_retry_001',
          'title': '自治规划长篇开局',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '完善规格、总纲与章节任务清单。',
          'brief': '先落地规划，不要停在方向分叉。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'tool_hint':
              '优先保存 specs/project_spec.md、outlines/story/总纲.md、outlines/chapters/章节任务清单.md，不要因为 profile 提案停下。',
          'metadata': const <String, Object?>{
            'plan_id': 'plan_seed',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_autonomous_retry_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_write_spec',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'relative_path': 'specs/project_spec.md',
                    'content': '# 项目规格\n\n先写出规格。',
                  },
                },
                <String, Object?>{
                  'id': 'call_profile_update',
                  'name': 'propose_narrative_profile_update',
                  'arguments': <String, Object?>{
                    'proposal_id': 'proposal_profile_seed',
                    'target_profile_id': 'project.story_rules',
                    'profile_patch': <String, Object?>{
                      'patch_label': '补充长篇叙事解释器',
                      'narrative_rule': '先建立长期承诺与视角约束。',
                    },
                    'reason': '需要补充长期规则',
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
          const <String, Object?>{'id': 'planning_autonomous_retry_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.boolValue(result['retry_scheduled']), isTrue);
        expect(
          ValueReaders.boolValue(result['waiting_for_user_choice']),
          isFalse,
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_autonomous_retry_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusRetrying,
        );
        expect(ValueReaders.intValue(task['recovery_retry_count']), 1);
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['next_action']),
          'resume_dispatch',
        );
      },
    );

    test(
      'runWorkflowTaskOnce keeps continuous autonomous planning at waiting_user when canonical planning artifacts already exist and profile proposal needs confirmation',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n长期规则已存在。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n\n长期主线已存在。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务\n\n第一卷章纲已存在。',
        );
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_profile_wait_user_001',
          'title': '提交项目级 narrative profile 提案',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '收拢长期规则并提交 profile 提案。',
          'brief': 'canonical planning 文件已存在。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_profile_wait_user',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_profile_wait_user_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_profile_update',
                  'name': 'propose_narrative_profile_update',
                  'arguments': <String, Object?>{
                    'proposal_id': 'proposal_profile_wait_user',
                    'target_profile_id': 'project.story_rules',
                    'profile_patch': <String, Object?>{
                      'patch_label': '补充长期规则',
                      'narrative_rule': '长期规则提案需要用户确认。',
                    },
                    'reason': '需要更新项目级 narrative profile',
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
          const <String, Object?>{'id': 'planning_profile_wait_user_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.boolValue(result['waiting_for_user_choice']),
          isTrue,
        );
        expect(ValueReaders.boolValue(result['retry_scheduled']), isFalse);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_profile_wait_user_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusWaitingUser,
        );
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['next_action']),
          'resume_when_user_confirms',
        );
      },
    );

    test(
      'runWorkflowTaskQueue stops continuous autonomous planning queue at waiting user when canonical planning artifacts already exist',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'planning_profile_wait_user_queue_case',
          name: '规划 profile 提案等待确认队列测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}planning_profile_wait_user_queue_case',
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n长期规则已存在。',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n\n长期主线已存在。',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务\n\n第一卷章纲已存在。',
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_profile_wait_user_queue_001',
          'title': '提交项目级 narrative profile 提案',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '收拢长期规则并提交 profile 提案。',
          'brief': 'canonical planning 文件已存在。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'output_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_profile_wait_user_queue',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_profile_wait_user_queue_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_profile_update_queue',
                  'name': 'propose_narrative_profile_update',
                  'arguments': <String, Object?>{
                    'proposal_id': 'proposal_profile_wait_user_queue',
                    'target_profile_id': 'project.story_rules',
                    'profile_patch': <String, Object?>{
                      'patch_label': '补充长期规则',
                      'narrative_rule': '长期规则提案需要用户确认。',
                    },
                    'reason': '需要更新项目级 narrative profile',
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

        final result = await workflowService.runWorkflowTaskQueue(
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.intValue(result['steps_run']), 1);
        expect(
          ValueReaders.stringValue(result['stop_reason']),
          'waiting_user_choice',
        );
        final queueRecord = ValueReaders.mapValue(result['record']);
        expect(ValueReaders.stringValue(queueRecord['status']), 'stopped');
        final task = await taskRepository.loadTask(
          queueProject,
          const <String, Object?>{'id': 'planning_profile_wait_user_queue_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusWaitingUser,
        );
        final longTaskRecord = ValueReaders.mapValue(
          result['long_task_record'],
        );
        expect(ValueReaders.stringValue(longTaskRecord['status']), isNotEmpty);
      },
    );

    test(
      'runWorkflowTaskOnce reuses existing canonical planning artifact as stable output when current step only reads it',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n长期规则已存在。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n\n长期主线已存在。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务\n\n第一卷章纲已存在。',
        );
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_existing_output_001',
          'title': '写入章节任务清单',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '基于总纲确认 outlines/chapters/章节任务清单.md 可继续作为稳定规划产物。',
          'brief': '复用现有 canonical planning 文件。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
          ],
          'output_paths': const <Object?>['outlines/chapters/章节任务清单.md'],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_existing_output',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_existing_output_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_load_skill_existing_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{'skill_id': 'story_planning'},
                },
                <String, Object?>{
                  'id': 'call_load_skill_existing_2',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'chapter_planning',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已核对现有规划产物，可以继续后续主链。',
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
          const <String, Object?>{'id': 'planning_existing_output_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringList(result['output_paths']),
          contains('outlines/chapters/章节任务清单.md'),
        );
        final checkpointReview = ValueReaders.mapValue(
          ValueReaders.mapValue(result['checkpoint_review'])['review'],
        );
        expect(
          ValueReaders.stringValue(checkpointReview['continuation_reason']),
          isNot('missing_output_paths'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_existing_output_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          isNot(TaskRuntimeConstants.statusPaused),
        );
        expect(
          ValueReaders.stringList(task['output_paths']),
          contains('outlines/chapters/章节任务清单.md'),
        );
      },
    );

    test(
      'runWorkflowTaskQueue does not stop on no_tool_output when canonical planning artifact already exists',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'planning_existing_output_queue_case',
          name: '规划现有产物队列复用测试',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}planning_existing_output_queue_case',
          projectType: 'long_novel',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n长期规则已存在。',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n\n长期主线已存在。',
        );
        await workspacePort.writeTextFile(
          queueProject.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务\n\n第一卷章纲已存在。',
        );
        await taskRepository.saveTask(queueProject, <String, Object?>{
          'schema_version': 1,
          'id': 'planning_existing_output_queue_001',
          'title': '写入章节任务清单',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '基于总纲确认 outlines/chapters/章节任务清单.md 可继续作为稳定规划产物。',
          'brief': '复用现有 canonical planning 文件。',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
          ],
          'output_paths': const <Object?>['outlines/chapters/章节任务清单.md'],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_existing_output_queue',
            'stage': 'planning',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/planning_existing_output_queue_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_load_skill_queue_existing_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{'skill_id': 'story_planning'},
                },
                <String, Object?>{
                  'id': 'call_load_skill_queue_existing_2',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'chapter_planning',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已核对现有规划产物，可以继续后续主链。',
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
          queueProject,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['stop_reason']),
          isNot('no_tool_output'),
        );
        final queueRecord = ValueReaders.mapValue(result['record']);
        final steps = ValueReaders.mapList(queueRecord['steps']);
        expect(steps, hasLength(1));
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(steps.first)['output_paths'],
          ),
          contains('outlines/chapters/章节任务清单.md'),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(steps.first)['task_status_after'],
          ),
          isNot(TaskRuntimeConstants.statusPaused),
        );
      },
    );

    test(
      'runWorkflowTaskQueue records retryable transport failures as paused long-task state instead of throwing',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n保持长任务稳定推进。',
        );
        final baseTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        await taskRepository.saveTask(project, <String, Object?>{
          ...baseTask,
          'metadata': <String, Object?>{
            ...ValueReaders.mapValue(baseTask['metadata']),
            'runtime_baseline_id': 'continuous_autonomous',
            'stage': 'draft',
          },
        });
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: _ThrowingWorkflowGateway(
            error: HandshakeException('Connection terminated during handshake'),
          ),
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );

        final result = await workflowService.runWorkflowTaskQueue(
          project,
          _testSettings(),
          options: const <String, Object?>{'max_steps': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(ValueReaders.intValue(result['steps_run']), 1);
        expect(ValueReaders.stringValue(result['stop_reason']), 'step_failed');
        final queueRecord = ValueReaders.mapValue(result['record']);
        expect(ValueReaders.stringValue(queueRecord['status']), 'failed');
        final steps = ValueReaders.mapList(queueRecord['steps']);
        expect(steps, hasLength(1));
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(steps.first)['task_status_after'],
          ),
          TaskRuntimeConstants.statusRetrying,
        );
        final longTaskRecord = ValueReaders.mapValue(
          result['long_task_record'],
        );
        expect(ValueReaders.stringValue(longTaskRecord['status']), 'paused');
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusRetrying,
        );
      },
    );

    test(
      'runWorkflowTaskOnce auto-retries continuous autonomous formal chapter waiting user before delivery and injects retry guidance into next run',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n主角回京翻案。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/story/总纲.md',
          '# 总纲\n\n第一卷回京设局。',
        );
        await workspacePort.writeTextFile(
          project.rootPath,
          'outlines/chapters/章节任务清单.md',
          '# 章节任务\n\n第01章入局。',
        );
        await taskRepository.saveTask(project, <String, Object?>{
          'schema_version': 1,
          'id': 'chapter_autonomous_retry_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'goal': '基于现有规划完成第01章正式正文。',
          'brief': '自治样章测试',
          'depends_on': const <Object?>[],
          'source_paths': const <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
            'styles/seed_autopilot_style.md',
          ],
          'output_paths': const <Object?>['chapters/第01章.md'],
          'metadata': const <String, Object?>{
            'plan_id': 'plan_autonomous_retry',
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'sort_order': 1,
            'stage': 'sample',
            'generated_by': 'LongTaskPlanner',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'tool_hint': '先读取规格与总纲，再完成正式交付。',
          'created_at': '2026-06-10T00:00:00Z',
          'updated_at': '2026-06-10T00:00:00Z',
          'history': const <Object?>[
            <String, Object?>{
              'status': TaskRuntimeConstants.statusQueued,
              'note': 'created',
              'created_at': '2026-06-10T00:00:00Z',
            },
          ],
          'relative_path': 'tasks/chapter_autonomous_retry_001.json',
        });
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
                    'question': '规划文件似乎不足，是否先补规划？',
                    'options': <Object?>[
                      <String, Object?>{
                        'label': '先补规划',
                        'description': '补齐规划后再写正文。',
                        'prompt': '先补规划',
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
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/第01章.md',
                    'chapter_content': '第01章正文',
                    'summary': '主角回京入局。',
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

        final firstResult = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'chapter_autonomous_retry_001'},
        );

        expect(ValueReaders.boolValue(firstResult['ok']), isTrue);
        expect(ValueReaders.boolValue(firstResult['retry_scheduled']), isTrue);
        expect(
          ValueReaders.boolValue(firstResult['waiting_for_user_choice']),
          isFalse,
        );
        final retryingTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_autonomous_retry_001'},
        );
        expect(
          ValueReaders.stringValue(retryingTask['status']),
          TaskRuntimeConstants.statusRetrying,
        );
        expect(ValueReaders.intValue(retryingTask['recovery_retry_count']), 1);
        expect(
          ValueReaders.stringValue(
            retryingTask['resume_dispatch_prompt_appendix'],
          ),
          contains('上轮在正式章节交付前错误停回用户选择点'),
        );

        final secondResult = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'chapter_autonomous_retry_001'},
        );

        final secondPrompt = gateway.requests.last.messages
            .map((message) => ValueReaders.stringValue(message['content']))
            .join('\n');
        expect(
          secondPrompt,
          contains('不要再次因为“规划不完整”或一般方向分叉调用 present_user_options'),
        );
        expect(
          secondPrompt,
          contains(
            'specs/project_spec.md、outlines/story/总纲.md、outlines/chapters/章节任务清单.md',
          ),
        );
        expect(ValueReaders.boolValue(secondResult['ok']), isTrue);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              secondResult['chapter_delivery'],
            )['chapter_path'],
          ),
          'chapters/第01章.md',
        );
      },
    );

    test(
      'runWorkflowTaskOnce requeues task when cancellation token is already requested',
      () async {
        final gateway = _CancellationAwareBlockingWorkflowGateway();
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: gateway,
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
        );
        final cancellationToken = DraftGenerationCancellationToken();
        cancellationToken.cancel();

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
          cancellationToken: cancellationToken,
        );

        expect(ValueReaders.boolValue(result['timeout']), isTrue);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusQueued,
        );
      },
    );

    test(
      'runWorkflowTaskOnce schedules one direct retry for retryable formal workflow chapter non-delivery',
      () async {
        final baseTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        await taskRepository.saveTask(project, <String, Object?>{
          ...baseTask,
          'metadata': <String, Object?>{
            ...ValueReaders.mapValue(baseTask['metadata']),
            'runtime_baseline_id': 'continuous_autonomous',
            'stage': 'draft',
          },
        });
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
        expect(ValueReaders.boolValue(result['retry_scheduled']), isTrue);
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
          WritingExecutionOutcomeStatuses.recoverableFailure,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['next_action'],
          ),
          'pause_for_failure',
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusRetrying,
        );
        expect(ValueReaders.intValue(task['recovery_retry_count']), 1);
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              task['last_writing_execution_result'],
            )['retryable'],
          ),
          isTrue,
        );

        final nextTask = await workflowService.nextWorkflowTask(project);
        expect(ValueReaders.stringValue(nextTask['id']), 'task_001');
      },
    );

    test(
      'runWorkflowTaskOnce converts retryable transport failure into formal chapter retry state',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n保持长任务稳定推进。',
        );
        final baseTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        await taskRepository.saveTask(project, <String, Object?>{
          ...baseTask,
          'metadata': <String, Object?>{
            ...ValueReaders.mapValue(baseTask['metadata']),
            'runtime_baseline_id': 'continuous_autonomous',
          },
        });
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: _ThrowingWorkflowGateway(
            error: HandshakeException('Connection terminated during handshake'),
          ),
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
        expect(ValueReaders.boolValue(result['retry_scheduled']), isTrue);
        expect(ValueReaders.stringValue(result['error']), contains('模型传输中断'));
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusRetrying,
        );
        expect(ValueReaders.intValue(task['recovery_retry_count']), 1);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              task['last_writing_execution_result'],
            )['next_action'],
          ),
          'resume_dispatch',
        );
        final execution = await workflowService.loadWorkflowTaskExecution(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['writing_execution_result'],
            )['overall_status'],
          ),
          WritingExecutionOutcomeStatuses.technicalFailure,
        );
      },
    );

    test(
      'nextWorkflowTask recovers resume-dispatch running task back to retrying',
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
        );
        await taskRepository.saveTask(project, <String, Object?>{
          ...(await taskRepository.loadTask(project, const <String, Object?>{
            'id': 'task_001',
          })),
          'status': TaskRuntimeConstants.statusRunning,
          'last_writing_execution_result': <String, Object?>{
            'overall_status':
                WritingExecutionOutcomeStatuses.recoverableFailure,
            'next_action': 'resume_dispatch',
            'recovery': <String, Object?>{
              'recommended_action': 'resume_dispatch',
              'resume_allowed': true,
            },
          },
        });

        final nextTask = await workflowService.nextWorkflowTask(project);
        expect(ValueReaders.stringValue(nextTask['id']), 'task_001');
        expect(
          ValueReaders.stringValue(nextTask['status']),
          TaskRuntimeConstants.statusRetrying,
        );
        final updatedTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(updatedTask['status']),
          TaskRuntimeConstants.statusRetrying,
        );
      },
    );

    test(
      'nextWorkflowTask selects inherited workflow planning tasks emitted by set_agent_tasks',
      () async {
        final queueProject = ProjectDescriptor(
          id: 'set_agent_tasks_workflow_scope',
          name: 'set_agent_tasks workflow scope',
          rootPath:
              '${tempDirectory.path}${Platform.pathSeparator}set_agent_tasks_workflow_scope',
          projectType: 'long_novel',
        );
        await taskRepository.saveTasks(queueProject, <JsonMap>[
          <String, Object?>{
            'schema_version': 1,
            'id': 'plan_seed_001_planning',
            'title': '规划：长篇开局',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'depends_on': const <Object?>[],
            'output_paths': const <Object?>['specs/project_spec.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_seed_001',
              'generated_by': 'LongTaskPlanner',
              'runtime_baseline_id': 'continuous_autonomous',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'stage': 'planning',
            },
            'created_at': '2026-06-11T00:00:00Z',
            'updated_at': '2026-06-11T00:00:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusWaitingUser,
                'note': 'planning review waiting',
                'created_at': '2026-06-11T00:00:00Z',
              },
            ],
            'relative_path': 'tasks/plan_seed_001_planning.json',
          },
          <String, Object?>{
            'schema_version': 1,
            'id': 'write_spec',
            'title': '写入项目规格',
            'task_type': 'planning',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusQueued,
            'depends_on': const <Object?>[],
            'output_paths': const <Object?>['specs/project_spec.md'],
            'metadata': const <String, Object?>{
              'plan_id': 'plan_seed_001',
              'generated_by': 'LongTaskPlanner',
              'runtime_baseline_id': 'continuous_autonomous',
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'stage': 'planning',
            },
            'created_at': '2026-06-11T00:01:00Z',
            'updated_at': '2026-06-11T00:01:00Z',
            'history': const <Object?>[
              <String, Object?>{
                'status': TaskRuntimeConstants.statusQueued,
                'note': 'created',
                'created_at': '2026-06-11T00:01:00Z',
              },
            ],
            'relative_path': 'tasks/写入项目规格.task.json',
          },
        ]);

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
        );

        final nextTask = await workflowService.nextWorkflowTask(queueProject);
        expect(ValueReaders.stringValue(nextTask['id']), 'write_spec');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(nextTask['metadata'])['generated_by'],
          ),
          'LongTaskPlanner',
        );
      },
    );

    test(
      'runWorkflowTaskOnce keeps retryable formal workflow chapter failed after direct retry budget is exhausted',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          ...(await taskRepository.loadTask(project, const <String, Object?>{
            'id': 'task_001',
          })),
          'recovery_retry_count': 1,
          'recovery_retry_budget': 1,
        });
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
          options: const <String, Object?>{'recovery_retry_budget': 1},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(ValueReaders.boolValue(result['retry_scheduled']), isFalse);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              result['writing_execution_result'],
            )['next_action'],
          ),
          'pause_for_failure',
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
        expect(ValueReaders.intValue(task['recovery_retry_count']), 1);
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
          ValueReaders.stringValue(writingExecutionResult['next_action']),
          'pause_for_repair',
        );
      },
    );

    test(
      'runWorkflowTaskOnce routes information awaiting confirmation to waiting_user checkpoint state',
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
              'relative_path':
                  'tracking/checkpoint_reviews/info_waiting_user.json',
              'changed_paths': <Object?>[
                'tracking/checkpoint_reviews/info_waiting_user.json',
              ],
              'review': <String, Object?>{
                'summary': '待研究 1 项，建议先确认是否补研究。',
                'continuation_disposition': 'blocked_wait_user',
                'disposition': const <String, Object?>{
                  'disposition': 'blocked_wait_user',
                  'reason': 'information_waiting_user',
                },
                'information_signal': <String, Object?>{
                  'present': true,
                  'category': 'checkpoint_user',
                  'reason': 'information_awaiting_confirmation',
                  'summary': '待研究 1 项，建议先确认是否补研究。',
                  'waiting_user': true,
                  'awaiting_confirmation_count': 1,
                  'changed_paths': <Object?>[
                    '.novel_agent/information/research_requests/request_waiting.json',
                  ],
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

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'task_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusWaitingUser,
        );
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['overall_status']),
          WritingExecutionOutcomeStatuses.userActionRequired,
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['next_action']),
          'resume_when_user_confirms',
        );
      },
    );

    test(
      'runWorkflowTaskOnce keeps gateway failed information signal as repair instead of technical failure',
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
              'relative_path':
                  'tracking/checkpoint_reviews/info_gateway_failed.json',
              'changed_paths': <Object?>[
                'tracking/checkpoint_reviews/info_gateway_failed.json',
              ],
              'review': <String, Object?>{
                'summary': '资料网关执行失败，建议先修复网关或重试研究链路。',
                'continuation_disposition': 'blocked_wait_user',
                'disposition': const <String, Object?>{
                  'disposition': 'blocked_wait_user',
                  'reason': 'information_gateway_failed',
                },
                'information_signal': <String, Object?>{
                  'present': true,
                  'category': 'repair',
                  'reason': 'information_gateway_failed',
                  'summary': '资料网关执行失败，建议先修复网关或重试研究链路。',
                  'requires_repair': true,
                  'gateway_failure_count': 1,
                  'changed_paths': <Object?>[
                    '.novel_agent/information/research_requests/request_failed.json',
                  ],
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

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        final information = ValueReaders.mapValue(
          writingExecutionResult['information'],
        );
        expect(ValueReaders.boolValue(information['requires_repair']), isTrue);
        expect(
          ValueReaders.stringValue(information['risk_category']),
          'repair',
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['next_action']),
          'pause_for_repair',
        );
        expect(
          ValueReaders.stringValue(writingExecutionResult['overall_status']),
          isNot(WritingExecutionOutcomeStatuses.technicalFailure),
        );
      },
    );

    test(
      'runWorkflowTaskOnce passes host information permission context into long task draft execution',
      () async {
        HostInformationPermissionContext? capturedContext;
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
          onHostInformationPermissionContext: (context) {
            capturedContext = context;
          },
        );

        await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings().copyWith(
            permissionSettings: const <String, Object?>{
              'mode': 'open',
              'allow_network': true,
            },
          ),
          const <String, Object?>{'id': 'task_001'},
        );

        expect(capturedContext, isNotNull);
        expect(
          capturedContext!.permissionMode,
          HostInformationPermissionModes.open,
        );
        expect(capturedContext!.allowNetwork, isTrue);
        expect(
          capturedContext!.source,
          'workflow_runtime.app_settings.permission_settings',
        );
      },
    );

    test(
      'runWorkflowTaskOnce passes expression policy option into constraint runtime',
      () async {
        final fakeConstraintRuntime =
            _FakeProjectDraftExecutionConstraintRuntimeService(
              response: const <String, Object?>{
                'expression_constraint_policy_mode': 'force',
                'expression_constraint_injection_strength': 'full',
                'expression_constraint_review_requirement':
                    'always_for_writing',
                'expression_constraint_violation_disposition': 'repair',
                'expression_constraint_applied': true,
                'expression_constraint_injection_mode': 'brief_and_sections',
                'expression_constraint_review_required': true,
                'runtime_report': <String, Object?>{},
              },
            );
        final workflowService = _buildRuntimeService(
          taskRepository: taskRepository,
          promptTemplateService: promptTemplateService,
          workspacePort: workspacePort,
          gateway: _RecordingWorkflowGateway(
            scriptedResults: <JsonMap>[
              <String, Object?>{
                'ok': true,
                'content': '',
                'tool_calls': <Object?>[
                  <String, Object?>{
                    'id': 'call_delivery_policy',
                    'name': 'submit_chapter_delivery',
                    'arguments': <String, Object?>{
                      'chapter_path': 'chapters/第01章_seed_to_full.md',
                      'chapter_content': '# 第01章\n\n正式正文。',
                      'submission': <String, Object?>{
                        'submission_id': 'delivery-policy',
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
          ),
          toolExecutionPort: _WorkflowToolExecutionPort(
            workspacePort: workspacePort,
          ),
          draftExecutionConstraintRuntimeService: fakeConstraintRuntime,
        );

        await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'task_001'},
          options: const <String, Object?>{
            'expression_constraint_policy_mode': 'force',
          },
        );

        expect(fakeConstraintRuntime.calls, isNotEmpty);
        expect(
          fakeConstraintRuntime.calls.last.expressionConstraintPolicyMode,
          ExpressionConstraintExecutionPolicyModes.force,
        );
      },
    );

    test(
      'runWorkflowTaskOnce persists shared semantic review contracts while keeping review trigger on agent-group path',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_contract_001',
          'title': '语义审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>[
            'chapters/第01章_seed_to_full.md',
            'outline/总纲.md',
          ],
          'output_paths': <Object?>[
            'reviews/general/ch01_contract.md',
            'reviews/general/ch01_contract.json',
          ],
          'metadata': <String, Object?>{
            'review_type': 'general',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_contract_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_submit_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'workflow-semantic-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'reviewer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '建议补强开场冲突，但不需要阻断主流程。',
                    'findings': <Object?>[
                      <String, Object?>{
                        'finding_id': 'finding-1',
                        'severity': 'low',
                        'summary': '开场冲突偏弱。',
                        'suggested_action': '下一轮补强第一页冲突密度。',
                        'unable_to_locate_evidence': true,
                        'unlocatable_reason': '测试只验证共享合同接线。',
                      },
                    ],
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '建议补强开场冲突。',
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
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'optional_review_room',
                  displayName: '审稿组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'review_task_contract_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          everyElement('reviewer-child-model'),
        );
        final execution = ValueReaders.mapValue(result['execution']);
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['semantic_review_authority_policy'],
            )['trigger_authority'],
          ),
          ReviewTriggerAuthorities.agentGroupPolicy,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['semantic_review_contract'],
            )['recommended_disposition'],
          ),
          ReviewRecommendedDispositions.remind,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['semantic_review_summary'],
            )['recommended_disposition'],
          ),
          ReviewRecommendedDispositions.remind,
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              execution['semantic_review_repair_handoff'],
            )['action'],
          ),
          RepairHandoffActions.noteOnly,
        );
        final response = ValueReaders.mapValue(result['response']);
        final toolCalls = ValueReaders.objectList(
          response['tool_calls'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(
          toolCalls.any(
            (tool) =>
                ValueReaders.stringValue(tool['name']) == 'call_sub_agent',
          ),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskOnce dispatches review tasks to the selected reviewer child with isolated tool scope',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_delegate_001',
          'title': '语义审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>[
            'chapters/第01章_seed_to_full.md',
            'outline/总纲.md',
          ],
          'output_paths': <Object?>[
            'reviews/general/ch01_delegate.md',
            'reviews/general/ch01_delegate.json',
          ],
          'metadata': <String, Object?>{
            'review_type': 'general',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_delegate_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_submit_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'delegated-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'reviewer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '建议加强第一幕冲突，但当前版本可继续。',
                    'findings': <Object?>[
                      <String, Object?>{
                        'finding_id': 'delegated-finding-1',
                        'severity': 'low',
                        'summary': '第一幕冲突密度可以更高。',
                        'suggested_action': '下一轮补一处更早的压力来源。',
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
            <String, Object?>{
              'ok': true,
              'content': '已完成结构化审稿，建议后续加强第一幕冲突。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成结构化审稿，建议后续加强第一幕冲突。',
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
              'id': 'story_room',
              'name': '正文协作组',
              'agents': <String>['writer', 'reviewer'],
              'primary_agent_id': 'writer',
            },
          ],
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'story_room',
                  displayName: '正文协作组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'review_task_delegate_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          everyElement('reviewer-child-model'),
        );
        expect(
          gateway.requests.first.toolNames,
          contains('submit_semantic_review'),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('submit_narrative_state_claims')),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('call_sub_agent')),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('submit_chapter_delivery')),
        );
        expect(
          gateway.requests.first.messages
              .map((message) => ValueReaders.stringValue(message['content']))
              .join('\n'),
          contains('内部子智能体视角'),
        );
        expect(
          gateway.requests.first.messages
              .map((message) => ValueReaders.stringValue(message['content']))
              .join('\n'),
          contains('只接收主智能体整理后的摘录'),
        );
        final execution = ValueReaders.mapValue(result['execution']);
        final reviewerDispatch = ValueReaders.mapValue(
          execution['reviewer_dispatch'],
        );
        expect(
          ValueReaders.stringValue(reviewerDispatch['selection_mode']),
          ReviewerSelectionModes.delegatedReviewer,
        );
        expect(
          ValueReaders.stringValue(reviewerDispatch['agent_id']),
          'reviewer',
        );
        final response = ValueReaders.mapValue(result['response']);
        final toolCalls = ValueReaders.objectList(
          response['tool_calls'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(
          ValueReaders.stringValue(toolCalls.single['name']),
          'call_sub_agent',
        );
      },
    );

    test(
      'runWorkflowTaskOnce does not expose chapter delivery to direct review tasks',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_scope_001',
          'title': '连续性检查：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': <Object?>[
            'reviews/continuity/ch01_scope.md',
            'reviews/continuity/ch01_scope.json',
          ],
          'metadata': <String, Object?>{
            'plan_id': 'plan_scope',
            'review_type': 'continuity',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_scope_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_submit_scope_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'scope-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'reviewer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '连续性可继续。',
                    'findings': const <Object?>[],
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
              'content': '已完成结构化审稿。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成结构化审稿。',
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
          const <String, Object?>{'id': 'review_task_scope_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.first.toolNames,
          contains('submit_semantic_review'),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('submit_chapter_delivery')),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('present_user_options')),
        );
        final writingExecutionResult = ValueReaders.mapValue(
          result['writing_execution_result'],
        );
        expect(
          ValueReaders.boolValue(
            ValueReaders.mapValue(
              writingExecutionResult['metadata'],
            )['formal_review_completed'],
          ),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskOnce auto completes checkpoint followup review tasks when checkpoint review auto continues',
      () async {
        await workspacePort.writeTextFile(
          project.rootPath,
          'specs/project_spec.md',
          '# 项目规格\n\n已生成规格正文。\n',
        );
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_followup_auto_continue_001',
          'title': '连续性检查：project_spec',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'goal': '确认 project_spec 是否可以继续推进。',
          'brief': '检查点自动派生的 planning follow-up review。',
          'source_paths': <Object?>['specs/project_spec.md'],
          'output_paths': <Object?>[
            'reviews/continuity/project_spec_followup.md',
            'reviews/continuity/project_spec_followup.json',
          ],
          'metadata': <String, Object?>{
            'plan_id': 'plan_test',
            'origin': 'checkpoint_review_suggestion',
            'checkpoint_review_id': 'checkpoint_review_planning_001',
            'review_type': 'continuity',
            'stage': 'planning',
            'runtime_baseline_id': 'continuous_autonomous',
          },
          'relative_path': 'tasks/review_task_followup_auto_continue_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_submit_followup_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'followup-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'reviewer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '规格连续性可继续推进。',
                    'findings': const <Object?>[],
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
              'content': '已完成结构化审稿，当前节点可以自动继续。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成结构化审稿，当前节点可以自动继续。',
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
              'relative_path':
                  'tracking/checkpoint_reviews/review_followup_auto_continue.json',
              'changed_paths': <Object?>[
                'tracking/checkpoint_reviews/review_followup_auto_continue.json',
              ],
              'review': <String, Object?>{
                'id': 'checkpoint_review_followup_auto_continue',
                'task': <String, Object?>{
                  'id': 'review_task_followup_auto_continue_001',
                  'title': '连续性检查：project_spec',
                  'task_type': 'review',
                  'relative_path':
                      'tasks/review_task_followup_auto_continue_001.json',
                },
                'task_type': 'review',
                'stage': 'planning',
                'summary': '当前 follow-up review 已完成，不需要等待用户。',
                'result_ok': true,
                'severity': 'low',
                'continuation_disposition': 'auto_continue',
                'disposition': <String, Object?>{
                  'disposition': 'auto_continue',
                  'reason': 'followup_review_completed',
                },
                'waiting_user': false,
                'information_signal': const <String, Object?>{
                  'present': false,
                  'category': 'accept',
                },
                'collaboration_signal': const <String, Object?>{
                  'present': false,
                  'category': 'accept',
                },
                'expression_constraint_signal': const <String, Object?>{
                  'present': false,
                  'category': 'accept',
                },
              },
            },
          ),
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{
            'id': 'review_task_followup_auto_continue_001',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{
            'id': 'review_task_followup_auto_continue_001',
          },
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
      },
    );

    test(
      'runWorkflowTaskOnce fails review task that tries to close with chapter delivery',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_invalid_delivery_001',
          'title': '连续性检查：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': <Object?>[
            'reviews/continuity/ch01_invalid.md',
            'reviews/continuity/ch01_invalid.json',
          ],
          'metadata': <String, Object?>{
            'plan_id': 'plan_invalid_delivery',
            'review_type': 'continuity',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_invalid_delivery_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_delivery_invalid_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'reviews/continuity/ch01_invalid.md',
                    'chapter_content': '# 连续性检查\n\n这是一份错误的章节式交付。',
                    'submission': <String, Object?>{
                      'submission_id': 'invalid-review-delivery',
                      'title': '连续性检查：第01章',
                      'summary': '错误地把审稿当成章节交付',
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
              'content': '已提交审稿报告。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已提交审稿报告。',
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
          const <String, Object?>{'id': 'review_task_invalid_delivery_001'},
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(
          ValueReaders.stringValue(result['error']),
          contains('submit_semantic_review'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'review_task_invalid_delivery_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusFailed,
        );
      },
    );

    test(
      'runWorkflowTaskOnce falls back to critic or editor child when reviewer is absent',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_editor_001',
          'title': '语义审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': <Object?>[
            'reviews/general/ch01_editor.md',
            'reviews/general/ch01_editor.json',
          ],
          'metadata': <String, Object?>{
            'review_type': 'general',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_editor_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'editor_submit_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'editor-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'editor_alpha',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '编辑建议强化段落收束。',
                    'findings': <Object?>[
                      <String, Object?>{
                        'finding_id': 'editor-finding-1',
                        'severity': 'low',
                        'summary': '段落收束还可更紧。',
                        'suggested_action': '压缩结尾两句解释。',
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
            <String, Object?>{
              'ok': true,
              'content': '已完成编辑向审稿，建议压缩段落收束。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成编辑向审稿，建议压缩段落收束。',
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
              'id': 'editor_alpha',
              'name': '主编智能体',
              'role': '负责编辑收束',
              'model_id': 'editor-child-model',
              'tool_policy': const <String, Object?>{
                'allowed_tools': <String>[
                  'read_project_file',
                  'submit_semantic_review',
                ],
              },
            },
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'editor_room',
              'name': '编辑协作组',
              'agents': <String>['writer', 'editor_alpha'],
              'primary_agent_id': 'writer',
            },
          ],
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'editor_room',
                  displayName: '编辑协作组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'review_task_editor_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          everyElement('editor-child-model'),
        );
        final execution = ValueReaders.mapValue(result['execution']);
        final reviewerDispatch = ValueReaders.mapValue(
          execution['reviewer_dispatch'],
        );
        expect(
          ValueReaders.stringValue(reviewerDispatch['selection_mode']),
          ReviewerSelectionModes.delegatedCriticOrEditor,
        );
        expect(
          ValueReaders.stringValue(reviewerDispatch['agent_id']),
          'editor_alpha',
        );
      },
    );

    test(
      'runWorkflowTaskOnce falls back to primary writer self-review when no reviewer-like child exists',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_self_001',
          'title': '语义审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>['chapters/第01章_seed_to_full.md'],
          'output_paths': <Object?>[
            'reviews/general/ch01_self.md',
            'reviews/general/ch01_self.json',
          ],
          'metadata': <String, Object?>{
            'review_type': 'general',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_self_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'self_submit_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'self-review-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.writer,
                      'source_id': 'writer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '主写自检后建议补一处承接。',
                    'findings': <Object?>[
                      <String, Object?>{
                        'finding_id': 'self-finding-1',
                        'severity': 'low',
                        'summary': '章节转场还能更顺。',
                        'suggested_action': '补一处动作承接句。',
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
            <String, Object?>{
              'ok': true,
              'content': '已完成自检审稿，建议补一处承接。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已完成自检审稿，建议补一处承接。',
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
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'solo_writer_room',
              'name': '单人正文组',
              'agents': <String>['writer'],
              'primary_agent_id': 'writer',
            },
          ],
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'solo_writer_room',
                  displayName: '单人正文组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'review_task_self_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          everyElement('test-model'),
        );
        final execution = ValueReaders.mapValue(result['execution']);
        final reviewerDispatch = ValueReaders.mapValue(
          execution['reviewer_dispatch'],
        );
        expect(
          ValueReaders.stringValue(reviewerDispatch['selection_mode']),
          ReviewerSelectionModes.primaryWriterSelfReview,
        );
        final response = ValueReaders.mapValue(result['response']);
        final toolCalls = ValueReaders.objectList(
          response['tool_calls'],
        ).map(ValueReaders.mapValue).toList(growable: false);
        expect(
          toolCalls.any(
            (tool) =>
                ValueReaders.stringValue(tool['name']) ==
                'submit_semantic_review',
          ),
          isTrue,
        );
      },
    );

    test(
      'runWorkflowTaskOnce applies child-specific model and tool policy in workflow runtime',
      () async {
        await taskRepository.saveTask(project, <String, Object?>{
          'id': 'review_task_child_policy_001',
          'title': '语义审稿：第01章',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSingleChapterAtomic,
          'status': TaskRuntimeConstants.statusQueued,
          'chapter': '第01章',
          'source_paths': <Object?>[
            'chapters/第01章_seed_to_full.md',
            'outline/总纲.md',
          ],
          'output_paths': <Object?>[
            'reviews/general/ch01_child_policy.md',
            'reviews/general/ch01_child_policy.json',
          ],
          'metadata': <String, Object?>{
            'review_type': 'general',
            'stage': 'review',
          },
          'relative_path': 'tasks/review_task_child_policy_001.json',
        });
        final gateway = _RecordingWorkflowGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'review_submit_1',
                  'name': 'submit_semantic_review',
                  'arguments': <String, Object?>{
                    'review_id': 'delegated-review-policy-1',
                    'source': <String, Object?>{
                      'source_type': NarrativeSourceTypes.reviewer,
                      'source_id': 'reviewer',
                    },
                    'recommended_disposition': 'accept_with_note',
                    'summary': '建议先强化第一段冲突，再补一处动机承接。',
                    'findings': <Object?>[
                      <String, Object?>{
                        'finding_id': 'delegated-policy-finding-1',
                        'severity': 'low',
                        'summary': '第一段冲突可以更早进入。',
                        'suggested_action': '开头一页内补出更早的压力来源。',
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
          loadProjectAgentGroupSelections: (_) async =>
              const <ProjectAgentGroupSelection>[
                ProjectAgentGroupSelection(
                  groupId: 'optional_review_room',
                  displayName: '审稿组',
                  selectedByDefault: true,
                ),
              ],
        );

        final result = await workflowService.runWorkflowTaskOnce(
          project,
          _testSettings(),
          const <String, Object?>{'id': 'review_task_child_policy_001'},
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          gateway.requests.map((request) => request.modelId),
          everyElement('reviewer-child-model'),
        );
        expect(
          gateway.requests.first.toolNames,
          containsAll(<String>['submit_semantic_review', 'read_project_file']),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('write_project_file')),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('call_sub_agent')),
        );
        expect(
          gateway.requests.first.toolNames,
          isNot(contains('submit_chapter_delivery')),
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
  void Function(HostInformationPermissionContext? context)?
  onHostInformationPermissionContext,
  void Function(HostToolPermissionContext? context)?
  onHostToolPermissionContext,
  Future<List<JsonMap>> Function(ProjectDescriptor project)?
  loadAvailableAgents,
  Future<List<JsonMap>> Function(ProjectDescriptor project)?
  loadAvailableAgentGroups,
  Future<List<ProjectAgentGroupSelection>> Function(ProjectDescriptor project)?
  loadProjectAgentGroupSelections,
  ProjectDraftExecutionConstraintRuntimeService?
  draftExecutionConstraintRuntimeService,
  ProjectLongTaskCheckpointReviewService? checkpointReviewService,
  TaskQueueOptionService? taskQueueOptionService,
}) {
  return ProjectWorkflowRuntimeService(
    taskRepository: taskRepository,
    promptTemplateService: promptTemplateService,
    loadProjectAgentGroupSelections: loadProjectAgentGroupSelections,
    loadAvailableAgents: loadAvailableAgents,
    loadAvailableAgentGroups: loadAvailableAgentGroups,
    draftExecutionConstraintRuntimeService:
        draftExecutionConstraintRuntimeService,
    checkpointReviewService: checkpointReviewService,
    taskQueueOptionService: taskQueueOptionService,
    hostAwareGenerateDraftUseCaseFactory:
        (_, _, {hostInformationPermissionContext, hostToolPermissionContext}) {
          onHostInformationPermissionContext?.call(
            hostInformationPermissionContext,
          );
          onHostToolPermissionContext?.call(hostToolPermissionContext);
          return GenerateDraftUseCase(
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
          );
        },
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
        messages: request.messages
            .map(ValueReaders.deepCopyMap)
            .toList(growable: false),
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

class _ThrowingWorkflowGateway extends LlmGateway {
  _ThrowingWorkflowGateway({required this.error});

  final Object error;
  int requestCount = 0;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    requestCount += 1;
    throw error;
  }
}

class _RecordedWorkflowRequest {
  const _RecordedWorkflowRequest({
    required this.modelId,
    required this.toolNames,
    required this.messages,
  });

  final String modelId;
  final List<String> toolNames;
  final List<JsonMap> messages;
}

class _CancellationAwareBlockingWorkflowGateway extends LlmGateway {
  bool cancellationObserved = false;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    if (cancellationToken == null) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return const <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': <Object?>[],
        'message': <String, Object?>{'role': 'assistant', 'content': ''},
      };
    }
    final completer = Completer<void>();
    void onCancel() {
      cancellationObserved = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    cancellationToken.addListener(onCancel);
    if (cancellationToken.isCancellationRequested) {
      onCancel();
    }
    await completer.future;
    cancellationToken.removeListener(onCancel);
    return const <String, Object?>{
      'ok': true,
      'content': '',
      'tool_calls': <Object?>[],
      'message': <String, Object?>{'role': 'assistant', 'content': ''},
    };
  }
}

class _ShortTimeoutTaskQueueOptionService extends TaskQueueOptionService {
  _ShortTimeoutTaskQueueOptionService();

  @override
  JsonMap normalizeOptions([JsonMap options = const <String, Object?>{}]) {
    final normalized = super.normalizeOptions(options);
    return <String, Object?>{...normalized, 'max_seconds': 1};
  }
}

class _QueueSelectionBoundaryWorkflowRuntimeService
    extends ProjectWorkflowRuntimeService {
  _QueueSelectionBoundaryWorkflowRuntimeService({
    required ProjectTaskRepository taskRepository,
    required ProjectPromptTemplateService promptTemplateService,
  }) : _taskRepository = taskRepository,
       super(
         taskRepository: taskRepository,
         promptTemplateService: promptTemplateService,
         generateDraftUseCaseFactory: (_, __) {
           throw UnimplementedError('queue boundary test does not hit gateway');
         },
       );

  final ProjectTaskRepository _taskRepository;
  final List<String> executedTaskIds = <String>[];

  @override
  Future<JsonMap> runWorkflowTaskOnce(
    ProjectDescriptor project,
    AppSettings settings,
    JsonMap selector, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap options = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
    DraftGenerationCancellationToken? cancellationToken,
  }) async {
    final task = await _taskRepository.loadTask(project, selector);
    final taskId = ValueReaders.stringValue(task['id']);
    if (taskId.isNotEmpty) {
      executedTaskIds.add(taskId);
    }
    final transitioned = await _taskRepository.transitionTask(
      project,
      selector,
      TaskRuntimeConstants.statusSucceeded,
      note: 'queue boundary test auto-completed current primary task.',
      extra: <String, Object?>{
        'output_paths': ValueReaders.stringList(task['output_paths']),
      },
    );
    final updatedTask = ValueReaders.mapValue(transitioned['task']).isNotEmpty
        ? ValueReaders.mapValue(transitioned['task'])
        : await _taskRepository.loadTask(project, selector);
    return <String, Object?>{
      'ok': true,
      'response': const <String, Object?>{},
      'output_paths': ValueReaders.stringList(updatedTask['output_paths']),
      'changed_paths': ValueReaders.stringList(updatedTask['output_paths']),
      'executed_tools': const <Object?>[],
      'execution': const <String, Object?>{},
      'checkpoint_review': const <String, Object?>{},
    };
  }
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
  final List<_RecordedExecutionConstraintResolveCall> calls =
      <_RecordedExecutionConstraintResolveCall>[];

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
    String expressionConstraintPolicyMode = '',
    String expressionConstraintInjectionMode = '',
    JsonMap legacyChapterLengthOptions = const <String, Object?>{},
    List<WritingExecutionConstraintSummary>
        recentExpressionConstraintSummaries =
        const <WritingExecutionConstraintSummary>[],
  }) async {
    calls.add(
      _RecordedExecutionConstraintResolveCall(
        appliesTo: appliesTo,
        taskType: taskType,
        expressionConstraintPolicyMode: expressionConstraintPolicyMode,
        recentExpressionConstraintSummaries:
            List<WritingExecutionConstraintSummary>.unmodifiable(
              recentExpressionConstraintSummaries,
            ),
      ),
    );
    return ValueReaders.deepCopyMap(response);
  }
}

class _RecordedExecutionConstraintResolveCall {
  const _RecordedExecutionConstraintResolveCall({
    required this.appliesTo,
    required this.taskType,
    required this.expressionConstraintPolicyMode,
    required this.recentExpressionConstraintSummaries,
  });

  final String appliesTo;
  final String taskType;
  final String expressionConstraintPolicyMode;
  final List<WritingExecutionConstraintSummary>
  recentExpressionConstraintSummaries;
}

class _WorkflowToolExecutionPort implements ToolExecutionPort {
  _WorkflowToolExecutionPort({
    required LocalProjectWorkspacePort workspacePort,
    this.requestGatewayToolResult,
  }) : _workspacePort = workspacePort;

  final LocalProjectWorkspacePort _workspacePort;
  final JsonMap? requestGatewayToolResult;

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
    if (name == 'create_backup') {
      final targetPath = ValueReaders.stringValue(
        arguments['target_path'],
        ValueReaders.stringValue(arguments['relative_path']),
      );
      final backupPath = targetPath.trim().isEmpty
          ? 'backups/generated.bak'
          : 'backups/${targetPath.replaceAll('/', '_')}.bak';
      final content = targetPath.trim().isEmpty
          ? ''
          : await _workspacePort.readTextFile(project.rootPath, targetPath) ??
                '';
      await _workspacePort.writeTextFile(project.rootPath, backupPath, content);
      return <String, Object?>{
        'ok': true,
        'backup_path': backupPath,
        'changed_paths': <Object?>[backupPath],
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
    if (name == 'submit_semantic_review') {
      final review = NarrativeSemanticReview.fromJson(arguments);
      return <String, Object?>{
        'ok': true,
        'domain_tool_name': 'submit_semantic_review',
        'domain_outcome': <String, Object?>{
          'outcome_payload': <String, Object?>{
            'review': review.toJson(),
            'review_advances_workflow': false,
            'finding_count': review.findings.length,
            'blocking_finding_count': review.findings
                .where(
                  (finding) =>
                      finding.severity == SemanticReviewSeverity.blocking,
                )
                .length,
          },
          'metadata': <String, Object?>{
            'recommended_disposition': review.recommendedDisposition.id,
          },
        },
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
    if (name == 'request_gateway_tool' && requestGatewayToolResult != null) {
      return ValueReaders.deepCopyMap(requestGatewayToolResult!);
    }
    if (name == 'propose_narrative_profile_update') {
      return const <String, Object?>{
        'ok': true,
        'waiting_for_user_choice': true,
        'domain_tool_name': 'propose_narrative_profile_update',
        'domain_outcome_status': 'needs_user_confirmation',
        'tool_result_summary': '领域工具等待用户确认：提出项目叙事解释器更新',
        'changed_paths': <Object?>[],
      };
    }
    throw UnimplementedError('Unexpected tool call: $name');
  }
}

class _FakeProjectLongTaskCheckpointReviewService
    extends ProjectLongTaskCheckpointReviewService {
  _FakeProjectLongTaskCheckpointReviewService({
    required this.response,
    this.persistentTaskRepository,
  }) : super(
         taskRepository: ProjectTaskRepository(
           workspacePort: LocalProjectWorkspacePort(),
         ),
       );

  final JsonMap response;
  final ProjectTaskRepository? persistentTaskRepository;

  @override
  Future<JsonMap> saveReview({
    required ProjectDescriptor project,
    required JsonMap task,
    required JsonMap result,
    required List<JsonMap> memorySections,
    JsonMap execution = const <String, Object?>{},
  }) async {
    final saved = ValueReaders.deepCopyMap(response);
    final repository = persistentTaskRepository;
    if (repository != null) {
      final relativePath = ValueReaders.stringValue(
        saved['relative_path'],
      ).trim();
      final review = ValueReaders.mapValue(saved['review']);
      if (relativePath.isNotEmpty && review.isNotEmpty) {
        await repository.saveRecord(project, relativePath, review);
      }
    }
    return saved;
  }
}
