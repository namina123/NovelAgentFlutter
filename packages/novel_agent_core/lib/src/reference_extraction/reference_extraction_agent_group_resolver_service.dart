import '../agents/agent_availability_assessment.dart';
import '../agents/agent_profile.dart';
import '../agents/agent_group_availability_assessment.dart';
import '../agents/agent_task_family.dart';
import '../agents/project_agent_binding.dart';
import '../agents/project_agent_group_candidate_resolution.dart';
import '../agents/project_agent_group_candidate_resolver_service.dart';
import '../agents/project_agent_group_selection.dart';
import '../agents/single_agent_group_adapter_service.dart';
import 'reference_extraction_constants.dart';
import 'reference_extraction_execution_profile.dart';
import 'reference_extraction_group_resolution.dart';
import 'reference_extraction_strategy_profile.dart';
import 'reference_extraction_task_family_support_service.dart';

class ReferenceExtractionAgentGroupResolverService {
  ReferenceExtractionAgentGroupResolverService({
    ProjectAgentGroupCandidateResolverService? candidateResolverService,
    ReferenceExtractionTaskFamilySupportService? supportService,
    SingleAgentGroupAdapterService? singleAgentGroupAdapterService,
  }) : _candidateResolverService =
           candidateResolverService ??
           ProjectAgentGroupCandidateResolverService(),
       _supportService =
           supportService ??
           const ReferenceExtractionTaskFamilySupportService(),
       _singleAgentGroupAdapterService =
           singleAgentGroupAdapterService ?? SingleAgentGroupAdapterService();

  final ProjectAgentGroupCandidateResolverService _candidateResolverService;
  final ReferenceExtractionTaskFamilySupportService _supportService;
  final SingleAgentGroupAdapterService _singleAgentGroupAdapterService;

  ReferenceExtractionGroupResolution resolve({
    required List<ProjectAgentGroupSelection> groupSelections,
    required List<AgentGroupAvailabilityAssessment> groupAssessments,
    required List<ProjectAgentBinding> agentBindings,
    required List<AgentAvailabilityAssessment> agentAssessments,
    String modeId = '',
    String stageId = '',
  }) {
    final candidate = _candidateResolverService.resolve(
      groupSelections: groupSelections,
      groupAssessments: groupAssessments,
      agentBindings: agentBindings,
      agentAssessments: agentAssessments,
      taskFamilyId: AgentTaskFamilies.referenceExtraction,
      modeId: modeId,
      stageId: stageId,
    );
    final selection = candidate.currentSelection;
    if (selection != null && candidate.currentGroup != null) {
      if (selection.taskFamilyIds.contains(
        AgentTaskFamilies.referenceExtraction,
      )) {
        return ReferenceExtractionGroupResolution(
          selectedGroup: candidate.currentGroup!,
          resolutionKind: ReferenceExtractionResolutionKinds.taskFamilyOverride,
          executionProfile: _groupExecutionProfile(),
          selection: selection,
        );
      }
      if (_supportService.supportsReferenceExtraction(
        candidate.currentGroup!,
      )) {
        return ReferenceExtractionGroupResolution(
          selectedGroup: candidate.currentGroup!,
          resolutionKind: ReferenceExtractionResolutionKinds.capableGroup,
          executionProfile: _groupExecutionProfile(),
          selection: selection,
        );
      }
    }

    for (final assessment in groupAssessments) {
      if (!assessment.isSupported) {
        continue;
      }
      if (!_supportService.supportsReferenceExtraction(assessment.group)) {
        continue;
      }
      return ReferenceExtractionGroupResolution(
        selectedGroup: assessment.group,
        resolutionKind: ReferenceExtractionResolutionKinds.capableGroup,
        executionProfile: _groupExecutionProfile(),
      );
    }

    final fallbackProfile = _resolveFallbackProfile(
      candidate,
      agentAssessments,
    );
    if (fallbackProfile == null) {
      throw StateError(
        'No supported agent is available for reference extraction fallback.',
      );
    }
    final fallbackGroup = _singleAgentGroupAdapterService.adapt(
      fallbackProfile,
      groupId: 'reference_extraction_single_${fallbackProfile.id}',
      groupName: '参考资产提取兜底组',
      description: '缺少正式提取组时，为 reference_extraction 任务族生成的受控单智能体兜底组。',
      metadata: <String, Object?>{
        'task_family_ids': <String>[AgentTaskFamilies.referenceExtraction],
        'reference_extraction_fallback': true,
      },
    );
    return ReferenceExtractionGroupResolution(
      selectedGroup: fallbackGroup,
      resolutionKind: ReferenceExtractionResolutionKinds.singleAgentFallback,
      executionProfile: const ReferenceExtractionExecutionProfile(
        taskFamilyId: AgentTaskFamilies.referenceExtraction,
        executionMode: ReferenceExtractionExecutionModes.singleAgentFallback,
        instructionProfileId: ReferenceExtractionPromptProfiles.singleAgent,
        toolPermissionProfileId:
            ReferenceExtractionToolPermissionProfiles.standard,
        requiresReviewer: true,
        strategyProfile: ReferenceExtractionStrategyProfiles.standard,
      ),
    );
  }

  ReferenceExtractionExecutionProfile _groupExecutionProfile() {
    return const ReferenceExtractionExecutionProfile(
      taskFamilyId: AgentTaskFamilies.referenceExtraction,
      executionMode: ReferenceExtractionExecutionModes.group,
      instructionProfileId: ReferenceExtractionPromptProfiles.group,
      toolPermissionProfileId:
          ReferenceExtractionToolPermissionProfiles.standard,
      requiresReviewer: true,
      strategyProfile: ReferenceExtractionStrategyProfiles.standard,
    );
  }

  AgentProfile? _resolveFallbackProfile(
    ProjectAgentGroupCandidateResolution candidate,
    List<AgentAvailabilityAssessment> agentAssessments,
  ) {
    final group = candidate.currentGroup ?? candidate.defaultGroup;
    final member =
        group?.primaryMember ??
        (group?.members.isEmpty ?? true ? null : group!.members.first);
    if (member != null) {
      return member.profile;
    }
    for (final assessment in agentAssessments) {
      if (assessment.isSupported) {
        return assessment.profile;
      }
    }
    return null;
  }
}
