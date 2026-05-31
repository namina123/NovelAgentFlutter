import 'agent_availability_assessment.dart';
import 'agent_group_availability_assessment.dart';
import 'project_agent_binding.dart';
import 'project_agent_binding_resolver_service.dart';
import 'project_agent_group_candidate_resolution.dart';
import 'project_agent_group_selection.dart';
import 'project_agent_group_selection_resolver_service.dart';
import 'resolved_agent_group_profile.dart';
import 'single_agent_group_adapter_service.dart';

class ProjectAgentGroupCandidateResolverService {
  ProjectAgentGroupCandidateResolverService({
    ProjectAgentGroupSelectionResolverService? groupSelectionResolverService,
    ProjectAgentBindingResolverService? agentBindingResolverService,
    SingleAgentGroupAdapterService? singleAgentGroupAdapterService,
  }) : _groupSelectionResolverService =
           groupSelectionResolverService ??
           const ProjectAgentGroupSelectionResolverService(),
       _agentBindingResolverService =
           agentBindingResolverService ??
           const ProjectAgentBindingResolverService(),
       _singleAgentGroupAdapterService =
           singleAgentGroupAdapterService ?? SingleAgentGroupAdapterService();

  final ProjectAgentGroupSelectionResolverService
  _groupSelectionResolverService;
  final ProjectAgentBindingResolverService _agentBindingResolverService;
  final SingleAgentGroupAdapterService _singleAgentGroupAdapterService;

  ProjectAgentGroupCandidateResolution resolve({
    required List<ProjectAgentGroupSelection> groupSelections,
    required List<AgentGroupAvailabilityAssessment> groupAssessments,
    required List<ProjectAgentBinding> agentBindings,
    required List<AgentAvailabilityAssessment> agentAssessments,
    String modeId = '',
    String stageId = '',
  }) {
    // 中文注释: 项目级候选解析优先尊重显式 group 绑定；如果项目仍只有 agent 绑定，则退化为单成员组候选，避免旧项目断流。
    final preferredSelection = _groupSelectionResolverService
        .resolvePreferredSelection(
          groupSelections,
          modeId: modeId,
          stageId: stageId,
        );
    final supportedGroups = groupAssessments
        .where((assessment) => assessment.isSupported)
        .map((assessment) => assessment.group)
        .toList(growable: false);
    if (preferredSelection != null) {
      final currentGroup = _findGroupById(
        preferredSelection.groupId,
        supportedGroups,
      );
      return ProjectAgentGroupCandidateResolution(
        currentSelection: preferredSelection,
        currentGroup: currentGroup,
        defaultGroup:
            currentGroup ??
            (supportedGroups.isEmpty ? null : supportedGroups.first),
      );
    }

    final preferredBinding = _agentBindingResolverService
        .resolvePreferredBinding(
          agentBindings,
          modeId: modeId,
          stageId: stageId,
        );
    if (preferredBinding != null) {
      final supportedAgent = _findSupportedAgentAssessment(
        preferredBinding.agentId,
        agentAssessments,
      );
      if (supportedAgent != null) {
        final derivedGroup = _singleAgentGroupAdapterService.adapt(
          supportedAgent.profile,
          groupId: 'derived_project_agent_${supportedAgent.profile.id}',
          groupName: preferredBinding.displayName.trim().isNotEmpty
              ? preferredBinding.displayName.trim()
              : supportedAgent.profile.name,
          description: '从项目级智能体绑定 ${supportedAgent.profile.id} 自动派生的单成员智能体组。',
          metadata: <String, Object?>{
            'derived_from_project_agent_binding': true,
            'agent_binding_id': preferredBinding.agentId,
          },
        );
        return ProjectAgentGroupCandidateResolution(
          currentGroup: derivedGroup,
          defaultGroup: derivedGroup,
          derivedFromAgentBinding: true,
        );
      }
    }

    return ProjectAgentGroupCandidateResolution(
      defaultGroup: supportedGroups.isEmpty ? null : supportedGroups.first,
    );
  }

  ResolvedAgentGroupProfile? _findGroupById(
    String groupId,
    List<ResolvedAgentGroupProfile> groups,
  ) {
    for (final group in groups) {
      if (group.id == groupId.trim()) {
        return group;
      }
    }
    return null;
  }

  AgentAvailabilityAssessment? _findSupportedAgentAssessment(
    String agentId,
    List<AgentAvailabilityAssessment> assessments,
  ) {
    for (final assessment in assessments) {
      if (assessment.profile.id == agentId.trim() && assessment.isSupported) {
        return assessment;
      }
    }
    return null;
  }
}
