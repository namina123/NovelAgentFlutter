import 'package:novel_agent_core/novel_agent_core.dart';

class OpenNarrativeStateProjectionWriterService {
  OpenNarrativeStateProjectionWriterService({
    required ProjectWorkspacePort workspacePort,
    required NarrativeProfileRepository profileRepository,
    required NarrativeClaimRepository claimRepository,
    required NarrativeLedgerRepository ledgerRepository,
    required SemanticReviewRepository reviewRepository,
    required ConstraintBindingRepository bindingRepository,
    NarrativeStateMarkdownProjectionService? projectionService,
  }) : _workspacePort = workspacePort,
       _profileRepository = profileRepository,
       _claimRepository = claimRepository,
       _ledgerRepository = ledgerRepository,
       _reviewRepository = reviewRepository,
       _bindingRepository = bindingRepository,
       _projectionService =
           projectionService ?? NarrativeStateMarkdownProjectionService();

  final ProjectWorkspacePort _workspacePort;
  final NarrativeProfileRepository _profileRepository;
  final NarrativeClaimRepository _claimRepository;
  final NarrativeLedgerRepository _ledgerRepository;
  final SemanticReviewRepository _reviewRepository;
  final ConstraintBindingRepository _bindingRepository;
  final NarrativeStateMarkdownProjectionService _projectionService;

  Future<List<NarrativeStateProjectionDocument>> writeProjection(
    ProjectDescriptor project,
  ) async {
    final source = NarrativeStateProjectionSource(
      profiles: await _profileRepository.listProfiles(project),
      claims: await _claimRepository.listClaims(project),
      ledgers: await _ledgerRepository.listLedgers(project),
      reviews: await _reviewRepository.listReviews(project),
      bindings: await _bindingRepository.listBindings(project),
    );
    final documents = _projectionService.buildDocuments(source);
    for (final document in documents) {
      await _workspacePort.writeTextFile(
        project.rootPath,
        document.relativePath,
        document.markdown,
      );
    }
    return documents;
  }
}
