import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskTaskFactoryService runtime baseline integration', () {
    final service = LongTaskTaskFactoryService(
      modeService: LongTaskModeService(),
      pathPolicyService: LongTaskPathPolicyService(),
    );

    test('chapter collaboration autorun inserts gate review tasks', () {
      final tasks = service.buildTasks(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'plan_b',
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
          'outline_text': '第一章：回京入局\n第二章：旧案翻动',
          'chapter_count': 2,
        },
        createdAt: '2026-05-25T00:00:00Z',
      );

      final taskTypes = tasks
          .map((task) => ValueReaders.stringValue(task['task_type']))
          .toList(growable: false);
      expect(taskTypes, <String>['chapter', 'review', 'chapter', 'review']);
      expect(
        ValueReaders.stringList(tasks[2]['depends_on']).first,
        ValueReaders.stringValue(tasks[1]['id']),
      );
    });

    test('runtime cadence baseline controls checkpoint interval generation', () {
      // 中文注释: 任务工厂应直接复用 cadence 基线，避免 checkpoint 默认值在工厂内再次分叉。
      final humanOutlineTasks = service.buildTasks(
        TaskRuntimeConstants.modeHumanOutlineAiDraft,
        'plan_h',
        options: const <String, Object?>{
          'outline_text': '第一章：起笔\n第二章：追踪\n第三章：翻面\n第四章：对局',
          'chapter_count': 4,
        },
        createdAt: '2026-05-25T00:00:00Z',
      );
      final checkpointTasks = humanOutlineTasks
          .where(
            (task) => ValueReaders.stringValue(task['task_type']) == 'checkpoint',
          )
          .toList(growable: false);

      expect(checkpointTasks.length, 1);
      expect(ValueReaders.stringValue(checkpointTasks.first['id']), contains('003'));
    });

    test('seed to full checkpoints start queued until dependencies finish', () {
      final tasks = service.buildTasks(
        TaskRuntimeConstants.modeSeedToFullNovel,
        'plan_seed',
        options: const <String, Object?>{
          'seed_prompt': '历史轻喜剧长篇',
          'chapter_count': 2,
        },
        createdAt: '2026-05-25T00:00:00Z',
      );
      final checkpointTasks = tasks
          .where(
            (task) => ValueReaders.stringValue(task['task_type']) == 'checkpoint',
          )
          .toList(growable: false);

      expect(checkpointTasks, isNotEmpty);
      expect(
        checkpointTasks.every(
          (task) =>
              ValueReaders.stringValue(task['status']) ==
              TaskRuntimeConstants.statusQueued,
        ),
        isTrue,
      );
    });

    test('seed to full sample gate carries style and outline readiness contract', () {
      final tasks = service.buildTasks(
        TaskRuntimeConstants.modeSeedToFullNovel,
        'plan_seed_ready',
        options: const <String, Object?>{
          'seed_prompt': '历史轻喜剧长篇',
          'chapter_count': 2,
        },
        createdAt: '2026-05-25T00:00:00Z',
      );
      final checkpoint = tasks.firstWhere(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'checkpoint' &&
            ValueReaders.boolValue(
              ValueReaders.mapValue(
                task['metadata'],
              )[LongTaskSampleReadinessService.readinessCheckpointFlag],
            ),
      );
      final sampleTask = tasks.firstWhere(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'chapter' &&
            ValueReaders.stringValue(
                  ValueReaders.mapValue(task['metadata'])['stage'],
                ) ==
                'sample',
      );

      expect(
        ValueReaders.stringList(checkpoint['source_paths']),
        containsAll(<String>[
          'specs/project_spec.md',
          'assets/styles/全书风格指南.md',
          'outlines/story/总纲.md',
          'outlines/chapters/章节任务清单.md',
          'outlines/volumes',
        ]),
      );
      expect(
        ValueReaders.stringList(sampleTask['source_paths']),
        containsAll(<String>[
          'specs/project_spec.md',
          'assets/styles/全书风格指南.md',
          'outlines/story/总纲.md',
          'outlines/chapters/章节任务清单.md',
        ]),
      );
      expect(
        ValueReaders.stringList(sampleTask['output_paths']),
        contains('samples/样章_seed_to_full.md'),
      );
    });
  });
}
