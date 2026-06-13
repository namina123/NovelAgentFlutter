import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';

import '../tool/hfvv_wave1_user_decision_support.dart';

void main() {
  group('decideLaneAResearchFirstStep', () {
    test('sends follow-up when options mention research loosely but not first', () {
      final decision = decideLaneAResearchFirstStep(<UserOptionViewData>[
        _option('A. 轻松优先，资料为辅'),
        _option('B. 轻考据，有依据地改良'),
        _option('C. 先定框架，再按领域分级'),
        _option('D. 先定主角和开局，资料边走边查'),
      ]);

      expect(decision.strategy, 'send_follow_up_prompt');
      expect(decision.option, isNull);
      expect(decision.followUpPrompt, contains('我选择信息先行路线'));
      expect(decision.reason, 'no_explicit_research_first_option');
    });

    test('selects an explicit research-first option when one exists', () {
      final target = _option('B. 先做资料整理，再定主角和开局');
      final decision = decideLaneAResearchFirstStep(<UserOptionViewData>[
        _option('A. 轻松优先，资料为辅'),
        target,
      ]);

      expect(decision.strategy, 'select_pending_option');
      expect(decision.option, same(target));
      expect(decision.followUpPrompt, isEmpty);
      expect(decision.reason, 'matched_explicit_research_first_option');
    });
  });

  group('shouldRequestLaneBActualSubAgents', () {
    test('returns true when assistant replied but no sub-agent runs exist', () {
      expect(
        shouldRequestLaneBActualSubAgents(
          subAgentRuns: const <SubAgentRunViewData>[],
          latestAssistant: '我基于自己的知识来执行多视角协作。',
        ),
        isTrue,
      );
    });

    test('returns false once real sub-agent runs are present', () {
      expect(
        shouldRequestLaneBActualSubAgents(
          subAgentRuns: const <SubAgentRunViewData>[
            SubAgentRunViewData(
              id: 'run_1',
              agentName: '资料考据子智能体',
              task: '核查历史制度',
              status: 'completed',
              summary: '',
              content: '',
              reasoning: '',
              toolCount: 1,
              events: <String>[],
            ),
          ],
          latestAssistant: '已综合子智能体结果。',
        ),
        isFalse,
      );
    });
  });
}

UserOptionViewData _option(String label) {
  return UserOptionViewData(
    label: label,
    description: '',
    prompt: label,
    sourceQuestion: '请选择',
    allOptions: const <Map<String, Object?>>[],
  );
}
