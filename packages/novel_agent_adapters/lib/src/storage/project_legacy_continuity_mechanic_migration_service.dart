import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_constraint_binding_repository.dart';
import 'local_narrative_claim_repository.dart';
import 'local_narrative_ledger_repository.dart';
import 'local_narrative_profile_repository.dart';
import 'local_semantic_review_repository.dart';
import 'open_narrative_state_path_service.dart';
import 'open_narrative_state_projection_writer_service.dart';
import 'project_continuity_input_repository.dart';
import 'project_continuity_repository.dart';

/// Deprecated bridge-only migration entry for old continuity/mechanic state.
///
/// The old files remain readable and unchanged; this service only mirrors them
/// into the open narrative state repositories under `legacy.special_mechanic.*`.
class ProjectLegacyContinuityMechanicMigrationService {
  ProjectLegacyContinuityMechanicMigrationService({
    required ProjectWorkspacePort workspacePort,
    ProjectContinuityRepository? continuityRepository,
    ProjectContinuityInputRepository? continuityInputRepository,
    NarrativeProfileRepository? profileRepository,
    NarrativeClaimRepository? claimRepository,
    NarrativeLedgerRepository? ledgerRepository,
    SemanticReviewRepository? reviewRepository,
    ConstraintBindingRepository? bindingRepository,
    OpenNarrativeStateProjectionWriterService? projectionWriterService,
    LegacyContinuityMechanicImporterService? importerService,
    OpenNarrativeStatePathService? pathService,
    NarrativeProfileCodecService? profileCodecService,
    NarrativeStateClaimCodecService? claimCodecService,
  }) : _continuityRepository =
           continuityRepository ??
           ProjectContinuityRepository(workspacePort: workspacePort),
       _continuityInputRepository =
           continuityInputRepository ??
           ProjectContinuityInputRepository(workspacePort: workspacePort),
       _profileRepository =
           profileRepository ??
           LocalNarrativeProfileRepository(workspacePort: workspacePort),
       _claimRepository =
           claimRepository ??
           LocalNarrativeClaimRepository(workspacePort: workspacePort),
       _projectionWriterService =
           projectionWriterService ??
           OpenNarrativeStateProjectionWriterService(
             workspacePort: workspacePort,
             profileRepository:
                 profileRepository ??
                 LocalNarrativeProfileRepository(workspacePort: workspacePort),
             claimRepository:
                 claimRepository ??
                 LocalNarrativeClaimRepository(workspacePort: workspacePort),
             ledgerRepository:
                 ledgerRepository ??
                 LocalNarrativeLedgerRepository(workspacePort: workspacePort),
             reviewRepository:
                 reviewRepository ??
                 LocalSemanticReviewRepository(workspacePort: workspacePort),
             bindingRepository:
                 bindingRepository ??
                 LocalConstraintBindingRepository(workspacePort: workspacePort),
           ),
       _importerService =
           importerService ?? const LegacyContinuityMechanicImporterService(),
       _pathService = pathService ?? OpenNarrativeStatePathService(),
       _profileCodecService =
           profileCodecService ?? const NarrativeProfileCodecService(),
       _claimCodecService =
           claimCodecService ?? const NarrativeStateClaimCodecService();

  final ProjectContinuityRepository _continuityRepository;
  final ProjectContinuityInputRepository _continuityInputRepository;
  final NarrativeProfileRepository _profileRepository;
  final NarrativeClaimRepository _claimRepository;
  final OpenNarrativeStateProjectionWriterService _projectionWriterService;
  final LegacyContinuityMechanicImporterService _importerService;
  final OpenNarrativeStatePathService _pathService;
  final NarrativeProfileCodecService _profileCodecService;
  final NarrativeStateClaimCodecService _claimCodecService;

  Future<JsonMap> migrate(ProjectDescriptor project) async {
    // 中文注释: 这里只负责把旧 continuity/mechanic 文件桥接进新事实源，不改旧文件也不复活旧逻辑。
    final bundle = await _continuityRepository.load(project);
    if (bundle == null) {
      return const <String, Object?>{
        'ok': true,
        'action': 'no_legacy_continuity',
        'changed_paths': <Object?>[],
      };
    }
    final inputProfile = await _continuityInputRepository.load(project);
    final package = _importerService.buildPackage(
      project: project,
      bundle: bundle,
      inputProfile: inputProfile,
    );
    final changedPaths = <String>[];
    if (await _upsertProfile(project, package.profile)) {
      changedPaths.add(_pathService.profilePath(package.profile.profileId));
      changedPaths.add(_pathService.profilesIndexPath());
    }
    final importedClaimIds = <String>[];
    for (final claim in package.claims) {
      importedClaimIds.add(claim.claimId);
      if (await _upsertClaim(project, claim)) {
        changedPaths.add(_pathService.claimsLogPath());
      }
    }
    if (changedPaths.isNotEmpty) {
      final projections = await _projectionWriterService.writeProjection(project);
      changedPaths.addAll(projections.map((entry) => entry.relativePath));
    }
    return <String, Object?>{
      'ok': true,
      'action': changedPaths.isEmpty ? 'up_to_date' : 'migrated',
      'profile_id': package.profile.profileId,
      'claim_ids': importedClaimIds,
      'legacy_namespace_root': 'legacy.special_mechanic',
      'pressure_probe_note':
          'Legacy special mechanic labels remain readable as probe input only.',
      'changed_paths': changedPaths.toSet().toList(growable: false),
    };
  }

  Future<bool> _upsertProfile(
    ProjectDescriptor project,
    NarrativeProfile profile,
  ) async {
    final existing = await _profileRepository.readProfile(
      project,
      profileId: profile.profileId,
    );
    if (existing != null &&
        _jsonEquals(
          _profileCodecService.profileToJson(existing),
          _profileCodecService.profileToJson(profile),
        )) {
      return false;
    }
    await _profileRepository.appendProfile(project, profile);
    return true;
  }

  Future<bool> _upsertClaim(
    ProjectDescriptor project,
    NarrativeStateClaim claim,
  ) async {
    final existing = await _claimRepository.readClaim(
      project,
      claimId: claim.claimId,
    );
    if (existing != null &&
        _jsonEquals(
          _claimCodecService.toJson(existing),
          _claimCodecService.toJson(claim),
        )) {
      return false;
    }
    await _claimRepository.appendClaim(project, claim);
    return true;
  }

  bool _jsonEquals(JsonMap left, JsonMap right) {
    return jsonEncode(left) == jsonEncode(right);
  }
}
