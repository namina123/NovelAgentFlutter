import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('LongTaskCheckpointDispositionService', () {
    final service = LongTaskCheckpointDispositionService();

    test(
      'resolves high risk chapter review to blocked wait with revision followup',
      () {
        final disposition = service.resolve(const <String, Object?>{
          'task_type': 'chapter',
          'severity': 'high',
          'result_ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'persistent_context_paths': <Object?>[
            'tracking/modes/seed_autopilot_novel/guidance.md',
          ],
        });

        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'blocked_wait_user',
        );
        expect(
          ValueReaders.boolValue(disposition['request_revision_followup']),
          isTrue,
        );
        expect(
          ValueReaders.stringValue(disposition['recommended_action_id']),
          'request_revision_followup',
        );
      },
    );

    test('resolves failed step to manual attention', () {
      final disposition = service.resolve(const <String, Object?>{
        'task_type': 'planning',
        'severity': 'critical',
        'result_ok': false,
        'error': 'provider failed',
        'output_paths': <Object?>[],
      });

      expect(
        ValueReaders.stringValue(disposition['disposition']),
        'manual_attention',
      );
      expect(ValueReaders.boolValue(disposition['allow_continue']), isFalse);
    });
  });
}
