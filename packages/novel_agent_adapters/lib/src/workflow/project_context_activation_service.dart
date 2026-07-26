import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/local_constraint_binding_repository.dart';
import '../storage/local_narrative_claim_repository.dart';
import '../storage/local_narrative_ledger_repository.dart';
import '../storage/local_narrative_profile_repository.dart';
import '../storage/open_narrative_state_path_service.dart';
import 'project_chapter_continuity_handoff_item_service.dart';
import 'project_chapter_continuity_priority_service.dart';
import 'project_information_activation_bridge_service.dart';
import 'project_narrative_claim_activation_contract_service.dart';
import 'project_relative_path_canonicalizer_service.dart';

class ProjectContextActivationService {
  ProjectContextActivationService({
    required ProjectWorkspacePort workspacePort,
    NarrativeProfileRepository? profileRepository,
    NarrativeClaimRepository? claimRepository,
    NarrativeLedgerRepository? ledgerRepository,
    ConstraintBindingRepository? bindingRepository,
    ProjectContextFileSelectionService? fileSelectionService,
    ContextActivationPlannerService? plannerService,
    OpenNarrativeStatePathService? pathService,
    ProjectNarrativeClaimActivationContractService?
    narrativeClaimActivationContractService,
    ProjectInformationActivationBridgeService?
    informationActivationBridgeService,
    ProjectChapterContinuityHandoffItemService?
    chapterContinuityHandoffItemService,
    ProjectChapterContinuityPriorityService? chapterContinuityPriorityService,
  }) : _workspacePort = workspacePort,
       _profileRepository =
           profileRepository ??
           LocalNarrativeProfileRepository(workspacePort: workspacePort),
       _claimRepository =
           claimRepository ??
           LocalNarrativeClaimRepository(workspacePort: workspacePort),
       _ledgerRepository =
           ledgerRepository ??
           LocalNarrativeLedgerRepository(workspacePort: workspacePort),
       _bindingRepository =
           bindingRepository ??
           LocalConstraintBindingRepository(workspacePort: workspacePort),
       _fileSelectionService =
           fileSelectionService ?? ProjectContextFileSelectionService(),
       _plannerService =
           plannerService ?? const ContextActivationPlannerService(),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _narrativeClaimActivationContractService =
           narrativeClaimActivationContractService ??
           ProjectNarrativeClaimActivationContractService(
             pathService: pathService ?? OpenNarrativeStatePathService(),
           ),
       _informationActivationBridgeService =
           informationActivationBridgeService ??
           ProjectInformationActivationBridgeService(
             workspacePort: workspacePort,
           ),
       _chapterContinuityHandoffItemService =
           chapterContinuityHandoffItemService ??
           const ProjectChapterContinuityHandoffItemService(),
       _chapterContinuityPriorityService =
           chapterContinuityPriorityService ??
           const ProjectChapterContinuityPriorityService(),
       _pathCanonicalizerService =
           const ProjectRelativePathCanonicalizerService();

  final ProjectWorkspacePort _workspacePort;
  final NarrativeProfileRepository _profileRepository;
  final NarrativeClaimRepository _claimRepository;
  final NarrativeLedgerRepository _ledgerRepository;
  final ConstraintBindingRepository _bindingRepository;
  final ProjectContextFileSelectionService _fileSelectionService;
  final ContextActivationPlannerService _plannerService;
  final OpenNarrativeStatePathService _pathService;
  final ProjectNarrativeClaimActivationContractService
  _narrativeClaimActivationContractService;
  final ProjectInformationActivationBridgeService
  _informationActivationBridgeService;
  final ProjectChapterContinuityHandoffItemService
  _chapterContinuityHandoffItemService;
  final ProjectChapterContinuityPriorityService
  _chapterContinuityPriorityService;
  final ProjectRelativePathCanonicalizerService _pathCanonicalizerService;

  Future<ContextActivationPlan> buildPlan({
    required ProjectDescriptor project,
    String taskType = 'draft',
    int budgetChars = 6000,
    int reservedOutputChars = 2000,
    int maxFiles = 12,
    List<String> pinnedRelativePaths = const <String>[],
    String chapterLabel = '',
    String source = 'project_context_activation_adapter',
  }) async {
    final cleanTaskType = taskType.trim().isEmpty ? 'draft' : taskType.trim();
    final pinnedPathSet = pinnedRelativePaths
        .map((path) => path.trim().replaceAll('\\', '/'))
        .where((path) => path.isNotEmpty)
        .toSet();

    final items = <ContextActivationItem>[
      ...await _buildProjectFileItems(
        project: project,
        taskType: cleanTaskType,
        maxFiles: maxFiles,
        pinnedPaths: pinnedPathSet,
        chapterLabel: chapterLabel,
      ),
      ...await _buildProfileItems(project),
      ...await _buildClaimItems(project),
      ...await _buildConstraintItems(project),
      ...await _informationActivationBridgeService.buildItems(
        project,
        taskType: cleanTaskType,
      ),
    ];

    final sourceCounts = _countBySource(items);
    return ContextActivationPlan(
      planId: _planId(project, cleanTaskType),
      source: source,
      taskType: cleanTaskType,
      budgetChars: budgetChars < 0 ? 0 : budgetChars,
      reservedOutputChars: reservedOutputChars < 0 ? 0 : reservedOutputChars,
      items: items,
      summary:
          'project files ${sourceCounts['project_file'] ?? 0}, profiles ${sourceCounts['narrative_profile'] ?? 0}, claims ${sourceCounts['narrative_claim'] ?? 0}, claim submissions ${sourceCounts['narrative_claim_submission'] ?? 0}, constraints ${sourceCounts['narrative_constraint'] ?? 0}, knowledge ${sourceCounts['project_knowledge_card'] ?? 0}, design ${sourceCounts['project_design_element'] ?? 0}, research ${sourceCounts['project_research_note'] ?? 0}, references ${sourceCounts['project_reference_work'] ?? 0}.',
      schemaVersion: '1',
      metadata: <String, Object?>{
        'project_id': project.id,
        'project_name': project.name,
        'task_type': cleanTaskType,
        'chapter_label': chapterLabel.trim(),
        'max_files': maxFiles,
        'pinned_relative_paths': pinnedPathSet.toList()..sort(),
        'candidate_source_counts': sourceCounts,
      },
    );
  }

  Future<ContextActivationReport> buildReport({
    required ProjectDescriptor project,
    String taskType = 'draft',
    int budgetChars = 6000,
    int reservedOutputChars = 2000,
    int maxFiles = 12,
    List<String> pinnedRelativePaths = const <String>[],
    String chapterLabel = '',
    String planSource = 'project_context_activation_adapter',
    String reportSource = 'project_context_activation_adapter',
  }) async {
    final plan = await buildPlan(
      project: project,
      taskType: taskType,
      budgetChars: budgetChars,
      reservedOutputChars: reservedOutputChars,
      maxFiles: maxFiles,
      pinnedRelativePaths: pinnedRelativePaths,
      chapterLabel: chapterLabel,
      source: planSource,
    );
    final plannedTextById = <String, String>{
      for (final item in plan.items)
        item.itemId: ValueReaders.stringValue(item.metadata['activation_text']),
    };
    final rawReport = _plannerService.buildReport(
      plan: plan,
      reportId: _reportId(plan),
      source: reportSource,
    );
    final enrichedItems = rawReport.items
        .map(
          (item) => _enrichReportItem(item, plannedTextById[item.itemId] ?? ''),
        )
        .toList(growable: false);
    return rawReport.copyWith(
      items: enrichedItems,
      summary: _reportSummary(rawReport, enrichedItems),
      metadata: <String, Object?>{
        ...rawReport.metadata,
        'project_id': project.id,
        'project_name': project.name,
        'candidate_source_counts': _countBySource(plan.items),
        'selected_context_sections': _selectionSections(
          enrichedItems.where((item) => item.selected),
        ),
        'omitted_context_sections': _selectionSections(
          enrichedItems.where((item) => item.omitted),
        ),
        'truncated_context_sections': _selectionSections(
          enrichedItems.where((item) => item.truncated),
        ),
      },
    );
  }

  Future<List<ContextActivationItem>> _buildProjectFileItems({
    required ProjectDescriptor project,
    required String taskType,
    required int maxFiles,
    required Set<String> pinnedPaths,
    required String chapterLabel,
  }) async {
    final entries = await _workspacePort.listEntries(project.rootPath);
    final priorityWeights = _chapterContinuityPriorityService
        .buildPriorityWeights(
          entries,
          taskType: taskType,
          chapterLabel: chapterLabel,
        );
    final handoffItems = await _chapterContinuityHandoffItemService.buildItems(
      workspacePort: _workspacePort,
      project: project,
      visibleEntries: entries,
      taskType: taskType,
      chapterLabel: chapterLabel,
    );
    final selectedPaths = _fileSelectionService.select(
      entries,
      maxFiles: maxFiles,
    );
    final selectedPathSet = <String>{...selectedPaths, ...priorityWeights.keys};
    final result = <ContextActivationItem>[];
    for (final path in selectedPathSet) {
      final content = await _workspacePort.readTextFile(project.rootPath, path);
      final normalized = _normalizeContent(content);
      if (normalized.isEmpty) {
        continue;
      }
      final priorityWeight = priorityWeights[path];
      final pinned = pinnedPaths.contains(path) || priorityWeight != null;
      final activationText = _activationTextForPath(path, normalized);
      final title = path.split('/').last;
      result.add(
        ContextActivationItem(
          itemId: 'file:$path',
          source: 'project_file',
          title: title,
          targetPath: path,
          refs: <NarrativeRef>[
            NarrativeRef(
              refType: NarrativeRefTypes.asset,
              refId: path,
              displayName: title,
              relativePath: path,
              sourcePath: path,
            ),
          ],
          activationReasons: <String>[
            if (pinned) ContextActivationReasonCodes.manualPin,
            ContextActivationReasonCodes.taskType,
          ],
          reasonDetails: <String, Object?>{
            'task_type': taskType,
            'relative_path': path,
            'pinned': pinned,
            if (priorityWeight != null) 'weight': priorityWeight,
          },
          requestedChars: activationText.length,
          metadata: <String, Object?>{
            'source_kind': 'project_file',
            'relative_path': path,
            'task_type': taskType,
            'pinned': pinned,
            if (priorityWeight != null) 'weight': priorityWeight,
            'activation_text': activationText,
          },
        ),
      );
    }
    return <ContextActivationItem>[...result, ...handoffItems];
  }

  Future<List<ContextActivationItem>> _buildProfileItems(
    ProjectDescriptor project,
  ) async {
    final profiles = await _profileRepository.listProfiles(project);
    profiles.sort(
      (left, right) =>
          left.profileNamespace.compareTo(right.profileNamespace) != 0
          ? left.profileNamespace.compareTo(right.profileNamespace)
          : left.profileId.compareTo(right.profileId),
    );
    return profiles
        .map((profile) => _profileItem(profile))
        .toList(growable: false);
  }

  Future<List<ContextActivationItem>> _buildClaimItems(
    ProjectDescriptor project,
  ) async {
    // 中文注释: claim 激活候选不再直接把 raw claim log 当正式状态源，而是统一通过 ledger-backed 合同区分正式真相与待裁决提交流。
    final claims = await _claimRepository.listClaims(project);
    final ledgers = await _ledgerRepository.listLedgers(project);
    return _narrativeClaimActivationContractService.buildItems(
      claims: claims,
      ledgers: ledgers,
    );
  }

  Future<List<ContextActivationItem>> _buildConstraintItems(
    ProjectDescriptor project,
  ) async {
    final bindings = await _bindingRepository.listBindings(project);
    bindings.sort(
      (left, right) => left.constraintType.compareTo(right.constraintType) != 0
          ? left.constraintType.compareTo(right.constraintType)
          : left.bindingId.compareTo(right.bindingId),
    );
    return bindings
        .map((binding) => _constraintItem(binding))
        .toList(growable: false);
  }

  ContextActivationItem _profileItem(NarrativeProfile profile) {
    final targetPath = _pathService.profilePath(profile.profileId);
    final label = profile.profileLabel.trim().isEmpty
        ? profile.profileId
        : profile.profileLabel.trim();
    final pinned = _boolFlags(
      profile.metadata['pinned'],
      profile.metadata['pin'],
      profile.profileExtensions['pinned'],
    );
    final required = _boolFlags(
      profile.metadata['required'],
      profile.metadata['is_required'],
      profile.profileExtensions['required'],
    );
    final activationText = _profileActivationText(profile);
    return ContextActivationItem(
      itemId: 'profile:${profile.profileId}',
      source: 'narrative_profile',
      title: label,
      targetPath: targetPath,
      refs: <NarrativeRef>[
        NarrativeRef(
          refType: NarrativeRefTypes.asset,
          refId: profile.profileId,
          displayName: label,
          relativePath: targetPath,
          sourcePath: targetPath,
        ),
      ],
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.profilePolicy,
      ],
      reasonDetails: <String, Object?>{
        'profile_id': profile.profileId,
        'profile_namespace': profile.profileNamespace,
        'required': required,
        'pinned': pinned,
      },
      requestedChars: activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'narrative_profile',
        'profile_id': profile.profileId,
        'profile_namespace': profile.profileNamespace,
        'lifecycle_status': profile.lifecycleStatus.id,
        'activation_text': activationText,
        'required': required,
        'pinned': pinned,
      },
    );
  }

  ContextActivationItem _constraintItem(
    NarrativeConstraintBindingProposal binding,
  ) {
    final targetPath = _pathService.bindingPath(binding.bindingId);
    final label = binding.constraintLabel.trim().isEmpty
        ? binding.bindingId
        : binding.constraintLabel.trim();
    final pinned = _boolFlags(
      binding.metadata['pinned'],
      binding.metadata['pin'],
      binding.policy.metadata['pinned'],
    );
    final required =
        _boolFlags(
          binding.metadata['required'],
          binding.metadata['is_required'],
        ) ||
        binding.policy.requiresUserConfirmation ||
        binding.policy.forbiddenAutoApply;
    final activationText = _constraintActivationText(binding);
    return ContextActivationItem(
      itemId: 'constraint:${binding.bindingId}',
      source: 'narrative_constraint',
      title: label,
      targetPath: targetPath,
      refs: binding.scope.targetRefs.isEmpty
          ? <NarrativeRef>[
              NarrativeRef(
                refType: NarrativeRefTypes.asset,
                refId: binding.bindingId,
                displayName: label,
                relativePath: targetPath,
                sourcePath: targetPath,
              ),
            ]
          : _dedupeRefs(binding.scope.targetRefs),
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.profilePolicy,
      ],
      reasonDetails: <String, Object?>{
        'binding_id': binding.bindingId,
        'constraint_type': binding.constraintType,
        'required': required,
        'pinned': pinned,
      },
      requestedChars: activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'narrative_constraint',
        'binding_id': binding.bindingId,
        'constraint_type': binding.constraintType,
        'requires_user_confirmation': binding.policy.requiresUserConfirmation,
        'forbidden_auto_apply': binding.policy.forbiddenAutoApply,
        'activation_text': activationText,
        'required': required,
        'pinned': pinned,
      },
    );
  }

  ContextActivationItem _enrichReportItem(
    ContextActivationItem item,
    String activationText,
  ) {
    final safeIncludedChars = item.includedChars < 0 ? 0 : item.includedChars;
    final boundedIncludedChars = safeIncludedChars > activationText.length
        ? activationText.length
        : safeIncludedChars;
    final selectedText = boundedIncludedChars == 0
        ? ''
        : activationText.substring(0, boundedIncludedChars);
    final trimmedChars = item.requestedChars - item.includedChars;
    return item.copyWith(
      metadata: <String, Object?>{
        ...item.metadata,
        'activation_text': activationText,
        'selected_text': selectedText,
        'trimmed_chars': trimmedChars < 0 ? 0 : trimmedChars,
        'explanation': _itemExplanation(item),
      },
    );
  }

  List<JsonMap> _selectionSections(Iterable<ContextActivationItem> items) {
    return items
        .map(
          (item) => <String, Object?>{
            'item_id': item.itemId,
            'source': item.source,
            'title': item.title,
            'target_path': item.targetPath,
            'requested_chars': item.requestedChars,
            'included_chars': item.includedChars,
            'selected': item.selected,
            'omitted': item.omitted,
            'truncated': item.truncated,
            'omission_reason': item.omissionReason,
            'truncation_reason': item.truncationReason,
            'selected_text': ValueReaders.stringValue(
              item.metadata['selected_text'],
            ),
            'source_kind': ValueReaders.stringValue(
              item.metadata['source_kind'],
            ),
            'source_of_truth_locator': ValueReaders.stringValue(
              item.metadata['source_of_truth_locator'],
            ),
            'source_display': ValueReaders.stringValue(
              item.metadata['source_display'],
            ),
            'source_refs': ValueReaders.mapList(item.metadata['source_refs']),
            'evidence_refs': ValueReaders.mapList(
              item.metadata['evidence_refs'],
            ),
            'explanation': ValueReaders.stringValue(
              item.metadata['explanation'],
            ),
          },
        )
        .toList(growable: false);
  }

  Map<String, int> _countBySource(Iterable<ContextActivationItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts.update(item.source, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<NarrativeRef> _dedupeRefs(List<NarrativeRef> refs) {
    final seen = <String>{};
    final result = <NarrativeRef>[];
    for (final ref in refs) {
      final key = [
        ref.refType,
        ref.refId,
        ref.relativePath,
        ref.chapterId,
        ref.segmentId,
      ].join('|');
      if (seen.add(key)) {
        result.add(ref);
      }
    }
    return result;
  }

  bool _boolFlags(Object? first, Object? second, [Object? third]) {
    return ValueReaders.boolValue(first) ||
        ValueReaders.boolValue(second) ||
        ValueReaders.boolValue(third);
  }

  String _normalizeContent(String? content) {
    return (content ?? '').trim();
  }

  String _activationTextForPath(String path, String normalizedContent) {
    final normalizedPath = _pathCanonicalizerService
        .canonicalize(path)
        .toLowerCase();
    if (normalizedPath == 'tracking/continuity/bundle.json') {
      // 中文注释: 连续性总包只需要把主线、作用域和机制摘要带进上下文，不必把整份 JSON 原样塞给模型。
      final parsed = _tryParseJson(normalizedContent);
      if (parsed.isNotEmpty) {
        final displayName = ValueReaders.stringValue(
          parsed['display_name'],
          '连续性总包',
        ).trim();
        final defaultFrameId = ValueReaders.stringValue(
          parsed['default_frame_id'],
          'mainline',
        ).trim();
        final defaultMechanicProfileId = ValueReaders.stringValue(
          parsed['default_mechanic_profile_id'],
          'default_general_project',
        ).trim();
        final scopeIds = ValueReaders.stringList(parsed['scope_ids'])
            .where((item) => item.trim().isNotEmpty)
            .take(4)
            .toList(growable: false);
        return [
          '# File: $path',
          '',
          '# Continuity Bundle: $displayName',
          '- 默认主线帧：$defaultFrameId',
          '- 默认机制档：$defaultMechanicProfileId',
          if (scopeIds.isNotEmpty) '- 作用域：${scopeIds.join('、')}',
          '- 这里只保留连续性主线摘要，详细 JSON 另有正式文件可回看。',
        ].join('\n');
      }
    }
    if (normalizedPath.startsWith('tracking/continuity/scopes/') &&
        normalizedPath.endsWith('.json')) {
      // 中文注释: scope 文件只需要暴露当前作用域和父级边界，避免把完整 JSON 重复灌进激活上下文。
      final parsed = _tryParseJson(normalizedContent);
      final scope = ValueReaders.mapValue(parsed['scope']);
      if (scope.isNotEmpty) {
        final displayName = ValueReaders.stringValue(
          scope['display_name'],
          ValueReaders.stringValue(scope['id'], 'scope'),
        ).trim();
        final kind = ValueReaders.stringValue(scope['kind'], 'global').trim();
        final parentScopeId = ValueReaders.stringValue(
          scope['parent_scope_id'],
        ).trim();
        return [
          '# File: $path',
          '',
          '# Continuity Scope: $displayName',
          '- 作用域类型：$kind',
          if (parentScopeId.isNotEmpty) '- 父作用域：$parentScopeId',
          '- 这里只保留作用域摘要，不展开完整结构。',
        ].join('\n');
      }
    }
    if (normalizedPath.startsWith('tracking/continuity/frames/') &&
        normalizedPath.endsWith('.json')) {
      // 中文注释: frame 文件只保留主线、作用域和关系说明，避免完整 JSON 抢走章节上下文预算。
      final parsed = _tryParseJson(normalizedContent);
      final frame = ValueReaders.mapValue(parsed['frame']);
      if (frame.isNotEmpty) {
        final displayName = ValueReaders.stringValue(
          frame['display_name'],
          ValueReaders.stringValue(frame['id'], 'frame'),
        ).trim();
        final scopeId = ValueReaders.stringValue(frame['scope_id'], '').trim();
        final mechanicProfileId = ValueReaders.stringValue(
          frame['mechanic_profile_id'],
          'default_general_project',
        ).trim();
        final relation = ValueReaders.stringValue(
          frame['relation'],
          'sameLine',
        ).trim();
        return [
          '# File: $path',
          '',
          '# Continuity Frame: $displayName',
          '- 所属作用域：$scopeId',
          '- 默认机制档：$mechanicProfileId',
          '- 关系：$relation',
          '- 这里只保留连续性框架摘要，不展开完整结构。',
        ].join('\n');
      }
    }
    return '# File: $path\n\n$normalizedContent';
  }

  JsonMap _tryParseJson(String raw) {
    try {
      return ValueReaders.mapValue(jsonDecode(raw));
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _profileActivationText(NarrativeProfile profile) {
    final lines = <String>[
      '[Profile] ${profile.profileLabel.trim().isEmpty ? profile.profileId : profile.profileLabel.trim()}',
      'profile_id: ${profile.profileId}',
      'profile_namespace: ${profile.profileNamespace}',
      'lifecycle_status: ${profile.lifecycleStatus.id}',
      'confidence: ${profile.confidence}',
    ];
    if (profile.reason.trim().isNotEmpty) {
      lines.add('reason: ${profile.reason.trim()}');
    }
    if (profile.profilePayload.isNotEmpty) {
      lines
        ..add('profile_payload:')
        ..add(_prettyJson(profile.profilePayload));
    }
    if (profile.profileExtensions.isNotEmpty) {
      lines
        ..add('profile_extensions:')
        ..add(_prettyJson(profile.profileExtensions));
    }
    return lines.join('\n');
  }

  String _constraintActivationText(NarrativeConstraintBindingProposal binding) {
    final lines = <String>[
      '[Constraint] ${binding.constraintLabel.trim().isEmpty ? binding.bindingId : binding.constraintLabel.trim()}',
      'binding_id: ${binding.bindingId}',
      'constraint_type: ${binding.constraintType}',
    ];
    if (binding.constraintOrigin.trim().isNotEmpty) {
      lines.add('constraint_origin: ${binding.constraintOrigin.trim()}');
    }
    if (binding.reason.trim().isNotEmpty) {
      lines.add('reason: ${binding.reason.trim()}');
    }
    lines
      ..add('binding_scope:')
      ..add(_prettyJson(binding.scope.toJson()))
      ..add('binding_policy:')
      ..add(_prettyJson(binding.policy.toJson()));
    if (binding.constraintPayload.isNotEmpty) {
      lines
        ..add('constraint_payload:')
        ..add(_prettyJson(binding.constraintPayload));
    }
    return lines.join('\n');
  }

  List<JsonMap> _refsJson(List<NarrativeRef> refs) {
    return refs.map((ref) => ref.toJson()).toList(growable: false);
  }

  String _prettyJson(JsonMap json) => _prettyObject(json);

  String _prettyObject(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  String _planId(ProjectDescriptor project, String taskType) {
    return '${project.id}.${taskType}.context_activation';
  }

  String _reportId(ContextActivationPlan plan) => '${plan.planId}.report';

  String _reportSummary(
    ContextActivationReport report,
    List<ContextActivationItem> items,
  ) {
    final kinds = _countByKind(items);
    return '${report.summary} selected profiles ${kinds['narrative_profile_selected'] ?? 0}, claims ${kinds['narrative_claim_selected'] ?? 0}, claim submissions ${kinds['narrative_claim_submission_selected'] ?? 0}, constraints ${kinds['narrative_constraint_selected'] ?? 0}, files ${kinds['project_file_selected'] ?? 0}, knowledge ${kinds['project_knowledge_card_selected'] ?? 0}, design ${kinds['project_design_element_selected'] ?? 0}, research ${kinds['project_research_note_selected'] ?? 0}, references ${kinds['project_reference_work_selected'] ?? 0}.';
  }

  Map<String, int> _countByKind(List<ContextActivationItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final kind = ValueReaders.stringValue(item.metadata['source_kind']);
      final key =
          '${kind}_${item.selected
              ? 'selected'
              : item.omitted
              ? 'omitted'
              : 'other'}';
      counts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  String _itemExplanation(ContextActivationItem item) {
    if (item.truncated) {
      return 'Selected with ${item.includedChars}/${item.requestedChars} chars because ${item.truncationReason}.';
    }
    if (item.omitted) {
      return 'Omitted because ${item.omissionReason}.';
    }
    return 'Selected with ${item.includedChars}/${item.requestedChars} chars.';
  }
}
