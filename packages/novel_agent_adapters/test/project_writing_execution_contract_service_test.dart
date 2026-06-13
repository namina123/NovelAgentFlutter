import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectWritingExecutionContractService', () {
    const service = ProjectWritingExecutionContractService();

    test('chapterDeliveryStateFromDelivery reuses fallback chapter path', () {
      final result = service.chapterDeliveryStateFromDelivery(
        delivery: <String, Object?>{
          'delivery_id': 'delivery-01',
          'delivery_state': 'missing_output_recoverable',
          'state_result': <String, Object?>{
            'state': 'missing_output_recoverable',
            'reason': 'formal_chapter_missing_delivery',
            'summary': '正式章节交付缺失。',
            'retryable': true,
            'blocks_progress': true,
            'chapter_body_delivered': false,
            'submission_accepted': false,
          },
        },
        fallbackChapterPath: 'chapters/chapter_01.md',
      );

      expect(result, isNotNull);
      expect(result!.state, 'missing_output_recoverable');
      expect(result.retryable, isTrue);
      expect(result.metadata['chapter_path'], 'chapters/chapter_01.md');
    });

    test('activationReportFromJson returns null for empty payload', () {
      expect(
        service.activationReportFromJson(const <String, Object?>{}),
        isNull,
      );
    });

    test(
      'attachDerivedProjections appends expression constraint projection',
      () {
        final result = service.attachDerivedProjections(<String, Object?>{
          'constraints': <String, Object?>{
            'present': true,
            'expression_constraint_active': true,
            'expression_constraint_policy_mode': 'force',
            'expression_constraint_applied': true,
            'repair_required': true,
            'expression_constraint_gate': <String, Object?>{
              'present': true,
              'repair_required': true,
            },
            'summary': '表达限制当前要求先修订后再继续。',
          },
        });

        final projection = result['expression_constraint_projection'];
        expect(projection, isA<Map<String, Object?>>());
        expect(
          (projection as Map<String, Object?>)['status'],
          'repair_blocked',
        );
      },
    );
  });
}
