import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointReviewService', () {
    test(
      'builds checkpoint review with drift watch items and next actions',
      () {
        final service = LongTaskCheckpointReviewService(
          taskSummaryService: LongTaskTaskSummaryService(),
        );

        final review = service.buildReview(
          task: <String, Object?>{
            'id': 'chapter_001',
            'title': '样章：第01章',
            'task_type': 'chapter',
            'mode': TaskRuntimeConstants.modeSeedToFullNovel,
            'status': TaskRuntimeConstants.statusWaitingUser,
            'output_paths': <Object?>['drafts/ch01.md'],
            'metadata': <String, Object?>{
              'stage': 'sample',
              'persistent_context_paths': <Object?>[
                'tracking/modes/seed_autopilot_novel/guidance.md',
              ],
            },
          },
          result: <String, Object?>{
            'ok': true,
            'output_paths': <Object?>['drafts/ch01.md'],
            'changed_paths': <Object?>['drafts/ch01.md'],
            'response': <String, Object?>{
              'content': '已写出样章。',
              'tool_calls': <Object?>[
                <String, Object?>{'name': 'write_project_file'},
              ],
            },
          },
          memorySections: const <JsonMap>[
            <String, Object?>{'title': '风格锚点'},
            <String, Object?>{'title': '世界硬约束'},
            <String, Object?>{'title': '角色/身份锚点'},
          ],
          outputPaths: const <String>['drafts/ch01.md'],
          createdAt: '2026-05-25T08:00:00Z',
        );

        expect(
          ValueReaders.stringList(review['drift_watch_items']),
          contains('样章阶段要重点检查文风是否稳定、入口是否干净利落。'),
        );
        expect(
          ValueReaders.mapList(
            review['drift_signals'],
          ).map((item) => ValueReaders.stringValue(item['domain'])),
          containsAll(<String>['style', 'world', 'entity']),
        );
        expect(
          ValueReaders.stringList(review['confirmation_focus']),
          contains('样章入口是否成立，是否能证明题材钩子和叙事方式可持续。'),
        );
        expect(
          ValueReaders.stringList(review['next_actions']),
          contains('样章通过后，确认是否继续正文队列或先修订风格与大纲。'),
        );
        final severity = LongTaskCheckpointSeverityService().assess(review);
        expect(ValueReaders.stringValue(severity['severity']), 'high');
      },
    );
  });
}
