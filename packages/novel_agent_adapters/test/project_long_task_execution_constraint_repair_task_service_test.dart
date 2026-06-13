import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskExecutionConstraintRepairTaskService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskExecutionConstraintRepairTaskService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_constraint_repair_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskExecutionConstraintRepairTaskService(
        taskRepository: taskRepository,
      );
      project = ProjectDescriptor(
        id: 'constraint_repair_test',
        name: '执行约束修订测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapters/第02章_摸底.md',
        '# 第02章 摸底\n\n正文里出现了多次——这样的表达。',
      );
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'chapter_002',
        'title': '第02章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusSucceeded,
        'depends_on': <Object?>['chapter_001'],
        'output_paths': <Object?>['chapters/第02章.md'],
        'metadata': <String, Object?>{
          'plan_id': 'plan_001',
          'runtime_baseline_id': 'continuous_autonomous',
          'sort_order': 5,
          'persistent_context_paths': <Object?>['styles/style.md'],
        },
        'relative_path': 'tasks/chapter_002.json',
      });
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'chapter_003',
        'title': '第03章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusQueued,
        'depends_on': <Object?>['chapter_002'],
        'output_paths': <Object?>['chapters/第03章.md'],
        'metadata': <String, Object?>{'sort_order': 6},
        'relative_path': 'tasks/chapter_003.json',
      });
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('creates repair task and rewires downstream chapter', () async {
      final result = await service.createTaskIfNeeded(
        project: project,
        task: await taskRepository.loadTask(project, const <String, Object?>{
          'id': 'chapter_002',
        }),
        checkpointReviewPath: 'tracking/checkpoint_reviews/chapter_002.json',
        checkpointReview: const <String, Object?>{
          'id': 'checkpoint_review_chapter_002',
          'markdown_path': 'tracking/checkpoint_reviews/chapter_002.md',
          'output_paths': <Object?>['chapters/第02章.md', 'chapters/第02章_摸底.md'],
          'expression_constraint_signal': <String, Object?>{
            'repair_required': true,
            'gate_disposition':
                ExpressionConstraintGateRecommendedDispositions.repair,
            'gate_reason': 'expression_constraint_force_repair_authenticity',
            'summary': '表达限制风险已达到强修复门槛，当前轮次需要先修订。',
            'risk_signals': <Object?>['正文表面风险命中：去 AI 风：—— x5'],
          },
          'expression_constraint_review': <String, Object?>{
            'authenticity_pass_level': 'aggressive',
            'mini_recheck_items': <Object?>['正文表面风险命中：去 AI 风：—— x5'],
          },
          'narrative_supervisor_risk': <String, Object?>{
            'delivery': <String, Object?>{
              'chapter_path': 'chapters/第02章_摸底.md',
            },
          },
        },
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(ValueReaders.boolValue(result['created']), isTrue);
      final repairTask = ValueReaders.mapValue(result['repair_task']);
      expect(ValueReaders.stringValue(repairTask['task_type']), 'revision');
      expect(
        ValueReaders.stringList(repairTask['depends_on']),
        contains('chapter_002'),
      );
      expect(ValueReaders.stringList(repairTask['output_paths']), <String>[
        'chapters/第02章_摸底.md',
      ]);
      expect(
        ValueReaders.stringList(repairTask['source_paths']),
        contains('tracking/checkpoint_reviews/chapter_002.json'),
      );

      final chapterThree = await taskRepository.loadTask(
        project,
        const <String, Object?>{'id': 'chapter_003'},
      );
      expect(
        ValueReaders.stringList(chapterThree['depends_on']),
        contains(ValueReaders.stringValue(repairTask['id'])),
      );
      expect(
        ValueReaders.stringList(chapterThree['depends_on']),
        isNot(contains('chapter_002')),
      );
    });
  });
}
