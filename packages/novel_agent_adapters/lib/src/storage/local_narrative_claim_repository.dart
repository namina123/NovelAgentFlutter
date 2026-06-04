import 'package:novel_agent_core/novel_agent_core.dart';

import 'open_narrative_state_jsonl_document_service.dart';
import 'open_narrative_state_path_service.dart';

class LocalNarrativeClaimRepository implements NarrativeClaimRepository {
  LocalNarrativeClaimRepository({
    required ProjectWorkspacePort workspacePort,
    OpenNarrativeStatePathService? pathService,
    NarrativeStateClaimCodecService? codecService,
  }) : _jsonlDocumentService = OpenNarrativeStateJsonlDocumentService(
         workspacePort: workspacePort,
       ),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _codecService = codecService ?? const NarrativeStateClaimCodecService();

  final OpenNarrativeStateJsonlDocumentService _jsonlDocumentService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeStateClaimCodecService _codecService;

  @override
  Future<void> appendClaim(
    ProjectDescriptor project,
    NarrativeStateClaim claim,
  ) {
    return _jsonlDocumentService.appendJsonLine(
      project.rootPath,
      _pathService.claimsLogPath(),
      _codecService.toJson(claim),
    );
  }

  @override
  Future<List<NarrativeStateClaim>> listClaims(
    ProjectDescriptor project, {
    String? claimNamespace,
  }) async {
    final latestById = <String, NarrativeStateClaim>{};
    for (final raw in await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.claimsLogPath(),
    )) {
      final claim = _codecService.fromJson(raw);
      if (claim.claimId.trim().isEmpty) {
        continue;
      }
      latestById.remove(claim.claimId);
      latestById[claim.claimId] = claim;
    }
    return latestById.values
        .where(
          (claim) =>
              claimNamespace == null || claim.claimNamespace == claimNamespace,
        )
        .toList(growable: false);
  }

  @override
  Future<NarrativeStateClaim?> readClaim(
    ProjectDescriptor project, {
    required String claimId,
  }) async {
    final rows = await _jsonlDocumentService.readJsonLines(
      project.rootPath,
      _pathService.claimsLogPath(),
    );
    for (var index = rows.length - 1; index >= 0; index -= 1) {
      final claim = _codecService.fromJson(rows[index]);
      if (claim.claimId == claimId) {
        return claim;
      }
    }
    return null;
  }
}
