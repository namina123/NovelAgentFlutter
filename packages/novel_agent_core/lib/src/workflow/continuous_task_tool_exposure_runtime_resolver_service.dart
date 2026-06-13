import '../agents/agent_group_tool_capability_scope_service.dart';
import '../agents/agent_task_family.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/tool_strategy_service.dart';
import '../tools/tool_capability_family_catalog_service.dart';
import 'continuous_task_family.dart';
import 'continuous_task_profile.dart';
import 'continuous_task_profile_resolver_service.dart';
import 'continuous_task_tool_exposure_profile_resolver_service.dart';
import 'continuous_task_tool_exposure_runtime_resolution.dart';

class ContinuousTaskToolExposureRuntimeResolverService {
  const ContinuousTaskToolExposureRuntimeResolverService({
    ContinuousTaskProfileResolverService? taskProfileResolverService,
    ContinuousTaskToolExposureProfileResolverService?
    exposureProfileResolverService,
    ToolCapabilityFamilyCatalogService? toolCapabilityFamilyCatalogService,
    ToolStrategyService? toolStrategyService,
    AgentGroupToolCapabilityScopeService? agentGroupToolCapabilityScopeService,
  }) : _taskProfileResolverService =
           taskProfileResolverService ??
           const ContinuousTaskProfileResolverService(),
       _exposureProfileResolverService =
           exposureProfileResolverService ??
           const ContinuousTaskToolExposureProfileResolverService(),
       _toolCapabilityFamilyCatalogService =
           toolCapabilityFamilyCatalogService ??
           const ToolCapabilityFamilyCatalogService(),
       _toolStrategyService =
           toolStrategyService ?? const ToolStrategyService(),
       _agentGroupToolCapabilityScopeService =
           agentGroupToolCapabilityScopeService ??
           const AgentGroupToolCapabilityScopeService();

  final ContinuousTaskProfileResolverService _taskProfileResolverService;
  final ContinuousTaskToolExposureProfileResolverService
  _exposureProfileResolverService;
  final ToolCapabilityFamilyCatalogService _toolCapabilityFamilyCatalogService;
  final ToolStrategyService _toolStrategyService;
  final AgentGroupToolCapabilityScopeService
  _agentGroupToolCapabilityScopeService;

  ContinuousTaskToolExposureRuntimeResolution resolve({
    required List<String> candidateToolIds,
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    JsonMap runtimeContext = const <String, Object?>{},
    String intent = '',
    String explicitTaskFamilyId = '',
    String explicitModeId = '',
    String explicitRunKind = '',
  }) {
    final taskProfile = _resolveTaskProfile(
      selectedCollaborationGroup: selectedCollaborationGroup,
      runtimeContext: runtimeContext,
      intent: intent,
      explicitTaskFamilyId: explicitTaskFamilyId,
      explicitModeId: explicitModeId,
      explicitRunKind: explicitRunKind,
    );
    final exposureProfile = _exposureProfileResolverService
        .resolveForTaskProfile(taskProfile);
    final groupSupportedFamilies = _agentGroupToolCapabilityScopeService
        .resolveSupportedCapabilityFamilyIds(selectedCollaborationGroup);
    final defaultOpenFamilies = _restrictFamilies(
      exposureProfile.defaultOpenFamilyIds,
      groupSupportedFamilies,
    );
    final requiresConfirmationFamilies = _restrictFamilies(
      exposureProfile.requiresConfirmationFamilyIds,
      groupSupportedFamilies,
    );
    final hostOnlyFamilies = _restrictFamilies(
      exposureProfile.hostOrSupervisorOnlyFamilyIds,
      groupSupportedFamilies,
    );
    final defaultOpenToolIds = _toolCapabilityFamilyCatalogService
        .toolIdsForFamilies(defaultOpenFamilies);
    final requiresConfirmationToolIds = _toolCapabilityFamilyCatalogService
        .toolIdsForFamilies(requiresConfirmationFamilies);
    final defaultCandidateToolIds = resolveDefaultCandidateToolIds(
      selectedCollaborationGroup: selectedCollaborationGroup,
      runtimeContext: runtimeContext,
      intent: intent,
      explicitTaskFamilyId: explicitTaskFamilyId,
      explicitModeId: explicitModeId,
      explicitRunKind: explicitRunKind,
      taskProfile: taskProfile,
    );
    final effectiveToolIds = candidateToolIds.isEmpty
        ? _filterCandidateToolIds(defaultCandidateToolIds, defaultOpenToolIds)
        : _filterCandidateToolIds(candidateToolIds, defaultOpenToolIds);
    return ContinuousTaskToolExposureRuntimeResolution(
      taskProfile: taskProfile,
      exposureProfile: exposureProfile,
      groupSupportedCapabilityFamilyIds: groupSupportedFamilies,
      defaultOpenCapabilityFamilyIds: defaultOpenFamilies,
      requiresConfirmationCapabilityFamilyIds: requiresConfirmationFamilies,
      hostOrSupervisorOnlyCapabilityFamilyIds: hostOnlyFamilies,
      defaultAllowedToolIds: effectiveToolIds,
      requiresConfirmationToolIds: requiresConfirmationToolIds,
      metadata: <String, Object?>{
        'intent': intent.trim(),
        'selected_group_id': ValueReaders.stringValue(
          selectedCollaborationGroup['id'],
        ),
      },
    );
  }

  List<String> resolveDefaultCandidateToolIds({
    JsonMap selectedCollaborationGroup = const <String, Object?>{},
    JsonMap runtimeContext = const <String, Object?>{},
    String intent = '',
    String explicitTaskFamilyId = '',
    String explicitModeId = '',
    String explicitRunKind = '',
    ContinuousTaskProfile? taskProfile,
  }) {
    final resolvedTaskProfile =
        taskProfile ??
        _resolveTaskProfile(
          selectedCollaborationGroup: selectedCollaborationGroup,
          runtimeContext: runtimeContext,
          intent: intent,
          explicitTaskFamilyId: explicitTaskFamilyId,
          explicitModeId: explicitModeId,
          explicitRunKind: explicitRunKind,
        );
    final base = _toolStrategyService.enabledToolIds(
      _toolStrategyService.defaultSettings(),
    );
    final preferred = _preferredDefaultCandidateToolIds(
      taskProfile: resolvedTaskProfile,
      runtimeContext: runtimeContext,
    );
    final result = <String>[];
    for (final toolId in preferred) {
      if ((base.contains(toolId) ||
              _allowPreferredToolEvenWhenDisabled(
                taskProfile: resolvedTaskProfile,
                toolId: toolId,
              )) &&
          !result.contains(toolId)) {
        result.add(toolId);
      }
    }
    for (final toolId in base) {
      if (!result.contains(toolId)) {
        result.add(toolId);
      }
    }
    return _pruneUnsafeDefaultCandidateToolIds(
      taskProfile: resolvedTaskProfile,
      runtimeContext: runtimeContext,
      toolIds: result,
    );
  }

  bool _allowPreferredToolEvenWhenDisabled({
    required ContinuousTaskProfile taskProfile,
    required String toolId,
  }) {
    // 中文注释: 研究整编态需要显式暴露“受控研究请求”入口；真正联网是否执行仍由信息权限策略决定。
    return taskProfile.familyId ==
            ContinuousTaskFamilies.researchConsolidation &&
        toolId == 'request_external_research';
  }

  ContinuousTaskProfile _resolveTaskProfile({
    required JsonMap selectedCollaborationGroup,
    required JsonMap runtimeContext,
    required String intent,
    required String explicitTaskFamilyId,
    required String explicitModeId,
    required String explicitRunKind,
  }) {
    final familyId = _taskFamilyId(
      selectedCollaborationGroup: selectedCollaborationGroup,
      runtimeContext: runtimeContext,
      intent: intent,
      explicitTaskFamilyId: explicitTaskFamilyId,
    );
    final modeId = explicitModeId.trim().isNotEmpty
        ? explicitModeId.trim()
        : ValueReaders.stringValue(
            runtimeContext['mode_id'],
            ValueReaders.stringValue(runtimeContext['mode']),
          ).trim();
    final metadata = <String, Object?>{
      'source_contract': 'continuous_task_tool_exposure_runtime_context',
      if (intent.trim().isNotEmpty) 'intent': intent.trim(),
      if (ValueReaders.stringValue(
        selectedCollaborationGroup['id'],
      ).trim().isNotEmpty)
        'selected_group_id': ValueReaders.stringValue(
          selectedCollaborationGroup['id'],
        ).trim(),
    };
    switch (familyId) {
      case ContinuousTaskFamilies.goalMode:
        return _taskProfileResolverService.forGoalMode(metadata: metadata);
      case ContinuousTaskFamilies.referenceExtraction:
        return _taskProfileResolverService.forReferenceExtraction(
          workflowStrategyId: ValueReaders.stringValue(
            runtimeContext['workflow_strategy_id'],
          ),
          metadata: metadata,
        );
      case ContinuousTaskFamilies.researchConsolidation:
        return _taskProfileResolverService.forResearchConsolidation(
          workflowStrategyId: ValueReaders.stringValue(
            runtimeContext['workflow_strategy_id'],
            'research_consolidation',
          ),
          metadata: metadata,
        );
      case ContinuousTaskFamilies.longFormWriting:
      default:
        return _taskProfileResolverService.forLongTaskMode(
          modeId,
          workflowStrategyId: ValueReaders.stringValue(
            runtimeContext['workflow_strategy_id'],
          ),
          metadata: <String, Object?>{
            ...metadata,
            if (explicitRunKind.trim().isNotEmpty)
              'run_kind_hint': explicitRunKind.trim(),
          },
        );
    }
  }

  String _taskFamilyId({
    required JsonMap selectedCollaborationGroup,
    required JsonMap runtimeContext,
    required String intent,
    required String explicitTaskFamilyId,
  }) {
    final explicit = explicitTaskFamilyId.trim();
    if (explicit.isNotEmpty) {
      return _normalizeTaskFamily(explicit);
    }
    final runtimeFamily = ValueReaders.stringValue(
      runtimeContext['task_family_id'],
      ValueReaders.stringValue(runtimeContext['task_family']),
    ).trim();
    if (runtimeFamily.isNotEmpty) {
      return _normalizeTaskFamily(runtimeFamily);
    }
    final metadata = ValueReaders.mapValue(
      selectedCollaborationGroup['metadata'],
    );
    final runtimeTaskType = ValueReaders.stringValue(
      runtimeContext['task_type'],
      ValueReaders.stringValue(runtimeContext['taskType']),
    ).trim().toLowerCase();
    if (_isResearchTaskType(runtimeTaskType)) {
      return ContinuousTaskFamilies.researchConsolidation;
    }
    final groupFamilies = <String>[
      ...ValueReaders.stringList(selectedCollaborationGroup['task_family_ids']),
      ...ValueReaders.stringList(metadata['task_family_ids']),
    ];
    for (final family in groupFamilies) {
      final normalized = _normalizeTaskFamily(family);
      if (normalized == ContinuousTaskFamilies.referenceExtraction ||
          normalized == ContinuousTaskFamilies.researchConsolidation) {
        return normalized;
      }
    }
    final cleanIntent = intent.trim().toLowerCase();
    if (cleanIntent == 'goal_mode') {
      return ContinuousTaskFamilies.goalMode;
    }
    if (cleanIntent == 'reference_extraction') {
      return ContinuousTaskFamilies.referenceExtraction;
    }
    if (cleanIntent == 'research_consolidation') {
      return ContinuousTaskFamilies.researchConsolidation;
    }
    return ContinuousTaskFamilies.longFormWriting;
  }

  bool _isResearchTaskType(String taskType) {
    return taskType.contains('research') || taskType.contains('information');
  }

  String _normalizeTaskFamily(String value) {
    switch (value.trim()) {
      case AgentTaskFamilies.referenceExtraction:
        return ContinuousTaskFamilies.referenceExtraction;
      case AgentTaskFamilies.research:
        return ContinuousTaskFamilies.researchConsolidation;
      case ContinuousTaskFamilies.goalMode:
        return ContinuousTaskFamilies.goalMode;
      case ContinuousTaskFamilies.longFormWriting:
      default:
        final normalized = value.trim();
        if (normalized == ContinuousTaskFamilies.referenceExtraction ||
            normalized == ContinuousTaskFamilies.researchConsolidation) {
          return normalized;
        }
        return ContinuousTaskFamilies.longFormWriting;
    }
  }

  List<String> _restrictFamilies(
    List<String> exposureFamilies,
    List<String> supportedFamilies,
  ) {
    if (supportedFamilies.isEmpty) {
      return List<String>.from(exposureFamilies);
    }
    return exposureFamilies
        .where((familyId) => supportedFamilies.contains(familyId))
        .toList(growable: false);
  }

  List<String> _filterCandidateToolIds(
    List<String> candidateToolIds,
    List<String> allowedManagedToolIds,
  ) {
    final capabilityManagedToolIds = _toolCapabilityFamilyCatalogService
        .toolIdsForFamilies(_toolCapabilityFamilyCatalogService.familyIds())
        .toSet();
    final allowedManagedSet = allowedManagedToolIds.toSet();
    final result = <String>[];
    final seen = <String>{};
    for (final toolId in candidateToolIds) {
      final cleanToolId = toolId.trim();
      if (cleanToolId.isEmpty || !seen.add(cleanToolId)) {
        continue;
      }
      if (capabilityManagedToolIds.contains(cleanToolId) &&
          !allowedManagedSet.contains(cleanToolId)) {
        continue;
      }
      result.add(cleanToolId);
    }
    return result;
  }

  List<String> _preferredDefaultCandidateToolIds({
    required ContinuousTaskProfile taskProfile,
    required JsonMap runtimeContext,
  }) {
    if (taskProfile.familyId == ContinuousTaskFamilies.researchConsolidation) {
      return const <String>[
        'request_external_research',
        'submit_research_note',
        'propose_knowledge_card',
        'propose_design_element',
        'link_information_evidence',
        'propose_reference_work',
        'read_project_file',
        'list_project_files',
      ];
    }
    if (taskProfile.familyId != ContinuousTaskFamilies.longFormWriting) {
      return const <String>[];
    }
    final taskType = ValueReaders.stringValue(
      runtimeContext['task_type'],
      ValueReaders.stringValue(runtimeContext['taskType']),
    ).trim();
    return switch (taskType) {
      'review' => const <String>[
        'submit_semantic_review',
        'submit_narrative_state_claims',
        'read_project_file',
        'list_project_files',
      ],
      'planning' => const <String>[
        'propose_narrative_profile_update',
        'request_profile_clarification',
        'read_project_file',
        'write_project_file',
        'edit_project_file',
      ],
      'revision' => const <String>[
        'submit_chapter_delivery',
        'submit_narrative_state_claims',
        'read_project_file',
        'edit_project_file',
        'write_project_file',
      ],
      _ => const <String>[
        'submit_chapter_delivery',
        'submit_narrative_state_claims',
        'read_project_file',
        'write_project_file',
        'edit_project_file',
      ],
    };
  }

  List<String> _pruneUnsafeDefaultCandidateToolIds({
    required ContinuousTaskProfile taskProfile,
    required JsonMap runtimeContext,
    required List<String> toolIds,
  }) {
    if (taskProfile.familyId != ContinuousTaskFamilies.longFormWriting) {
      return toolIds;
    }
    final taskType = ValueReaders.stringValue(
      runtimeContext['task_type'],
      ValueReaders.stringValue(runtimeContext['taskType']),
    ).trim();
    if (taskType == 'review') {
      return toolIds
          .where((toolId) {
            if (toolId == 'submit_chapter_delivery' ||
                toolId == 'propose_narrative_profile_update' ||
                toolId == 'propose_constraint_binding' ||
                toolId == 'present_user_options') {
              return false;
            }
            return true;
          })
          .toList(growable: false);
    }
    if (taskType != 'planning') {
      return toolIds;
    }
    final mode = ValueReaders.stringValue(
      runtimeContext['mode_id'],
      ValueReaders.stringValue(runtimeContext['mode']),
    ).trim();
    final runtimeBaselineId = ValueReaders.stringValue(
      runtimeContext['runtime_baseline_id'],
    ).trim();
    return toolIds
        .where((toolId) {
          if (toolId == 'submit_chapter_delivery') {
            return false;
          }
          if (toolId == 'present_user_options' &&
              mode == 'seed_to_full_novel' &&
              runtimeBaselineId == 'continuous_autonomous') {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }
}
