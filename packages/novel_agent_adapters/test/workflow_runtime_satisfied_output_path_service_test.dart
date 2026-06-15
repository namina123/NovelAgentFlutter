import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_adapters/src/storage/project_task_repository.dart';
import 'package:novel_agent_adapters/src/workflow/workflow_runtime_satisfied_output_path_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('WorkflowRuntimeSatisfiedOutputPathService', () {
    late Directory tempDirectory;
    late LocalProjectWorkspacePort workspacePort;
    late ProjectTaskRepository taskRepository;
    late ProjectDescriptor project;
    late WorkflowRuntimeSatisfiedOutputPathService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'workflow-runtime-satisfied-output-',
      );
      workspacePort = LocalProjectWorkspacePort();
      taskRepository = ProjectTaskRepository(workspacePort: workspacePort);
      project = ProjectDescriptor(
        id: 'demo',
        name: '示例项目',
        rootPath: tempDirectory.path,
      );
      service = WorkflowRuntimeSatisfiedOutputPathService(
        taskRepository: taskRepository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('reuses only non-empty canonical planning outputs', () async {
      await workspacePort.writeTextFile(
        project.rootPath,
        'specs/project_spec.md',
        '# 项目规格\n\n已有内容。',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outlines/story/总纲.md',
        '',
      );
      await workspacePort.writeTextFile(
        project.rootPath,
        'outlines/chapters/章节任务清单.md',
        '# 章纲\n\n已有章纲。',
      );

      final merged = await service.mergeSatisfiedOutputPaths(
        project: project,
        task: <String, Object?>{
          'task_type': 'planning',
          'metadata': <String, Object?>{
            'stage': 'planning',
            'plan_id': 'plan_001',
          },
          'output_paths': <Object?>[
            'specs/project_spec.md',
            'outlines/story/总纲.md',
            'outlines/chapters/章节任务清单.md',
          ],
        },
        outputPaths: const <String>['specs/project_spec.md'],
      );

      expect(
        merged,
        <String>[
          'specs/project_spec.md',
          'outlines/chapters/章节任务清单.md',
        ],
      );
    });
  });
}
