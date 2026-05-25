import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskChapterGateService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskChapterGateService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_chapter_gate_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      final reviewReportService = ProjectReviewReportService(
        workspacePort: workspacePort,
        taskRepository: taskRepository,
      );
      final repairTaskService = ProjectLongTaskReviewRepairTaskService(
        taskRepository: taskRepository,
        reviewReportService: reviewReportService,
      );
      service = ProjectLongTaskChapterGateService(
        taskRepository: taskRepository,
        reviewReportService: reviewReportService,
        reviewRepairTaskService: repairTaskService,
      );
      project = ProjectDescriptor(
        id: 'chapter_gate_test',
        name: '章级闸门测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/general/ch01_gate.md',
        '# 章级审稿：第01章\n\n- 范围：第01章\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/general/ch01_gate.json',
        '''
{
  "id": "gate_review_001",
  "title": "章级审稿：第01章",
  "review_type": "general",
  "scope": "第01章",
  "summary": "剧情节奏和设定存在问题。",
  "issues": [
    {
      "title": "设定前后冲突",
      "suggestion": "统一誓约代价。"
    }
  ],
  "suggestions": ["收紧本章结尾节奏。"]
}
''',
      );
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'chapter_001',
        'title': '第01章',
        'task_type': 'chapter',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusSucceeded,
        'output_paths': <Object?>['drafts/ch01.md'],
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'sort_order': 1,
        },
        'relative_path': 'tasks/chapter_001.json',
      });
      await taskRepository.saveTask(project, <String, Object?>{
        'id': 'gate_review_task_001',
        'title': '章级审稿：第01章',
        'task_type': 'review',
        'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'status': TaskRuntimeConstants.statusSucceeded,
        'depends_on': <Object?>['chapter_001'],
        'output_paths': <Object?>[
          'reviews/general/ch01_gate.md',
          'reviews/general/ch01_gate.json',
        ],
        'metadata': <String, Object?>{
          'origin': 'chapter_gate_review',
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'workflow_mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'review_report_path': 'reviews/general/ch01_gate.md',
          'persistent_context_paths': <Object?>[
            'tracking/modes/full_outline/guidance.md',
          ],
          'sort_order': 2,
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
        'output_paths': <Object?>['drafts/ch02.md'],
        'metadata': <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'sort_order': 3,
        },
        'relative_path': 'tasks/chapter_002.json',
      });
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'creates repair task and rewires downstream dependency on gate failure',
      () async {
        final result = await service.applyReviewOutcome(
          project: project,
          task: await taskRepository.loadTask(project, const <String, Object?>{
            'id': 'gate_review_task_001',
          }),
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(
          ValueReaders.stringValue(result['action']),
          'create_repair_task',
        );

        final repairTask = ValueReaders.mapValue(result['repair_task']);
        expect(ValueReaders.stringValue(repairTask['task_type']), 'revision');
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              repairTask['metadata'],
            )['runtime_baseline_id'],
          ),
          'chapter_collaboration_autorun',
        );
        expect(
          ValueReaders.stringList(repairTask['depends_on']),
          contains('gate_review_task_001'),
        );

        final chapterTwo = await taskRepository.loadTask(
          project,
          const <String, Object?>{'id': 'chapter_002'},
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          contains(ValueReaders.stringValue(repairTask['id'])),
        );
        expect(
          ValueReaders.stringList(chapterTwo['depends_on']),
          isNot(contains('gate_review_task_001')),
        );
      },
    );
  });
}
