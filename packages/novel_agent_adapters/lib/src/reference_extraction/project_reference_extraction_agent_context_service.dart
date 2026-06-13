import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_agent_group_binding_repository.dart';

class ProjectReferenceExtractionAgentContextService {
  ProjectReferenceExtractionAgentContextService({
    required Future<List<JsonMap>> Function(ProjectDescriptor project)
    loadAvailableAgents,
    required Future<List<JsonMap>> Function(ProjectDescriptor project)
    loadAvailableGroups,
    required ProjectAgentGroupBindingRepository groupBindingRepository,
    AgentProfileMapperService? agentProfileMapperService,
    ResolvedAgentGroupProfileBuilderService? groupProfileBuilderService,
    AgentAvailabilityResolverService? agentAvailabilityResolverService,
    AgentGroupAvailabilityResolverService? groupAvailabilityResolverService,
    AgentApplicabilityScopeNormalizerService? agentScopeNormalizerService,
    AgentGroupApplicabilityScopeNormalizerService? groupScopeNormalizerService,
    ProjectTraitResolverService? projectTraitResolverService,
    BuiltinCollaboratorCatalogService? collaboratorCatalogService,
  }) : _loadAvailableAgents = loadAvailableAgents,
       _loadAvailableGroups = loadAvailableGroups,
       _groupBindingRepository = groupBindingRepository,
       _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService(),
       _groupProfileBuilderService =
           groupProfileBuilderService ??
           ResolvedAgentGroupProfileBuilderService(),
       _agentAvailabilityResolverService =
           agentAvailabilityResolverService ??
           AgentAvailabilityResolverService(),
       _groupAvailabilityResolverService =
           groupAvailabilityResolverService ??
           AgentGroupAvailabilityResolverService(),
       _agentScopeNormalizerService =
           agentScopeNormalizerService ??
           const AgentApplicabilityScopeNormalizerService(),
       _groupScopeNormalizerService =
           groupScopeNormalizerService ??
           const AgentGroupApplicabilityScopeNormalizerService(),
       _projectTraitResolverService =
           projectTraitResolverService ?? ProjectTraitResolverService(),
       _collaboratorCatalogService =
           collaboratorCatalogService ?? BuiltinCollaboratorCatalogService();

  final Future<List<JsonMap>> Function(ProjectDescriptor project)
  _loadAvailableAgents;
  final Future<List<JsonMap>> Function(ProjectDescriptor project)
  _loadAvailableGroups;
  final ProjectAgentGroupBindingRepository _groupBindingRepository;
  final AgentProfileMapperService _agentProfileMapperService;
  final ResolvedAgentGroupProfileBuilderService _groupProfileBuilderService;
  final AgentAvailabilityResolverService _agentAvailabilityResolverService;
  final AgentGroupAvailabilityResolverService _groupAvailabilityResolverService;
  final AgentApplicabilityScopeNormalizerService _agentScopeNormalizerService;
  final AgentGroupApplicabilityScopeNormalizerService
  _groupScopeNormalizerService;
  final ProjectTraitResolverService _projectTraitResolverService;
  final BuiltinCollaboratorCatalogService _collaboratorCatalogService;

  Future<ProjectReferenceExtractionAgentContext> build(
    ProjectDescriptor project,
  ) async {
    final rawAgents = _mergeEntriesById(
      await _loadAvailableAgents(project),
      _collaboratorCatalogService.optionalCollaboratorProfiles(),
    );
    final rawGroups = _mergeEntriesById(
      await _loadAvailableGroups(project),
      _collaboratorCatalogService.optionalCollaboratorGroups(),
    );
    final selections = await _groupBindingRepository.loadSelections(project);
    final agentProfiles = rawAgents
        .map(_agentProfileMapperService.fromDocument)
        .toList(growable: false);
    final availabilityContext = AgentAvailabilityContext(
      projectTypeId: project.projectType,
      projectTraits: _projectTraitResolverService.resolve(
        projectTypeId: project.projectType,
        runtimeBaselineId: project.runtimeBaselineId,
        modeId: 'book_asset_extraction',
      ),
      // 中文注释: 参考资产提取不是正文写作阶段机的一环，这里只保留稳定 trait，
      // 不强迫通用协作者额外声明 extraction mode/stage 才能作为 fallback 生效。
      stageId: 'draft',
    );
    final agentAssessments = <AgentAvailabilityAssessment>[];
    for (var index = 0; index < rawAgents.length; index += 1) {
      final agentDocument = rawAgents[index];
      agentAssessments.add(
        _agentAvailabilityResolverService.resolve(
          profile: agentProfiles[index],
          context: availabilityContext,
          scope: _agentScopeNormalizerService.normalize(agentDocument),
        ),
      );
    }
    final groupAssessments = <AgentGroupAvailabilityAssessment>[];
    for (final groupDocument in rawGroups) {
      final resolvedGroup = _groupProfileBuilderService.buildFromDocuments(
        groupDocument,
        rawAgents.cast<Object?>(),
      );
      groupAssessments.add(
        _groupAvailabilityResolverService.resolve(
          group: resolvedGroup,
          context: availabilityContext,
          memberAssessments: agentAssessments,
          scope: _groupScopeNormalizerService.normalize(groupDocument),
        ),
      );
    }
    return ProjectReferenceExtractionAgentContext(
      selections: selections,
      agentAssessments: agentAssessments,
      groupAssessments: groupAssessments,
    );
  }

  List<JsonMap> _mergeEntriesById(
    List<JsonMap> primary,
    List<JsonMap> fallback,
  ) {
    final merged = <String, JsonMap>{};
    for (final entry in fallback) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      merged[id] = ValueReaders.deepCopyMap(entry);
    }
    for (final entry in primary) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      merged[id] = ValueReaders.deepCopyMap(entry);
    }
    return merged.values.toList(growable: false);
  }
}

class ProjectReferenceExtractionAgentContext {
  const ProjectReferenceExtractionAgentContext({
    required this.selections,
    required this.agentAssessments,
    required this.groupAssessments,
  });

  final List<ProjectAgentGroupSelection> selections;
  final List<AgentAvailabilityAssessment> agentAssessments;
  final List<AgentGroupAvailabilityAssessment> groupAssessments;
}
