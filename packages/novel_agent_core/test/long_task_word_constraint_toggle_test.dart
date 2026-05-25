import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTask word constraint toggle', () {
    final factory = LongTaskTaskFactoryService(
      modeService: LongTaskModeService(),
      pathPolicyService: LongTaskPathPolicyService(),
    );

    test('does not write constraints when toggle is off', () {
      final tasks = factory.buildTasks(
        TaskRuntimeConstants.modeSeedToFullNovel,
        'plan_off',
        options: const <String, Object?>{
          'chapter_count': 2,
          'enable_chapter_word_constraints': false,
          'chapter_word_target': 1800,
          'sample_chapter_word_target': 1200,
        },
      );
      final sampleTask = tasks.firstWhere(
        (task) => ValueReaders.stringValue(task['task_type']) == 'chapter',
      );
      final metadata = ValueReaders.mapValue(sampleTask['metadata']);

      expect(metadata.containsKey('chapter_word_target'), isFalse);
      expect(metadata.containsKey('chapter_word_min'), isFalse);
      expect(metadata.containsKey('chapter_word_max'), isFalse);
    });

    test('writes constraints when toggle is on', () {
      final tasks = factory.buildTasks(
        TaskRuntimeConstants.modeSeedToFullNovel,
        'plan_on',
        options: const <String, Object?>{
          'chapter_count': 2,
          'enable_chapter_word_constraints': true,
          'chapter_word_target': 1800,
          'chapter_word_min': 1400,
          'chapter_word_max': 2200,
          'sample_chapter_word_target': 1200,
        },
      );
      final sampleTask = tasks.firstWhere(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'chapter' &&
            ValueReaders.stringValue(
                  ValueReaders.mapValue(task['metadata'])['stage'],
                ) ==
                'sample',
      );
      final draftTask = tasks.firstWhere(
        (task) =>
            ValueReaders.stringValue(task['task_type']) == 'chapter' &&
            ValueReaders.stringValue(
                  ValueReaders.mapValue(task['metadata'])['stage'],
                ) ==
                'draft',
      );
      final sampleMetadata = ValueReaders.mapValue(sampleTask['metadata']);
      final draftMetadata = ValueReaders.mapValue(draftTask['metadata']);

      expect(
        ValueReaders.intValue(sampleMetadata['chapter_word_target']),
        1200,
      );
      expect(ValueReaders.intValue(draftMetadata['chapter_word_target']), 1800);
      expect(ValueReaders.intValue(draftMetadata['chapter_word_min']), 1400);
      expect(ValueReaders.intValue(draftMetadata['chapter_word_max']), 2200);
    });
  });
}
