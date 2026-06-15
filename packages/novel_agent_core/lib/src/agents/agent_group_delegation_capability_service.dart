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
    if (ValueReaders.boolValue(metadata['derived_from_single_agent'])) {
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
}
