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
  });
}
