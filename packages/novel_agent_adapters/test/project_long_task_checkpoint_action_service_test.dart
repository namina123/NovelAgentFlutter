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
    late ProjectLongTaskCheckpointActionService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_checkpoint_action_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskCheckpointActionService(
        taskRepository: taskRepository,
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
      'builds action package and materializes followup review tasks',
      () async {
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
      },
    );

    test(
      'materializes request revision followup and persists related review task state',
      () async {
        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_001.json',
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
          'tracking/checkpoint_reviews/chapter_001.json',
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
      'confirms explicit checkpoint task and unlocks continuation',
      () async {
        await taskRepository.saveTask(project, const <String, Object?>{
          'id': 'checkpoint_001',
          'title': '检查点：第一卷样章确认',
          'task_type': 'checkpoint',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'status': TaskRuntimeConstants.statusWaitingUser,
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
        final applied = await service.applyAction(
          project,
          'tracking/checkpoint_reviews/chapter_001.json',
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
