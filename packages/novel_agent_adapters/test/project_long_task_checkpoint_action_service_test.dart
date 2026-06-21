import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskCheckpointActionService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late LongTaskSupervisor longTaskSupervisor;
    late ProjectLongTaskCheckpointActionService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_checkpoint_action_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      longTaskSupervisor = LongTaskSupervisor(
        runRegistry: LocalLongTaskRunRegistry(
          settingsRootPath: tempDirectory.path,
        ),
      );
      service = ProjectLongTaskCheckpointActionService(
        taskRepository: taskRepository,
        longTaskSupervisor: longTaskSupervisor,
        checkpointReviewTaskService: ProjectLongTaskCheckpointReviewTaskService(
          taskRepository: taskRepository,
          reviewReportService: ProjectReviewReportService(
            workspacePort: workspacePort,
            taskRepository: taskRepository,
          ),
        ),
      );
      project = ProjectDescriptor(
        id: 'checkpoint_action_test',
        name: '检查点动作测试',
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
          'value': '黑暗奇幻长篇',
          'label': '黑暗奇幻长篇',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '誓约体系不可被真正伪造，违约会反噬。',
          'label': '誓约体系',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '主角要翻案复仇，并夺回北境话语权。',
          'label': '翻案复仇',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '干净利落，减少说明腔。',
          'label': '干净利落',
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
        'chapters/ch01.md',
        '# 第01章\n\n样章正文\n',
      );
      await taskRepository.saveTask(project, const <String, Object?>{
        'id': 'chapter_001',
        'title': '样章：第01章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusWaitingUser,
        'output_paths': <Object?>['chapters/ch01.md'],
        'metadata': <String, Object?>{
          'stage': 'sample',
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
        },
        'relative_path': 'tasks/chapter_001.json',
      });
      await taskRepository.saveRecord(
        project,
        'tracking/checkpoint_reviews/chapter_001.json',
        const <String, Object?>{
          'task': <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'relative_path': 'tasks/chapter_001.json',
          },
          'task_type': 'chapter',
          'stage': 'sample',
          'result_ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'confirmation_focus': <Object?>['样章入口是否成立。'],
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
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'builds action package and materializes non-blocking followup review tasks',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'chapter_002',
          'title': '正文：第02章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['chapter_001'],
          'output_paths': <Object?>['chapters/ch02.md'],
          'metadata': <String, Object?>{'plan_id': 'plan_001', 'sort_order': 2},
          'relative_path': 'tasks/chapter_002.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_medium.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'medium',
            'severity_label': '中',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口是否成立。'],
            'drift_watch_items': <Object?>['检查文风是否漂移。'],
            'persistent_context_paths': <Object?>[],
          },
        );

        final package = await service.buildActionPackage(
          project,
          'tracking/checkpoint_reviews/chapter_medium.json',
        );

        expect(ValueReaders.boolValue(package['ok']), isTrue);
        expect(ValueReaders.stringValue(package['severity']), 'medium');

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_medium.json',
          'create_followup_review_tasks',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(ValueReaders.mapList(applied['tasks']), isNotEmpty);
        final sourceTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
        );
        expect(
          ValueReaders.stringValue(sourceTask['followup_review_state']),
          'created',
        );
        expect(
          ValueReaders.stringValue(
            sourceTask['followup_review_checkpoint_review_path'],
          ),
          'tracking/checkpoint_reviews/chapter_medium.json',
        );
        final downstream = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002'},
        );
        expect(
          ValueReaders.stringList(downstream['depends_on']),
          contains('chapter_001'),
        );
        expect(ValueReaders.mapList(applied['rewired_tasks']), isEmpty);
      },
    );

    test(
      'request revision followup rewires downstream dependents and persists related review task state',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'chapter_002',
          'title': '正文：第02章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['chapter_001'],
          'output_paths': <Object?>['chapters/ch02.md'],
          'metadata': <String, Object?>{'plan_id': 'plan_001', 'sort_order': 2},
          'relative_path': 'tasks/chapter_002.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_high.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'high',
            'severity_label': '高',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口是否成立。'],
            'drift_watch_items': <Object?>[
              '检查文风是否漂移。',
              '检查世界规则是否漂移。',
              '检查角色动机是否漂移。',
            ],
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
            'narrative_supervisor_risk': <String, Object?>{
              'overall': <String, Object?>{
                'category': 'repair',
                'reason': 'semantic_review_repair_required',
                'summary': '语义复核已经给出 blocking/high 风险，建议先返工再决定是否继续。',
              },
            },
          },
        );
        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_high.json',
          'request_revision_followup',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(ValueReaders.mapList(applied['review_tasks']), isNotEmpty);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
        );
        expect(
          ValueReaders.stringValue(task['followup_request_state']),
          'requested',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(task['metadata'])['followup_request_state'],
          ),
          'requested',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              task['metadata'],
            )['followup_request_checkpoint_review_path'],
          ),
          'tracking/checkpoint_reviews/chapter_high.json',
        );
        final reviewTaskIds = ValueReaders.mapList(
          applied['review_tasks'],
        ).map((item) => ValueReaders.stringValue(item['id'])).toList();
        final downstream = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002'},
        );
        expect(
          ValueReaders.stringList(downstream['depends_on']),
          isNot(contains('chapter_001')),
        );
        expect(
          ValueReaders.stringList(downstream['depends_on']),
          containsAll(reviewTaskIds),
        );
      },
    );

    test(
      'request revision followup on review task creates repair revision and rewires downstream dependency',
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
  "suggestions": ["统一世界规则。"],
  "review_contract": {
    "review_id": "review_001",
    "review_type": "continuity",
    "reviewer": {
      "reviewer_id": "reviewer-agent",
      "reviewer_role": "critic"
    },
    "basis": {
      "basis_type": "semantic_review",
      "summary": "第01章",
      "source_paths": ["chapters/ch01.md", "outline/总纲.md"],
      "target_paths": ["chapters/ch01.md"]
    },
    "findings": [
      {
        "finding_id": "finding_001",
        "severity": "blocking",
        "summary": "设定前后矛盾",
        "suggested_action": "统一誓约代价描述。",
        "evidence_paths": ["chapters/ch01.md"]
      }
    ],
    "risk_level": "critical",
    "recommended_disposition": "repair",
    "repair_brief": "统一誓约代价描述。",
    "summary": "存在连续性问题。",
    "evidence_paths": ["chapters/ch01.md"],
    "created_at": "2026-06-09T10:00:00Z"
  },
  "review_summary": {
    "review_id": "review_001",
    "review_type": "continuity",
    "reviewer_id": "reviewer-agent",
    "reviewer_role": "critic",
    "risk_level": "critical",
    "recommended_disposition": "repair",
    "finding_count": 1,
    "blocking_finding_count": 1,
    "summary": "存在连续性问题。",
    "repair_brief": "统一誓约代价描述。",
    "evidence_paths": ["chapters/ch01.md"]
  },
  "review_repair_handoff": {
    "action": "create_blocking_repair",
    "reason": "review_requests_blocking_repair",
    "blocks_main_flow": true,
    "requires_repair_task": true,
    "note": "存在连续性问题。",
    "repair_request": {
      "request_id": "repair_request_review_001",
      "source_review_id": "review_001",
      "source_review_type": "continuity",
      "source_disposition": "repair",
      "repair_brief": "统一誓约代价描述。",
      "finding_ids": ["finding_001"],
      "target_paths": ["chapters/ch01.md"],
      "context_paths": ["chapters/ch01.md", "outline/总纲.md"],
      "evidence_paths": ["chapters/ch01.md"],
      "blocks_main_flow": true
    }
  }
}
''',
        );
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'review_task_001',
          'title': '连续性检查：ch01',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>[
            'reviews/continuity/ch01.md',
            'reviews/continuity/ch01.json',
          ],
          'metadata': <String, Object?>{
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'runtime_baseline_id': 'continuous_autonomous',
            'checkpoint_review_path':
                'tracking/checkpoint_reviews/review_task_001.json',
          },
          'relative_path': 'tasks/review_task_001.json',
        });
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'chapter_002_after_review',
          'title': '正文：第02章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['review_task_001'],
          'output_paths': <Object?>['chapters/ch02.md'],
          'relative_path': 'tasks/chapter_002_after_review.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/review_task_001.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'review_task_001',
              'title': '连续性检查：ch01',
              'task_type': 'review',
              'relative_path': 'tasks/review_task_001.json',
            },
            'task_type': 'review',
            'stage': 'repair',
            'result_ok': true,
            'severity': 'high',
            'severity_label': '高风险',
            'output_paths': <Object?>['reviews/continuity/ch01.md'],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/review_task_001.json',
          'request_revision_followup',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(ValueReaders.mapList(applied['created_tasks']), hasLength(1));
        expect(ValueReaders.mapList(applied['followup_tasks']), hasLength(1));
        final createdTask = ValueReaders.mapValue(
          ValueReaders.mapList(applied['created_tasks']).first,
        );
        expect(ValueReaders.stringValue(createdTask['task_type']), 'revision');
        final reviewTask = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'review_task_001'},
        );
        expect(
          ValueReaders.stringValue(reviewTask['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(reviewTask['followup_request_state']),
          'requested',
        );
        expect(
          ValueReaders.stringList(
            ValueReaders.mapValue(
              reviewTask['metadata'],
            )['followup_request_task_ids'],
          ),
          contains(ValueReaders.stringValue(createdTask['id'])),
        );
        final downstream = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002_after_review'},
        );
        expect(
          ValueReaders.stringList(downstream['depends_on']),
          contains(ValueReaders.stringValue(createdTask['id'])),
        );
        expect(
          ValueReaders.stringList(downstream['depends_on']),
          isNot(contains('review_task_001')),
        );
      },
    );

    test(
      'continues low risk chapter checkpoint by marking task succeeded',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_continue.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口成立。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_continue.json',
          'continue_long_task',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(task['continued_checkpoint_review_path']),
          'tracking/checkpoint_reviews/chapter_continue.json',
        );
      },
    );

    test(
      'continue action resumes paused long task run waiting on same checkpoint review',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 't5_propose_profile',
          'title': '提交 narrative profile 更新提案',
          'task_type': 'agent_task',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>[
            'chapters/narrative_profile_update_proposal.md',
          ],
          'metadata': <String, Object?>{
            'plan_id': 'plan_agent_001',
            'stage': 'planning',
          },
          'last_writing_execution_result': <String, Object?>{
            'overall_status':
                WritingExecutionOutcomeStatuses.userActionRequired,
            'blocks_progress': false,
            'next_action': 'resume_when_user_confirms',
          },
          'relative_path': 'tasks/t5_propose_profile.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/t5_propose_profile.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 't5_propose_profile',
              'title': '提交 narrative profile 更新提案',
              'task_type': 'agent_task',
              'relative_path': 'tasks/t5_propose_profile.json',
            },
            'task_type': 'agent_task',
            'stage': 'planning',
            'result_ok': true,
            'severity': 'medium',
            'severity_label': '中',
            'output_paths': <Object?>[
              'chapters/narrative_profile_update_proposal.md',
            ],
            'confirmation_focus': <Object?>['这一单步的结果是否满足当前任务目标。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );
        await taskRepository.saveRecord(
          project,
          'tracking/long_task_runs/plan_agent_001_run.json',
          const <String, Object?>{
            'id': 'plan_agent_001_run',
            'plan_id': 'plan_agent_001',
            'status': 'paused',
            'pause_requested': true,
            'last_task_id': 't5_propose_profile',
            'last_task_path': 'tasks/t5_propose_profile.json',
            'last_checkpoint_review_path':
                'tracking/checkpoint_reviews/t5_propose_profile.json',
            'last_writing_execution_next_action': 'resume_when_user_confirms',
            'updated_at': '2026-06-11T18:56:05.000000Z',
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/t5_propose_profile.json',
          'continue_long_task',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(
          ValueReaders.stringList(applied['resumed_long_task_run_paths']),
          contains('tracking/long_task_runs/plan_agent_001_run.json'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 't5_propose_profile'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        final run = await taskRepository.loadRecord(
          project,
          'tracking/long_task_runs/plan_agent_001_run.json',
        );
        expect(
          ValueReaders.stringValue(run['status']),
          TaskRuntimeConstants.statusRunning,
        );
        expect(ValueReaders.boolValue(run['pause_requested']), isFalse);
        expect(ValueReaders.stringValue(run['stop_reason']), isEmpty);
        expect(
          ValueReaders.stringValue(run['last_writing_execution_next_action']),
          'resume_dispatch',
        );
        expect(
          ValueReaders.stringValue(run['last_information_risk_category']),
          'accept',
        );
        final mirrored = await longTaskSupervisor.loadRun('plan_agent_001_run');
        expect(mirrored, isNotNull);
        expect(mirrored!.status, LongTaskRunStatus.running);
        expect(
          ValueReaders.stringValue(mirrored.metadata['record_relative_path']),
          'tracking/long_task_runs/plan_agent_001_run.json',
        );
      },
    );

    test(
      'buildActionPackage disables repeated continue action after same review was already applied',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_continue_repeat.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口成立。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final firstApply = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_continue_repeat.json',
          'continue_long_task',
        );
        expect(ValueReaders.boolValue(firstApply['ok']), isTrue);

        final package = await service.buildActionPackage(
          project,
          'tracking/checkpoint_reviews/chapter_continue_repeat.json',
        );
        final continueAction = ValueReaders.mapList(package['actions'])
            .firstWhere(
              (action) =>
                  ValueReaders.stringValue(action['id']) ==
                  'continue_long_task',
            );

        expect(ValueReaders.boolValue(package['ok']), isTrue);
        expect(ValueReaders.boolValue(continueAction['enabled']), isFalse);
        expect(
          ValueReaders.stringValue(continueAction['disabled_reason']),
          'checkpoint_action_already_applied',
        );
      },
    );

    test(
      'buildActionPackage disables repeated followup review creation after same review was already applied',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_followup_repeat.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'medium',
            'severity_label': '中',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口成立。'],
            'drift_watch_items': <Object?>['检查文风是否漂移。'],
            'persistent_context_paths': <Object?>[],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_followup_repeat.json',
          'create_followup_review_tasks',
        );
        expect(ValueReaders.boolValue(applied['ok']), isTrue);

        final package = await service.buildActionPackage(
          project,
          'tracking/checkpoint_reviews/chapter_followup_repeat.json',
        );
        final createAction = ValueReaders.mapList(package['actions'])
            .firstWhere(
              (action) =>
                  ValueReaders.stringValue(action['id']) ==
                  'create_followup_review_tasks',
            );
        final continueAction = ValueReaders.mapList(package['actions'])
            .firstWhere(
              (action) =>
                  ValueReaders.stringValue(action['id']) ==
                  'continue_long_task',
            );

        expect(ValueReaders.boolValue(package['ok']), isTrue);
        expect(ValueReaders.boolValue(createAction['enabled']), isFalse);
        expect(
          ValueReaders.stringValue(createAction['disabled_reason']),
          'checkpoint_action_already_applied',
        );
        expect(ValueReaders.boolValue(continueAction['enabled']), isTrue);
        expect(
          ValueReaders.stringValue(package['recommended_action_id']),
          'continue_long_task',
        );
      },
    );

    test(
      'buildActionPackage disables continue actions when source task still blocks progress',
      () async {
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusRunning,
          note: 'simulate failed chapter execution',
        );
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusFailed,
          note: 'formal chapter delivery missing',
          extra: const <String, Object?>{
            'last_writing_execution_result': <String, Object?>{
              'overall_status':
                  WritingExecutionOutcomeStatuses.recoverableFailure,
              'blocks_progress': true,
              'retryable': true,
              'next_action': 'pause_for_failure',
            },
          },
        );
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusRetrying,
          note: 'auto retry scheduled',
        );
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_retrying.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口成立。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final package = await service.buildActionPackage(
          project,
          'tracking/checkpoint_reviews/chapter_retrying.json',
        );
        final continueAction = ValueReaders.mapList(package['actions'])
            .firstWhere(
              (action) =>
                  ValueReaders.stringValue(action['id']) ==
                  'continue_long_task',
            );

        expect(ValueReaders.boolValue(package['ok']), isTrue);
        expect(ValueReaders.boolValue(continueAction['enabled']), isFalse);
        expect(
          ValueReaders.stringValue(continueAction['disabled_reason']),
          'source_task_blocks_progress',
        );
      },
    );

    test(
      'applyAction rejects continue action when source task still blocks progress',
      () async {
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusRunning,
          note: 'simulate failed chapter execution',
        );
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusFailed,
          note: 'formal chapter delivery missing',
          extra: const <String, Object?>{
            'last_writing_execution_result': <String, Object?>{
              'overall_status':
                  WritingExecutionOutcomeStatuses.recoverableFailure,
              'blocks_progress': true,
              'retryable': true,
              'next_action': 'pause_for_failure',
            },
          },
        );
        await taskRepository.transitionTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
          TaskRuntimeConstants.statusRetrying,
          note: 'auto retry scheduled',
        );
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_retrying_apply.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['chapters/ch01.md'],
            'confirmation_focus': <Object?>['样章入口成立。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_retrying_apply.json',
          'continue_long_task',
        );

        expect(ValueReaders.boolValue(applied['ok']), isFalse);
        expect(
          ValueReaders.stringValue(applied['error']),
          contains('source task still blocks progress'),
        );
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusRetrying,
        );
      },
    );

    test(
      'continue action unlocks immediate manual checkpoint dependents',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'planning_001',
          'title': '规划：扩展总纲',
          'task_type': 'planning',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'output_paths': <Object?>['outline/总纲.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_001',
            'stage': 'planning',
          },
          'relative_path': 'tasks/planning_001.json',
        });
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'checkpoint_outline',
          'title': '检查点：确认总纲与章节任务',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
          'depends_on': <Object?>['planning_001'],
          'output_paths': <Object?>['outline/总纲.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_001',
            'stage': 'checkpoint',
            'manual_checkpoint': true,
            'sample_readiness_checkpoint': true,
          },
          'relative_path': 'tasks/checkpoint_outline.json',
        });
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'chapter_001_after_outline',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'depends_on': <Object?>['checkpoint_outline'],
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_001',
            'stage': 'sample',
          },
          'relative_path': 'tasks/chapter_001_after_outline.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/planning_continue.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'planning_001',
              'title': '规划：扩展总纲',
              'task_type': 'planning',
              'relative_path': 'tasks/planning_001.json',
            },
            'task_type': 'planning',
            'stage': 'planning',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['outline/总纲.md'],
            'confirmation_focus': <Object?>['总纲与章节任务可以继续。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/planning_continue.json',
          'continue_long_task',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(
          ValueReaders.stringList(applied['unlocked_checkpoint_task_ids']),
          contains('checkpoint_outline'),
        );
        final planning = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'planning_001'},
        );
        final checkpoint = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'checkpoint_outline'},
        );
        final chapter = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_001_after_outline'},
        );
        expect(
          ValueReaders.stringValue(planning['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(checkpoint['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(
            checkpoint['auto_confirmed_by_checkpoint_review_path'],
          ),
          'tracking/checkpoint_reviews/planning_continue.json',
        );
        final next = TaskSelectionService(
          taskDefinitionService: TaskDefinitionService(),
        ).nextRunnableTaskFromTasks(<Object?>[planning, checkpoint, chapter]);
        expect(
          ValueReaders.stringValue(next['id']),
          'chapter_001_after_outline',
        );
      },
    );

    test(
      'confirms explicit checkpoint task and unlocks continuation',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点：第一卷样章确认',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusQueued,
          'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
          'metadata': <String, Object?>{'stage': 'checkpoint'},
          'relative_path': 'tasks/checkpoint_001.json',
        });
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/checkpoint_001.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'checkpoint_001',
              'title': '检查点：第一卷样章确认',
              'task_type': 'checkpoint',
              'relative_path': 'tasks/checkpoint_001.json',
            },
            'task_type': 'checkpoint',
            'stage': 'checkpoint',
            'result_ok': true,
            'severity': 'low',
            'severity_label': '低风险',
            'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
            'confirmation_focus': <Object?>['确认当前检查点可以继续。'],
            'drift_watch_items': <Object?>[],
            'persistent_context_paths': <Object?>[],
          },
        );

        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/checkpoint_001.json',
          'confirm_checkpoint_continue',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        final task = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'checkpoint_001'},
        );
        expect(
          ValueReaders.stringValue(task['status']),
          TaskRuntimeConstants.statusSucceeded,
        );
        expect(
          ValueReaders.stringValue(task['confirmed_checkpoint_review_path']),
          'tracking/checkpoint_reviews/checkpoint_001.json',
        );
      },
    );

    test(
      'revisit mode guidance returns focused package with previews',
      () async {
        await taskRepository.saveRecord(
          project,
          'tracking/checkpoint_reviews/chapter_manual_attention.json',
          const <String, Object?>{
            'task': <String, Object?>{
              'id': 'chapter_001',
              'title': '样章：第01章',
              'task_type': 'chapter',
              'relative_path': 'tasks/chapter_001.json',
            },
            'task_type': 'chapter',
            'stage': 'sample',
            'result_ok': true,
            'severity': 'critical',
            'severity_label': '关键',
            'output_paths': <Object?>['chapters/ch01.md'],
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
            'narrative_supervisor_risk': <String, Object?>{
              'overall': <String, Object?>{
                'category': 'manual_attention',
                'reason': 'narrative_manual_attention',
                'summary': '长期约束出现高风险偏移，需要先回看模式摘要。',
              },
            },
          },
        );
        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_manual_attention.json',
          'revisit_mode_guidance',
        );

        expect(ValueReaders.boolValue(applied['ok']), isTrue);
        expect(
          ValueReaders.stringList(applied['focus_domains']),
          contains('style'),
        );
        expect(
          ValueReaders.mapList(applied['items']).any(
            (item) =>
                ValueReaders.stringValue(item['domain']) == 'summary' &&
                ValueReaders.stringValue(item['content_preview']).isNotEmpty,
          ),
          isTrue,
        );
      },
    );
  });
}
