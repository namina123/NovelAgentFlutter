import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_conflict_preview_service.dart';
import 'bundle_import_preview.dart';
import 'bundle_kind.dart';
import 'character_card_bundle_document_service.dart';

class CharacterCardBundleImportPreviewService {
  CharacterCardBundleImportPreviewService({
    CharacterCardBundleDocumentService? documentService,
    BundleConflictPreviewService? conflictPreviewService,
  }) : _documentService =
           documentService ?? CharacterCardBundleDocumentService(),
       _conflictPreviewService =
           conflictPreviewService ?? BundleConflictPreviewService();

  final CharacterCardBundleDocumentService _documentService;
  final BundleConflictPreviewService _conflictPreviewService;

  BundleImportPreview previewBundle({
    required String bundleContent,
    required List<JsonMap> existingCharacters,
    required List<JsonMap> existingOrganizations,
    bool overwrite = false,
  }) {
    final bundle = _documentService.parseBundle(bundleContent);
    final title = ValueReaders.stringValue(bundle['title']);
    final description = ValueReaders.stringValue(bundle['description']);
    final characterPreview = _conflictPreviewService.previewEntries(
      bundleKind: BundleKind.characterCardBundle,
      title: title,
      description: description,
      entryKind: 'character',
      incomingEntries: ValueReaders.mapList(bundle['characters']),
      existingEntries: existingCharacters,
      overwrite: overwrite,
      targetPathBuilder: (entry) => 'assets/characters/${entry['id']}.md',
    );
    final organizationPreview = _conflictPreviewService.previewEntries(
      bundleKind: BundleKind.characterCardBundle,
      title: title,
      description: description,
      entryKind: 'organization',
      incomingEntries: ValueReaders.mapList(bundle['organizations']),
      existingEntries: existingOrganizations,
      overwrite: overwrite,
      targetPathBuilder: (entry) => 'assets/organizations/${entry['id']}.md',
    );
    return BundleImportPreview(
      bundleKind: BundleKind.characterCardBundle,
      title: title,
      description: description,
      items: <dynamic>[
        ...characterPreview.items,
        ...organizationPreview.items,
      ].cast(),
      totalCount: characterPreview.totalCount + organizationPreview.totalCount,
      newCount: characterPreview.newCount + organizationPreview.newCount,
      conflictCount:
          characterPreview.conflictCount + organizationPreview.conflictCount,
      overwriteCount:
          characterPreview.overwriteCount + organizationPreview.overwriteCount,
      skippedCount:
          characterPreview.skippedCount + organizationPreview.skippedCount,
      invalidCount:
          characterPreview.invalidCount + organizationPreview.invalidCount,
    );
  }
}
