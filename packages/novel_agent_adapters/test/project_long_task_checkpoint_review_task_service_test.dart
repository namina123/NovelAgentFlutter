import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskCheckpointReviewTaskService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskCheckpointReviewTaskService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_checkpoint_review_task_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskCheckpointReviewTaskService(
        taskRepository: taskRepository,
        reviewReportService: ProjectReviewReportService(
          workspacePort: workspacePort,
          taskRepository: taskRepository,
        ),
      );
      project = ProjectDescriptor(
        id: 'checkpoint_review_task_test',
        name: '检查点建议任务测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await taskRepository.writeTextFile(
        project,
        'drafts/ch01.md',
        '# 第01章\n\n样章正文',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'creates review tasks from checkpoint review suggestions and dedupes',
      () async {
        final first = await service.createTasks(
          project: project,
          task: const <String, Object?>{
            'id': 'chapter_001',
            'task_type': 'chapter',
            'metadata': <String, Object?>{'stage': 'sample'},
          },
          checkpointReview: const <String, Object?>{
            'id': 'checkpoint_review_001',
            'relative_path': 'tracking/checkpoint_reviews/rev_001.json',
            'task_type': 'chapter',
            'stage': 'sample',
            'output_paths': <Object?>['drafts/ch01.md'],
            'drift_watch_items': <Object?>['检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。'],
          },
        );

        expect(ValueReaders.boolValue(first['ok']), isTrue);
        expect(ValueReaders.mapList(first['tasks']), hasLength(3));
        final firstTask = ValueReaders.mapList(first['tasks']).first;
        expect(ValueReaders.stringValue(firstTask['task_type']), 'review');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(firstTask['metadata'])['review_type'],
          ),
          'style',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              firstTask['metadata'],
            )['checkpoint_review_id'],
          ),
          'checkpoint_review_001',
        );
        expect(
          ValueReaders.intValue(
            ValueReaders.mapValue(firstTask['metadata'])['priority_rank'],
          ),
          1,
        );

        final second = await service.createTasks(
          project: project,
          task: const <String, Object?>{
            'id': 'chapter_001',
            'task_type': 'chapter',
            'metadata': <String, Object?>{'stage': 'sample'},
          },
          checkpointReview: const <String, Object?>{
            'id': 'checkpoint_review_001',
            'relative_path': 'tracking/checkpoint_reviews/rev_001.json',
            'task_type': 'chapter',
            'stage': 'sample',
            'output_paths': <Object?>['drafts/ch01.md'],
            'drift_watch_items': <Object?>['检查文风是否仍符合已确认风格锚点，避免语言质地突然漂移。'],
          },
        );

        expect(ValueReaders.mapList(second['tasks']), isEmpty);
        expect(
          ValueReaders.mapList(second['skipped']).every(
            (item) =>
                ValueReaders.stringValue(item['skip_reason']) == 'duplicate',
          ),
          isTrue,
        );
      },
    );

    test(
      'inherits long task mode and persistent context into created review task',
      () async {
        final created = await service.createTasks(
          project: project,
          task: const <String, Object?>{
            'id': 'chapter_002',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'metadata': <String, Object?>{
              'stage': 'sample',
              'persistent_context_paths': <Object?>[
                'tracking/modes/seed_autopilot_novel/guidance.md',
              ],
            },
          },
          checkpointReview: const <String, Object?>{
            'id': 'checkpoint_review_002',
            'relative_path': 'tracking/checkpoint_reviews/rev_002.json',
            'task_type': 'chapter',
            'stage': 'sample',
            'output_paths': <Object?>['drafts/ch01.md'],
          },
        );

        final reviewTask = ValueReaders.mapList(created['tasks']).first;
        expect(
          ValueReaders.stringValue(reviewTask['mode']),
          TaskRuntimeConstants.modeSeedToFullNovel,
        );
        expect(
          ValueReaders.stringList(reviewTask['source_paths']),
          contains('tracking/modes/seed_autopilot_novel/guidance.md'),
        );
      },
    );
  });
}
