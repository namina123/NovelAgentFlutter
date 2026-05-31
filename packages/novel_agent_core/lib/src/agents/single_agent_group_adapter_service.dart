import 'agent_orchestration_service.dart';
import 'agent_profile.dart';
import 'resolved_agent_group_member_profile.dart';
import 'resolved_agent_group_profile.dart';

class SingleAgentGroupAdapterService {
  SingleAgentGroupAdapterService({
    AgentOrchestrationService? orchestrationService,
  }) : _orchestrationService =
           orchestrationService ?? AgentOrchestrationService();

  final AgentOrchestrationService _orchestrationService;

  ResolvedAgentGroupProfile adapt(
    AgentProfile profile, {
    String groupId = '',
    String groupName = '',
    String description = '',
    String orchestration = 'main_with_children',
    String source = 'derived_single_agent_group',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    // 中文注释: 单智能体模式统一包装成单成员组，后续项目绑定、适用性过滤和运行入口都不再维护双轨逻辑。
    final resolvedGroupId = groupId.trim().isNotEmpty
        ? groupId.trim()
        : 'single_agent_${profile.id}';
    return ResolvedAgentGroupProfile(
      id: resolvedGroupId,
      name: groupName.trim().isNotEmpty ? groupName.trim() : profile.name,
      description: description.trim().isNotEmpty
          ? description.trim()
          : '由单智能体 ${profile.name} 自动包装得到的单成员智能体组。',
      orchestration: _orchestrationService.normalizeOrchestration(
        orchestration,
      ),
      members: List<ResolvedAgentGroupMemberProfile>.unmodifiable(
        <ResolvedAgentGroupMemberProfile>[
          ResolvedAgentGroupMemberProfile(
            profile: profile,
            isPrimary: true,
            isRequired: true,
          ),
        ],
      ),
      source: source,
      enabled: true,
      metadata: <String, Object?>{
        'derived_from_single_agent': true,
        'agent_id': profile.id,
        ...metadata,
      },
    );
  }
}
