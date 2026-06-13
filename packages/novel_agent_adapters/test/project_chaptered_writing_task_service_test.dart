import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectChapteredWritingTaskService', () {
    const service = ProjectChapteredWritingTaskService();

    test('treats chapter-labeled writing followups as chaptered writing', () {
      expect(
        service.isChapteredWritingTask(taskType: 'draft', chapterLabel: '第03章'),
        isTrue,
      );
      expect(
        service.isChapteredWritingTask(taskType: 'draft', chapterLabel: '第三章'),
        isTrue,
      );
      expect(
        service.isChapteredWritingTask(
          taskType: 'book_deconstruction_continuation',
          chapterLabel: '第03章',
        ),
        isTrue,
      );
      expect(
        service.canApplyContinuity(
          taskType: 'book_deconstruction_continuation',
          chapterLabel: '第三章',
        ),
        isTrue,
      );
    });

    test('keeps planning and research flows from triggering continuity', () {
      expect(
        service.canApplyContinuity(taskType: 'planning', chapterLabel: '第03章'),
        isFalse,
      );
      expect(
        service.canApplyContinuity(
          taskType: 'information_research',
          chapterLabel: '第03章',
        ),
        isFalse,
      );
      expect(
        service.canApplyContinuity(
          taskType: 'book_deconstruction_followup',
          chapterLabel: '第03章',
        ),
        isFalse,
      );
    });

    test(
      'requires formal delivery for chaptered continuation chapter files',
      () {
        expect(
          service.requiresFormalChapterDelivery(
            taskType: 'book_deconstruction_continuation',
            outputPath: 'chapters/第03章.md',
          ),
          isTrue,
        );
        expect(
          service.requiresFormalChapterDelivery(
            taskType: 'planning',
            outputPath: 'chapters/第03章.md',
          ),
          isFalse,
        );
      },
    );
  });
}
