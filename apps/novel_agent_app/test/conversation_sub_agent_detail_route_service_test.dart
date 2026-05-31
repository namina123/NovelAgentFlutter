import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_sub_agent_detail_route_state.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/sub_agent_run_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_sub_agent_detail_route_service.dart';

void main() {
  group('ConversationSubAgentDetailRouteService', () {
    const service = ConversationSubAgentDetailRouteService();
    const run = SubAgentRunViewData(
      id: 'sub_1',
      agentName: '资料考据员',
      task: '补完设定细节',
      status: '完成',
      summary: '已返回整理结果。',
      content: '内容',
      reasoning: '推理',
      toolCount: 2,
      events: ['开始', '完成'],
    );

    test('selects and resolves active run', () {
      const initial = ConversationSubAgentDetailRouteState.idle();

      final selected = service.selectRun(initial, run);

      expect(selected.activeRunId, 'sub_1');
      expect(service.resolveActiveRun(selected, const [run]), same(run));
    });

    test('sanitizes missing run back to idle', () {
      const state = ConversationSubAgentDetailRouteState(activeRunId: 'missing');

      final sanitized = service.sanitize(state, const [run]);

      expect(sanitized, const ConversationSubAgentDetailRouteState.idle());
    });
  });
}
