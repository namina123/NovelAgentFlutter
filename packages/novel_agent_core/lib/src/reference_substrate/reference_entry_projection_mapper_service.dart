import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../information/design_element_card.dart';
import '../information/information_policy_constants.dart';
import '../information/information_projection_draft_bundle.dart';
import '../information/information_source_ref.dart';
import '../information/project_knowledge_card.dart';
import '../information/reference_work_record.dart';
import '../information/research_note.dart';
import 'reference_package_models.dart';
import 'reference_substrate_constants.dart';

class ReferenceEntryProjectionMapperService {
  const ReferenceEntryProjectionMapperService();

  InformationProjectionDraftBundle buildDraftBundle({
    required ReferencePackageRecord packageRecord,
    required ReferencePackageVersionRecord packageVersionRecord,
    required List<ReferenceEntryRecord> entries,
  }) {
    final knowledgeCards = <ProjectKnowledgeCard>[];
    final designElements = <DesignElementCard>[];
    final researchNotes = <ResearchNote>[];
    final referenceWorks = <ReferenceWorkRecord>[];

    for (final entry in entries) {
      switch (entry.entryKind) {
        case ReferenceEntryKinds.designElement:
        case ReferenceEntryKinds.styleTechnique:
        case ReferenceEntryKinds.divergenceSnapshot:
          designElements.add(
            _buildDesignElement(packageRecord, packageVersionRecord, entry),
          );
          break;
        case ReferenceEntryKinds.researchNote:
          researchNotes.add(
            _buildResearchNote(packageRecord, packageVersionRecord, entry),
          );
          break;
        case ReferenceEntryKinds.referenceWorkBoundary:
          referenceWorks.add(
            _buildReferenceWork(packageRecord, packageVersionRecord, entry),
          );
          break;
        default:
          knowledgeCards.add(
            _buildKnowledgeCard(packageRecord, packageVersionRecord, entry),
          );
          break;
      }
    }

    return InformationProjectionDraftBundle(
      projectionId:
          'reference_projection:${packageRecord.packageId}:${packageVersionRecord.packageVersionId}',
      relativePath:
          'knowledge/reference_projection_${packageRecord.packageId}_${packageVersionRecord.packageVersionId}.md',
      knowledgeCardDrafts: knowledgeCards,
      designElementDrafts: designElements,
      researchNoteDrafts: researchNotes,
      referenceWorkDrafts: referenceWorks,
    );
  }

  ProjectKnowledgeCard _buildKnowledgeCard(
    ReferencePackageRecord packageRecord,
    ReferencePackageVersionRecord versionRecord,
    ReferenceEntryRecord entry,
  ) {
    return ProjectKnowledgeCard(
      cardId: 'ref_${entry.entryId}',
      cardNamespace: entry.entryNamespace,
      cardType: entry.entryKind,
      title: entry.title,
      summary: entry.summary,
      contentPayload: ValueReaders.deepCopyMap(entry.payload),
      sourceRefs: _mergedSources(packageRecord, versionRecord, entry),
      activationPolicy: entry.activationPolicy,
      usagePolicy: entry.usagePolicy,
      confidence: entry.confidence,
      lifecycleStatus: entry.lifecycleStatus,
      metadata: _projectAssetMetadata(
        packageRecord: packageRecord,
        versionRecord: versionRecord,
        entry: entry,
      ),
    );
  }

  DesignElementCard _buildDesignElement(
    ReferencePackageRecord packageRecord,
    ReferencePackageVersionRecord versionRecord,
    ReferenceEntryRecord entry,
  ) {
    return DesignElementCard(
      designId: 'ref_${entry.entryId}',
      designNamespace: entry.entryNamespace,
      designLabel: entry.title,
      designPayload: ValueReaders.deepCopyMap(entry.payload),
      sourceRefs: _mergedSources(packageRecord, versionRecord, entry),
      activationPolicy: entry.activationPolicy,
      usagePolicy: entry.usagePolicy,
      confidence: entry.confidence,
      uncertainty: entry.summary,
      lifecycleStatus: entry.lifecycleStatus,
      metadata: _projectAssetMetadata(
        packageRecord: packageRecord,
        versionRecord: versionRecord,
        entry: entry,
      ),
    );
  }

  ResearchNote _buildResearchNote(
    ReferencePackageRecord packageRecord,
    ReferencePackageVersionRecord versionRecord,
    ReferenceEntryRecord entry,
  ) {
    return ResearchNote(
      researchId: 'ref_${entry.entryId}',
      query: entry.title,
      sourceKind: 'reference_substrate',
      sourceUrlOrRef:
          '${packageRecord.packageId}/${versionRecord.packageVersionId}/${entry.entryId}',
      citation: entry.summary,
      summary: entry.summary,
      usableFacts: ValueReaders.deepCopyList(
        ValueReaders.objectList(entry.payload['usable_facts']),
      ),
      creativeSuggestions: ValueReaders.deepCopyList(
        ValueReaders.objectList(entry.payload['creative_suggestions']),
      ),
      uncertainty: ValueReaders.stringValue(
        entry.payload['uncertainty'],
      ).trim(),
      licenseOrUsageNote: packageRecord.licenseSummary,
      createdBy: versionRecord.createdBy.isEmpty
          ? 'reference_substrate'
          : versionRecord.createdBy,
      linkedCards: const [],
      usagePolicy: entry.usagePolicy,
      metadata: _projectAssetMetadata(
        packageRecord: packageRecord,
        versionRecord: versionRecord,
        entry: entry,
      ),
    );
  }

  ReferenceWorkRecord _buildReferenceWork(
    ReferencePackageRecord packageRecord,
    ReferencePackageVersionRecord versionRecord,
    ReferenceEntryRecord entry,
  ) {
    return ReferenceWorkRecord(
      referenceWorkId: 'ref_${entry.entryId}',
      title: entry.title,
      creator: ValueReaders.stringValue(entry.payload['creator']).trim(),
      version: ValueReaders.stringValue(entry.payload['version']).trim(),
      sourceRefs: _mergedSources(packageRecord, versionRecord, entry),
      relationshipToProject: ValueReaders.stringValue(
        entry.payload['relationship_to_project'],
        packageRecord.packageKind,
      ).trim(),
      declaredUsageIntent: ValueReaders.stringValue(
        entry.payload['declared_usage_intent'],
        entry.summary,
      ).trim(),
      allowedUsageSummary: packageRecord.licenseSummary,
      riskNotes: ValueReaders.deepCopyList(
        ValueReaders.objectList(entry.payload['risk_notes']),
      ),
      requiresConfirmation: entry.usagePolicy.requiresConfirmation,
      metadata: _projectAssetMetadata(
        packageRecord: packageRecord,
        versionRecord: versionRecord,
        entry: entry,
      ),
    );
  }

  List<InformationSourceRef> _mergedSources(
    ReferencePackageRecord packageRecord,
    ReferencePackageVersionRecord versionRecord,
    ReferenceEntryRecord entry,
  ) {
    return <InformationSourceRef>[
      InformationSourceRef(
        sourceRef: NarrativeSourceRef(
          sourceType: 'reference_substrate_entry',
          sourceId:
              '${packageRecord.packageId}:${versionRecord.packageVersionId}:${entry.entryId}',
          label: packageRecord.displayName,
          sourceAssetId:
              '${packageRecord.packageId}:${versionRecord.packageVersionId}:${entry.entryId}',
          displayName: packageRecord.displayName,
          sourceKind: 'reference_substrate_entry',
          resolverUri:
              'reference-entry://${packageRecord.packageId}/${versionRecord.packageVersionId}/${entry.entryId}',
          description: entry.title,
        ),
        sourceAuthority: InformationSourceAuthorities.externalResearched,
        roleAuthority: InformationRoleAuthorities.architect,
        researchDepth: InformationResearchDepths.standard,
        metadata: <String, Object?>{
          'reference_package_id': packageRecord.packageId,
          'reference_package_version_id': versionRecord.packageVersionId,
          'reference_entry_id': entry.entryId,
        },
      ),
      ...entry.sourceRefs,
    ];
  }

  JsonMap _projectAssetMetadata({
    required ReferencePackageRecord packageRecord,
    required ReferencePackageVersionRecord versionRecord,
    required ReferenceEntryRecord entry,
  }) {
    // 中文注释: 这里把项目资料、项目资料挂载和参考资产库的统一文案写进元数据，便于 projection / summary / probe 共用同一套口径。
    final state = _projectVisibilityStateOf(entry.lifecycleStatus);
    return <String, Object?>{
      ...entry.metadata,
      'reference_package_id': packageRecord.packageId,
      'reference_package_version_id': versionRecord.packageVersionId,
      'reference_entry_id': entry.entryId,
      'project_surface_label': '项目资料',
      'project_mount_label': '项目资料挂载',
      'reference_library_label': '参考资产库',
      'project_visibility_state': state.id,
      'project_visibility_state_label': state.label,
      'project_visibility_state_detail': state.detail,
    };
  }

  _ProjectVisibilityStateProfile _projectVisibilityStateOf(
    String lifecycleStatus,
  ) {
    // 中文注释: 生命周期这里仅做轻量状态映射，不把 reference 条目重新塞回一套新的重型状态机。
    final normalized = lifecycleStatus.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'draft' ||
        normalized == 'staged' ||
        normalized == 'working') {
      return const _ProjectVisibilityStateProfile(
        id: 'project_private_draft',
        label: '项目私有草稿资产',
        detail: '当前只在项目内使用，尚未进入审核或提升流程。',
      );
    }
    if (normalized == 'proposed' ||
        normalized == 'pending_review' ||
        normalized == 'under_review' ||
        normalized == 'review' ||
        normalized == 'reviewing') {
      return const _ProjectVisibilityStateProfile(
        id: 'pending_review',
        label: '待审核资产',
        detail: '已进入审核路径，但还不宜直接作为正式资产对外提升。',
      );
    }
    if (normalized == 'accepted' ||
        normalized == 'active' ||
        normalized == 'confirmed' ||
        normalized == 'published' ||
        normalized == 'finalized' ||
        normalized == 'promoted') {
      return const _ProjectVisibilityStateProfile(
        id: 'promotable_formal',
        label: '可提升到参考资产库的正式资产',
        detail: '已具备对外提升或正式挂载的成熟状态。',
      );
    }
    return _ProjectVisibilityStateProfile(
      id: normalized.isEmpty ? 'project_private_draft' : normalized,
      label: '项目私有草稿资产',
      detail: '状态不在已知映射中时，默认先按项目私有草稿资产处理。',
    );
  }
}

class _ProjectVisibilityStateProfile {
  const _ProjectVisibilityStateProfile({
    required this.id,
    required this.label,
    required this.detail,
  });

  final String id;
  final String label;
  final String detail;
}
