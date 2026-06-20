import '../common/value_readers.dart';
import '../continuity/narrative_state/narrative_source_ref.dart';
import '../information/design_element_card.dart';
import '../information/information_activation_policy.dart';
import '../information/information_policy_constants.dart';
import '../information/information_source_ref.dart';
import '../information/information_usage_policy.dart';
import '../information/project_knowledge_card.dart';
import '../information/reference_work_record.dart';
import '../information/research_note.dart';
import 'reference_package_models.dart';
import 'reference_projection_models.dart';
import 'reference_substrate_constants.dart';

class ProjectInformationPromotionMapperService {
  const ProjectInformationPromotionMapperService();

  ReferencePackageSnapshot buildSnapshotForKnowledgeCard(
    ReferencePromotionRequest request,
    ProjectKnowledgeCard card,
  ) {
    return _buildSnapshot(
      request: request,
      entryTitle: card.title,
      entrySummary: card.summary,
      entryNamespace: request.targetEntryNamespace.isEmpty
          ? card.cardNamespace
          : request.targetEntryNamespace,
      entryKind: request.targetEntryKind.isEmpty
          ? ReferenceEntryKinds.knowledgeFact
          : request.targetEntryKind,
      payload: card.contentPayload,
      sourceRefs: card.sourceRefs,
      activationPolicy: card.activationPolicy,
      usagePolicy: card.usagePolicy,
      confidence: card.confidence,
      lifecycleStatus: card.lifecycleStatus,
    );
  }

  ReferencePackageSnapshot buildSnapshotForDesignElement(
    ReferencePromotionRequest request,
    DesignElementCard card,
  ) {
    return _buildSnapshot(
      request: request,
      entryTitle: card.designLabel,
      entrySummary: card.uncertainty,
      entryNamespace: request.targetEntryNamespace.isEmpty
          ? card.designNamespace
          : request.targetEntryNamespace,
      entryKind: request.targetEntryKind.isEmpty
          ? ReferenceEntryKinds.designElement
          : request.targetEntryKind,
      payload: card.designPayload,
      sourceRefs: card.sourceRefs,
      activationPolicy: card.activationPolicy,
      usagePolicy: card.usagePolicy,
      confidence: card.confidence,
      lifecycleStatus: card.lifecycleStatus,
    );
  }

  ReferencePackageSnapshot buildSnapshotForResearchNote(
    ReferencePromotionRequest request,
    ResearchNote note,
  ) {
    return _buildSnapshot(
      request: request,
      entryTitle: note.query,
      entrySummary: note.summary,
      entryNamespace: request.targetEntryNamespace.isEmpty
          ? 'research'
          : request.targetEntryNamespace,
      entryKind: request.targetEntryKind.isEmpty
          ? ReferenceEntryKinds.researchNote
          : request.targetEntryKind,
      payload: <String, Object?>{
        'usable_facts': ValueReaders.deepCopyList(note.usableFacts),
        'creative_suggestions': ValueReaders.deepCopyList(
          note.creativeSuggestions,
        ),
        'uncertainty': note.uncertainty,
      },
      sourceRefs: <InformationSourceRef>[
        _projectSourceRef(request),
        ...const <InformationSourceRef>[],
      ],
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.reference,
      ),
      usagePolicy: note.usagePolicy,
      confidence: 0.7,
      lifecycleStatus: 'promoted',
    );
  }

  ReferencePackageSnapshot buildSnapshotForReferenceWork(
    ReferencePromotionRequest request,
    ReferenceWorkRecord record,
  ) {
    return _buildSnapshot(
      request: request,
      entryTitle: record.title,
      entrySummary: record.allowedUsageSummary,
      entryNamespace: request.targetEntryNamespace.isEmpty
          ? 'reference_work'
          : request.targetEntryNamespace,
      entryKind: request.targetEntryKind.isEmpty
          ? ReferenceEntryKinds.referenceWorkBoundary
          : request.targetEntryKind,
      payload: <String, Object?>{
        'creator': record.creator,
        'version': record.version,
        'relationship_to_project': record.relationshipToProject,
        'declared_usage_intent': record.declaredUsageIntent,
        'risk_notes': ValueReaders.deepCopyList(record.riskNotes),
      },
      sourceRefs: <InformationSourceRef>[
        _projectSourceRef(request),
        ...record.sourceRefs,
      ],
      activationPolicy: const InformationActivationPolicy(
        activationPriority: InformationActivationPriorities.reference,
      ),
      usagePolicy: const InformationUsagePolicy(
        usageMode: InformationUsageModes.readOnly,
        citationRiskLevel: InformationCitationRiskLevels.highRisk,
        requiresConfirmation: true,
        allowsDerivativeUse: false,
      ),
      confidence: 0.8,
      lifecycleStatus: 'promoted',
    );
  }

  ReferencePackageSnapshot _buildSnapshot({
    required ReferencePromotionRequest request,
    required String entryTitle,
    required String entrySummary,
    required String entryNamespace,
    required String entryKind,
    required Map<String, Object?> payload,
    required List<InformationSourceRef> sourceRefs,
    required InformationActivationPolicy activationPolicy,
    required InformationUsagePolicy usagePolicy,
    required double confidence,
    required String lifecycleStatus,
  }) {
    final entryId = request.targetEntryId.isEmpty
        ? '${request.sourceArtifactKind}_${request.sourceArtifactId}'
        : request.targetEntryId;
    return ReferencePackageSnapshot(
      packageRecord: ReferencePackageRecord(
        packageId: request.packageId,
        packageKind: request.packageKind,
        displayName: request.displayName,
        packageNamespace: request.packageNamespace,
        latestVersionId: request.packageVersionId,
        lifecycleStatus: 'active',
        createdAt: request.promotedAt,
        updatedAt: request.promotedAt,
      ),
      packageVersionRecord: ReferencePackageVersionRecord(
        packageVersionId: request.packageVersionId,
        packageId: request.packageId,
        versionLabel: request.versionLabel,
        createdAt: request.promotedAt,
        createdBy: request.promotedBy,
      ),
      entries: <ReferenceEntryRecord>[
        ReferenceEntryRecord(
          entryId: entryId,
          packageId: request.packageId,
          packageVersionId: request.packageVersionId,
          entryNamespace: entryNamespace,
          entryKind: entryKind,
          title: entryTitle,
          summary: entrySummary,
          payload: ValueReaders.deepCopyMap(payload),
          sourceRefs: <InformationSourceRef>[
            _projectSourceRef(request),
            ...sourceRefs,
          ],
          activationPolicy: activationPolicy,
          usagePolicy: usagePolicy,
          confidence: confidence,
          lifecycleStatus: lifecycleStatus,
        ),
      ],
      promotionRecords: <ReferencePromotionRecord>[
        ReferencePromotionRecord(
          promotionId:
              '${request.sourceProjectId}_${request.sourceArtifactKind}_${request.sourceArtifactId}_${request.packageVersionId}',
          sourceProjectId: request.sourceProjectId,
          sourceArtifactKind: request.sourceArtifactKind,
          sourceArtifactId: request.sourceArtifactId,
          targetPackageId: request.packageId,
          targetPackageVersionId: request.packageVersionId,
          targetEntryId: entryId,
          promotedAt: request.promotedAt,
          promotedBy: request.promotedBy,
        ),
      ],
    );
  }

  InformationSourceRef _projectSourceRef(ReferencePromotionRequest request) {
    return InformationSourceRef(
      sourceRef: NarrativeSourceRef(
        sourceType: 'project_information_artifact',
        sourceId:
            '${request.sourceProjectId}:${request.sourceArtifactKind}:${request.sourceArtifactId}',
        label: request.displayName,
        sourceAssetId:
            '${request.sourceProjectId}:${request.sourceArtifactKind}:${request.sourceArtifactId}',
        displayName: request.displayName,
        sourceKind: 'project_information_artifact',
        resolverUri:
            'project-information://${request.sourceProjectId}/${request.sourceArtifactKind}/${request.sourceArtifactId}',
      ),
      sourceAuthority: InformationSourceAuthorities.userDeclared,
      roleAuthority: InformationRoleAuthorities.architect,
      researchDepth: InformationResearchDepths.standard,
    );
  }
}
