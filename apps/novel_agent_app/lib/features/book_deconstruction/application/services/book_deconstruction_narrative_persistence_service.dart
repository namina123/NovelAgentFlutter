import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_information_persistence_bundle.dart';

class BookDeconstructionNarrativePersistenceService {
  BookDeconstructionNarrativePersistenceService({
    required ProjectWorkspacePort workspacePort,
    OpenNarrativeStatePathService? pathService,
    ProjectInformationPathService? informationPathService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    NarrativeClaimRepository? claimRepository,
    SemanticReviewRepository? reviewRepository,
    KnowledgeCardRepository? knowledgeCardRepository,
    DesignElementRepository? designElementRepository,
    ResearchNoteRepository? researchNoteRepository,
    ReferenceWorkRepository? referenceWorkRepository,
    OpenNarrativeStateProjectionWriterService? projectionWriterService,
    ProjectInformationProjectionWriterService?
    informationProjectionWriterService,
    BookDeconstructionInformationPersistenceBundleFactory?
    informationPersistenceBundleFactory,
  }) : _pathService = pathService ?? OpenNarrativeStatePathService(),
       _informationPathService =
           informationPathService ?? ProjectInformationPathService(),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(
             workspacePort: workspacePort,
           ),
       _profileCodecService = const NarrativeProfileCodecService(),
       _informationPersistenceBundleFactory =
           informationPersistenceBundleFactory ??
           BookDeconstructionInformationPersistenceBundleFactory(
             workspacePort: workspacePort,
           ),
       _claimRepository =
           claimRepository ??
           LocalNarrativeClaimRepository(workspacePort: workspacePort),
       _reviewRepository =
           reviewRepository ??
           LocalSemanticReviewRepository(workspacePort: workspacePort),
       _knowledgeCardRepository = knowledgeCardRepository,
       _designElementRepository = designElementRepository,
       _researchNoteRepository = researchNoteRepository,
       _referenceWorkRepository = referenceWorkRepository,
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
       _informationProjectionWriterService = informationProjectionWriterService;

  final OpenNarrativeStatePathService _pathService;
  final ProjectInformationPathService _informationPathService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final NarrativeProfileCodecService _profileCodecService;
  final BookDeconstructionInformationPersistenceBundleFactory
  _informationPersistenceBundleFactory;
  final NarrativeClaimRepository _claimRepository;
  final SemanticReviewRepository _reviewRepository;
  final KnowledgeCardRepository? _knowledgeCardRepository;
  final DesignElementRepository? _designElementRepository;
  final ResearchNoteRepository? _researchNoteRepository;
  final ReferenceWorkRepository? _referenceWorkRepository;
  final OpenNarrativeStateProjectionWriterService _projectionWriterService;
  final ProjectInformationProjectionWriterService?
  _informationProjectionWriterService;

  Future<List<String>> persist({
    required ProjectDescriptor project,
    required BookDeconstructionNarrativeArtifactBundle narrativeArtifacts,
  }) async {
    final changedPaths = <String>[];
    final informationPersistence = _resolveInformationPersistence(project);
    var wroteClaim = false;
    for (final claim in narrativeArtifacts.claims) {
      final existing = await _claimRepository.readClaim(
        project,
        claimId: claim.claimId,
      );
      if (existing != null && _claimsAreEquivalent(existing, claim)) {
        continue;
      }
      await _claimRepository.appendClaim(project, claim);
      wroteClaim = true;
    }
    if (wroteClaim) {
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
      await informationPersistence.knowledgeCardRepository.appendKnowledgeCard(
        project,
        card,
      );
      changedPaths
        ..add(_informationPathService.knowledgeCardPath(card.cardId))
        ..add(_informationPathService.knowledgeCardsIndexPath());
    }
    for (final card in narrativeArtifacts.designElements) {
      await informationPersistence.designElementRepository.appendDesignElement(
        project,
        card,
      );
      changedPaths
        ..add(_informationPathService.designElementPath(card.designId))
        ..add(_informationPathService.designElementsIndexPath());
    }
    for (final note in narrativeArtifacts.researchNotes) {
      await informationPersistence.researchNoteRepository.appendResearchNote(
        project,
        note,
      );
      changedPaths
        ..add(_informationPathService.researchNotePath(note.researchId))
        ..add(_informationPathService.researchNotesIndexPath());
    }
    for (final record in narrativeArtifacts.referenceWorks) {
      await informationPersistence.referenceWorkRepository.appendReferenceWork(
        project,
        record,
      );
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
      final documents = await informationPersistence.projectionWriterService
          .writeProjection(project);
      changedPaths.addAll(documents.map((document) => document.relativePath));
    }
    return changedPaths.toSet().toList(growable: false);
  }

  BookDeconstructionInformationPersistenceBundle _resolveInformationPersistence(
    ProjectDescriptor project,
  ) {
    final repositoriesProvided =
        _knowledgeCardRepository != null &&
        _designElementRepository != null &&
        _researchNoteRepository != null &&
        _referenceWorkRepository != null &&
        _informationProjectionWriterService != null;
    if (repositoriesProvided) {
      return BookDeconstructionInformationPersistenceBundle(
        knowledgeCardRepository: _knowledgeCardRepository,
        designElementRepository: _designElementRepository,
        researchNoteRepository: _researchNoteRepository,
        referenceWorkRepository: _referenceWorkRepository,
        projectionWriterService: _informationProjectionWriterService,
      );
    }
    return _informationPersistenceBundleFactory.create(project.storageStrategy);
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

  bool _claimsAreEquivalent(
    NarrativeStateClaim left,
    NarrativeStateClaim right,
  ) {
    // The JSON contract includes open metadata fields, so compare the encoded
    // records rather than maintaining a fragile field-by-field comparator.
    return jsonEncode(left.toJson()) == jsonEncode(right.toJson());
  }
}
