import 'package:novel_agent_core/novel_agent_core.dart';

import 'reference_bundle_export_service.dart';
import 'reference_source_document_file_reader_service.dart';

class ReferenceSourceDocumentFileIngestionService {
  ReferenceSourceDocumentFileIngestionService({
    required ReferenceEvidenceSubstrate substrate,
    ReferenceBundleExportService? exportService,
    BuildReferencePackageFromSourceDocumentUseCase? buildUseCase,
    ReferenceSourceDocumentFileReaderService? fileReaderService,
  }) : _substrate = substrate,
       _buildUseCase =
           buildUseCase ??
           BuildReferencePackageFromSourceDocumentUseCase(substrate: substrate),
       _exportService =
           exportService ?? ReferenceBundleExportService(substrate: substrate),
       _fileReaderService =
           fileReaderService ??
           const ReferenceSourceDocumentFileReaderService();

  final ReferenceEvidenceSubstrate _substrate;
  final BuildReferencePackageFromSourceDocumentUseCase _buildUseCase;
  final ReferenceBundleExportService _exportService;
  final ReferenceSourceDocumentFileReaderService _fileReaderService;

  Future<ReferenceSourceDocumentFileIngestionResult> ingestFile({
    required String sourceFilePath,
    required String packageId,
    required String packageKind,
    required String displayName,
    required String packageVersionId,
    required String versionLabel,
    required String createdAt,
    String packageNamespace = '',
    String createdBy = '',
    String sourceLanguage = '',
    String targetLanguage = 'zh-CN',
    String? bundleOutputDirectory,
    int maxChapterEntries = 6,
    int maxEntityEntries = 6,
  }) async {
    final sourceDocument = await _fileReaderService.read(
      sourceFilePath: sourceFilePath,
    );
    final ingestion = await _buildUseCase.execute(
      ReferenceSourceDocumentIngestionRequest(
        sourceText: sourceDocument.sourceText,
        sourceTitle: sourceDocument.sourceTitle,
        sourceRef: sourceDocument.sourceFilePath,
        packageId: packageId,
        packageKind: packageKind,
        displayName: displayName,
        packageNamespace: packageNamespace,
        packageVersionId: packageVersionId,
        versionLabel: versionLabel,
        createdAt: createdAt,
        createdBy: createdBy,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        maxChapterEntries: maxChapterEntries,
        maxEntityEntries: maxEntityEntries,
      ),
    );
    String bundlePath = '';
    if (bundleOutputDirectory != null &&
        bundleOutputDirectory.trim().isNotEmpty) {
      await _exportService.exportToDirectory(
        bundleOutputDirectory,
        ReferenceBundleExportRequest(
          packageId: packageId,
          packageVersionId: packageVersionId,
          bundleId: '${packageId}_${packageVersionId}',
          createdAt: createdAt,
          createdBy: createdBy,
        ),
      );
      bundlePath = bundleOutputDirectory;
    }
    final snapshot = await _substrate.readPackageSnapshot(
      packageId: packageId,
      packageVersionId: packageVersionId,
    );
    return ReferenceSourceDocumentFileIngestionResult(
      sourceFilePath: sourceDocument.sourceFilePath,
      packageId: packageId,
      packageVersionId: packageVersionId,
      sourceLanguage: ingestion.sourceLanguage,
      targetLanguage: ingestion.targetLanguage,
      generatedEntryCount: ingestion.generatedEntryCount,
      bundleOutputDirectory: bundlePath,
      snapshot: snapshot ?? ingestion.snapshot,
    );
  }
}

class ReferenceSourceDocumentFileIngestionResult {
  const ReferenceSourceDocumentFileIngestionResult({
    required this.sourceFilePath,
    required this.packageId,
    required this.packageVersionId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.generatedEntryCount,
    required this.bundleOutputDirectory,
    required this.snapshot,
  });

  final String sourceFilePath;
  final String packageId;
  final String packageVersionId;
  final String sourceLanguage;
  final String targetLanguage;
  final int generatedEntryCount;
  final String bundleOutputDirectory;
  final ReferencePackageSnapshot snapshot;
}
