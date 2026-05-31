import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectLongTaskToolExecutor', () {
    test('does not execute for non long task project', () async {
      final executor = ProjectLongTaskToolExecutor(
        loadPlanInput: (_, {required modeId}) async => null,
        createLongTaskWorkflow: (_, __, {options = const <String, Object?>{}}) async =>
            const <String, Object?>{},
      );
      final result = await executor.startLongTaskRun(
        const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
          projectType: 'novel',
        ),
        const <String, Object?>{},
      );

      expect(result['ok'], isFalse);
      expect(result['not_executed'], isTrue);
      expect(result['error'], contains('只有长任务相关项目'));
    });

    test('launches workflow and infers mode from runtime baseline', () async {
      var capturedModeId = '';
      var capturedRuntimeMode = '';
      JsonMap capturedOptions = const <String, Object?>{};
      final executor = ProjectLongTaskToolExecutor(
        loadPlanInput: (_, {required modeId}) async {
          capturedModeId = modeId;
          return const ModeGuidancePlanInput(
            modeId: 'seed_autopilot_novel',
            runtimeBaselineId: 'continuous_autonomous',
            runtimeMode: TaskRuntimeConstants.modeSeedToFullNovel,
            isReady: true,
            options: <String, Object?>{
              'runtime_baseline_id': 'continuous_autonomous',
            },
            missingFields: <String>[],
          );
        },
        createLongTaskWorkflow:
            (_, runtimeMode, {options = const <String, Object?>{}}) async {
              capturedRuntimeMode = runtimeMode;
              capturedOptions = options;
              return const <String, Object?>{
                'ok': true,
                'created_tasks': <Object?>[
                  <String, Object?>{
                    'relative_path': 'tasks/task_01.json',
                  },
                ],
                'changed_paths': <Object?>['tasks/task_01.json'],
              };
            },
      );
      final result = await executor.startLongTaskRun(
        const ProjectDescriptor(
          id: 'demo',
          name: '长篇项目',
          rootPath: 'D:/demo',
          projectType: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
        const <String, Object?>{},
      );

      expect(result['ok'], isTrue);
      expect(capturedModeId, 'seed_autopilot_novel');
      expect(capturedRuntimeMode, TaskRuntimeConstants.modeSeedToFullNovel);
      expect(
        ValueReaders.stringValue(capturedOptions['runtime_baseline_id']),
        'continuous_autonomous',
      );
      expect(result['guidance_path'], 'tracking/modes/seed_autopilot_novel/guidance.md');
      expect(result['created_task_count'], 1);
    });
  });
}
