import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_project_file_mutation_adapter.dart';

class ProjectAssetLibraryService {
  ProjectAssetLibraryService({
    required ProjectWorkspacePort workspacePort,
    required ProjectToolHostPort projectToolHostPort,
    WriteProjectTextFileUseCase? writeProjectTextFileUseCase,
    LocalProjectFileMutationAdapter? fileMutationAdapter,
    StyleProfileMarkdownParserService? styleParserService,
    ForeshadowRecordMarkdownParserService? foreshadowParserService,
    StyleProfileNormalizerService? styleNormalizerService,
    ForeshadowRecordNormalizerService? foreshadowNormalizerService,
    StyleProfileMarkdownCodecService? styleCodecService,
    ForeshadowRecordMarkdownCodecService? foreshadowCodecService,
    PreviewProjectAssetBundleImportUseCase? previewImportUseCase,
    ImportProjectAssetBundleUseCase? importUseCase,
    SaveProjectAssetBundleUseCase? saveBundleUseCase,
  }) : _workspacePort = workspacePort,
       _projectToolHostPort = projectToolHostPort,
       _writeProjectTextFileUseCase =
           writeProjectTextFileUseCase ??
           WriteProjectTextFileUseCase(projectWorkspacePort: workspacePort),
       _fileMutationAdapter =
           fileMutationAdapter ?? LocalProjectFileMutationAdapter(),
       _styleParserService =
           styleParserService ?? StyleProfileMarkdownParserService(),
       _foreshadowParserService =
           foreshadowParserService ?? ForeshadowRecordMarkdownParserService(),
       _styleNormalizerService =
           styleNormalizerService ?? const StyleProfileNormalizerService(),
       _foreshadowNormalizerService =
           foreshadowNormalizerService ??
           const ForeshadowRecordNormalizerService(),
       _styleCodecService =
           styleCodecService ?? StyleProfileMarkdownCodecService(),
       _foreshadowCodecService =
           foreshadowCodecService ?? ForeshadowRecordMarkdownCodecService(),
       _previewImportUseCase =
           previewImportUseCase ?? PreviewProjectAssetBundleImportUseCase(),
       _importUseCase =
           importUseCase ??
           ImportProjectAssetBundleUseCase(
             projectToolHostPort: projectToolHostPort,
           ),
       _saveBundleUseCase =
           saveBundleUseCase ??
           SaveProjectAssetBundleUseCase(
             writeProjectTextFileUseCase:
                 writeProjectTextFileUseCase ??
                 WriteProjectTextFileUseCase(
                   projectWorkspacePort: workspacePort,
                 ),
           );

  final ProjectWorkspacePort _workspacePort;
  final ProjectToolHostPort _projectToolHostPort;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final LocalProjectFileMutationAdapter _fileMutationAdapter;
  final StyleProfileMarkdownParserService _styleParserService;
  final ForeshadowRecordMarkdownParserService _foreshadowParserService;
  final StyleProfileNormalizerService _styleNormalizerService;
  final ForeshadowRecordNormalizerService _foreshadowNormalizerService;
  final StyleProfileMarkdownCodecService _styleCodecService;
  final ForeshadowRecordMarkdownCodecService _foreshadowCodecService;
  final PreviewProjectAssetBundleImportUseCase _previewImportUseCase;
  final ImportProjectAssetBundleUseCase _importUseCase;
  final SaveProjectAssetBundleUseCase _saveBundleUseCase;

  Future<List<JsonMap>> listStyles(ProjectDescriptor project) async {
    // 中文注释: 风格列表只负责项目内 styles/ 资产，不混入其他普通 Markdown 文档。
    final entries = await _workspacePort.listEntries(project.rootPath);
    final result = <JsonMap>[];
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !_isStylePath(relativePath)) {
        continue;
      }
      final content = await _workspacePort.readTextFile(
        project.rootPath,
        relativePath,
      );
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      final fallbackId = _fallbackIdFromPath(relativePath);
      final parsed = _styleParserService.parseDocument(
        content!,
        fallbackId: fallbackId,
        relativePath: relativePath,
      );
      if (ValueReaders.stringValue(parsed['id']).trim().isEmpty) {
        continue;
      }
      result.add(parsed);
    }
    result.sort((left, right) {
      return ValueReaders.stringValue(
        left['display_name'],
      ).compareTo(ValueReaders.stringValue(right['display_name']));
    });
    return result;
  }

  Future<List<JsonMap>> listForeshadows(ProjectDescriptor project) async {
    // 中文注释: 伏笔列表只读取 world/foreshadows/ 目录，给后续时间线和提醒留稳定入口。
    final entries = await _workspacePort.listEntries(project.rootPath);
    final result = <JsonMap>[];
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !_isForeshadowPath(relativePath)) {
        continue;
      }
      final content = await _workspacePort.readTextFile(
        project.rootPath,
        relativePath,
      );
      if ((content ?? '').trim().isEmpty) {
        continue;
      }
      final fallbackId = _fallbackIdFromPath(relativePath);
      final parsed = _foreshadowParserService.parseDocument(
        content!,
        fallbackId: fallbackId,
        relativePath: relativePath,
      );
      if (ValueReaders.stringValue(parsed['id']).trim().isEmpty) {
        continue;
      }
      result.add(parsed);
    }
    result.sort((left, right) {
      return ValueReaders.stringValue(
        left['title'],
      ).compareTo(ValueReaders.stringValue(right['title']));
    });
    return result;
  }

  Future<JsonMap> saveStyle(ProjectDescriptor project, JsonMap rawStyle) async {
    // 中文注释: 风格保存统一走 normalizer + codec，避免上层直接拼 frontmatter 文本。
    final normalized = _styleNormalizerService.normalize(rawStyle);
    final styleId = normalized.id.trim();
    if (styleId.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '风格 ID 不能为空。'};
    }
    final relativePath = _stylePath(styleId);
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: _styleCodecService.encode(normalized),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'asset': <String, Object?>{
        ..._styleNormalizerService.toDocument(normalized),
        'relative_path': relativePath,
      },
    };
  }

  Future<JsonMap> saveForeshadow(
    ProjectDescriptor project,
    JsonMap rawRecord,
  ) async {
    // 中文注释: 伏笔保存也只在这里落盘，便于后续接入校验和联动规则。
    final normalized = _foreshadowNormalizerService.normalize(rawRecord);
    final recordId = normalized.id.trim();
    if (recordId.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '伏笔 ID 不能为空。'};
    }
    final relativePath = _foreshadowPath(recordId);
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: _foreshadowCodecService.encode(normalized),
    );
    return <String, Object?>{
      'ok': true,
      'relative_path': relativePath,
      'asset': <String, Object?>{
        ..._foreshadowNormalizerService.toDocument(normalized),
        'relative_path': relativePath,
      },
    };
  }

  Future<JsonMap> deleteStyle(ProjectDescriptor project, String styleId) async {
    final relativePath = await _resolveExistingAssetPath(
      project.rootPath,
      preferredPath: _stylePath(styleId),
      legacyPath: 'styles/$styleId.md',
    );
    if (relativePath.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '未找到对应风格文件。'};
    }
    await _fileMutationAdapter.deleteEntry(project.rootPath, relativePath);
    return <String, Object?>{'ok': true, 'relative_path': relativePath};
  }

  Future<JsonMap> deleteForeshadow(
    ProjectDescriptor project,
    String recordId,
  ) async {
    final relativePath = await _resolveExistingAssetPath(
      project.rootPath,
      preferredPath: _foreshadowPath(recordId),
      legacyPath: 'world/foreshadows/$recordId.md',
    );
    if (relativePath.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '未找到对应伏笔文件。'};
    }
    await _fileMutationAdapter.deleteEntry(project.rootPath, relativePath);
    return <String, Object?>{'ok': true, 'relative_path': relativePath};
  }

  JsonMap previewImportBundle(
    ProjectDescriptor project, {
    required String bundleContent,
    required List<JsonMap> currentStyles,
    required List<JsonMap> currentForeshadows,
    bool overwrite = false,
  }) {
    // 中文注释: 资产包预检保持纯规则输出，GUI/CLI 只负责展示提示。
    return _previewImportUseCase.execute(
      bundleContent: bundleContent,
      projectStyles: currentStyles,
      projectForeshadows: currentForeshadows,
      overwrite: overwrite,
    );
  }

  Future<JsonMap> importBundle(
    ProjectDescriptor project, {
    required String bundleContent,
    bool overwrite = true,
  }) {
    // 中文注释: 正式导入继续复用 core 用例，服务层只承担项目上下文注入。
    return _importUseCase.execute(
      project: project,
      bundleContent: bundleContent,
      overwrite: overwrite,
    );
  }

  Future<JsonMap> exportBundle(
    ProjectDescriptor project, {
    String title = '',
    String description = '',
  }) async {
    // 中文注释: 导出资产包前统一重读当前资产，保证 CLI/GUI 拿到的是同一份项目快照。
    final styles = (await listStyles(
      project,
    )).map(_styleNormalizerService.normalize).toList(growable: false);
    final foreshadows = (await listForeshadows(
      project,
    )).map(_foreshadowNormalizerService.normalize).toList(growable: false);
    return _saveBundleUseCase.execute(
      project: project,
      styles: styles,
      foreshadows: foreshadows,
      title: title,
      description: description,
    );
  }

  Future<String?> readExternalBundle(String absolutePath) {
    // 中文注释: 外部 bundle 文本读取集中到资产服务，CLI 和 GUI 不再直接碰宿主适配细节。
    return _projectToolHostPort.readExternalTextFile(absolutePath);
  }

  bool _isStylePath(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (!lower.startsWith('styles/')) {
      return false;
    }
    return lower.endsWith('.style.md') || lower.endsWith('.md');
  }

  bool _isForeshadowPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (!lower.startsWith('world/foreshadows/')) {
      return false;
    }
    return lower.endsWith('.foreshadow.md') || lower.endsWith('.md');
  }

  String _stylePath(String styleId) => 'styles/$styleId.style.md';

  String _foreshadowPath(String recordId) =>
      'world/foreshadows/$recordId.foreshadow.md';

  String _fallbackIdFromPath(String relativePath) {
    var name = relativePath.split('/').last;
    if (name.toLowerCase().endsWith('.style.md')) {
      name = name.substring(0, name.length - '.style.md'.length);
    } else if (name.toLowerCase().endsWith('.foreshadow.md')) {
      name = name.substring(0, name.length - '.foreshadow.md'.length);
    } else if (name.toLowerCase().endsWith('.md')) {
      name = name.substring(0, name.length - '.md'.length);
    }
    return name.trim();
  }

  Future<String> _resolveExistingAssetPath(
    String rootPath, {
    required String preferredPath,
    required String legacyPath,
  }) async {
    if (await _fileMutationAdapter.entryExists(rootPath, preferredPath)) {
      return preferredPath;
    }
    if (await _fileMutationAdapter.entryExists(rootPath, legacyPath)) {
      return legacyPath;
    }
    return '';
  }
}
