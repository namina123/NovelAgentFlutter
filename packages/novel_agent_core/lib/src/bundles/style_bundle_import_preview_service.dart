import '../assets/style_profile_normalizer_service.dart';
import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_conflict_preview_service.dart';
import 'bundle_import_preview.dart';
import 'bundle_kind.dart';
import 'style_bundle_document_service.dart';

class StyleBundleImportPreviewService {
  StyleBundleImportPreviewService({
    StyleBundleDocumentService? documentService,
    BundleConflictPreviewService? conflictPreviewService,
    StyleProfileNormalizerService? styleNormalizerService,
  }) : _documentService = documentService ?? StyleBundleDocumentService(),
       _conflictPreviewService =
           conflictPreviewService ?? BundleConflictPreviewService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService();

  final StyleBundleDocumentService _documentService;
  final BundleConflictPreviewService _conflictPreviewService;
  final StyleProfileNormalizerService _styleNormalizerService;

  BundleImportPreview previewBundle({
    required String bundleContent,
    required List<JsonMap> existingStyles,
    bool overwrite = false,
  }) {
    final bundle = _documentService.parseBundle(bundleContent);
    return _conflictPreviewService.previewEntries(
      bundleKind: BundleKind.styleBundle,
      title: bundle['title']?.toString() ?? '',
      description: bundle['description']?.toString() ?? '',
      entryKind: 'style',
      incomingEntries: ValueReaders.mapList(bundle['styles'])
          .map(_styleNormalizerService.normalize)
          .map(_styleNormalizerService.toDocument)
          .toList(growable: false),
      existingEntries: existingStyles,
      overwrite: overwrite,
      targetPathBuilder: (entry) => 'assets/styles/${entry['id']}.style.md',
    );
  }
}
