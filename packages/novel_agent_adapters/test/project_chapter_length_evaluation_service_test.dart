import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectChapterLengthEvaluationService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskRepository taskRepository;
    late ProjectChapterLengthEvaluationService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_length_eval_test_',
      );
      taskRepository = ProjectTaskRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
      service = ProjectChapterLengthEvaluationService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'length_eval_test',
        name: '字数评估测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('evaluates current chapter against recent chapter distribution', () async {
      await taskRepository.writeTextFile(
        project,
        'chapters/ch01.md',
        '甲' * 2100,
      );
      await taskRepository.writeTextFile(
        project,
        'chapters/ch02.md',
        '乙' * 2200,
      );
      await taskRepository.saveTasks(project, <Object?>[
        <String, Object?>{
          'id': 'chapter_001',
          'task_type': 'chapter',
          'title': '第01章',
          'output_paths': <Object?>['chapters/ch01.md'],
          'metadata': <String, Object?>{'sort_order': 1, 'stage': 'draft'},
        },
        <String, Object?>{
          'id': 'chapter_002',
          'task_type': 'chapter',
          'title': '第02章',
          'output_paths': <Object?>['chapters/ch02.md'],
          'metadata': <String, Object?>{'sort_order': 2, 'stage': 'draft'},
        },
      ]);
      final currentTask = <String, Object?>{
        'id': 'chapter_003',
        'task_type': 'chapter',
        'title': '第03章',
        'output_paths': <Object?>['chapters/ch03.md'],
        'metadata': <String, Object?>{
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
          'chapter_length_distribution_policy': <String, Object?>{
            'rolling_window': 4,
            'mild_deviation_ratio': 0.18,
            'severe_deviation_ratio': 0.35,
            'mild_adjacent_delta_ratio': 0.22,
            'severe_adjacent_delta_ratio': 0.45,
          },
        },
      };

      await taskRepository.writeTextFile(project, 'chapters/ch03.md', '丙' * 3200);
      final evaluation = await service.evaluate(
        project: project,
        task: currentTask,
        result: DraftGenerationResult(
          project: project,
          projectInfo: const <String, Object?>{},
          userPrompt: '写第三章',
          prompt: '写第三章',
          modelId: 'test-model',
          draftMarkdown: '丙' * 3200,
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>[],
          executedTools: const <Object?>[],
          writtenPaths: const <String>['chapters/ch03.md'],
          changedPaths: const <String>['chapters/ch03.md'],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
        ),
      );

      expect(ValueReaders.intValue(evaluation['current_length']), 3200);
      expect(ValueReaders.intValue(evaluation['rolling_average_length']), 2150);
      expect(ValueReaders.stringValue(evaluation['recommended_action']), isNotEmpty);
    });
  });
}
