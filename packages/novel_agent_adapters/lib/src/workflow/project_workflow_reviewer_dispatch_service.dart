import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectWorkflowReviewerDispatchService {
  ProjectWorkflowReviewerDispatchService({
    ReviewerSelectionService? reviewerSelectionService,
    ResolvedAgentGroupProfileBuilderService? groupProfileBuilderService,
    SingleAgentGroupAdapterService? singleAgentGroupAdapterService,
    AgentProfileMapperService? agentProfileMapperService,
  }) : _reviewerSelectionService =
           reviewerSelectionService ?? const ReviewerSelectionService(),
       _groupProfileBuilderService =
           groupProfileBuilderService ??
           ResolvedAgentGroupProfileBuilderService(),
       _singleAgentGroupAdapterService =
           singleAgentGroupAdapterService ?? SingleAgentGroupAdapterService(),
       _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService();

  final ReviewerSelectionService _reviewerSelectionService;
  final ResolvedAgentGroupProfileBuilderService _groupProfileBuilderService;
  final SingleAgentGroupAdapterService _singleAgentGroupAdapterService;
  final AgentProfileMapperService _agentProfileMapperService;

  JsonMap resolve({
    required JsonMap task,
    required JsonMap mainAgent,
    required JsonMap selectedCollaborationGroup,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
  }) {
    if (ValueReaders.stringValue(task['task_type']) != 'review') {
      return const <String, Object?>{
        'applicable': false,
        'review_execution_mode': 'not_review_task',
      };
    }
    final resolvedGroup = _resolveGroup(
      mainAgent: mainAgent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
    );
    if (resolvedGroup == null) {
      return <String, Object?>{
        'applicable': true,
        'review_execution_mode': 'self_review',
        'selection_mode': ReviewerSelectionModes.unavailable,
        'selection_rationale': 'missing_resolved_group',
        'should_delegate': false,
      };
    }
    final selection = _reviewerSelectionService.selectReviewer(resolvedGroup);
    final shouldDelegate = selection.isAvailable && !selection.isSelfReview;
    return <String, Object?>{
      'applicable': true,
      'review_execution_mode': shouldDelegate
          ? 'delegated_child'
          : 'self_review',
      'selection_mode': selection.mode,
      'selection_rationale': selection.rationale,
      'should_delegate': shouldDelegate,
      'agent_id': selection.agentId,
      'agent_name': selection.member?.profile.name ?? '',
      'agent_role': selection.member?.profile.role ?? '',
      'group_id': resolvedGroup.id,
      'group_name': resolvedGroup.name,
      'group_member_ids': resolvedGroup.members
          .map((member) => member.profile.id)
          .toList(growable: false),
      'selected_group': ValueReaders.deepCopyMap(selectedCollaborationGroup),
    };
  }

  ResolvedAgentGroupProfile? _resolveGroup({
    required JsonMap mainAgent,
    required JsonMap selectedCollaborationGroup,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
  }) {
    final groupId = ValueReaders.stringValue(selectedCollaborationGroup['id']);
    if (groupId.trim().isNotEmpty) {
      for (final group in availableGroups) {
        if (ValueReaders.stringValue(group['id']).trim() == groupId.trim()) {
          return _groupProfileBuilderService.buildFromDocuments(
            group,
            availableAgents.cast<Object?>(),
          );
        }
      }
    }
    if (ValueReaders.stringList(selectedCollaborationGroup['agents']).isNotEmpty) {
      return _groupProfileBuilderService.buildFromDocuments(
        selectedCollaborationGroup,
        availableAgents.cast<Object?>(),
      );
    }
    if (availableGroups.length == 1) {
      return _groupProfileBuilderService.buildFromDocuments(
        availableGroups.first,
        availableAgents.cast<Object?>(),
      );
    }
    final fallbackAgent = _fallbackMainAgent(
      mainAgent: mainAgent,
      availableAgents: availableAgents,
    );
    if (fallbackAgent.isEmpty) {
      return null;
    }
    return _singleAgentGroupAdapterService.adapt(
      _agentProfileMapperService.fromDocument(fallbackAgent),
    );
  }

  JsonMap _fallbackMainAgent({
    required JsonMap mainAgent,
    required List<JsonMap> availableAgents,
  }) {
    if (mainAgent.isNotEmpty &&
        ValueReaders.stringValue(mainAgent['id']).trim().isNotEmpty) {
      return ValueReaders.deepCopyMap(mainAgent);
    }
    if (availableAgents.isNotEmpty) {
      return ValueReaders.deepCopyMap(availableAgents.first);
    }
    return const <String, Object?>{};
  }
}
