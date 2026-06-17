import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/reviewer_selection.dart';
import '../review/reviewer_selection_service.dart';
import '../tools/tool_strategy_service.dart';
import '../workflow/continuous_task_tool_exposure_runtime_resolution.dart';
import '../workflow/continuous_task_tool_exposure_runtime_resolver_service.dart';
import 'agent_collaboration_contract.dart';
import 'agent_group_delegation_capability_service.dart';
import 'agent_member_directory_service.dart';
import 'agent_profile_mapper_service.dart';
import 'resolved_agent_group_profile.dart';
import 'resolved_agent_group_profile_builder_service.dart';
import 'single_agent_group_adapter_service.dart';

class AgentCollaborationContractService {
  AgentCollaborationContractService({
    ContinuousTaskToolExposureRuntimeResolverService?
    toolExposureResolverService,
    ToolStrategyService? toolStrategyService,
    AgentGroupDelegationCapabilityService? delegationCapabilityService,
    ReviewerSelectionService? reviewerSelectionService,
    ResolvedAgentGroupProfileBuilderService? groupProfileBuilderService,
    SingleAgentGroupAdapterService? singleAgentGroupAdapterService,
    AgentProfileMapperService? agentProfileMapperService,
    AgentMemberDirectoryService? memberDirectoryService,
  }) : _toolExposureResolverService =
           toolExposureResolverService ??
           const ContinuousTaskToolExposureRuntimeResolverService(),
       _toolStrategyService =
           toolStrategyService ?? const ToolStrategyService(),
       _delegationCapabilityService =
           delegationCapabilityService ??
           const AgentGroupDelegationCapabilityService(),
       _reviewerSelectionService =
           reviewerSelectionService ?? const ReviewerSelectionService(),
       _groupProfileBuilderService =
           groupProfileBuilderService ??
           ResolvedAgentGroupProfileBuilderService(
             memberDirectoryService: memberDirectoryService,
             profileMapperService: agentProfileMapperService,
           ),
       _singleAgentGroupAdapterService =
           singleAgentGroupAdapterService ?? SingleAgentGroupAdapterService(),
       _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService();

  final ContinuousTaskToolExposureRuntimeResolverService
  _toolExposureResolverService;
  final ToolStrategyService _toolStrategyService;
  final AgentGroupDelegationCapabilityService _delegationCapabilityService;
  final ReviewerSelectionService _reviewerSelectionService;
  final ResolvedAgentGroupProfileBuilderService _groupProfileBuilderService;
  final SingleAgentGroupAdapterService _singleAgentGroupAdapterService;
  final AgentProfileMapperService _agentProfileMapperService;

  AgentCollaborationContract resolve({
    required List<String> candidateToolIds,
    required JsonMap selectedCollaborationGroup,
    required JsonMap runtimeContext,
    required String intent,
    required JsonMap mainAgent,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
    String explicitTaskFamilyId = '',
    String explicitModeId = '',
    String explicitRunKind = '',
    JsonMap toolSettings = const <String, Object?>{},
  }) {
    final exposureResolution = _toolExposureResolverService.resolve(
      candidateToolIds: candidateToolIds,
      selectedCollaborationGroup: selectedCollaborationGroup,
      runtimeContext: runtimeContext,
      intent: intent,
      explicitTaskFamilyId: explicitTaskFamilyId,
      explicitModeId: explicitModeId,
      explicitRunKind: explicitRunKind,
    );
    final requestOptions = _toolStrategyService.requestOptionsForIntent(
      toolSettings,
      intent,
    );
    // 中文注释: 这里把工具可见性、委派资格和审核分派一次性算成同源合同，供 prompt 和 runtime 共用。
    final toolVisibility = AgentToolVisibilityContract(
      visibleToolIds: exposureResolution.visibleToolIds,
      defaultAllowedToolIds: exposureResolution.defaultAllowedToolIds,
      requiresConfirmationToolIds:
          exposureResolution.requiresConfirmationToolIds,
      interactionHintToolIds: _interactionHintToolIds(
        exposureResolution.visibleToolIds,
        requestOptions,
        exposureResolution,
      ),
      delegationAllowed: exposureResolution.metadata['delegation_allowed']
          as bool? ??
          false,
    );
    final delegation = _resolveDelegation(
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
      mainAgent: mainAgent,
    );
    final reviewer = _resolveReviewer(
      runtimeContext: runtimeContext,
      mainAgent: mainAgent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
      delegation: delegation,
    );
    return AgentCollaborationContract(
      exposureResolution: exposureResolution,
      toolVisibility: toolVisibility,
      delegation: delegation,
      reviewer: reviewer,
    );
  }

  List<String> _interactionHintToolIds(
    List<String> visibleToolIds,
    JsonMap requestOptions,
    ContinuousTaskToolExposureRuntimeResolution exposureResolution,
  ) {
    final result = <String>[];
    if (ValueReaders.stringValue(requestOptions['preferred_tool']) ==
            'present_user_options' &&
        visibleToolIds.contains('present_user_options')) {
      result.add('present_user_options');
    }
    if (exposureResolution.defaultAllowedToolIds.contains('call_sub_agent') &&
        visibleToolIds.contains('call_sub_agent')) {
      result.add('call_sub_agent');
    }
    return List<String>.unmodifiable(result);
  }

  AgentDelegationContract _resolveDelegation({
    required JsonMap selectedCollaborationGroup,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
    required JsonMap mainAgent,
  }) {
    final group = _resolveGroup(
      mainAgent: mainAgent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
    );
    final childAgentIds = group == null
        ? const <String>[]
        : _delegationCapabilityService.childAgentIds(
            _groupDocumentFromResolvedGroup(group),
            availableAgents: availableAgents,
            currentAgentId: ValueReaders.stringValue(mainAgent['id']),
          );
    final allowed = group != null &&
        _delegationCapabilityService.supportsChildDelegation(
          _groupDocumentFromResolvedGroup(group),
          availableAgents: availableAgents,
          currentAgentId: ValueReaders.stringValue(mainAgent['id']),
        );
    return AgentDelegationContract(
      allowed: allowed,
      childAgentIds: childAgentIds,
      primaryAgentId: ValueReaders.stringValue(
        mainAgent['id'],
        ValueReaders.stringValue(group?.primaryMember?.profile.id),
      ).trim(),
      selectedAgentId: '',
      rationale: allowed
          ? 'group_has_child_agents'
          : 'single_agent_or_derived_group',
    );
  }

  AgentReviewerDispatchContract _resolveReviewer({
    required JsonMap runtimeContext,
    required JsonMap mainAgent,
    required JsonMap selectedCollaborationGroup,
    required List<JsonMap> availableAgents,
    required List<JsonMap> availableGroups,
    required AgentDelegationContract delegation,
  }) {
    if (ValueReaders.stringValue(runtimeContext['task_type']) != 'review') {
      return const AgentReviewerDispatchContract(
        applicable: false,
        shouldDelegate: false,
        executionMode: 'not_review_task',
        selectionMode: ReviewerSelectionModes.unavailable,
        selectionRationale: 'not_review_task',
        agentId: '',
        agentName: '',
        agentRole: '',
        groupId: '',
        groupName: '',
        groupMemberIds: <String>[],
      );
    }
    final resolvedGroup = _resolveGroup(
      mainAgent: mainAgent,
      selectedCollaborationGroup: selectedCollaborationGroup,
      availableAgents: availableAgents,
      availableGroups: availableGroups,
    );
    if (resolvedGroup == null) {
      return const AgentReviewerDispatchContract(
        applicable: true,
        shouldDelegate: false,
        executionMode: 'self_review',
        selectionMode: ReviewerSelectionModes.unavailable,
        selectionRationale: 'missing_resolved_group',
        agentId: '',
        agentName: '',
        agentRole: '',
        groupId: '',
        groupName: '',
        groupMemberIds: <String>[],
      );
    }
    final selection = _reviewerSelectionService.selectReviewer(resolvedGroup);
    final shouldDelegate = selection.isAvailable && !selection.isSelfReview;
    return AgentReviewerDispatchContract(
      applicable: true,
      shouldDelegate: shouldDelegate,
      executionMode: shouldDelegate ? 'delegated_child' : 'self_review',
      selectionMode: selection.mode,
      selectionRationale: selection.rationale,
      agentId: selection.agentId,
      agentName: selection.member?.profile.name ?? '',
      agentRole: selection.member?.profile.role ?? '',
      groupId: resolvedGroup.id,
      groupName: resolvedGroup.name,
      groupMemberIds: resolvedGroup.members
          .map((member) => member.profile.id)
          .toList(growable: false),
    );
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

  JsonMap _groupDocumentFromResolvedGroup(
    ResolvedAgentGroupProfile group,
  ) {
    return <String, Object?>{
      'id': ValueReaders.stringValue(group.id),
      'name': ValueReaders.stringValue(group.name),
      'description': ValueReaders.stringValue(group.description),
      'orchestration': ValueReaders.stringValue(group.orchestration),
      'agents': group.members
          .map((member) => member.profile.id)
          .toList(growable: false),
      'metadata': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(group.metadata),
      ),
    };
  }
}
