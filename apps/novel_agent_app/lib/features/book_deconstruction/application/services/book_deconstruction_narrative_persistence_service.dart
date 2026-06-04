import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionNarrativePersistenceService {
  BookDeconstructionNarrativePersistenceService({
    required ProjectWorkspacePort workspacePort,
    OpenNarrativeStatePathService? pathService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    LocalNarrativeClaimRepository? claimRepository,
    LocalSemanticReviewRepository? reviewRepository,
    OpenNarrativeStateProjectionWriterService? projectionWriterService,
  }) : _pathService = pathService ?? OpenNarrativeStatePathService(),
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
           );

  final OpenNarrativeStatePathService _pathService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final NarrativeProfileCodecService _profileCodecService;
  final LocalNarrativeClaimRepository _claimRepository;
  final LocalSemanticReviewRepository _reviewRepository;
  final OpenNarrativeStateProjectionWriterService _projectionWriterService;

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
    if (narrativeArtifacts.isEmpty) {
      return changedPaths;
    }
    final documents = await _projectionWriterService.writeProjection(project);
    changedPaths.addAll(documents.map((document) => document.relativePath));
    return changedPaths.toSet().toList(growable: false);
  }
}
