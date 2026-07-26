import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/opening_agent_group_summary.dart';
import '../models/opening_agent_member_summary.dart';
import '../models/opening_primary_agent_summary.dart';
import '../models/opening_session_projection.dart';

typedef LoadProjectAgentPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadProjectAgentGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadProjectAgentGroupSelections =
    Future<List<ProjectAgentGroupSelection>> Function(
      ProjectDescriptor project,
    );

class ProjectOpeningSessionProjectionService {
  ProjectOpeningSessionProjectionService({
    required LoadProjectAgentPackages loadAgentPackages,
    required LoadProjectAgentGroups loadAgentGroups,
    required LoadProjectAgentGroupSelections loadProjectAgentGroupSelections,
    AgentProfileNormalizerService? agentProfileNormalizerService,
    AgentProfileMapperService? agentProfileMapperService,
    AgentApplicabilityScopeNormalizerService?
    agentApplicabilityScopeNormalizerService,
    AgentAvailabilityResolverService? agentAvailabilityResolverService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    ResolvedAgentGroupProfileBuilderService?
    resolvedAgentGroupProfileBuilderService,
    AgentGroupApplicabilityScopeNormalizerService?
    agentGroupApplicabilityScopeNormalizerService,
    AgentGroupAvailabilityResolverService?
    agentGroupAvailabilityResolverService,
    ProjectAgentGroupCandidateResolverService?
    projectAgentGroupCandidateResolverService,
    ProjectTraitResolverService? projectTraitResolverService,
    ProjectTypeCatalogService? projectTypeCatalogService,
    AgentProfileCatalogService? agentProfileCatalogService,
    OpeningOrchestrationService? openingOrchestrationService,
  }) : _loadAgentPackages = loadAgentPackages,
       _loadAgentGroups = loadAgentGroups,
       _loadProjectAgentGroupSelections = loadProjectAgentGroupSelections,
       _agentProfileNormalizerService =
           agentProfileNormalizerService ?? AgentProfileNormalizerService(),
       _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService(),
       _agentApplicabilityScopeNormalizerService =
           agentApplicabilityScopeNormalizerService ??
           const AgentApplicabilityScopeNormalizerService(),
       _agentAvailabilityResolverService =
           agentAvailabilityResolverService ??
           AgentAvailabilityResolverService(),
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _resolvedAgentGroupProfileBuilderService =
           resolvedAgentGroupProfileBuilderService ??
           ResolvedAgentGroupProfileBuilderService(),
       _agentGroupApplicabilityScopeNormalizerService =
           agentGroupApplicabilityScopeNormalizerService ??
           const AgentGroupApplicabilityScopeNormalizerService(),
       _agentGroupAvailabilityResolverService =
           agentGroupAvailabilityResolverService ??
           AgentGroupAvailabilityResolverService(),
       _projectAgentGroupCandidateResolverService =
           projectAgentGroupCandidateResolverService ??
           ProjectAgentGroupCandidateResolverService(),
       _projectTraitResolverService =
           projectTraitResolverService ?? ProjectTraitResolverService(),
       _projectTypeCatalogService =
           projectTypeCatalogService ?? const ProjectTypeCatalogService(),
       _agentProfileCatalogService =
           agentProfileCatalogService ?? AgentProfileCatalogService(),
       _openingOrchestrationService =
           openingOrchestrationService ?? OpeningOrchestrationService();

  final LoadProjectAgentPackages _loadAgentPackages;
  final LoadProjectAgentGroups _loadAgentGroups;
  final LoadProjectAgentGroupSelections _loadProjectAgentGroupSelections;
  final AgentProfileNormalizerService _agentProfileNormalizerService;
  final AgentProfileMapperService _agentProfileMapperService;
  final AgentApplicabilityScopeNormalizerService
  _agentApplicabilityScopeNormalizerService;
  final AgentAvailabilityResolverService _agentAvailabilityResolverService;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final ResolvedAgentGroupProfileBuilderService
  _resolvedAgentGroupProfileBuilderService;
  final AgentGroupApplicabilityScopeNormalizerService
  _agentGroupApplicabilityScopeNormalizerService;
  final AgentGroupAvailabilityResolverService
  _agentGroupAvailabilityResolverService;
  final ProjectAgentGroupCandidateResolverService
  _projectAgentGroupCandidateResolverService;
  final ProjectTraitResolverService _projectTraitResolverService;
  final ProjectTypeCatalogService _projectTypeCatalogService;
  final AgentProfileCatalogService _agentProfileCatalogService;
  final OpeningOrchestrationService _openingOrchestrationService;

  Future<OpeningSessionProjection> build({
    required ProjectDescriptor project,
    required ProjectRuntimeProfile? runtimeProfile,
    required ModeGuidanceState? modeGuidanceState,
    String sessionGoalModeId = '',
    String freeTextIntent = '',
    List<ProjectAgentBinding> agentBindings = const <ProjectAgentBinding>[],
  }) async {
    // 中文注释: 这里把 app 当前项目上下文收束成 opening 投影，保证控制器和 view data 只消费稳定结果。
    final normalizedProjectType = _projectTypeCatalogService.normalize(
      project.projectType,
    );
    final runtimeBaselineId = _resolveRuntimeBaselineId(
      project,
      runtimeProfile,
    );
    final modeId = modeGuidanceState?.modeId.trim() ?? '';
    final projectTraits = _projectTraitResolverService.resolve(
      projectTypeId: normalizedProjectType,
      runtimeBaselineId: runtimeBaselineId,
      modeId: modeId,
      additionalTraitIds: project.additionalTraitIds,
    );
    final availabilityContext = AgentAvailabilityContext(
      projectTypeId: normalizedProjectType,
      projectTraits: projectTraits,
      modeId: modeId,
    );
    final agentDocuments = await _loadNormalizedAgentDocuments(project);
    final agentProfiles = agentDocuments
        .map(_agentProfileMapperService.fromDocument)
        .where((profile) => profile.id.trim().isNotEmpty)
        .toList(growable: false);
    final agentAssessments = _buildAgentAssessments(
      agentDocuments: agentDocuments,
      agentProfiles: agentProfiles,
      agentBindings: agentBindings,
      availabilityContext: availabilityContext,
    );
    final groupSelections = await _loadProjectAgentGroupSelections(project);
    final groupAssessments = await _buildGroupAssessments(
      project: project,
      agentProfiles: agentProfiles,
      memberAssessments: agentAssessments,
      availabilityContext: availabilityContext,
    );
    final candidate = _projectAgentGroupCandidateResolverService.resolve(
      groupSelections: groupSelections,
      groupAssessments: groupAssessments,
      agentBindings: agentBindings,
      agentAssessments: agentAssessments,
      modeId: modeId,
    );
    final intent = OpeningIntentSnapshot(
      resolvedAgentGroupId:
          candidate.currentGroup?.id ?? candidate.defaultGroup?.id ?? '',
      availableAgentGroupIds: groupAssessments
          .where((assessment) => assessment.isSupported)
          .map((assessment) => assessment.group.id)
          .toList(growable: false),
      runtimeBaselineId: runtimeBaselineId,
      modeId: modeId,
      sessionGoalModeId: sessionGoalModeId.trim(),
      freeTextIntent: freeTextIntent.trim(),
    );
    final orchestration = _openingOrchestrationService.orchestrate(
      project: project,
      intent: intent,
      modeGuidanceState: modeGuidanceState,
    );
    final currentGroupId = orchestration.state.intent.resolvedAgentGroupId;
    final groupSummaries = groupAssessments
        .map(
          (assessment) =>
              _toGroupSummary(assessment, currentGroupId: currentGroupId),
        )
        .toList(growable: false);
    final currentGroupDisplayName = _resolveCurrentGroupDisplayName(
      currentGroupId: currentGroupId,
      groupSummaries: groupSummaries,
      candidate: candidate,
    );
    final currentPrimaryAgentSummary = _resolveCurrentPrimaryAgentSummary(
      currentGroupId: currentGroupId,
      groupAssessments: groupAssessments,
    );
    final availableAgentSummaries = _resolveAvailableAgentSummaries(
      currentGroupId: currentGroupId,
      groupAssessments: groupAssessments,
    );
    return OpeningSessionProjection(
      projectTypeId: normalizedProjectType,
      currentGroupId: currentGroupId,
      currentGroupDisplayName: currentGroupDisplayName,
      groupSummaries: groupSummaries,
      orchestration: orchestration,
      availableAgentSummaries: availableAgentSummaries,
      currentPrimaryAgentSummary: currentPrimaryAgentSummary,
      derivedFromAgentBinding: candidate.derivedFromAgentBinding,
    );
  }

  Future<List<JsonMap>> _loadNormalizedAgentDocuments(
    ProjectDescriptor project,
  ) async {
    final documents = await _loadAgentPackages(project);
    final normalized = documents
        .map(_agentProfileNormalizerService.normalizeAgentProfile)
        .where(
          (document) => ValueReaders.stringValue(document['id']).isNotEmpty,
        )
        .toList(growable: true);
    final hasDefaultGeneralist = normalized.any(
      (document) =>
          ValueReaders.stringValue(document['id']).trim() ==
          'default_generalist',
    );
    if (!hasDefaultGeneralist) {
      normalized.add(_agentProfileCatalogService.fallbackDefaultAgent());
    }
    return normalized;
  }

  List<AgentAvailabilityAssessment> _buildAgentAssessments({
    required List<JsonMap> agentDocuments,
    required List<AgentProfile> agentProfiles,
    required List<ProjectAgentBinding> agentBindings,
    required AgentAvailabilityContext availabilityContext,
  }) {
    final bindingsById = <String, ProjectAgentBinding>{
      for (final binding in agentBindings) binding.agentId.trim(): binding,
    };
    final documentsById = <String, JsonMap>{
      for (final document in agentDocuments)
        ValueReaders.stringValue(document['id']).trim(): document,
    };
    return agentProfiles
        .map((profile) {
          final rawDocument =
              documentsById[profile.id] ?? const <String, Object?>{};
          final scope = _agentApplicabilityScopeNormalizerService.normalize(
            ValueReaders.mapValue(rawDocument['applicability_scope']),
          );
          return _agentAvailabilityResolverService.resolve(
            profile: profile,
            context: availabilityContext,
            scope: scope,
            binding: bindingsById[profile.id],
          );
        })
        .toList(growable: false);
  }

  Future<List<AgentGroupAvailabilityAssessment>> _buildGroupAssessments({
    required ProjectDescriptor project,
    required List<AgentProfile> agentProfiles,
    required List<AgentAvailabilityAssessment> memberAssessments,
    required AgentAvailabilityContext availabilityContext,
  }) async {
    final documents = await _loadAgentGroups(project);
    return documents
        .map((rawGroup) {
          final normalizedGroup = _agentGroupNormalizerService
              .normalizeAgentGroup(rawGroup);
          final resolvedGroup = _resolvedAgentGroupProfileBuilderService
              .buildFromDocument(normalizedGroup, agentProfiles);
          final scope = _agentGroupApplicabilityScopeNormalizerService
              .normalize(
                ValueReaders.mapValue(rawGroup['applicability_scope']),
              );
          final enrichedGroup = ResolvedAgentGroupProfile(
            id: resolvedGroup.id,
            name: _displayNameOfGroup(rawGroup, fallback: resolvedGroup.name),
            description: ValueReaders.stringValue(
              rawGroup['description'],
              resolvedGroup.description,
            ),
            orchestration: resolvedGroup.orchestration,
            members: resolvedGroup.members,
            source: resolvedGroup.source,
            enabled: resolvedGroup.enabled,
            metadata: resolvedGroup.metadata,
          );
          return _agentGroupAvailabilityResolverService.resolve(
            group: enrichedGroup,
            context: availabilityContext,
            memberAssessments: memberAssessments,
            scope: scope,
          );
        })
        .toList(growable: false);
  }

  OpeningAgentGroupSummary _toGroupSummary(
    AgentGroupAvailabilityAssessment assessment, {
    required String currentGroupId,
  }) {
    return OpeningAgentGroupSummary(
      groupId: assessment.group.id,
      displayName: assessment.group.name,
      description: assessment.group.description,
      isSupported: assessment.isSupported,
      isDegraded: assessment.isDegraded,
      isCurrent: assessment.group.id == currentGroupId.trim(),
      isStarterGroup: ValueReaders.boolValue(
        assessment.group.metadata['starter_group'],
      ),
      reasonCodes: assessment.reasons
          .map((reason) => reason.code.name)
          .toList(growable: false),
      members: assessment.group.members
          .map(
            (member) => OpeningAgentMemberSummary(
              agentId: member.profile.id,
              displayName: member.profile.name,
              role: member.profile.role,
              isPrimary: member.isPrimary,
              thinkingSupported: member.profile.thinkingSupported,
              description: member.profile.description,
            ),
          )
          .toList(growable: false),
    );
  }

  String _resolveCurrentGroupDisplayName({
    required String currentGroupId,
    required List<OpeningAgentGroupSummary> groupSummaries,
    required ProjectAgentGroupCandidateResolution candidate,
  }) {
    for (final summary in groupSummaries) {
      if (summary.groupId == currentGroupId.trim()) {
        return summary.displayName;
      }
    }
    if (candidate.currentGroup != null) {
      return candidate.currentGroup!.name;
    }
    if (candidate.defaultGroup != null) {
      return candidate.defaultGroup!.name;
    }
    return '';
  }

  OpeningPrimaryAgentSummary? _resolveCurrentPrimaryAgentSummary({
    required String currentGroupId,
    required List<AgentGroupAvailabilityAssessment> groupAssessments,
  }) {
    // 中文注释: 当前主智能体摘要必须和当前项目默认组保持一致，避免会话栏再从旧单智能体设置做二次猜测。
    for (final assessment in groupAssessments) {
      if (assessment.group.id != currentGroupId.trim()) {
        continue;
      }
      final primaryMember = assessment.group.primaryMember;
      if (primaryMember == null) {
        return null;
      }
      return OpeningPrimaryAgentSummary(
        agentId: primaryMember.profile.id,
        displayName: primaryMember.profile.name,
        role: primaryMember.profile.role,
        thinkingSupported: primaryMember.profile.thinkingSupported,
      );
    }
    return null;
  }

  List<OpeningAgentMemberSummary> _resolveAvailableAgentSummaries({
    required String currentGroupId,
    required List<AgentGroupAvailabilityAssessment> groupAssessments,
  }) {
    for (final assessment in groupAssessments) {
      if (assessment.group.id != currentGroupId.trim()) {
        continue;
      }
      return assessment.supportedMembers
          .map(
            (member) => OpeningAgentMemberSummary(
              agentId: member.profile.id,
              displayName: member.profile.name,
              role: member.profile.role,
              isPrimary: member.isPrimary,
              thinkingSupported: member.profile.thinkingSupported,
              description: member.profile.description,
            ),
          )
          .toList(growable: false);
    }
    return const <OpeningAgentMemberSummary>[];
  }

  String _resolveRuntimeBaselineId(
    ProjectDescriptor project,
    ProjectRuntimeProfile? runtimeProfile,
  ) {
    final profileBaselineId = runtimeProfile?.runtimeBaselineId.trim() ?? '';
    if (profileBaselineId.isNotEmpty) {
      return profileBaselineId;
    }
    return project.runtimeBaselineId.trim();
  }

  String _displayNameOfGroup(JsonMap rawGroup, {required String fallback}) {
    final displayLabel = ValueReaders.stringValue(rawGroup['display_label']);
    if (displayLabel.trim().isNotEmpty) {
      return displayLabel.trim();
    }
    return fallback;
  }
}
