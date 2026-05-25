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
          'output_paths': <Object?>['drafts/第01章_seed_to_full.md'],
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
            (section) => ValueReaders.stringValue(section['title']) == '风格锚点',
          ),
          isTrue,
        );
        expect(
          sections.any(
            (section) => ValueReaders.stringValue(section['title']) == '世界硬约束',
          ),
          isTrue,
        );
        expect(
          sections.any(
            (section) =>
                ValueReaders.stringValue(section['title']) == '角色/身份锚点',
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
          'drafts/ch01.md',
          '# 第01章\n\n样章正文',
        );
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/rev_1.json',
          const <String, Object?>{
            'id': 'checkpoint_review_1',
            'task_type': 'chapter',
            'stage': 'sample',
            'output_paths': <Object?>['drafts/ch01.md'],
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
            'output_paths': <Object?>['drafts/第01章_seed_to_full.md'],
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
            'output_paths': <Object?>['drafts/第01章_seed_to_full.md'],
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
      },
    );
  });
}
