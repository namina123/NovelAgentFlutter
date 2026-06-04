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

    test('uses structured narrative repair signal before generic high severity fallback', () {
      final disposition = service.resolve(const <String, Object?>{
        'task_type': 'chapter',
        'severity': 'high',
        'result_ok': true,
        'output_paths': <Object?>['chapters/ch01.md'],
        'narrative_supervisor_risk': <String, Object?>{
          'overall': <String, Object?>{
            'category': 'repair',
            'reason': 'semantic_review_repair_required',
            'summary': '语义复核已经给出 blocking/high 风险，建议先返工再决定是否继续。',
          },
        },
      });

      expect(
        ValueReaders.stringValue(disposition['disposition']),
        'blocked_wait_user',
      );
      expect(
        ValueReaders.boolValue(disposition['request_revision_followup']),
        isTrue,
      );
      expect(ValueReaders.boolValue(disposition['allow_continue']), isFalse);
      expect(
        ValueReaders.stringValue(disposition['recommended_action_id']),
        'request_revision_followup',
      );
    });

    test('keeps true permission waiting separate from repair or technical failure', () {
      final disposition = service.resolve(const <String, Object?>{
        'task_type': 'checkpoint',
        'severity': 'medium',
        'result_ok': true,
        'output_paths': <Object?>['tracking/checkpoints/ch01.md'],
        'narrative_supervisor_risk': <String, Object?>{
          'overall': <String, Object?>{
            'category': 'checkpoint_user',
            'reason': 'permission_waiting_user',
            'summary': '至少一个领域工具正在等待用户确认，本轮应停在真正的用户确认点。',
          },
        },
      });

      expect(
        ValueReaders.stringValue(disposition['disposition']),
        'blocked_wait_user',
      );
      expect(ValueReaders.boolValue(disposition['allow_continue']), isFalse);
      expect(
        ValueReaders.boolValue(disposition['allow_confirm_checkpoint']),
        isFalse,
      );
      expect(
        ValueReaders.stringValue(disposition['reason']),
        'permission_waiting_user',
      );
    });
  });
}
