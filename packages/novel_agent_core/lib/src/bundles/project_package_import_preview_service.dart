import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'bundle_conflict_item.dart';
import 'bundle_conflict_preview_service.dart';
import 'bundle_import_preview.dart';
import 'bundle_import_preview_builder_service.dart';
import 'bundle_kind.dart';
import 'project_package_document_service.dart';

class ProjectPackageImportPreviewService {
  ProjectPackageImportPreviewService({
    ProjectPackageDocumentService? documentService,
    BundleConflictPreviewService? conflictPreviewService,
    BundleImportPreviewBuilderService? previewBuilderService,
  }) : _documentService = documentService ?? ProjectPackageDocumentService(),
       _conflictPreviewService =
           conflictPreviewService ?? BundleConflictPreviewService(),
       _previewBuilderService =
           previewBuilderService ?? const BundleImportPreviewBuilderService();

  final ProjectPackageDocumentService _documentService;
  final BundleConflictPreviewService _conflictPreviewService;
  final BundleImportPreviewBuilderService _previewBuilderService;

  BundleImportPreview previewBundle({
    required String bundleContent,
    required String existingProjectId,
    required List<JsonMap> existingCharacters,
    required List<JsonMap> existingOrganizations,
    required List<JsonMap> existingStyles,
    required List<JsonMap> existingTemplates,
    bool overwrite = false,
  }) {
    final bundle = _documentService.parseBundle(bundleContent);
    final title = ValueReaders.stringValue(bundle['title']);
    final description = ValueReaders.stringValue(bundle['description']);
    final projectInfo = ValueReaders.mapValue(bundle['project']);
    final incomingProjectId = ValueReaders.stringValue(
      projectInfo['project_id'],
    ).trim();
    final items = <BundleConflictItem>[
      _projectConflictItem(
        incomingProjectId: incomingProjectId,
        existingProjectId: existingProjectId,
        title: title,
        overwrite: overwrite,
      ),
      ..._conflictPreviewService
          .previewEntries(
            bundleKind: BundleKind.projectPackage,
            title: title,
            description: description,
            entryKind: 'character',
            incomingEntries: ValueReaders.mapList(bundle['characters']),
            existingEntries: existingCharacters,
            overwrite: overwrite,
            targetPathBuilder: (entry) => 'assets/characters/${entry['id']}.md',
          )
          .items,
      ..._conflictPreviewService
          .previewEntries(
            bundleKind: BundleKind.projectPackage,
            title: title,
            description: description,
            entryKind: 'organization',
            incomingEntries: ValueReaders.mapList(bundle['organizations']),
            existingEntries: existingOrganizations,
            overwrite: overwrite,
            targetPathBuilder: (entry) =>
                'assets/organizations/${entry['id']}.md',
          )
          .items,
      ..._conflictPreviewService
          .previewEntries(
            bundleKind: BundleKind.projectPackage,
            title: title,
            description: description,
            entryKind: 'style',
            incomingEntries: ValueReaders.mapList(bundle['styles']),
            existingEntries: existingStyles,
            overwrite: overwrite,
            targetPathBuilder: (entry) =>
                'assets/styles/${entry['id']}.style.md',
          )
          .items,
      ..._conflictPreviewService
          .previewEntries(
            bundleKind: BundleKind.projectPackage,
            title: title,
            description: description,
            entryKind: 'prompt_template',
            incomingEntries: ValueReaders.mapList(bundle['prompt_templates']),
            existingEntries: existingTemplates,
            overwrite: overwrite,
            targetPathBuilder: (entry) => 'prompts/${entry['id']}.json',
          )
          .items,
    ];
    return _previewBuilderService.buildPreview(
      bundleKind: BundleKind.projectPackage,
      title: title,
      description: description,
      items: items,
    );
  }

  BundleConflictItem _projectConflictItem({
    required String incomingProjectId,
    required String existingProjectId,
    required String title,
    required bool overwrite,
  }) {
    if (incomingProjectId.isEmpty) {
      return const BundleConflictItem(
        entryKind: 'project',
        entryId: '',
        displayName: '',
        targetPath: '.novel_agent/project_manifest.json',
        status: 'invalid',
        action: 'skip',
      );
    }
    final conflict =
        existingProjectId.trim().isNotEmpty &&
        existingProjectId.trim() != incomingProjectId.trim();
    return BundleConflictItem(
      entryKind: 'project',
      entryId: incomingProjectId,
      displayName: title,
      targetPath: '.novel_agent/project_manifest.json',
      status: conflict ? 'project_conflict' : 'new',
      action: conflict && !overwrite
          ? 'skip'
          : (conflict ? 'overwrite' : 'import'),
      changedFields: conflict ? const <String>['project_id'] : const <String>[],
    );
  }
}
