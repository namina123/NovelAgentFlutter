import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_bundle_directory_codec_service.dart';

class ReferenceBundleImportService {
  ReferenceBundleImportService({
    required ReferenceEvidenceSubstrate substrate,
    ReferenceBundleDirectoryCodecService? codecService,
  }) : _substrate = substrate,
       _codecService =
           codecService ?? const ReferenceBundleDirectoryCodecService();

  final ReferenceEvidenceSubstrate _substrate;
  final ReferenceBundleDirectoryCodecService _codecService;

  Future<ReferenceBundleImportResult> importFromDirectory(
    String bundleRootPath,
  ) async {
    final document = _codecService.readDirectory(bundleRootPath);
    await _substrate.upsertPackageSnapshot(document.snapshot);
    return ReferenceBundleImportResult(
      packageId: document.manifest.packageId,
      packageVersionId: document.manifest.packageVersionId,
      importedEntryIds: document.snapshot.entries
          .map((entry) => entry.entryId)
          .toList(growable: false),
      warnings: document.manifest.validateBasics(),
    );
  }
}
