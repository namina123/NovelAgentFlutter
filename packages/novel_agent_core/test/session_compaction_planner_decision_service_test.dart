import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session compaction planner and decision services', () {
    test(
      'planner preserves pinned refs and computes stable retain indices',
      () {
        // 中文注释: 这里验证 planner 只计算计划，不直接改写 session，同时会把 pinned refs 原样带进计划结果。
        final planner = SessionCompactionPlannerService();
        final snapshot = SessionContextPressureSnapshot(
          settings: SessionTokenBudgetSettings(
            modelContextWindowTokens: 2000,
            reservedOutputTokens: 200,
            warningThresholdRatio: 0.75,
            criticalThresholdRatio: 0.9,
          ),
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 120,
            messageTokens: 1100,
            framingTokens: 80,
          ),
          pressureLevel: SessionContextPressureLevel.warning,
        );
        final sessionRecord = <String, Object?>{
          SessionRecordConstants.workingContextMessagesField:
              List<Object?>.generate(
                10,
                (index) => <String, Object?>{
                  'role': index.isEven ? 'user' : 'assistant',
                  'content': '消息 $index',
                },
              ),
          SessionRecordConstants.pinnedContextRefsField: <Object?>[
            'scene.anchor',
            'timeline.anchor',
          ],
        };

        final plan = planner.plan(
          sessionRecord: sessionRecord,
          pressureSnapshot: snapshot,
          triggerKind: SessionCompactionTriggerKind.preflightToolRound,
        );

        expect(plan.pressureLevel, SessionContextPressureLevel.warning);
        expect(plan.pinnedContextRefs, <String>[
          'scene.anchor',
          'timeline.anchor',
        ]);
        expect(plan.compactionMessageIndices, <int>[0, 1]);
        expect(plan.retainedMessageIndices, <int>[2, 3, 4, 5, 6, 7, 8, 9]);
        expect(plan.hasCompactionCandidates, isTrue);
        expect(plan.validateBasics(), isEmpty);
        expect(plan.toJson(), containsPair('keep_recent_message_count', 8));
      },
    );

    test(
      'decision compacts only when pressure is warning critical or overLimit',
      () {
        // 中文注释: 这里验证决策层不会在 safe 压力下误触发 compactNow，但 warning 及以上会进入压缩动作。
        final planner = SessionCompactionPlannerService();
        final decisionService = SessionCompactionDecisionService(
          plannerService: planner,
        );
        final sessionRecord = <String, Object?>{
          SessionRecordConstants.workingContextMessagesField:
              List<Object?>.generate(
                10,
                (index) => <String, Object?>{
                  'role': 'user',
                  'content': '消息 $index',
                },
              ),
        };
        final settings = SessionTokenBudgetSettings(
          modelContextWindowTokens: 2000,
          reservedOutputTokens: 200,
          warningThresholdRatio: 0.75,
          criticalThresholdRatio: 0.9,
        );
        final safeSnapshot = SessionContextPressureSnapshot(
          settings: settings,
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 100,
            messageTokens: 300,
            framingTokens: 60,
          ),
          pressureLevel: SessionContextPressureLevel.safe,
        );
        final warningSnapshot = SessionContextPressureSnapshot(
          settings: settings,
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 100,
            messageTokens: 1200,
            framingTokens: 60,
          ),
          pressureLevel: SessionContextPressureLevel.warning,
        );
        final criticalSnapshot = SessionContextPressureSnapshot(
          settings: settings,
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 100,
            messageTokens: 1350,
            framingTokens: 60,
          ),
          pressureLevel: SessionContextPressureLevel.critical,
        );
        final overLimitSnapshot = SessionContextPressureSnapshot(
          settings: settings,
          estimate: SessionTokenBudgetEstimate(
            systemPromptTokens: 100,
            messageTokens: 1700,
            framingTokens: 60,
          ),
          pressureLevel: SessionContextPressureLevel.overLimit,
        );

        final safeDecision = decisionService.decideFromSnapshot(
          sessionRecord: sessionRecord,
          pressureSnapshot: safeSnapshot,
        );
        final warningDecision = decisionService.decideFromSnapshot(
          sessionRecord: sessionRecord,
          pressureSnapshot: warningSnapshot,
        );
        final criticalDecision = decisionService.decideFromSnapshot(
          sessionRecord: sessionRecord,
          pressureSnapshot: criticalSnapshot,
        );
        final overLimitDecision = decisionService.decideFromSnapshot(
          sessionRecord: sessionRecord,
          pressureSnapshot: overLimitSnapshot,
        );

        expect(
          safeDecision.actionKind,
          SessionCompactionActionKind.noCompaction,
        );
        expect(safeDecision.shouldCompact, isFalse);
        expect(
          warningDecision.actionKind,
          SessionCompactionActionKind.compactNow,
        );
        expect(warningDecision.shouldCompact, isTrue);
        expect(
          criticalDecision.actionKind,
          SessionCompactionActionKind.compactNow,
        );
        expect(
          overLimitDecision.actionKind,
          SessionCompactionActionKind.compactNow,
        );
        expect(warningDecision.validateBasics(), isEmpty);
        expect(
          warningDecision.toJson(),
          containsPair('action_kind', 'compact_now'),
        );
      },
    );
  });
}
