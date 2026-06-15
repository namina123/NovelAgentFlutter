import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_delegation_capability_service.dart';
import 'agent_member_directory_service.dart';
import 'agent_task_brief_service.dart';

class AgentCollaborationBriefService {
  AgentCollaborationBriefService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentTaskBriefService? taskBriefService,
    AgentGroupDelegationCapabilityService? delegationCapabilityService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _taskBriefService = taskBriefService ?? AgentTaskBriefService(),
       _delegationCapabilityService =
           delegationCapabilityService ??
           const AgentGroupDelegationCapabilityService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentTaskBriefService _taskBriefService;
  final AgentGroupDelegationCapabilityService _delegationCapabilityService;

  String collaborationBrief(
    JsonMap agentGroup,
    List<Object?> availableAgents, {
    int maxAgents = 8,
  }) {
    // 中文注释: 主智能体只需要看到“有哪些协作视角可以调用”，不该拿到整份编排配置。
    final agents = _memberDirectoryService.agentsInGroup(
      agentGroup,
      availableAgents,
    );
    if (agents.isEmpty) {
      return '当前没有可用子智能体组；如需多视角，请在主智能体内部综合。';
    }
    if (!_delegationCapabilityService.supportsChildDelegation(
      agentGroup,
      availableAgents: agents,
    )) {
      return '当前协作组只有主智能体可用，本轮不开放子智能体委派。请由当前主智能体直接完成。';
    }
    final lines = <String>[
      '当前可用内部协作视角（由智能体组提供，不是用户必须手动选择的主智能体）：',
      '策略：一主多子。需要不同视角时调用 call_sub_agent(agent_id, task, context_excerpt, constraints, source_paths)，'
          'agent_id 优先来自下列清单；如果一时拿不准精确 id，可传空字符串，让运行时按 task 自动兜底选人。子智能体不接收完整主会话。',
    ];
    var count = 0;
    for (final agent in agents) {
      final id = ValueReaders.stringValue(agent['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      lines.add(
        '- ${ValueReaders.stringValue(agent['name'], id)}（$id）：'
        '${_taskBriefService.shortPreview(ValueReaders.stringValue(agent['role']), 110)}',
      );
      count += 1;
      if (count >= maxAgents) {
        break;
      }
    }
    return lines.join('\n');
  }
}
