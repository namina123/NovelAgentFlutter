import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

import '../lib/src/workflow/chapter_delivery_outcome_projection_service.dart';

void main() {
  group('ChapterDeliveryOutcomeProjectionService', () {
    const service = ChapterDeliveryOutcomeProjectionService();

    test(
      'fromPayload normalizes duplicate chapter path and title fallback',
      () {
        final projection = service.fromPayload(
          toolName: NarrativeDomainToolNames.submitChapterDelivery,
          outcomeStatus: DomainToolOutcomeStatuses.accepted,
          payload: <String, Object?>{
            'delivery_id': 'delivery-004',
            'chapter_path': 'chapters/第04章_第04章.md',
            'requested_chapter_path': 'chapters\\..\\chapters\\第04章_第04章.md',
            'resolved_chapter_path': 'chapters/第04章_第04章.md',
            'title': '',
            'delivery_state': 'delivered',
            'chapter_body_state': 'delivered',
            'sidecar_state': 'accepted',
            'state_result': const <String, Object?>{
              'state': 'delivered',
              'chapter_body_delivered': true,
              'submission_accepted': true,
            },
            'path_resolution': const <String, Object?>{
              'requested_path': 'chapters/第04章_第04章.md',
              'resolved_path': 'chapters/第04章_第04章.md',
              'chapter_number': 4,
            },
            'submission': const <String, Object?>{
              'submission_id': 'submission-004',
              'chapter_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.chapter,
                'ref_id': 'chapters/第04章_第04章.md',
                'relative_path': 'chapters/第04章_第04章.md',
              },
            },
          },
        );

        final pathResolution = ValueReaders.mapValue(
          projection['path_resolution'],
        );
        final submission = ValueReaders.mapValue(projection['submission']);
        final chapterRef = ValueReaders.mapValue(submission['chapter_ref']);

        expect(projection['chapter_path'], 'chapters/第04章.md');
        expect(projection['resolved_chapter_path'], 'chapters/第04章.md');
        expect(projection['title'], '第04章');
        expect(pathResolution['resolved_path'], 'chapters/第04章.md');
        expect(submission['title'], '第04章');
        expect(chapterRef['ref_id'], 'chapters/第04章.md');
        expect(chapterRef['relative_path'], 'chapters/第04章.md');
        expect(chapterRef['display_name'], '第04章');
      },
    );

    test(
      'latestFromExecutedTools projects normalized title from submission title',
      () {
        final projection = service.latestFromExecutedTools(<Object?>[
          <String, Object?>{
            'name': NarrativeDomainToolNames.submitChapterDelivery,
            'result': <String, Object?>{
              'domain_outcome': <String, Object?>{
                'outcome_status': DomainToolOutcomeStatuses.accepted,
                'outcome_payload': <String, Object?>{
                  'delivery_id': 'delivery-005',
                  'chapter_path': 'chapters/第05章.md',
                  'requested_chapter_path': 'chapters/第05章.md',
                  'resolved_chapter_path': 'chapters/第05章.md',
                  'title': '',
                  'delivery_state': 'delivered',
                  'chapter_body_state': 'delivered',
                  'sidecar_state': 'accepted',
                  'state_result': const <String, Object?>{
                    'state': 'delivered',
                    'chapter_body_delivered': true,
                    'submission_accepted': true,
                  },
                  'path_resolution': const <String, Object?>{
                    'requested_path': 'chapters/第05章.md',
                    'resolved_path': 'chapters/第05章.md',
                    'chapter_number': 5,
                  },
                  'submission': const <String, Object?>{
                    'submission_id': 'submission-005',
                    'title': '第05章 雪夜入城',
                    'chapter_ref': <String, Object?>{
                      'ref_type': NarrativeRefTypes.chapter,
                      'ref_id': 'chapters/第05章.md',
                      'relative_path': 'chapters/第05章.md',
                    },
                  },
                },
              },
            },
          },
        ]);

        final submission = ValueReaders.mapValue(projection['submission']);

        expect(projection['title'], '第05章 雪夜入城');
        expect(submission['title'], '第05章 雪夜入城');
        expect(
          ValueReaders.mapValue(submission['chapter_ref'])['display_name'],
          '第05章 雪夜入城',
        );
      },
    );
  });
}
