import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectInformationPromotionService {
  ProjectInformationPromotionService({
    required ReferenceEvidenceSubstrate substrate,
    required KnowledgeCardRepository knowledgeCardRepository,
    required DesignElementRepository designElementRepository,
    required ResearchNoteRepository researchNoteRepository,
    required ReferenceWorkRepository referenceWorkRepository,
    ProjectInformationPromotionMapperService? mapperService,
  }) : _substrate = substrate,
       _knowledgeCardRepository = knowledgeCardRepository,
       _designElementRepository = designElementRepository,
       _researchNoteRepository = researchNoteRepository,
       _referenceWorkRepository = referenceWorkRepository,
       _mapperService =
           mapperService ?? const ProjectInformationPromotionMapperService();

  final ReferenceEvidenceSubstrate _substrate;
  final KnowledgeCardRepository _knowledgeCardRepository;
  final DesignElementRepository _designElementRepository;
  final ResearchNoteRepository _researchNoteRepository;
  final ReferenceWorkRepository _referenceWorkRepository;
  final ProjectInformationPromotionMapperService _mapperService;

  Future<ReferencePromotionResult> promote(
    ProjectDescriptor project,
    ReferencePromotionRequest request,
  ) async {
    final snapshot = await _buildSnapshot(project, request);
    if (snapshot == null) {
      return ReferencePromotionResult(
        status: ReferencePromotionStatuses.sourceMissing,
        packageId: request.packageId,
        packageVersionId: request.packageVersionId,
      );
    }
    final existing = await _substrate.readPackageSnapshot(
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
    );
    final merged = existing == null ? snapshot : _merge(existing, snapshot);
    await _substrate.upsertPackageSnapshot(merged);
    return ReferencePromotionResult(
      status: ReferencePromotionStatuses.promoted,
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
      entryId: snapshot.entries.first.entryId,
    );
  }

  Future<ReferencePackageSnapshot?> _buildSnapshot(
    ProjectDescriptor project,
    ReferencePromotionRequest request,
  ) async {
    switch (request.sourceArtifactKind) {
      case ProjectInformationArtifactKinds.knowledgeCard:
        final card = await _knowledgeCardRepository.readKnowledgeCard(
          project,
          cardId: request.sourceArtifactId,
        );
        if (card == null) {
          return null;
        }
        return _mapperService.buildSnapshotForKnowledgeCard(request, card);
      case ProjectInformationArtifactKinds.designElement:
        final card = await _designElementRepository.readDesignElement(
          project,
          designId: request.sourceArtifactId,
        );
        if (card == null) {
          return null;
        }
        return _mapperService.buildSnapshotForDesignElement(request, card);
      case ProjectInformationArtifactKinds.researchNote:
        final note = await _researchNoteRepository.readResearchNote(
          project,
          researchId: request.sourceArtifactId,
        );
        if (note == null) {
          return null;
        }
        return _mapperService.buildSnapshotForResearchNote(request, note);
      case ProjectInformationArtifactKinds.referenceWork:
        final record = await _referenceWorkRepository.readReferenceWork(
          project,
          referenceWorkId: request.sourceArtifactId,
        );
        if (record == null) {
          return null;
        }
        return _mapperService.buildSnapshotForReferenceWork(request, record);
      default:
        return null;
    }
  }

  ReferencePackageSnapshot _merge(
    ReferencePackageSnapshot existing,
    ReferencePackageSnapshot incoming,
  ) {
    final entries = <String, ReferenceEntryRecord>{
      for (final entry in existing.entries) entry.entryId: entry,
      for (final entry in incoming.entries) entry.entryId: entry,
    };
    final promotions = <String, ReferencePromotionRecord>{
      for (final item in existing.promotionRecords) item.promotionId: item,
      for (final item in incoming.promotionRecords) item.promotionId: item,
    };
    final dependencies = <String, ReferenceDependencyRecord>{
      for (final item in existing.dependencies)
        '${item.packageVersionId}:${item.dependencyPackageId}:${item.dependencyVersionId}':
            item,
      for (final item in incoming.dependencies)
        '${item.packageVersionId}:${item.dependencyPackageId}:${item.dependencyVersionId}':
            item,
    };
    return ReferencePackageSnapshot(
      packageRecord: incoming.packageRecord,
      packageVersionRecord: incoming.packageVersionRecord,
      entries: entries.values.toList(growable: false),
      dependencies: dependencies.values.toList(growable: false),
      promotionRecords: promotions.values.toList(growable: false),
    );
  }
}
