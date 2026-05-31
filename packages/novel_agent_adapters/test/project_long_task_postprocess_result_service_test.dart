import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskPostprocessResultService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskPostprocessResultService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_postprocess_result_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskPostprocessResultService(
        taskRepository: taskRepository,
        checkpointReviewService: ProjectLongTaskCheckpointReviewService(
          taskRepository: taskRepository,
        ),
      );
      project = ProjectDescriptor(
        id: 'postprocess_result_test',
        name: '后处理结果测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'saves postprocess execution update, review paths and checkpoint review',
      () async {
        final execution = await taskRepository.saveRecord(
          project,
          'tracking/chapter_atomic/chapter.execution.json',
          const <String, Object?>{
            'relative_path': 'tracking/chapter_atomic/chapter.execution.json',
            'task_type': 'chapter',
            'steps': <Object?>[],
            'events': <Object?>[],
            'output_paths': <Object?>['chapters/ch01.md'],
          },
        );
        await taskRepository.writeTextFile(
          project,
          'chapters/ch01.md',
          '章' * 3000,
        );
        await taskRepository.writeTextFile(
          project,
          'reviews/continuity/ch01_fix.md',
          '# 修订检查\n\n仍有一处细节需要确认。',
        );
        await taskRepository.writeTextFile(
          project,
          'reviews/continuity/ch01_fix.json',
          '{"id":"review_fix_1"}',
        );

        final saved = await service.saveResult(
          project: project,
          task: const <String, Object?>{
            'id': 'chapter_003',
            'title': '第03章',
            'task_type': 'chapter',
            'output_paths': <Object?>['chapters/ch01.md'],
            'metadata': <String, Object?>{
              'review_report_path': 'reviews/continuity/ch01.md',
              'sort_order': 3,
              'stage': 'draft',
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
          execution: execution,
          result: DraftGenerationResult(
            project: project,
            projectInfo: const <String, Object?>{},
            userPrompt: 'postprocess',
            prompt: 'postprocess',
            modelId: 'test-model',
            draftMarkdown: '修订检查已保存。',
            contextPack: const <String, Object?>{'summary': '后处理上下文'},
            selectedPaths: const <String>[],
            executedTools: const <Object?>[
              <String, Object?>{'name': 'run_continuity_check'},
            ],
            writtenPaths: const <String>[
              'reviews/continuity/ch01_fix.md',
              'reviews/continuity/ch01_fix.json',
            ],
            changedPaths: const <String>[
              'reviews/continuity/ch01_fix.md',
              'reviews/continuity/ch01_fix.json',
            ],
            transcriptMessages: const <JsonMap>[],
            waitingForUserChoice: false,
            reasoningContent: '',
            stoppedByToolError: false,
            toolErrorSummary: '',
          ),
          memorySections: const <JsonMap>[
            <String, Object?>{'title': '风格锚点'},
          ],
        );

        expect(ValueReaders.boolValue(saved['ok']), isTrue);
        expect(
          ValueReaders.stringValue(saved['postprocess_review_report_path']),
          'reviews/continuity/ch01_fix.md',
        );
        expect(
          ValueReaders.stringValue(
            saved['postprocess_review_report_json_path'],
          ),
          'reviews/continuity/ch01_fix.json',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(saved['checkpoint_review'])['relative_path'],
          ),
          startsWith('tracking/checkpoint_reviews/'),
        );
        expect(
          ValueReaders.mapValue(saved['chapter_length_evaluation']),
          isNotEmpty,
        );
        final updatedExecution = ValueReaders.mapValue(saved['execution']);
        expect(
          ValueReaders.stringList(updatedExecution['postprocess_output_paths']),
          contains('reviews/continuity/ch01_fix.md'),
        );
      },
    );
  });
}
