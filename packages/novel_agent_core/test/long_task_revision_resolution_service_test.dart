import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskRevisionResolutionService', () {
    final service = LongTaskRevisionResolutionService();

    test('builds resolution actions from postprocess checkpoint', () {
      final result = service.buildResolution(<String, Object?>{
        'id': 'revision_001',
        'title': '修复第01章',
        'task_type': 'revision',
        'status': TaskRuntimeConstants.statusWaitingUser,
        'relative_path': 'tasks/revision_001.json',
        'revision_diff_path': 'tracking/revision_diffs/revision_001.md',
        'postprocess_review_report_path': 'reviews/continuity/ch01.md',
        'postprocess_checkpoint_review_path':
            'tracking/checkpoint_reviews/revision_001.json',
        'metadata': <String, Object?>{
          'review_report_path': 'reviews/continuity/ch01.md',
          'origin_checkpoint_review_path':
              'tracking/checkpoint_reviews/source.json',
        },
      });

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(ValueReaders.stringValue(result['stage']), 'awaiting_resolution');
      expect(
        ValueReaders.stringValue(result['checkpoint_review_path']),
        'tracking/checkpoint_reviews/revision_001.json',
      );
      final actions = ValueReaders.mapList(result['actions']);
      expect(
        actions
            .where(
              (item) =>
                  ValueReaders.stringValue(item['id']) == 'accept_revision',
            )
            .single['enabled'],
        isTrue,
      );
      expect(
        actions
            .where(
              (item) =>
                  ValueReaders.stringValue(item['id']) ==
                  'create_followup_review_tasks',
            )
            .single['enabled'],
        isTrue,
      );
    });

    test(
      'falls back to origin checkpoint when postprocess checkpoint missing',
      () {
        final result = service.buildResolution(<String, Object?>{
          'id': 'revision_002',
          'title': '修复第02章',
          'task_type': 'revision',
          'status': TaskRuntimeConstants.statusFailed,
          'relative_path': 'tasks/revision_002.json',
          'metadata': <String, Object?>{
            'origin_checkpoint_review_path':
                'tracking/checkpoint_reviews/origin.json',
          },
        });

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringValue(result['stage']), 'failed');
        expect(
          ValueReaders.stringValue(result['checkpoint_review_source']),
          'origin',
        );
        expect(
          ValueReaders.stringValue(result['checkpoint_review_path']),
          'tracking/checkpoint_reviews/origin.json',
        );
      },
    );
  });
}
