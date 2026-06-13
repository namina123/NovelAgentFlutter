import '../common/source_asset_identity.dart';
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
      metadata: <String, Object?>{
        ...entry.metadata,
        'reference_package_id': packageRecord.packageId,
        'reference_package_version_id': versionRecord.packageVersionId,
        'reference_entry_id': entry.entryId,
      },
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
      metadata: <String, Object?>{
        ...entry.metadata,
        'reference_package_id': packageRecord.packageId,
        'reference_package_version_id': versionRecord.packageVersionId,
        'reference_entry_id': entry.entryId,
      },
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
      metadata: <String, Object?>{
        ...entry.metadata,
        'reference_package_id': packageRecord.packageId,
        'reference_package_version_id': versionRecord.packageVersionId,
        'reference_entry_id': entry.entryId,
      },
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
      metadata: <String, Object?>{
        ...entry.metadata,
        'reference_package_id': packageRecord.packageId,
        'reference_package_version_id': versionRecord.packageVersionId,
        'reference_entry_id': entry.entryId,
      },
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
}
