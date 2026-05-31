import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_group_member_role_service.dart';
import 'agent_member_directory_service.dart';
import 'agent_orchestration_service.dart';
import 'agent_profile.dart';
import 'agent_profile_mapper_service.dart';
import 'resolved_agent_group_member_profile.dart';
import 'resolved_agent_group_profile.dart';

class ResolvedAgentGroupProfileBuilderService {
  ResolvedAgentGroupProfileBuilderService({
    AgentMemberDirectoryService? memberDirectoryService,
    AgentOrchestrationService? orchestrationService,
    AgentGroupMemberRoleService? memberRoleService,
    AgentProfileMapperService? profileMapperService,
  }) : _memberDirectoryService =
           memberDirectoryService ?? AgentMemberDirectoryService(),
       _orchestrationService =
           orchestrationService ?? AgentOrchestrationService(),
       _memberRoleService =
           memberRoleService ?? const AgentGroupMemberRoleService(),
       _profileMapperService =
           profileMapperService ?? const AgentProfileMapperService();

  final AgentMemberDirectoryService _memberDirectoryService;
  final AgentOrchestrationService _orchestrationService;
  final AgentGroupMemberRoleService _memberRoleService;
  final AgentProfileMapperService _profileMapperService;

  ResolvedAgentGroupProfile buildFromDocument(
    JsonMap groupDocument,
    List<AgentProfile> availableAgents,
  ) {
    // 中文注释: 这里把轻量 group 声明与强类型 agent profile 合成为正式运行对象，供后续 availability 和 runtime 层直接消费。
    final memberDirectory = _memberDirectoryService.agentsById(
      availableAgents
          .map(_profileMapperService.toDocument)
          .cast<Object?>()
          .toList(growable: false),
    );
    final memberAgentIds = ValueReaders.stringList(groupDocument['agents'])
        .where((agentId) => memberDirectory.containsKey(agentId))
        .toList(growable: false);
    final primaryAgentId = _memberRoleService.resolvePrimaryAgentId(
      groupDocument,
      memberAgentIds,
    );
    final members = <ResolvedAgentGroupMemberProfile>[];
    for (final agentId in memberAgentIds) {
      final agentDocument = ValueReaders.mapValue(memberDirectory[agentId]);
      if (agentDocument.isEmpty) {
        continue;
      }
      final profile = _profileMapperService.fromDocument(agentDocument);
      members.add(
        ResolvedAgentGroupMemberProfile(
          profile: profile,
          isPrimary: _memberRoleService.isPrimaryMember(
            agentId,
            primaryAgentId: primaryAgentId,
          ),
          isRequired: _memberRoleService.isRequiredMember(
            groupDocument,
            agentId,
            primaryAgentId: primaryAgentId,
          ),
        ),
      );
    }
    final groupId = ValueReaders.stringValue(groupDocument['id']).trim();
    return ResolvedAgentGroupProfile(
      id: groupId,
      name: ValueReaders.stringValue(
        groupDocument['name'],
        groupId.isEmpty ? '未命名智能体组' : groupId,
      ).trim(),
      description: ValueReaders.stringValue(
        groupDocument['description'],
      ).trim(),
      orchestration: _orchestrationService.normalizeOrchestration(
        ValueReaders.stringValue(groupDocument['orchestration'], 'supervised'),
      ),
      members: List<ResolvedAgentGroupMemberProfile>.unmodifiable(members),
      source: ValueReaders.stringValue(
        groupDocument['source'],
        'builtin',
      ).trim(),
      enabled: ValueReaders.boolValue(groupDocument['enabled'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(groupDocument['metadata']),
      ),
    );
  }

  ResolvedAgentGroupProfile buildFromDocuments(
    JsonMap groupDocument,
    List<Object?> availableAgentDocuments,
  ) {
    // 中文注释: 这里保留 document 级入口，让现有 map-based 运行链可以逐步迁移，而不要求调用方先完成 profile 强类型化。
    final profiles = availableAgentDocuments
        .map(ValueReaders.mapValue)
        .where((document) => document.isNotEmpty)
        .map(_profileMapperService.fromDocument)
        .toList(growable: false);
    return buildFromDocument(groupDocument, profiles);
  }
}
