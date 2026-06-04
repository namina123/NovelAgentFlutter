import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskChapterGateDispositionService', () {
    const service = LongTaskChapterGateDispositionService();

    test('creates repair task when report has non critical issues', () {
      final decision = service.resolve(const <String, Object?>{
        'issues': <Object?>[
          <String, Object?>{'title': '连续性问题', 'severity': 'high'},
        ],
        'suggestions': <Object?>[],
      }, runtimeBaselineId: 'chapter_collaboration_autorun');

      expect(
        ValueReaders.stringValue(decision['disposition']),
        'auto_create_repair_task',
      );
      expect(
        ValueReaders.stringValue(decision['action']),
        'create_repair_task',
      );
    });

    test('blocks gate when report has suggestions only', () {
      final decision = service.resolve(const <String, Object?>{
        'issues': <Object?>[],
        'suggestions': <Object?>['建议收紧本章结尾节奏。'],
      }, runtimeBaselineId: 'chapter_collaboration_autorun');

      expect(
        ValueReaders.stringValue(decision['disposition']),
        'blocked_wait_user',
      );
      expect(ValueReaders.stringValue(decision['action']), 'block_gate');
      expect(ValueReaders.boolValue(decision['blocks_auto_advance']), isTrue);
    });

    test('respects semantic review manual attention recommendation even without issues', () {
      final decision = service.resolve(const <String, Object?>{
        'issues': <Object?>[],
        'suggestions': <Object?>[],
        'metadata': <String, Object?>{
          'recommended_disposition': 'manual_attention',
        },
      }, runtimeBaselineId: 'chapter_collaboration_autorun');

      expect(
        ValueReaders.stringValue(decision['disposition']),
        'manual_attention',
      );
      expect(ValueReaders.boolValue(decision['manual_attention_required']), isTrue);
    });

    test('respects semantic review repair recommendation even without issues', () {
      final decision = service.resolve(const <String, Object?>{
        'issues': <Object?>[],
        'suggestions': <Object?>[],
        'metadata': <String, Object?>{
          'recommended_disposition': 'repair',
        },
      }, runtimeBaselineId: 'chapter_collaboration_autorun');

      expect(
        ValueReaders.stringValue(decision['action']),
        'create_repair_task',
      );
      expect(ValueReaders.boolValue(decision['blocks_auto_advance']), isTrue);
    });
  });
}
