import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../prompts/prompt_template_normalizer_service.dart';
import 'bundle_conflict_preview_service.dart';
import 'bundle_import_preview.dart';
import 'bundle_kind.dart';
import 'prompt_template_bundle_document_service.dart';

class PromptTemplateBundleImportPreviewService {
  PromptTemplateBundleImportPreviewService({
    PromptTemplateBundleDocumentService? documentService,
    BundleConflictPreviewService? conflictPreviewService,
    PromptTemplateNormalizerService? templateNormalizerService,
  }) : _documentService =
           documentService ?? PromptTemplateBundleDocumentService(),
       _conflictPreviewService =
           conflictPreviewService ?? BundleConflictPreviewService(),
       _templateNormalizerService =
           templateNormalizerService ?? PromptTemplateNormalizerService();

  final PromptTemplateBundleDocumentService _documentService;
  final BundleConflictPreviewService _conflictPreviewService;
  final PromptTemplateNormalizerService _templateNormalizerService;

  BundleImportPreview previewBundle({
    required String bundleContent,
    required List<JsonMap> existingTemplates,
    bool overwrite = false,
  }) {
    final bundle = _documentService.parseBundle(bundleContent);
    return _conflictPreviewService.previewEntries(
      bundleKind: BundleKind.promptTemplateBundle,
      title: ValueReaders.stringValue(bundle['title']),
      description: ValueReaders.stringValue(bundle['description']),
      entryKind: 'prompt_template',
      incomingEntries: ValueReaders.mapList(bundle['templates'])
          .map(_templateNormalizerService.normalizeTemplate)
          .toList(growable: false),
      existingEntries: existingTemplates,
      overwrite: overwrite,
      targetPathBuilder: (entry) => _templateNormalizerService.templatePath(
        ValueReaders.stringValue(entry['id']),
      ),
    );
  }
}
