import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_bundle_directory_codec_service.dart';

class ReferenceBundleExportService {
  ReferenceBundleExportService({
    required ReferenceEvidenceSubstrate substrate,
    ReferenceBundleDirectoryCodecService? codecService,
    BundleChecksumService? checksumService,
  }) : _substrate = substrate,
       _codecService =
           codecService ?? const ReferenceBundleDirectoryCodecService(),
       _checksumService = checksumService ?? const BundleChecksumService();

  final ReferenceEvidenceSubstrate _substrate;
  final ReferenceBundleDirectoryCodecService _codecService;
  final BundleChecksumService _checksumService;

  Future<ReferenceBundleDocument> exportToDirectory(
    String bundleRootPath,
    ReferenceBundleExportRequest request,
  ) async {
    final snapshot = await _substrate.readPackageSnapshot(
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
    );
    if (snapshot == null) {
      throw StateError(
        'Reference package snapshot not found for ${request.packageId}@${request.packageVersionId}.',
      );
    }
    final manifest = ReferenceBundleManifest(
      bundleId: request.bundleId,
      packageId: request.packageId,
      packageVersionId: request.packageVersionId,
      displayName: snapshot.packageRecord.displayName,
      packageKind: snapshot.packageRecord.packageKind,
      createdAt: request.createdAt,
      sourceLanguage: snapshot.packageRecord.sourceLanguage,
      targetLanguage: snapshot.packageRecord.targetLanguage,
      createdBy: request.createdBy,
      sourceSummary: snapshot.packageRecord.sourceSummary,
      licenseSummary: snapshot.packageRecord.licenseSummary,
      dependencySummary: snapshot.packageVersionRecord.dependencySummary,
    );
    final bundleProjection = _buildProjection(snapshot);
    final integrity = <String, Object?>{
      'payload_checksum': _checksumService.checksumOf(snapshot.toJson()),
      'manifest_checksum': _checksumService.checksumOf(manifest.toJson()),
    };
    final document = ReferenceBundleDocument(
      manifest: manifest,
      snapshot: snapshot,
      projections: <String, String>{'summary.md': bundleProjection},
      integrity: integrity,
    );
    _codecService.writeDirectory(bundleRootPath, document);
    return document;
  }

  String _buildProjection(ReferencePackageSnapshot snapshot) {
    final useChinese =
        snapshot.packageRecord.targetLanguage.trim().isEmpty ||
        snapshot.packageRecord.targetLanguage.trim().startsWith('zh');
    final buffer = StringBuffer()
      ..writeln('# ${snapshot.packageRecord.displayName}')
      ..writeln()
      ..writeln(
        useChinese
            ? '- 资料包 ID：`${snapshot.packageRecord.packageId}`'
            : '- Package ID: `${snapshot.packageRecord.packageId}`',
      )
      ..writeln(
        useChinese
            ? '- 版本 ID：`${snapshot.packageVersionRecord.packageVersionId}`'
            : '- Version ID: `${snapshot.packageVersionRecord.packageVersionId}`',
      )
      ..writeln(
        useChinese
            ? '- 源语言：`${snapshot.packageRecord.sourceLanguage}`'
            : '- Source Language: `${snapshot.packageRecord.sourceLanguage}`',
      )
      ..writeln(
        useChinese
            ? '- 目标语言：`${snapshot.packageRecord.targetLanguage}`'
            : '- Target Language: `${snapshot.packageRecord.targetLanguage}`',
      )
      ..writeln(
        useChinese
            ? '- 条目数量：${snapshot.entries.length}'
            : '- Entry Count: ${snapshot.entries.length}',
      )
      ..writeln();
    for (final entry in snapshot.entries) {
      buffer
        ..writeln('## ${entry.title}')
        ..writeln()
        ..writeln(
          useChinese
              ? '- 命名空间：`${entry.entryNamespace}`'
              : '- Namespace: `${entry.entryNamespace}`',
        )
        ..writeln(
          useChinese
              ? '- 条目类型：`${entry.entryKind}`'
              : '- Kind: `${entry.entryKind}`',
        )
        ..writeln(
          useChinese
              ? '- 摘要：${entry.summary.isEmpty ? '无' : entry.summary}'
              : '- Summary: ${entry.summary.isEmpty ? 'n/a' : entry.summary}',
        )
        ..writeln();
    }
    return buffer.toString();
  }
}
