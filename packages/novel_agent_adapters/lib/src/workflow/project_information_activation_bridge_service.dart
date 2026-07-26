import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/project_information_path_service.dart';
import '../storage/sqlite_design_element_repository.dart';
import '../storage/sqlite_knowledge_card_repository.dart';
import '../storage/sqlite_project_information_record_store.dart';
import '../storage/sqlite_reference_work_repository.dart';
import '../storage/sqlite_research_note_repository.dart';

const _informationPolicyReason = 'information_policy';

class ProjectInformationActivationBridgeService {
  ProjectInformationActivationBridgeService({
    required ProjectWorkspacePort workspacePort,
    SqliteProjectInformationRecordStore? recordStore,
    KnowledgeCardRepository? knowledgeCardRepository,
    DesignElementRepository? designElementRepository,
    ResearchNoteRepository? researchNoteRepository,
    ReferenceWorkRepository? referenceWorkRepository,
    ProjectInformationPathService? pathService,
  }) : _knowledgeCardRepository =
           knowledgeCardRepository ??
           _defaultKnowledgeCardRepository(recordStore),
       _designElementRepository =
           designElementRepository ??
           _defaultDesignElementRepository(recordStore),
       _researchNoteRepository =
           researchNoteRepository ??
           _defaultResearchNoteRepository(recordStore),
       _referenceWorkRepository =
           referenceWorkRepository ??
           _defaultReferenceWorkRepository(recordStore),
       _pathService = pathService ?? ProjectInformationPathService();

  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ReferenceWorkRepository _referenceWorkRepository;
  final ProjectInformationPathService _pathService;

  static KnowledgeCardRepository _defaultKnowledgeCardRepository(
    SqliteProjectInformationRecordStore? recordStore,
  ) {
    return SqliteKnowledgeCardRepository(
      recordStore: recordStore ?? SqliteProjectInformationRecordStore(),
    );
  }

  static DesignElementRepository _defaultDesignElementRepository(
    SqliteProjectInformationRecordStore? recordStore,
  ) {
    return SqliteDesignElementRepository(
      recordStore: recordStore ?? SqliteProjectInformationRecordStore(),
    );
  }

  static ResearchNoteRepository _defaultResearchNoteRepository(
    SqliteProjectInformationRecordStore? recordStore,
  ) {
    return SqliteResearchNoteRepository(
      recordStore: recordStore ?? SqliteProjectInformationRecordStore(),
    );
  }

  static ReferenceWorkRepository _defaultReferenceWorkRepository(
    SqliteProjectInformationRecordStore? recordStore,
  ) {
    return SqliteReferenceWorkRepository(
      recordStore: recordStore ?? SqliteProjectInformationRecordStore(),
    );
  }

  Future<List<ContextActivationItem>> buildItems(
    ProjectDescriptor project, {
    String taskType = 'draft',
  }) async {
    // 中文注释: 这里专门负责把 information 层事实源桥接成 activation candidates，不在 ProjectContextActivationService 里继续堆信息侧装配算法。
    final cleanTaskType = taskType.trim().isEmpty ? 'draft' : taskType.trim();
    final loaded = await Future.wait<Object?>(<Future<Object?>>[
      _knowledgeCardRepository.listKnowledgeCards(project),
      _designElementRepository.listDesignElements(project),
      _researchNoteRepository.listResearchNotes(project),
      _referenceWorkRepository.listReferenceWorks(project),
    ]);
    final knowledgeCards =
        (loaded[0] as List<ProjectKnowledgeCard>).toList(growable: false)..sort(
          (left, right) =>
              left.cardNamespace.compareTo(right.cardNamespace) != 0
              ? left.cardNamespace.compareTo(right.cardNamespace)
              : left.cardId.compareTo(right.cardId),
        );
    final designElements =
        (loaded[1] as List<DesignElementCard>).toList(growable: false)..sort(
          (left, right) =>
              left.designNamespace.compareTo(right.designNamespace) != 0
              ? left.designNamespace.compareTo(right.designNamespace)
              : left.designId.compareTo(right.designId),
        );
    final researchNotes = (loaded[2] as List<ResearchNote>).toList(
      growable: false,
    )..sort((left, right) => left.researchId.compareTo(right.researchId));
    final referenceWorks =
        (loaded[3] as List<ReferenceWorkRecord>).toList(growable: false)..sort(
          (left, right) =>
              left.relationshipToProject.compareTo(
                    right.relationshipToProject,
                  ) !=
                  0
              ? left.relationshipToProject.compareTo(
                  right.relationshipToProject,
                )
              : left.referenceWorkId.compareTo(right.referenceWorkId),
        );
    return <ContextActivationItem>[
      for (final card in knowledgeCards)
        _knowledgeCardItem(card, taskType: cleanTaskType),
      for (final card in designElements)
        _designElementItem(card, taskType: cleanTaskType),
      for (final note in researchNotes)
        _researchNoteItem(note, taskType: cleanTaskType),
      for (final record in referenceWorks)
        _referenceWorkItem(record, taskType: cleanTaskType),
    ];
  }

  ContextActivationItem _knowledgeCardItem(
    ProjectKnowledgeCard card, {
    required String taskType,
  }) {
    // 中文注释: knowledge card 的激活候选需要保留 activation policy、范围 refs 和预算偏好，方便 planner 直接复用既有裁剪逻辑。
    final label = card.title.trim().isEmpty ? card.cardId : card.title.trim();
    final priority = _resolveActivationPriority(
      card.activationPolicy.activationPriority,
      fallback: InformationActivationPriorities.normal,
      metadata: card.metadata,
    );
    final required = _isRequired(priority: priority, metadata: card.metadata);
    final pinned = _isPinned(priority: priority, metadata: card.metadata);
    final activationTextDraft = _applyPreferredBudget(
      _knowledgeCardActivationText(card, priority: priority),
      _preferredBudgetChars(
        card.activationPolicy.preferredBudgetChars,
        card.metadata,
      ),
    );
    final targetPath = _pathService.knowledgeCardLocator(card.cardId);
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: card.cardId,
      title: label,
      refs: card.scopeRefs,
    );
    final requiresExplicitSelection =
        card.activationPolicy.requiresExplicitSelection ||
        _boolFlags(
          card.metadata['requires_explicit_selection'],
          card.metadata['explicit_selection_only'],
        );
    return ContextActivationItem(
      itemId: 'knowledge:${card.cardId}',
      source: 'project_knowledge_card',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        if (refs.isNotEmpty) ContextActivationReasonCodes.ref,
        _informationPolicyReason,
      ],
      reasonDetails: <String, Object?>{
        'task_type': taskType,
        'card_id': card.cardId,
        'card_namespace': card.cardNamespace,
        'card_type': card.cardType,
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'requires_explicit_selection': requiresExplicitSelection,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_knowledge_card',
          requiresExplicitSelection: requiresExplicitSelection,
        ),
      },
      requestedChars: activationTextDraft.activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'project_knowledge_card',
        'card_id': card.cardId,
        'card_namespace': card.cardNamespace,
        'card_type': card.cardType,
        'lifecycle_status': card.lifecycleStatus,
        'confidence': card.confidence,
        'source_of_truth_locator': targetPath,
        'source_display': _sourceDisplayFromRefs(card.sourceRefs),
        'source_refs': _sourceRefsJson(card.sourceRefs),
        'evidence_refs': _evidenceRefsJson(card.evidenceRefs),
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'requires_explicit_selection': requiresExplicitSelection,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_knowledge_card',
          requiresExplicitSelection: requiresExplicitSelection,
        ),
        'activation_text': activationTextDraft.activationText,
        'activation_text_source_chars': activationTextDraft.sourceChars,
        'activation_text_policy_clipped': activationTextDraft.clippedByPolicy,
        'preferred_budget_chars': activationTextDraft.preferredBudgetChars,
      },
    );
  }

  ContextActivationItem _designElementItem(
    DesignElementCard card, {
    required String taskType,
  }) {
    // 中文注释: design element 是一等上下文来源，桥接时要把 linked refs 与 design payload 一起带进 activation report。
    final label = card.designLabel.trim().isEmpty
        ? card.designId
        : card.designLabel.trim();
    final priority = _resolveActivationPriority(
      card.activationPolicy.activationPriority,
      fallback: InformationActivationPriorities.normal,
      metadata: card.metadata,
    );
    final required = _isRequired(priority: priority, metadata: card.metadata);
    final pinned = _isPinned(priority: priority, metadata: card.metadata);
    final activationTextDraft = _applyPreferredBudget(
      _designElementActivationText(card, priority: priority),
      _preferredBudgetChars(
        card.activationPolicy.preferredBudgetChars,
        card.metadata,
      ),
    );
    final targetPath = _pathService.designElementLocator(card.designId);
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: card.designId,
      title: label,
      refs: _dedupeRefs(<NarrativeRef>[...card.scopeRefs, ...card.linkedRefs]),
    );
    final requiresExplicitSelection =
        card.activationPolicy.requiresExplicitSelection ||
        _boolFlags(
          card.metadata['requires_explicit_selection'],
          card.metadata['explicit_selection_only'],
        );
    return ContextActivationItem(
      itemId: 'design:${card.designId}',
      source: 'project_design_element',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        if (refs.isNotEmpty) ContextActivationReasonCodes.ref,
        _informationPolicyReason,
      ],
      reasonDetails: <String, Object?>{
        'task_type': taskType,
        'design_id': card.designId,
        'design_namespace': card.designNamespace,
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'requires_explicit_selection': requiresExplicitSelection,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_design_element',
          requiresExplicitSelection: requiresExplicitSelection,
        ),
      },
      requestedChars: activationTextDraft.activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'project_design_element',
        'design_id': card.designId,
        'design_namespace': card.designNamespace,
        'lifecycle_status': card.lifecycleStatus,
        'confidence': card.confidence,
        'uncertainty': card.uncertainty,
        'source_of_truth_locator': targetPath,
        'source_display': _sourceDisplayFromRefs(card.sourceRefs),
        'source_refs': _sourceRefsJson(card.sourceRefs),
        'evidence_refs': _evidenceRefsJson(card.evidenceRefs),
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'requires_explicit_selection': requiresExplicitSelection,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_design_element',
          requiresExplicitSelection: requiresExplicitSelection,
        ),
        'activation_text': activationTextDraft.activationText,
        'activation_text_source_chars': activationTextDraft.sourceChars,
        'activation_text_policy_clipped': activationTextDraft.clippedByPolicy,
        'preferred_budget_chars': activationTextDraft.preferredBudgetChars,
      },
    );
  }

  ContextActivationItem _researchNoteItem(
    ResearchNote note, {
    required String taskType,
  }) {
    // 中文注释: research note 没有独立 activation policy，因此这里从 usage policy 和 metadata 推导默认优先级，但不引入新的权限判断。
    final label = note.query.trim().isEmpty
        ? note.researchId
        : note.query.trim();
    final priority = _resolveActivationPriority(
      _metadataString(note.metadata, 'activation_priority'),
      fallback: note.usagePolicy.usageMode == InformationUsageModes.normal
          ? InformationActivationPriorities.normal
          : InformationActivationPriorities.reference,
      metadata: note.metadata,
    );
    final required = _isRequired(priority: priority, metadata: note.metadata);
    final pinned = _isPinned(priority: priority, metadata: note.metadata);
    final activationTextDraft = _applyPreferredBudget(
      _researchNoteActivationText(note, priority: priority),
      _preferredBudgetChars(0, note.metadata),
    );
    final targetPath = _pathService.researchNoteLocator(note.researchId);
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: note.researchId,
      title: label,
      refs: note.linkedCards,
    );
    return ContextActivationItem(
      itemId: 'research:${note.researchId}',
      source: 'project_research_note',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        if (refs.isNotEmpty) ContextActivationReasonCodes.ref,
        _informationPolicyReason,
      ],
      reasonDetails: <String, Object?>{
        'task_type': taskType,
        'research_id': note.researchId,
        'source_kind': note.sourceKind,
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_research_note',
          requiresExplicitSelection: false,
        ),
      },
      requestedChars: activationTextDraft.activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'project_research_note',
        'research_id': note.researchId,
        'research_source_kind': note.sourceKind,
        'source_url_or_ref': note.sourceUrlOrRef,
        'citation': note.citation,
        'source_of_truth_locator': targetPath,
        'source_display': _sourceDisplayForResearchNote(note),
        'source_refs': const <JsonMap>[],
        'evidence_refs': const <JsonMap>[],
        'usage_mode': note.usagePolicy.usageMode,
        'citation_risk_level': note.usagePolicy.citationRiskLevel,
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_research_note',
          requiresExplicitSelection: false,
        ),
        'activation_text': activationTextDraft.activationText,
        'activation_text_source_chars': activationTextDraft.sourceChars,
        'activation_text_policy_clipped': activationTextDraft.clippedByPolicy,
        'preferred_budget_chars': activationTextDraft.preferredBudgetChars,
      },
    );
  }

  ContextActivationItem _referenceWorkItem(
    ReferenceWorkRecord record, {
    required String taskType,
  }) {
    // 中文注释: reference work 的核心价值是把引用边界带进 report，因此这里优先保留 relationship、usage intent 和 risk notes。
    final label = record.title.trim().isEmpty
        ? record.referenceWorkId
        : record.title.trim();
    final priority = _resolveActivationPriority(
      _metadataString(record.metadata, 'activation_priority'),
      fallback: InformationActivationPriorities.reference,
      metadata: record.metadata,
    );
    final required = _isRequired(priority: priority, metadata: record.metadata);
    final pinned = _isPinned(priority: priority, metadata: record.metadata);
    final activationTextDraft = _applyPreferredBudget(
      _referenceWorkActivationText(record, priority: priority),
      _preferredBudgetChars(0, record.metadata),
    );
    final targetPath = _pathService.referenceWorkLocator(
      record.referenceWorkId,
    );
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: record.referenceWorkId,
      title: label,
      refs: const <NarrativeRef>[],
    );
    return ContextActivationItem(
      itemId: 'reference:${record.referenceWorkId}',
      source: 'project_reference_work',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.ref,
        _informationPolicyReason,
      ],
      reasonDetails: <String, Object?>{
        'task_type': taskType,
        'reference_work_id': record.referenceWorkId,
        'relationship_to_project': record.relationshipToProject,
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_reference_work',
          requiresExplicitSelection: false,
        ),
      },
      requestedChars: activationTextDraft.activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'project_reference_work',
        'reference_work_id': record.referenceWorkId,
        'relationship_to_project': record.relationshipToProject,
        'declared_usage_intent': record.declaredUsageIntent,
        'requires_confirmation': record.requiresConfirmation,
        'source_of_truth_locator': targetPath,
        'source_display': _sourceDisplayFromRefs(record.sourceRefs),
        'source_refs': _sourceRefsJson(record.sourceRefs),
        'evidence_refs': const <JsonMap>[],
        'activation_priority': priority,
        'required': required,
        'pinned': pinned,
        'priority_weight': _priorityWeightFor(
          priority: priority,
          sourceKind: 'project_reference_work',
          requiresExplicitSelection: false,
        ),
        'activation_text': activationTextDraft.activationText,
        'activation_text_source_chars': activationTextDraft.sourceChars,
        'activation_text_policy_clipped': activationTextDraft.clippedByPolicy,
        'preferred_budget_chars': activationTextDraft.preferredBudgetChars,
      },
    );
  }

  String _knowledgeCardActivationText(
    ProjectKnowledgeCard card, {
    required String priority,
  }) {
    // 中文注释: knowledge activation text 保持可解释但尽量精简，避免把完整事实源正文直接硬塞进上下文预算。
    final lines = <String>[
      '[Knowledge] ${card.title.trim().isEmpty ? card.cardId : card.title.trim()}',
      'card_id: ${card.cardId}',
      'card_namespace: ${card.cardNamespace}',
      'card_type: ${card.cardType}',
      'activation_priority: $priority',
      'lifecycle_status: ${card.lifecycleStatus}',
      'confidence: ${card.confidence}',
    ];
    if (card.summary.trim().isNotEmpty) {
      lines.add('summary: ${card.summary.trim()}');
    }
    if (card.scopeRefs.isNotEmpty) {
      lines
        ..add('scope_refs:')
        ..add(_prettyObject(_refsJson(card.scopeRefs)));
    }
    if (card.sourceRefs.isNotEmpty) {
      lines
        ..add('source_refs:')
        ..add(_prettyObject(_sourceRefsJson(card.sourceRefs)));
    }
    if (card.evidenceRefs.isNotEmpty) {
      lines
        ..add('evidence_refs:')
        ..add(_prettyObject(_evidenceRefsJson(card.evidenceRefs)));
    }
    if (card.sourceRefs.isNotEmpty) {
      lines.add('source_display: ${_sourceDisplayFromRefs(card.sourceRefs)}');
    }
    if (card.contentPayload.isNotEmpty) {
      lines
        ..add('content_payload:')
        ..add(_prettyObject(card.contentPayload));
    }
    return lines.join('\n');
  }

  String _designElementActivationText(
    DesignElementCard card, {
    required String priority,
  }) {
    // 中文注释: design element 的激活文本需要让运行时看到巧思名称、作用域和 linked refs，但不把整份分析报告原样搬运。
    final lines = <String>[
      '[Design] ${card.designLabel.trim().isEmpty ? card.designId : card.designLabel.trim()}',
      'design_id: ${card.designId}',
      'design_namespace: ${card.designNamespace}',
      'activation_priority: $priority',
      'lifecycle_status: ${card.lifecycleStatus}',
      'confidence: ${card.confidence}',
    ];
    if (card.uncertainty.trim().isNotEmpty) {
      lines.add('uncertainty: ${card.uncertainty.trim()}');
    }
    if (card.scopeRefs.isNotEmpty) {
      lines
        ..add('scope_refs:')
        ..add(_prettyObject(_refsJson(card.scopeRefs)));
    }
    if (card.linkedRefs.isNotEmpty) {
      lines
        ..add('linked_refs:')
        ..add(_prettyObject(_refsJson(card.linkedRefs)));
    }
    if (card.sourceRefs.isNotEmpty) {
      lines
        ..add('source_refs:')
        ..add(_prettyObject(_sourceRefsJson(card.sourceRefs)));
    }
    if (card.evidenceRefs.isNotEmpty) {
      lines
        ..add('evidence_refs:')
        ..add(_prettyObject(_evidenceRefsJson(card.evidenceRefs)));
    }
    if (card.sourceRefs.isNotEmpty) {
      lines.add('source_display: ${_sourceDisplayFromRefs(card.sourceRefs)}');
    }
    if (card.designPayload.isNotEmpty) {
      lines
        ..add('design_payload:')
        ..add(_prettyObject(card.designPayload));
    }
    return lines.join('\n');
  }

  String _researchNoteActivationText(
    ResearchNote note, {
    required String priority,
  }) {
    // 中文注释: research note 只保留摘要、事实和引用边界，避免把大段抓取正文重新回灌到 activation 文本里。
    final lines = <String>[
      '[Research] ${note.query.trim().isEmpty ? note.researchId : note.query.trim()}',
      'research_id: ${note.researchId}',
      'source_kind: ${note.sourceKind}',
      'source_url_or_ref: ${note.sourceUrlOrRef}',
      'citation: ${note.citation}',
      'source_display: ${_sourceDisplayForResearchNote(note)}',
      'activation_priority: $priority',
      'usage_mode: ${note.usagePolicy.usageMode}',
      'citation_risk_level: ${note.usagePolicy.citationRiskLevel}',
      'summary: ${note.summary}',
    ];
    if (note.uncertainty.trim().isNotEmpty) {
      lines.add('uncertainty: ${note.uncertainty.trim()}');
    }
    if (note.licenseOrUsageNote.trim().isNotEmpty) {
      lines.add('license_or_usage_note: ${note.licenseOrUsageNote.trim()}');
    }
    if (note.linkedCards.isNotEmpty) {
      lines
        ..add('linked_cards:')
        ..add(_prettyObject(_refsJson(note.linkedCards)));
    }
    if (note.usableFacts.isNotEmpty) {
      lines
        ..add('usable_facts:')
        ..add(_prettyObject(note.usableFacts.take(4).toList(growable: false)));
      if (note.usableFacts.length > 4) {
        lines.add('usable_facts_omitted: ${note.usableFacts.length - 4}');
      }
    }
    if (note.creativeSuggestions.isNotEmpty) {
      lines
        ..add('creative_suggestions:')
        ..add(
          _prettyObject(
            note.creativeSuggestions.take(3).toList(growable: false),
          ),
        );
      if (note.creativeSuggestions.length > 3) {
        lines.add(
          'creative_suggestions_omitted: ${note.creativeSuggestions.length - 3}',
        );
      }
    }
    return lines.join('\n');
  }

  String _referenceWorkActivationText(
    ReferenceWorkRecord record, {
    required String priority,
  }) {
    // 中文注释: reference work 激活文本要优先提醒边界和风险，而不是让正文生成器误把它当普通资料全文。
    final lines = <String>[
      '[Reference Work] ${record.title.trim().isEmpty ? record.referenceWorkId : record.title.trim()}',
      'reference_work_id: ${record.referenceWorkId}',
      'relationship_to_project: ${record.relationshipToProject}',
      'declared_usage_intent: ${record.declaredUsageIntent}',
      'activation_priority: $priority',
      'requires_confirmation: ${record.requiresConfirmation}',
    ];
    if (record.creator.trim().isNotEmpty) {
      lines.add('creator: ${record.creator.trim()}');
    }
    if (record.version.trim().isNotEmpty) {
      lines.add('version: ${record.version.trim()}');
    }
    if (record.allowedUsageSummary.trim().isNotEmpty) {
      lines.add('allowed_usage_summary: ${record.allowedUsageSummary.trim()}');
    }
    if (record.sourceRefs.isNotEmpty) {
      lines.add('source_display: ${_sourceDisplayFromRefs(record.sourceRefs)}');
      lines.add('source_ref_count: ${record.sourceRefs.length}');
    }
    if (record.riskNotes.isNotEmpty) {
      lines
        ..add('risk_notes:')
        ..add(_prettyObject(record.riskNotes.take(4).toList(growable: false)));
      if (record.riskNotes.length > 4) {
        lines.add('risk_notes_omitted: ${record.riskNotes.length - 4}');
      }
    }
    return lines.join('\n');
  }

  String _resolveActivationPriority(
    String candidate, {
    required String fallback,
    required JsonMap metadata,
  }) {
    // 中文注释: research/reference 没有强制 activation policy 合同，这里允许 metadata 覆盖但仍回落到稳定默认值。
    final direct = candidate.trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final fromMetadata = _metadataString(metadata, 'activation_priority');
    if (fromMetadata.isNotEmpty) {
      return fromMetadata;
    }
    return fallback;
  }

  bool _isRequired({required String priority, required JsonMap metadata}) {
    // 中文注释: required 只表达上下文注入优先级，不代替 permission policy 的审批语义。
    return priority == InformationActivationPriorities.required ||
        _boolFlags(
          metadata['required'],
          metadata['is_required'],
          metadata['activation_required'],
        );
  }

  bool _isPinned({required String priority, required JsonMap metadata}) {
    // 中文注释: pinned 优先接受正式 activation priority，其次兼容 metadata 中已有的 pin 标记。
    return priority == InformationActivationPriorities.pinned ||
        _boolFlags(
          metadata['pinned'],
          metadata['pin'],
          metadata['activation_pinned'],
        );
  }

  int _preferredBudgetChars(int candidate, JsonMap metadata) {
    // 中文注释: 优先走正式 activation policy，research/reference 再兼容 metadata 中的预算提示。
    final normalized = candidate < 0 ? 0 : candidate;
    if (normalized > 0) {
      return normalized;
    }
    return _readInt(
      metadata['preferred_budget_chars'],
      metadata['activation_preferred_budget_chars'],
    );
  }

  int _priorityWeightFor({
    required String priority,
    required String sourceKind,
    required bool requiresExplicitSelection,
  }) {
    // 中文注释: planner 继续掌管排序算法，这里只提供 information 候选的稳定显式权重，避免把 source-specific 逻辑塞回主服务。
    final sourceBase = switch (sourceKind) {
      'project_design_element' => 340,
      'project_knowledge_card' => 300,
      'project_research_note' => 180,
      'project_reference_work' => 140,
      _ => 100,
    };
    final priorityBonus = switch (priority) {
      InformationActivationPriorities.required => 600,
      InformationActivationPriorities.pinned => 420,
      InformationActivationPriorities.normal => 240,
      InformationActivationPriorities.reference => 120,
      InformationActivationPriorities.background => 0,
      _ => 160,
    };
    final explicitPenalty = requiresExplicitSelection ? -80 : 0;
    return sourceBase + priorityBonus + explicitPenalty;
  }

  _ActivationTextDraft _applyPreferredBudget(
    String activationText,
    int preferredBudgetChars,
  ) {
    // 中文注释: 这里的裁剪只是 activation policy 自己声明的理想预算，不替代 report 阶段的最终预算裁剪。
    final normalized = activationText.trim();
    final safePreferred = preferredBudgetChars < 0 ? 0 : preferredBudgetChars;
    if (safePreferred == 0 || normalized.length <= safePreferred) {
      return _ActivationTextDraft(
        activationText: normalized,
        sourceChars: normalized.length,
        preferredBudgetChars: safePreferred,
        clippedByPolicy: false,
      );
    }
    return _ActivationTextDraft(
      activationText: normalized.substring(0, safePreferred),
      sourceChars: normalized.length,
      preferredBudgetChars: safePreferred,
      clippedByPolicy: true,
    );
  }

  List<NarrativeRef> _fallbackRefs({
    required String targetPath,
    required String targetId,
    required String title,
    required List<NarrativeRef> refs,
  }) {
    // 中文注释: information 对象优先沿用 scope/linked refs；如果没有，就回退到自身隐藏事实源文件路径，保证 report 可回指。
    final deduped = _dedupeRefs(refs);
    if (deduped.isNotEmpty) {
      return deduped;
    }
    return <NarrativeRef>[
      NarrativeRef(
        refType: NarrativeRefTypes.asset,
        refId: targetId,
        displayName: title,
        relativePath: targetPath,
        sourcePath: targetPath,
      ),
    ];
  }

  List<NarrativeRef> _dedupeRefs(List<NarrativeRef> refs) {
    // 中文注释: activation report 只需要稳定回指，不应因为 refs 重复而虚增权重。
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

  List<JsonMap> _refsJson(List<NarrativeRef> refs) {
    // 中文注释: refs 在 activation 文本中只作为可解释结构输出，不参与额外语义加工。
    return refs.map((ref) => ref.toJson()).toList(growable: false);
  }

  List<JsonMap> _sourceRefsJson(List<InformationSourceRef> refs) {
    // 中文注释: source refs 保留 authority 与来源姿态，便于 report 解释“这条信息从哪来”。
    return refs
        .map((ref) => ref.toJson())
        .take(4)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
  }

  List<JsonMap> _evidenceRefsJson(List<NarrativeEvidenceRef> refs) {
    return refs
        .take(4)
        .map((ref) => ValueReaders.deepCopyMap(ref.toJson()))
        .toList(growable: false);
  }

  String _sourceDisplayFromRefs(List<InformationSourceRef> refs) {
    final labels = refs
        .map((ref) => _sourceIdentityDisplay(ref.sourceIdentity))
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return labels.isEmpty ? '未记录来源身份' : labels.join('；');
  }

  String _sourceDisplayForResearchNote(ResearchNote note) {
    final citation = note.citation.trim();
    if (citation.isNotEmpty) {
      return citation;
    }
    final sourceRef = note.sourceUrlOrRef.trim();
    if (sourceRef.isNotEmpty) {
      return sourceRef;
    }
    return note.sourceKind.trim().isEmpty ? '未记录研究来源' : note.sourceKind;
  }

  String _sourceIdentityDisplay(SourceAssetIdentity identity) {
    final displayName = identity.displayName.trim();
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final sourceAssetId = identity.sourceAssetId.trim();
    if (sourceAssetId.isNotEmpty) {
      return sourceAssetId;
    }
    final resolverUri = identity.resolverUri.trim();
    if (resolverUri.isNotEmpty) {
      return resolverUri;
    }
    final localHintPath = identity.localHintPath.trim();
    if (localHintPath.isNotEmpty) {
      return localHintPath;
    }
    return identity.sourceKind.trim();
  }

  String _metadataString(JsonMap metadata, String key) {
    // 中文注释: metadata 是开放合同，这里只做轻量读取，不强行定义第二套正式 schema。
    final direct = ValueReaders.stringValue(metadata[key]).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    final nestedPolicy = ValueReaders.mapValue(metadata['activation_policy']);
    return ValueReaders.stringValue(nestedPolicy[key]).trim();
  }

  int _readInt(Object? first, [Object? second]) {
    // 中文注释: 兼容开放 metadata 里的字符串/数字写法，避免 bridge 对历史记录过于脆弱。
    for (final candidate in <Object?>[first, second]) {
      if (candidate == null) {
        continue;
      }
      if (candidate is num) {
        return candidate.round();
      }
      final text = candidate.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
      final parsedDouble = double.tryParse(text);
      if (parsedDouble != null) {
        return parsedDouble.round();
      }
    }
    return 0;
  }

  bool _boolFlags(Object? first, Object? second, [Object? third]) {
    // 中文注释: 信息层历史记录可能混用几个布尔命名，这里统一兼容读取，减少桥接层的格式脆弱性。
    return ValueReaders.boolValue(first) ||
        ValueReaders.boolValue(second) ||
        ValueReaders.boolValue(third);
  }

  String _prettyObject(Object? value) {
    // 中文注释: activation 文本需要稳定可读，因此统一使用缩进 JSON，而不是散落手写拼接格式。
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

class _ActivationTextDraft {
  const _ActivationTextDraft({
    required this.activationText,
    required this.sourceChars,
    required this.preferredBudgetChars,
    required this.clippedByPolicy,
  });

  final String activationText;
  final int sourceChars;
  final int preferredBudgetChars;
  final bool clippedByPolicy;
}
