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

    test(
      'uses structured narrative repair signal before generic high severity fallback',
      () {
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
      },
    );

    test(
      'keeps true permission waiting separate from repair or technical failure',
      () {
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
        expect(ValueReaders.boolValue(disposition['allow_continue']), isTrue);
        expect(
          ValueReaders.boolValue(disposition['allow_confirm_checkpoint']),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(disposition['reason']),
          'permission_waiting_user',
        );
      },
    );

    test(
      'review task with medium risk auto continues instead of waiting for review-of-review',
      () {
        final disposition = service.resolve(const <String, Object?>{
          'task_type': 'review',
          'severity': 'medium',
          'result_ok': true,
          'output_paths': <Object?>['reviews/continuity/ch01.md'],
          'narrative_supervisor_risk': <String, Object?>{
            'overall': <String, Object?>{
              'category': 'accept',
              'reason': 'narrative_risk_clear',
              'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
            },
          },
        });

        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'auto_continue',
        );
        expect(
          ValueReaders.boolValue(disposition['create_followup_review_tasks']),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(disposition['recommended_action_id']),
          'continue_long_task',
        );
      },
    );

    test(
      'sample chapter with advisory checkpoint risk prefers followup review over blocking revision',
      () {
        final disposition = service.resolve(const <String, Object?>{
          'task_type': 'chapter',
          'severity': 'medium',
          'result_ok': true,
          'output_paths': <Object?>['chapters/ch01.md'],
          'narrative_supervisor_risk': <String, Object?>{
            'overall': <String, Object?>{
              'category': 'accept',
              'reason': 'narrative_risk_clear',
              'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
            },
          },
        });

        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'blocked_wait_user',
        );
        expect(
          ValueReaders.boolValue(disposition['create_followup_review_tasks']),
          isTrue,
        );
        expect(
          ValueReaders.boolValue(disposition['request_revision_followup']),
          isFalse,
        );
        expect(
          ValueReaders.stringValue(disposition['recommended_action_id']),
          'create_followup_review_tasks',
        );
      },
    );

    test('continuous agent task with advisory-only signals auto continues', () {
      final disposition = service.resolve(const <String, Object?>{
        'task_type': 'agent_task',
        'mode': 'seed_to_full_novel',
        'severity': 'medium',
        'result_ok': true,
        'output_paths': <Object?>[],
        'narrative_supervisor_risk': <String, Object?>{
          'overall': <String, Object?>{
            'category': 'accept',
            'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
          },
        },
        'information_signal': <String, Object?>{
          'category': 'accept',
          'summary': '当前没有新的 information 风险信号。',
        },
        'collaboration_signal': <String, Object?>{
          'category': 'accept',
          'summary': '',
        },
        'expression_constraint_signal': <String, Object?>{
          'category': 'suggest_strengthen',
          'summary': '表达限制复核已提供，建议记录提醒并继续观察。',
        },
      });

      expect(
        ValueReaders.stringValue(disposition['disposition']),
        'auto_continue',
      );
      expect(ValueReaders.boolValue(disposition['allow_continue']), isTrue);
      expect(
        ValueReaders.stringValue(disposition['recommended_action_id']),
        'continue_long_task',
      );
    });

    test(
      'explicit checkpoint without direct output files can still wait for confirmation instead of manual attention',
      () {
        final disposition = service.resolve(const <String, Object?>{
          'task_type': 'checkpoint',
          'severity': 'medium',
          'result_ok': true,
          'output_paths': <Object?>[],
          'narrative_supervisor_risk': <String, Object?>{
            'overall': <String, Object?>{
              'category': 'accept',
              'summary': '当前没有来自交付、语义复核或权限层的额外阻塞信号。',
            },
          },
        });

        expect(
          ValueReaders.stringValue(disposition['disposition']),
          'blocked_wait_user',
        );
        expect(ValueReaders.boolValue(disposition['manual_attention_required']), isFalse);
        expect(ValueReaders.boolValue(disposition['allow_continue']), isTrue);
        expect(
          ValueReaders.boolValue(disposition['allow_confirm_checkpoint']),
          isTrue,
        );
      },
    );
  });
}
