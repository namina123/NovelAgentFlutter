import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskChapterGateReviewTaskFactoryService', () {
    final service = LongTaskChapterGateReviewTaskFactoryService();

    test('builds queued review task after chapter task', () {
      final tasks = service.buildReviewTasksForChapter(
        <String, Object?>{
          'id': 'plan_a_chapter_001',
          'title': '第01章：回京',
          'task_type': 'chapter',
          'mode': TaskRuntimeConstants.modeHumanOutlineAiDraft,
          'output_paths': <Object?>['drafts/chapters/第01章_回京.md'],
          'metadata': <String, Object?>{
            'plan_id': 'plan_a',
            'persistent_context_paths': <Object?>['styles/default.md'],
            'runtime_baseline_id': 'chapter_collaboration_autorun',
          },
        },
        options: const <String, Object?>{
          'runtime_baseline_id': 'chapter_collaboration_autorun',
        },
        startingSortOrder: 2,
        createdAt: '2026-05-25T00:00:00Z',
      );

      expect(tasks, hasLength(1));
      expect(tasks.first['task_type'], 'review');
      expect(tasks.first['status'], TaskRuntimeConstants.statusQueued);
      expect(tasks.first['depends_on'], <Object?>['plan_a_chapter_001']);
      expect(
        ValueReaders.stringValue(
          ValueReaders.mapValue(tasks.first['metadata'])['runtime_baseline_id'],
        ),
        'chapter_collaboration_autorun',
      );
    });
  });
}
