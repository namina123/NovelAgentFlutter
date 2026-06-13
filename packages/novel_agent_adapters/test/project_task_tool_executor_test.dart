import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

import '../lib/src/tools/project_task_tool_executor.dart';

void main() {
  group('ProjectTaskToolExecutor', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectTaskToolExecutor executor;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel_agent_task_executor_test_',
      );
      final workspacePort = LocalProjectWorkspacePort();
      final hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      executor = ProjectTaskToolExecutor(hostPort: hostPort);
      project = ProjectDescriptor(
        id: 'project_task_test',
        name: '任务测试项目',
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
      'setAgentTasks persists plan tasks and markTaskStatus can update them',
      () async {
        final planResult = await executor.setAgentTasks(
          project,
          <String, Object?>{
            'goal': '建立总纲与卷纲',
            'tasks': <Object?>[
              <String, Object?>{
                'id': 'phase-1',
                'title': '扩展全书总纲',
                'description': '写入 outline/',
                'task_type': 'planning',
                'mode': TaskRuntimeConstants.modeSeedToFullNovel,
                'source_paths': <Object?>[
                  'tracking/modes/seed_autopilot_novel/guidance.md',
                ],
                'output_paths': <Object?>['outline/总纲.md'],
                'metadata': <String, Object?>{
                  'persistent_context_paths': <Object?>[
                    'tracking/modes/seed_autopilot_novel/guidance.md',
                    'styles/seed_autopilot_style.md',
                  ],
                },
              },
            ],
          },
        );

        final changedPaths = ValueReaders.stringList(
          planResult['changed_paths'],
        );
        expect(changedPaths, hasLength(1));
        final statusResult = await executor.markTaskStatus(
          project,
          <String, Object?>{
            'task_id': 'phase-1',
            'status': 'running',
            'note': '开始执行',
          },
        );
        expect(ValueReaders.boolValue(statusResult['ok']), isTrue);
        final relativePath = ValueReaders.stringValue(
          statusResult['relative_path'],
        );
        final taskFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
        );
        expect(await taskFile.exists(), isTrue);
        final content = await taskFile.readAsString();
        expect(content, contains('"status": "running"'));
        expect(content, contains('"id": "phase-1"'));
        expect(content, contains('"task_type": "planning"'));
        expect(content, contains('"mode": "seed_to_full_novel"'));
        expect(content, contains('"source_paths"'));
        expect(content, contains('"persistent_context_paths"'));
      },
    );

    test(
      'setAgentTasks inherits workflow plan metadata from hidden context',
      () async {
        final planResult = await executor.setAgentTasks(
          project,
          <String, Object?>{
            'goal': '补齐规划产物',
            '_workflow_task_context': <String, Object?>{
              'id': 'planning_seed_001',
              'title': '规划：长篇开局',
              'task_type': 'planning',
              'mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
              'metadata': <String, Object?>{
                'plan_id': 'plan_seed_001',
                'generated_by': 'LongTaskPlanner',
                'runtime_baseline_id': 'continuous_autonomous',
                'workflow_mode': TaskRuntimeConstants.modeSeedToFullNovel,
                'stage': 'planning',
              },
            },
            'tasks': <Object?>[
              <String, Object?>{
                'id': 'write_spec',
                'title': '写入项目规格',
                'task_type': 'planning',
                'output_paths': <Object?>['specs/project_spec.md'],
              },
            ],
          },
        );

        expect(ValueReaders.boolValue(planResult['ok']), isTrue);
        final persistedTask = ValueReaders.mapValue(
          ValueReaders.objectList(planResult['tasks']).single,
        );
        expect(
          ValueReaders.stringValue(persistedTask['mode']),
          TaskRuntimeConstants.modeSeedToFullNovel,
        );
        final metadata = ValueReaders.mapValue(persistedTask['metadata']);
        expect(ValueReaders.stringValue(metadata['plan_id']), 'plan_seed_001');
        expect(
          ValueReaders.stringValue(metadata['generated_by']),
          'LongTaskPlanner',
        );
        expect(
          ValueReaders.stringValue(metadata['runtime_baseline_id']),
          'continuous_autonomous',
        );
        expect(
          ValueReaders.stringValue(metadata['workflow_mode']),
          TaskRuntimeConstants.modeSeedToFullNovel,
        );
        expect(ValueReaders.stringValue(metadata['stage']), 'planning');
      },
    );
  });
}
