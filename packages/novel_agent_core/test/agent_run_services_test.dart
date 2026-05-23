import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Agent run services', () {
    final contractService = AgentLoopContractService();
    final policyService = AgentToolPolicyService();
    final responseService = AgentResponsePackageService();
    final subAgentResultService = SubAgentResultPackageService();

    test('builds tool execution contract and final content policy', () {
      // 中文注释: 这里验证工具轮合同会驱动宿主继续执行，而计划型空回复会触发统一兜底提示。
      final contract = contractService.loopStepContract(
        <String, Object?>{'ok': true, 'reasoning_content': 'plan'},
        <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'set_agent_tasks',
            'arguments': <String, Object?>{},
          },
        ],
        roundIndex: 1,
        maxRounds: 3,
        waitingForUserChoice: false,
        stoppedByToolError: false,
      );
      final policy = policyService.finalContentPolicy(
        '',
        waitingForUserChoice: false,
        executedTools: <Object?>[
          <String, Object?>{'name': 'set_agent_tasks'},
        ],
        writtenPaths: <Object?>[],
      );

      expect(contract['action'], 'execute_tools');
      expect(policy['mode'], 'only_plan');
    });

    test('builds response packages', () {
      // 中文注释: 这里验证主智能体和子智能体结果包装后都保留运行层需要的稳定字段。
      final response = responseService.runResponsePackage(
        agent: <String, Object?>{'id': 'writer', 'name': '作者'},
        provider: <String, Object?>{'id': 'default'},
        intent: 'draft',
        content: '正文',
        llmResult: <String, Object?>{'reasoning_content': '思考'},
        executedTools: <Object?>[],
        contextPack: <String, Object?>{'id': 'cp1', 'summary': '上下文'},
        totalToolCalls: 0,
        waitingForUserChoice: false,
        runId: 'run_1',
        createdAt: '2026-05-23T10:00:00Z',
      );
      final subResult = subAgentResultService.subAgentSuccessResultPackage(
        package: <String, Object?>{
          'agent_id': 'writer',
          'agent_name': '作者',
          'sub_session_id': 'sub_1',
          'strategy': 'main_with_children',
        },
        task: '写正文',
        content: '正文内容',
        llmResult: <String, Object?>{},
        executedTools: <Object?>[],
      );

      expect(response['context_pack_id'], 'cp1');
      expect(
        subResult['sub_session_tag'],
        '<sub_session_id>sub_1</sub_session_id>',
      );
    });
  });
}
