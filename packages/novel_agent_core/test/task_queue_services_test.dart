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
  });
}
