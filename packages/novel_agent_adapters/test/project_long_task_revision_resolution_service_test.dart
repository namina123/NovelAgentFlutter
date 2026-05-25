import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskRevisionResolutionService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectLongTaskRevisionResolutionService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_revision_resolution_test_',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      service = ProjectLongTaskRevisionResolutionService(
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
        id: 'revision_resolution_test',
        name: '修订收口测试',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'chapters/ch01.md',
        '# 第01章\n\n修订后的正文\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'backups/ch01.md',
        '# 第01章\n\n修订前的正文\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/style/ch01.md',
        '# 文风检查：ch01\n\n- 范围：chapters/ch01.md\n',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'reviews/style/ch01.json',
        '''
{
  "id": "style_review_ch01",
  "title": "文风检查：ch01",
  "review_type": "style",
  "scope": "chapters/ch01.md",
  "summary": "建议确认文风是否统一。",
  "source_paths": ["chapters/ch01.md"],
  "issues": [],
  "suggestions": ["确认文风约束仍然成立。"]
}
''',
      );
      await taskRepository.saveRecord(
        project,
        'tracking/revision_diffs/revision_001.json',
        const <String, Object?>{
          'pairs': <Object?>[
            <String, Object?>{
              'backup_path': 'backups/ch01.md',
              'target_path': 'chapters/ch01.md',
            },
          ],
        },
      );
      await taskRepository.saveRecord(
        project,
        'tracking/checkpoint_reviews/revision_001.json',
        const <String, Object?>{
          'id': 'checkpoint_revision_001',
          'task_type': 'revision',
          'stage': 'repair',
          'output_paths': <Object?>['chapters/ch01.md'],
          'drift_watch_items': <Object?>['确认文风与规则没有继续漂移。'],
          'summary': '修订后建议继续做连续性与文风审视。',
        },
      );
      await taskRepository.saveTask(project, const <String, Object?>{
        'id': 'revision_001',
        'title': '修复第01章',
        'task_type': 'revision',
        'mode': TaskRuntimeConstants.modeSeedToFullNovel,
        'status': TaskRuntimeConstants.statusWaitingUser,
        'revision_diff_path': 'tracking/revision_diffs/revision_001.md',
        'postprocess_review_report_path': 'reviews/style/ch01.md',
        'postprocess_review_report_json_path': 'reviews/style/ch01.json',
        'postprocess_checkpoint_review_path':
            'tracking/checkpoint_reviews/revision_001.json',
        'source_paths': <Object?>['chapters/ch01.md'],
        'output_paths': <Object?>['chapters/ch01.md'],
        'metadata': <String, Object?>{
          'review_report_path': 'reviews/style/ch01.md',
          'origin_checkpoint_review_path':
              'tracking/checkpoint_reviews/source.json',
        },
        'relative_path': 'tasks/revision_001.json',
      });
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('builds resolution and materializes followup review tasks', () async {
      final resolution = await service.buildResolution(
        project: project,
        selector: const <String, Object?>{'id': 'revision_001'},
      );

      expect(ValueReaders.boolValue(resolution['ok']), isTrue);
      expect(
        ValueReaders.stringValue(resolution['checkpoint_review_path']),
        'tracking/checkpoint_reviews/revision_001.json',
      );

      final followup = await service.applyAction(
        project: project,
        selector: const <String, Object?>{'id': 'revision_001'},
        command: 'create_followup_review_tasks',
      );

      expect(ValueReaders.boolValue(followup['ok']), isTrue);
      expect(ValueReaders.mapList(followup['tasks']), isNotEmpty);
    });

    test('retries and rolls back revision task', () async {
      final retried = await service.applyAction(
        project: project,
        selector: const <String, Object?>{'id': 'revision_001'},
        command: 'retry_revision',
      );

      expect(ValueReaders.boolValue(retried['ok']), isTrue);
      final retriedTask = await taskRepository.loadTask(
        project,
        const <String, Object?>{'id': 'revision_001'},
      );
      expect(
        ValueReaders.stringValue(retriedTask['status']),
        TaskRuntimeConstants.statusQueued,
      );

      await taskRepository.transitionTask(
        project,
        const <String, Object?>{'id': 'revision_001'},
        TaskRuntimeConstants.statusWaitingUser,
        note: '恢复为等待收口状态。',
      );
      final rolledBack = await service.applyAction(
        project: project,
        selector: const <String, Object?>{'id': 'revision_001'},
        command: 'rollback_revision',
      );

      expect(ValueReaders.boolValue(rolledBack['ok']), isTrue);
      final chapterText = await workspacePort.readTextFile(
        project.rootPath,
        'chapters/ch01.md',
      );
      expect(chapterText, contains('修订前的正文'));
    });
  });
}
