import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskCheckpointReviewService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskCheckpointReviewService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_checkpoint_review_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskCheckpointReviewService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'checkpoint_review_test',
        name: '检查点复盘测试',
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

    test('saves checkpoint review json and markdown', () async {
      final saved = await service.saveReview(
        project: project,
        task: <String, Object?>{
          'id': 'chapter_001',
          'title': '样章：第01章',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeSeedToFullNovel,
          'output_paths': <Object?>['drafts/ch01.md'],
          'metadata': <String, Object?>{
            'stage': 'sample',
            'persistent_context_paths': <Object?>[
              'tracking/modes/seed_autopilot_novel/guidance.md',
            ],
          },
        },
        result: <String, Object?>{
          'ok': true,
          'output_paths': <Object?>['drafts/ch01.md'],
          'changed_paths': <Object?>['drafts/ch01.md'],
          'response': <String, Object?>{'content': '已写出样章。'},
        },
        memorySections: const <JsonMap>[
          <String, Object?>{'title': '风格锚点'},
        ],
      );

      expect(ValueReaders.boolValue(saved['ok']), isTrue);
      expect(
        ValueReaders.stringValue(saved['relative_path']),
        startsWith('tracking/checkpoint_reviews/'),
      );
      expect(ValueReaders.stringValue(saved['markdown_path']), endsWith('.md'));
      final review = ValueReaders.mapValue(saved['review']);
      expect(ValueReaders.mapList(review['output_excerpts']), isNotEmpty);
      expect(ValueReaders.stringValue(review['severity']), isNotEmpty);
      expect(ValueReaders.mapList(review['suggested_actions']), isNotEmpty);
      expect(ValueReaders.stringValue(review['action_summary']), isNotEmpty);
    });
  });
}
