import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_asset_library_service.dart';
import 'project_bundle_apply_service.dart';
import 'project_bundle_directory_layout_service.dart';
import 'project_bundle_file_access_service.dart';
import 'project_bundle_write_file.dart';
import 'project_bundle_write_plan.dart';

class ProjectAssetBundleLibraryService {
  ProjectAssetBundleLibraryService({
    required ProjectAssetLibraryService assetLibraryService,
    required ProjectBundleFileAccessService fileAccessService,
    required ProjectBundleApplyService applyService,
    ProjectBundleDirectoryLayoutService? directoryLayoutService,
    ProjectAssetBundleDocumentService? documentService,
    PreviewProjectAssetBundleImportUseCase? previewUseCase,
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    StyleProfileMarkdownCodecService? styleCodecService,
    ForeshadowRecordMarkdownCodecService? foreshadowCodecService,
  }) : _assetLibraryService = assetLibraryService,
       _fileAccessService = fileAccessService,
       _applyService = applyService,
       _directoryLayoutService =
           directoryLayoutService ??
           const ProjectBundleDirectoryLayoutService(),
       _documentService =
           documentService ?? ProjectAssetBundleDocumentService(),
       _previewUseCase =
           previewUseCase ?? PreviewProjectAssetBundleImportUseCase(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _styleCodecService =
           styleCodecService ?? StyleProfileMarkdownCodecService(),
       _foreshadowCodecService =
           foreshadowCodecService ?? ForeshadowRecordMarkdownCodecService();

  final ProjectAssetLibraryService _assetLibraryService;
  final ProjectBundleFileAccessService _fileAccessService;
  final ProjectBundleApplyService _applyService;
  final ProjectBundleDirectoryLayoutService _directoryLayoutService;
  final ProjectAssetBundleDocumentService _documentService;
  final PreviewProjectAssetBundleImportUseCase _previewUseCase;
  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final StyleProfileMarkdownCodecService _styleCodecService;
  final ForeshadowRecordMarkdownCodecService _foreshadowCodecService;

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
    return <String, Object?>{
      'ok': true,
      'source_root_path': state['source_root_path'],
      'source_bundle_path': state['source_bundle_path'],
      'preview': state['preview'],
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
    )).map(_styleNormalizerService.normalize).toList(growable: false);
    final foreshadows = (await _assetLibraryService.listForeshadows(
      project,
    )).map(_foreshadowNormalizerService.normalize).toList(growable: false);
    final bundle = _documentService.buildBundle(
      styles: styles,
      foreshadows: foreshadows,
      title: title,
      description: description,
    );
    final directoryName = _directoryLayoutService.exportDirectoryName(
      bundleKind: ValueReaders.stringValue(bundle['kind']),
      title: ValueReaders.stringValue(bundle['title']),
    );
    final files = <String, String>{
      'bundle.json': _documentService.encodeBundle(bundle),
      for (final style in styles)
        'assets/styles/${style.id}.style.md': _styleCodecService.encode(style),
      for (final foreshadow in foreshadows)
        'assets/foreshadows/${foreshadow.id}.foreshadow.md':
            _foreshadowCodecService.encode(foreshadow),
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
      return <String, Object?>{
        'ok': false,
        'error': 'Bundle 源不存在或缺少 bundle.json。',
      };
    }
    final preview = _previewUseCase.execute(
      bundleContent: source.bundleContent,
      projectStyles: await _assetLibraryService.listStyles(project),
      projectForeshadows: await _assetLibraryService.listForeshadows(project),
      overwrite: overwrite,
    );
    return <String, Object?>{
      'ok': true,
      'source_root_path': source.rootDirectoryPath,
      'source_bundle_path': source.bundleFilePath,
      'bundle': _documentService.parseBundle(source.bundleContent),
      'preview': preview,
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
      final style = _styleNormalizerService.normalize(rawStyle);
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
          content: _styleCodecService.encode(style),
        ),
      );
    }
    for (final rawForeshadow in ValueReaders.mapList(bundle['foreshadows'])) {
      final foreshadow = _foreshadowNormalizerService.normalize(rawForeshadow);
      if (foreshadow.id.trim().isEmpty) {
        continue;
      }
      final targetPath = 'assets/foreshadows/${foreshadow.id}.foreshadow.md';
      if (actionByPath[targetPath] == 'skip') {
        skippedPaths.add(targetPath);
        continue;
      }
      files.add(
        ProjectBundleWriteFile(
          entryKind: 'foreshadow',
          entryId: foreshadow.id,
          targetPath: targetPath,
          content: _foreshadowCodecService.encode(foreshadow),
        ),
      );
    }
    return ProjectBundleWritePlan(
      bundleKind: ValueReaders.stringValue(bundle['kind']),
      title: ValueReaders.stringValue(preview['title']),
      sourcePath: sourcePath,
      files: files,
      skippedPaths: skippedPaths,
    );
  }

  Map<String, String> _actionByTargetPath(JsonMap preview) {
    final result = <String, String>{};
    for (final item in ValueReaders.mapList(preview['items'])) {
      result[ValueReaders.stringValue(item['relative_path'])] =
          ValueReaders.stringValue(item['action']);
    }
    return result;
  }
}
