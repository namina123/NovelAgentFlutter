import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionNarrativePersistenceService {
  BookDeconstructionNarrativePersistenceService({
    required ProjectWorkspacePort workspacePort,
    OpenNarrativeStatePathService? pathService,
    ProjectInformationPathService? informationPathService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    LocalNarrativeClaimRepository? claimRepository,
    LocalSemanticReviewRepository? reviewRepository,
    LocalKnowledgeCardRepository? knowledgeCardRepository,
    LocalDesignElementRepository? designElementRepository,
    LocalResearchNoteRepository? researchNoteRepository,
    LocalReferenceWorkRepository? referenceWorkRepository,
    OpenNarrativeStateProjectionWriterService? projectionWriterService,
    ProjectInformationProjectionWriterService?
    informationProjectionWriterService,
  }) : _pathService = pathService ?? OpenNarrativeStatePathService(),
       _informationPathService =
           informationPathService ?? ProjectInformationPathService(),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _profileCodecService = const NarrativeProfileCodecService(),
       _claimRepository =
           claimRepository ??
           LocalNarrativeClaimRepository(workspacePort: workspacePort),
       _reviewRepository =
           reviewRepository ??
           LocalSemanticReviewRepository(workspacePort: workspacePort),
       _knowledgeCardRepository =
           knowledgeCardRepository ??
           LocalKnowledgeCardRepository(workspacePort: workspacePort),
       _designElementRepository =
           designElementRepository ??
           LocalDesignElementRepository(workspacePort: workspacePort),
       _researchNoteRepository =
           researchNoteRepository ??
           LocalResearchNoteRepository(workspacePort: workspacePort),
       _referenceWorkRepository =
           referenceWorkRepository ??
           LocalReferenceWorkRepository(workspacePort: workspacePort),
       _projectionWriterService =
           projectionWriterService ??
           OpenNarrativeStateProjectionWriterService(
             workspacePort: workspacePort,
             profileRepository: LocalNarrativeProfileRepository(
               workspacePort: workspacePort,
             ),
             claimRepository:
                 claimRepository ??
                 LocalNarrativeClaimRepository(workspacePort: workspacePort),
             ledgerRepository: LocalNarrativeLedgerRepository(
               workspacePort: workspacePort,
             ),
             reviewRepository:
                 reviewRepository ??
                 LocalSemanticReviewRepository(workspacePort: workspacePort),
             bindingRepository: LocalConstraintBindingRepository(
               workspacePort: workspacePort,
             ),
           ),
       _informationProjectionWriterService =
           informationProjectionWriterService ??
           ProjectInformationProjectionWriterService(
             workspacePort: workspacePort,
             knowledgeCardRepository:
                 knowledgeCardRepository ??
                 LocalKnowledgeCardRepository(workspacePort: workspacePort),
             designElementRepository:
                 designElementRepository ??
                 LocalDesignElementRepository(workspacePort: workspacePort),
             researchNoteRepository:
                 researchNoteRepository ??
                 LocalResearchNoteRepository(workspacePort: workspacePort),
             referenceWorkRepository:
                 referenceWorkRepository ??
                 LocalReferenceWorkRepository(workspacePort: workspacePort),
           );

  final OpenNarrativeStatePathService _pathService;
  final ProjectInformationPathService _informationPathService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final NarrativeProfileCodecService _profileCodecService;
  final LocalNarrativeClaimRepository _claimRepository;
  final LocalSemanticReviewRepository _reviewRepository;
  final LocalKnowledgeCardRepository _knowledgeCardRepository;
  final LocalDesignElementRepository _designElementRepository;
  final LocalResearchNoteRepository _researchNoteRepository;
  final LocalReferenceWorkRepository _referenceWorkRepository;
  final OpenNarrativeStateProjectionWriterService _projectionWriterService;
  final ProjectInformationProjectionWriterService
  _informationProjectionWriterService;

  Future<List<String>> persist({
    required ProjectDescriptor project,
    required BookDeconstructionNarrativeArtifactBundle narrativeArtifacts,
  }) async {
    final changedPaths = <String>[];
    for (final claim in narrativeArtifacts.claims) {
      await _claimRepository.appendClaim(project, claim);
    }
    if (narrativeArtifacts.claims.isNotEmpty) {
      changedPaths.add(_pathService.claimsLogPath());
    }
    for (final proposal in narrativeArtifacts.profileProposals) {
      await _recordDocumentService.writeIndexedRecord(
        rootPath: project.rootPath,
        recordPath: _pathService.profileProposalPath(proposal.proposalId),
        document: <String, Object?>{
          'proposal': _profileCodecService.proposalToJson(proposal),
          'persisted_by': 'book_deconstruction_analysis_bridge',
          'persisted_at': 'ons_37',
        },
        indexPath: _pathService.profileProposalsIndexPath(),
        fieldName: 'proposal_ids',
        recordId: proposal.proposalId,
      );
      changedPaths
        ..add(_pathService.profileProposalPath(proposal.proposalId))
        ..add(_pathService.profileProposalsIndexPath());
    }
    for (final review in narrativeArtifacts.semanticReviews) {
      await _reviewRepository.appendReview(project, review);
      changedPaths
        ..add(_pathService.reviewPath(review.reviewId))
        ..add(_pathService.reviewsIndexPath());
    }
    for (final card in narrativeArtifacts.knowledgeCards) {
      await _knowledgeCardRepository.appendKnowledgeCard(project, card);
      changedPaths
        ..add(_informationPathService.knowledgeCardPath(card.cardId))
        ..add(_informationPathService.knowledgeCardsIndexPath());
    }
    for (final card in narrativeArtifacts.designElements) {
      await _designElementRepository.appendDesignElement(project, card);
      changedPaths
        ..add(_informationPathService.designElementPath(card.designId))
        ..add(_informationPathService.designElementsIndexPath());
    }
    for (final note in narrativeArtifacts.researchNotes) {
      await _researchNoteRepository.appendResearchNote(project, note);
      changedPaths
        ..add(_informationPathService.researchNotePath(note.researchId))
        ..add(_informationPathService.researchNotesIndexPath());
    }
    for (final record in narrativeArtifacts.referenceWorks) {
      await _referenceWorkRepository.appendReferenceWork(project, record);
      changedPaths
        ..add(_informationPathService.referenceWorkPath(record.referenceWorkId))
        ..add(_informationPathService.referenceWorksIndexPath());
    }
    if (narrativeArtifacts.isEmpty) {
      return changedPaths;
    }
    if (_hasNarrativeArtifacts(narrativeArtifacts)) {
      final documents = await _projectionWriterService.writeProjection(project);
      changedPaths.addAll(documents.map((document) => document.relativePath));
    }
    if (_hasInformationArtifacts(narrativeArtifacts)) {
      final documents = await _informationProjectionWriterService
          .writeProjection(project);
      changedPaths.addAll(documents.map((document) => document.relativePath));
    }
    return changedPaths.toSet().toList(growable: false);
  }

  bool _hasNarrativeArtifacts(
    BookDeconstructionNarrativeArtifactBundle narrativeArtifacts,
  ) {
    return narrativeArtifacts.claims.isNotEmpty ||
        narrativeArtifacts.profileProposals.isNotEmpty ||
        narrativeArtifacts.semanticReviews.isNotEmpty;
  }

  bool _hasInformationArtifacts(
    BookDeconstructionNarrativeArtifactBundle narrativeArtifacts,
  ) {
    return narrativeArtifacts.knowledgeCards.isNotEmpty ||
        narrativeArtifacts.designElements.isNotEmpty ||
        narrativeArtifacts.researchNotes.isNotEmpty ||
        narrativeArtifacts.referenceWorks.isNotEmpty;
  }
}
