import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_asset_library_service.dart';
import 'project_bundle_apply_service.dart';
import 'project_bundle_directory_layout_service.dart';
import 'project_bundle_file_access_service.dart';
import 'project_bundle_preview_mapper_service.dart';
import 'project_bundle_write_file.dart';
import 'project_bundle_write_plan.dart';

class ProjectStyleBundleLibraryService {
  ProjectStyleBundleLibraryService({
    required ProjectAssetLibraryService assetLibraryService,
    required ProjectBundleFileAccessService fileAccessService,
    required ProjectBundleApplyService applyService,
    ProjectBundlePreviewMapperService? previewMapperService,
    ProjectBundleDirectoryLayoutService? directoryLayoutService,
    StyleBundleDocumentService? documentService,
    StyleBundleImportPreviewService? previewService,
    StyleProfileNormalizerService? normalizerService,
    StyleProfileMarkdownCodecService? codecService,
  }) : _assetLibraryService = assetLibraryService,
       _fileAccessService = fileAccessService,
       _applyService = applyService,
       _previewMapperService =
           previewMapperService ?? const ProjectBundlePreviewMapperService(),
       _directoryLayoutService =
           directoryLayoutService ?? const ProjectBundleDirectoryLayoutService(),
       _documentService = documentService ?? StyleBundleDocumentService(),
       _previewService = previewService ?? StyleBundleImportPreviewService(),
       _normalizerService =
           normalizerService ?? const StyleProfileNormalizerService(),
       _codecService = codecService ?? StyleProfileMarkdownCodecService();

  final ProjectAssetLibraryService _assetLibraryService;
  final ProjectBundleFileAccessService _fileAccessService;
  final ProjectBundleApplyService _applyService;
  final ProjectBundlePreviewMapperService _previewMapperService;
  final ProjectBundleDirectoryLayoutService _directoryLayoutService;
  final StyleBundleDocumentService _documentService;
  final StyleBundleImportPreviewService _previewService;
  final StyleProfileNormalizerService _normalizerService;
  final StyleProfileMarkdownCodecService _codecService;

  Future<JsonMap> previewImport(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    final preview = ValueReaders.mapValue(state['preview']);
    return <String, Object?>{
      'ok': true,
      'source_root_path': state['source_root_path'],
      'source_bundle_path': state['source_bundle_path'],
      'preview': preview,
    };
  }

  Future<JsonMap> buildImportWritePlan(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    final plan = _buildPlan(
      sourcePath: ValueReaders.stringValue(state['source_bundle_path']),
      bundle: ValueReaders.mapValue(state['bundle']),
      preview: ValueReaders.mapValue(state['preview']),
    );
    return <String, Object?>{'ok': true, 'write_plan': plan.toJson()};
  }

  Future<JsonMap> importBundle(
    ProjectDescriptor project, {
    required String sourcePath,
    bool overwrite = false,
  }) async {
    final state = await _loadState(
      project,
      sourcePath: sourcePath,
      overwrite: overwrite,
    );
    if (!ValueReaders.boolValue(state['ok'])) {
      return state;
    }
    final plan = _buildPlan(
      sourcePath: ValueReaders.stringValue(state['source_bundle_path']),
      bundle: ValueReaders.mapValue(state['bundle']),
      preview: ValueReaders.mapValue(state['preview']),
    );
    return _applyService.applyToProject(project, plan);
  }

  Future<JsonMap> exportBundle(
    ProjectDescriptor project, {
    required String targetDirectoryPath,
    String title = '',
    String description = '',
  }) async {
    final styles = (await _assetLibraryService.listStyles(
      project,
    )).map(_normalizerService.normalize).toList(growable: false);
    final bundle = _documentService.buildBundle(
      styles: styles,
      title: title,
      description: description,
    );
    final directoryName = _directoryLayoutService.exportDirectoryName(
      bundleKind: BundleKind.styleBundle,
      title: ValueReaders.stringValue(bundle['title']),
    );
    final files = <String, String>{
      'bundle.json': _documentService.encodeBundle(bundle),
      for (final style in styles) 'assets/styles/${style.id}.style.md': _codecService.encode(style),
    };
    final exportDirectoryPath = await _fileAccessService.writeExportDirectory(
      targetDirectoryPath: targetDirectoryPath,
      directoryName: directoryName,
      files: files,
    );
    return <String, Object?>{
      'ok': true,
      'export_directory_path': exportDirectoryPath,
      'bundle_file_path': _fileAccessService.joinWithinDirectory(
        exportDirectoryPath,
        'bundle.json',
      ),
      'written_files': files.keys.toList(growable: false),
    };
  }

  Future<JsonMap> _loadState(
    ProjectDescriptor project, {
    required String sourcePath,
    required bool overwrite,
  }) async {
    final source = await _fileAccessService.readBundleSource(sourcePath);
    if (source == null) {
      return <String, Object?>{'ok': false, 'error': 'Bundle 源不存在或缺少 bundle.json。'};
    }
    final existingStyles = await _assetLibraryService.listStyles(project);
    final preview = _previewService.previewBundle(
      bundleContent: source.bundleContent,
      existingStyles: existingStyles,
      overwrite: overwrite,
    );
    return <String, Object?>{
      'ok': true,
      'source_root_path': source.rootDirectoryPath,
      'source_bundle_path': source.bundleFilePath,
      'bundle': _documentService.parseBundle(source.bundleContent),
      'preview': _previewMapperService.toJson(preview),
    };
  }

  ProjectBundleWritePlan _buildPlan({
    required String sourcePath,
    required JsonMap bundle,
    required JsonMap preview,
  }) {
    final actionByPath = _actionByTargetPath(preview);
    final files = <ProjectBundleWriteFile>[];
    final skippedPaths = <String>[];
    for (final rawStyle in ValueReaders.mapList(bundle['styles'])) {
      final style = _normalizerService.normalize(rawStyle);
      if (style.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/styles/${style.id}.style.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'style',
          entryId: style.id,
          targetPath: targetPath,
          content: _codecService.encode(style),
        ),
      );
    }
    return ProjectBundleWritePlan(
      bundleKind: BundleKind.styleBundle,
      title: ValueReaders.stringValue(preview['title']),
      sourcePath: sourcePath,
      files: files,
      skippedPaths: skippedPaths,
    );
  }

  Map<String, String> _actionByTargetPath(JsonMap preview) {
    final result = <String, String>{};
    for (final item in ValueReaders.mapList(preview['items'])) {
      result[ValueReaders.stringValue(item['target_path'])] = ValueReaders
          .stringValue(item['action']);
    }
    return result;
  }
}
