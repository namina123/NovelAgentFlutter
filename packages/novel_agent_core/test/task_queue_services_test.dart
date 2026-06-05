import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Task queue services', () {
    final definitionService = TaskDefinitionService();
    final selectionService = TaskSelectionService(
      taskDefinitionService: definitionService,
    );
    final optionService = TaskQueueOptionService();
    final preflightService = TaskQueuePreflightService(
      optionService: optionService,
      taskSelectionService: selectionService,
      taskDefinitionService: definitionService,
    );
    final stopPolicyService = TaskQueueStopPolicyService(
      optionService: optionService,
    );

    test('preflight reports waiting user as blocker', () {
      // 中文注释: 这里验证预检会准确解释队列为什么不能继续自动跑。
      final preflight = preflightService.preflightFromTasks(<Object?>[
        <String, Object?>{
          'id': 't1',
          'title': 'blocked',
          'status': TaskRuntimeConstants.statusWaitingUser,
        },
      ]);

      expect(preflight['can_run'], isFalse);
      expect(preflight['primary_blocker'], 'waiting_user');
    });

    test('stop policy pauses on waiting user choice', () {
      // 中文注释: 这里验证单步结果一旦进入用户选项等待态，队列就会请求宿主暂停。
      final decision = stopPolicyService.stopAfterStep(
        <String, Object?>{
          'ok': true,
          'response': <String, Object?>{'waiting_for_user_choice': true},
        },
        <String, Object?>{'status': TaskRuntimeConstants.statusRunning},
      );

      expect(decision['stop'], isTrue);
      expect(decision['reason'], 'waiting_user_choice');
    });

    test('stop policy pauses on delivery state machine repair signal', () {
      // 中文注释: 这里验证队列刹车会直接读取章节交付状态，而不是只靠无输出兜底。
      final decision = stopPolicyService.stopAfterStep(
        <String, Object?>{
          'ok': true,
          'chapter_delivery_state':
              ChapterDeliveryStateStatuses.missingOutputRecoverable,
          'response': const <String, Object?>{},
          'output_paths': const <Object?>[],
        },
        <String, Object?>{'status': TaskRuntimeConstants.statusSucceeded},
      );

      expect(decision['stop'], isTrue);
      expect(decision['reason'], 'delivery_repair_required');
    });

    test('stop policy pauses on structured information repair signal', () {
      final decision = stopPolicyService.stopAfterStep(
        <String, Object?>{
          'ok': true,
          'checkpoint_review': <String, Object?>{
            'review': <String, Object?>{
              'information_signal': <String, Object?>{
                'present': true,
                'category': 'repair',
                'summary': 'required 信息省略 1 项，建议先补上下文。',
              },
            },
          },
          'response': const <String, Object?>{},
          'output_paths': const <Object?>['chapters/ch01.md'],
        },
        <String, Object?>{'status': TaskRuntimeConstants.statusSucceeded},
      );

      expect(decision['stop'], isTrue);
      expect(decision['reason'], 'information_repair_required');
      expect(
        ValueReaders.stringValue(decision['note']),
        contains('required 信息省略 1 项'),
      );
    });

    test(
      'stop policy pauses on shared writing execution content quality signal',
      () {
        final decision = stopPolicyService.stopAfterStep(
          <String, Object?>{
            'ok': true,
            'writing_execution_result': <String, Object?>{
              'execution_id': 'task_001',
              'workflow_kind': 'workflow_task',
              'overall_status':
                  WritingExecutionOutcomeStatuses.contentQualityIssue,
              'summary': '正文内容质量不达标，需要人工复核。',
              'delivery': const <String, Object?>{
                'present': true,
                'state': 'invalid_output_rewrite_required',
                'summary': '正文内容质量不达标，需要人工复核。',
                'blocks_progress': true,
              },
              'constraints': const <String, Object?>{},
              'information': const <String, Object?>{},
              'collaboration': const <String, Object?>{},
              'recovery': const <String, Object?>{},
              'next_action': '',
              'blocks_progress': true,
              'retryable': false,
              'requires_user_action': false,
              'schema_version': 1,
              'metadata': const <String, Object?>{},
            },
            'response': const <String, Object?>{},
            'output_paths': const <Object?>['chapters/ch01.md'],
          },
          <String, Object?>{'status': TaskRuntimeConstants.statusSucceeded},
        );

        expect(decision['stop'], isTrue);
        expect(decision['reason'], 'delivery_manual_attention');
        expect(
          decision['writing_execution_category'],
          'content_quality_failed',
        );
      },
    );
  });
}
