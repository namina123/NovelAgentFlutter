import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_member_role_service.dart';

class AgentGroupDelegationCapabilityService {
  const AgentGroupDelegationCapabilityService({
    AgentGroupMemberRoleService? memberRoleService,
  }) : _memberRoleService =
           memberRoleService ?? const AgentGroupMemberRoleService();

  final AgentGroupMemberRoleService _memberRoleService;

  bool supportsChildDelegation(
    JsonMap group, {
    Iterable<Object?> availableAgents = const <Object?>[],
    String currentAgentId = '',
  }) {
    return childAgentIds(
      group,
      availableAgents: availableAgents,
      currentAgentId: currentAgentId,
    ).isNotEmpty;
  }

  List<String> childAgentIds(
    JsonMap group, {
    Iterable<Object?> availableAgents = const <Object?>[],
    String currentAgentId = '',
  }) {
    if (group.isEmpty) {
      return const <String>[];
    }
    final metadata = ValueReaders.mapValue(group['metadata']);
    if (_isDerivedFromSingleAgent(metadata)) {
      return const <String>[];
    }
    final memberIds = memberAgentIds(group, availableAgents: availableAgents);
    if (memberIds.length <= 1) {
      return const <String>[];
    }
    final cleanCurrentAgentId = currentAgentId.trim();
    final primaryAgentId =
        cleanCurrentAgentId.isNotEmpty &&
            memberIds.contains(cleanCurrentAgentId)
        ? cleanCurrentAgentId
        : _memberRoleService.resolvePrimaryAgentId(group, memberIds);
    return memberIds
        .where((agentId) => agentId.trim().isNotEmpty)
        .where((agentId) => agentId != primaryAgentId)
        .toList(growable: false);
  }

  List<String> memberAgentIds(
    JsonMap group, {
    Iterable<Object?> availableAgents = const <Object?>[],
  }) {
    if (group.isEmpty) {
      return const <String>[];
    }
    final availableAgentIds = availableAgents
        .map(ValueReaders.mapValue)
        .map((agent) => ValueReaders.stringValue(agent['id']).trim())
        .where((agentId) => agentId.isNotEmpty)
        .toSet();
    final result = <String>[];
    for (final rawAgentId in ValueReaders.stringList(group['agents'])) {
      final agentId = rawAgentId.trim();
      if (agentId.isEmpty || result.contains(agentId)) {
        continue;
      }
      if (availableAgentIds.isNotEmpty &&
          !availableAgentIds.contains(agentId)) {
        continue;
      }
      result.add(agentId);
    }
    return List<String>.unmodifiable(result);
  }

  bool _isDerivedFromSingleAgent(JsonMap metadata) {
    // 中文注释: “派生自单智能体”的标记位历史上在三个地方用三种拼写：
    // adapter 用 derived_from_single_agent、controller 用 derived_from_agent_binding、
    // candidate resolver 用 derived_from_project_agent_binding。它们语义一致（都是“把单个
    // 智能体包装成的合成单成员组，不应再向子智能体委派”），这里统一识别，避免某种拼写漂移
    // 导致合成组被错误允许委派。
    return ValueReaders.boolValue(metadata['derived_from_single_agent']) ||
        ValueReaders.boolValue(metadata['derived_from_agent_binding']) ||
        ValueReaders.boolValue(
          metadata['derived_from_project_agent_binding'],
        );
  }
}
