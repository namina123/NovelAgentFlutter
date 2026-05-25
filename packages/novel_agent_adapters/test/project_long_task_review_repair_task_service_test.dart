import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskReviewRepairTaskService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskReviewRepairTaskService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_review_repair_task_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskReviewRepairTaskService(
        taskRepository: taskRepository,
        reviewReportService: ProjectReviewReportService(
          workspacePort: workspacePort,
          taskRepository: taskRepository,
        ),
      );
      project = ProjectDescriptor(
        id: 'review_repair_task_test',
        name: '审稿修复任务测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
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
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('creates repair task from review task output and dedupes', () async {
      final first = await service.createTask(
        project: project,
        task: const <String, Object?>{
          'id': 'review_task_001',
          'task_type': 'review',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'metadata': <String, Object?>{
            'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
            'checkpoint_review_path': 'tracking/checkpoint_reviews/sample.json',
          },
          'output_paths': <Object?>[
            'reviews/continuity/ch01.md',
            'reviews/continuity/ch01.json',
          ],
        },
      );

      expect(ValueReaders.boolValue(first['ok']), isTrue);
      expect(ValueReaders.boolValue(first['duplicated']), isFalse);
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(first['task'])['task_type'],
        ),
        'revision',
      );
      expect(
        ValueReaders.stringValue(ValueReaders.mapValue(first['task'])['mode']),
        TaskRuntimeConstants.modeSeedToFullNovel,
      );
      expect(
        ValueReaders.stringList(
          ValueReaders.mapValue(first['task'])['source_paths'],
        ),
        contains('tracking/modes/seed_autopilot_novel/guidance.md'),
      );
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(first['task'])['metadata'],
          )['origin_checkpoint_review_path'],
        ),
        'tracking/checkpoint_reviews/sample.json',
      );

      final second = await service.createTask(
        project: project,
        task: const <String, Object?>{
          'id': 'review_task_001',
          'task_type': 'review',
          'metadata': <String, Object?>{
            'checkpoint_review_path': 'tracking/checkpoint_reviews/sample.json',
          },
          'output_paths': <Object?>['reviews/continuity/ch01.md'],
        },
      );

      expect(ValueReaders.boolValue(second['ok']), isTrue);
      expect(ValueReaders.boolValue(second['duplicated']), isTrue);
    });

    test(
      'accepts json-first report path and resolves markdown sibling correctly',
      () async {
        final created = await service.createTask(
          project: project,
          task: const <String, Object?>{
            'id': 'review_task_002',
            'task_type': 'review',
            'output_paths': <Object?>[
              'reviews/continuity/ch01.json',
              'reviews/continuity/ch01.md',
            ],
          },
        );

        expect(ValueReaders.boolValue(created['ok']), isTrue);
        expect(
          ValueReaders.stringValue(created['review_report_path']),
          'reviews/continuity/ch01.md',
        );
      },
    );
  });
}
