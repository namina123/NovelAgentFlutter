import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_project_file_mutation_adapter.dart';
import 'project_structured_content_bridge_service.dart';

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
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
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
           ),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

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
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<List<JsonMap>> listStyles(ProjectDescriptor project) async {
    // 中文注释: 风格列表只负责项目内 styles/ 资产，不混入其他普通 Markdown 文档。
    final entries = await _workspacePort.listEntries(project.rootPath);
    final result = <JsonMap>[];
    final seenIds = <String>{};
    void addStyle(String content, String relativePath) {
      if (content.trim().isEmpty) {
        return;
      }
      final parsed = _styleParserService.parseDocument(
        content,
        fallbackId: _fallbackIdFromPath(relativePath),
        relativePath: relativePath,
      );
      final id = ValueReaders.stringValue(parsed['id']).trim();
      if (id.isEmpty || seenIds.contains(id)) {
        return;
      }
      seenIds.add(id);
      result.add(parsed);
    }

    final structuredDocuments = await _structuredContentBridgeService
        .listStructuredDocuments(project: project);
    for (final document in structuredDocuments) {
      final relativePath = document.markdownPath.trim().isEmpty
          ? document.documentId
          : document.markdownPath;
      if (!_isStylePath(relativePath)) {
        continue;
      }
      addStyle(document.combinedText(), relativePath);
    }
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !_isStylePath(relativePath)) {
        continue;
      }
      final content =
          await _structuredContentBridgeService.readProjectedBodyText(
            project,
            relativePath,
          ) ??
          await _workspacePort.readTextFile(project.rootPath, relativePath);
      addStyle(content ?? '', relativePath);
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
    final seenIds = <String>{};
    void addForeshadow(String content, String relativePath) {
      if (content.trim().isEmpty) {
        return;
      }
      final parsed = _foreshadowParserService.parseDocument(
        content,
        fallbackId: _fallbackIdFromPath(relativePath),
        relativePath: relativePath,
      );
      final id = ValueReaders.stringValue(parsed['id']).trim();
      if (id.isEmpty || seenIds.contains(id)) {
        return;
      }
      seenIds.add(id);
      result.add(parsed);
    }

    final structuredDocuments = await _structuredContentBridgeService
        .listStructuredDocuments(project: project);
    for (final document in structuredDocuments) {
      final relativePath = document.markdownPath.trim().isEmpty
          ? document.documentId
          : document.markdownPath;
      if (!_isForeshadowPath(relativePath)) {
        continue;
      }
      addForeshadow(document.combinedText(), relativePath);
    }
    for (final entry in entries) {
      final relativePath = ValueReaders.stringValue(entry['relative_path']);
      final isDir = ValueReaders.boolValue(entry['is_dir']);
      if (isDir || !_isForeshadowPath(relativePath)) {
        continue;
      }
      final content =
          await _structuredContentBridgeService.readProjectedBodyText(
            project,
            relativePath,
          ) ??
          await _workspacePort.readTextFile(project.rootPath, relativePath);
      addForeshadow(content ?? '', relativePath);
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
    final content = _styleCodecService.encode(normalized);
    await _saveAssetWithCompensation(
      project: project,
      relativePath: relativePath,
      documentKind: 'style',
      title: normalized.displayName,
      content: content,
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
    final content = _foreshadowCodecService.encode(normalized);
    await _saveAssetWithCompensation(
      project: project,
      relativePath: relativePath,
      documentKind: 'foreshadow_record',
      title: normalized.title,
      content: content,
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
      project,
      preferredPath: _stylePath(styleId),
      legacyPath: 'styles/$styleId.md',
    );
    if (relativePath.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '未找到对应风格文件。'};
    }
    await _deleteAssetWithCompensation(
      project: project,
      relativePath: relativePath,
      documentKind: 'style',
    );
    return <String, Object?>{'ok': true, 'relative_path': relativePath};
  }

  Future<JsonMap> deleteForeshadow(
    ProjectDescriptor project,
    String recordId,
  ) async {
    final relativePath = await _resolveExistingAssetPath(
      project,
      preferredPath: _foreshadowPath(recordId),
      legacyPath: 'world/foreshadows/$recordId.md',
    );
    if (relativePath.isEmpty) {
      return <String, Object?>{'ok': false, 'error': '未找到对应伏笔文件。'};
    }
    await _deleteAssetWithCompensation(
      project: project,
      relativePath: relativePath,
      documentKind: 'foreshadow_record',
    );
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
  }) async {
    // 中文注释: core 用例会先写 SQLite 主事实源再写 Markdown 投影；导入任一文件失败时，
    // 必须把此前已处理的资产一起恢复，不能留下只存在于 SQLite 的半导入记录。
    final snapshots = <String, _AssetDocumentSnapshot>{};
    try {
      return await _importUseCase.execute(
        project: project,
        bundleContent: bundleContent,
        overwrite: overwrite,
        prepareDocumentWrite:
            ({
              required ProjectDescriptor project,
              required String relativePath,
              required String documentKind,
              required String title,
              required String content,
            }) async {
              final documentPath = relativePath.trim();
              if (!snapshots.containsKey(documentPath)) {
                snapshots[documentPath] = await _captureAssetSnapshot(
                  project: project,
                  relativePath: documentPath,
                );
              }
              await _structuredContentBridgeService.persistStructuredDocument(
                project: project,
                documentPath: documentPath,
                documentKind: documentKind,
                title: title,
                content: content,
              );
            },
      );
    } catch (_) {
      for (final entry in snapshots.entries.toList(growable: false).reversed) {
        await _restoreAssetSnapshot(
          project: project,
          relativePath: entry.key,
          snapshot: entry.value,
        );
      }
      rethrow;
    }
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

  Future<void> _saveAssetWithCompensation({
    required ProjectDescriptor project,
    required String relativePath,
    required String documentKind,
    required String title,
    required String content,
  }) async {
    final snapshot = await _captureAssetSnapshot(
      project: project,
      relativePath: relativePath,
    );
    try {
      await _structuredContentBridgeService.persistStructuredDocument(
        project: project,
        documentPath: relativePath,
        documentKind: documentKind,
        title: title,
        content: content,
      );
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: content,
      );
    } catch (_) {
      await _restoreAssetSnapshot(
        project: project,
        relativePath: relativePath,
        snapshot: snapshot,
      );
      rethrow;
    }
  }

  Future<_AssetDocumentSnapshot> _captureAssetSnapshot({
    required ProjectDescriptor project,
    required String relativePath,
  }) async {
    final projectionExisted = await _fileMutationAdapter.entryExists(
      project.rootPath,
      relativePath,
    );
    final projectionContent = await _workspacePort.readTextFile(
      project.rootPath,
      relativePath,
    );
    final structuredDocument = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: relativePath);
    return _AssetDocumentSnapshot(
      structuredDocument: structuredDocument,
      projectionContent: projectionContent,
      projectionExisted: projectionExisted,
    );
  }

  Future<void> _restoreAssetSnapshot({
    required ProjectDescriptor project,
    required String relativePath,
    required _AssetDocumentSnapshot snapshot,
  }) async {
    await _restoreStructuredSnapshot(
      project: project,
      documentPath: relativePath,
      snapshot: snapshot.structuredDocument,
    );
    await _restoreProjectionSnapshot(
      project: project,
      relativePath: relativePath,
      content: snapshot.projectionContent,
      existedBeforeOperation: snapshot.projectionExisted,
    );
  }

  Future<void> _deleteAssetWithCompensation({
    required ProjectDescriptor project,
    required String relativePath,
    required String documentKind,
  }) async {
    final snapshot = await _captureAssetSnapshot(
      project: project,
      relativePath: relativePath,
    );
    try {
      await _structuredContentBridgeService.deleteStructuredDocument(
        project: project,
        documentPath: relativePath,
        documentKind: documentKind,
      );
      await _fileMutationAdapter.deleteEntry(project.rootPath, relativePath);
    } catch (_) {
      await _restoreAssetSnapshot(
        project: project,
        relativePath: relativePath,
        snapshot: snapshot,
      );
      rethrow;
    }
  }

  Future<void> _restoreStructuredSnapshot({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    try {
      await _structuredContentBridgeService.restoreStructuredDocument(
        project: project,
        documentPath: documentPath,
        snapshot: snapshot,
      );
    } catch (_) {
      // Preserve the original file operation failure for the caller.
    }
  }

  Future<void> _restoreProjectionSnapshot({
    required ProjectDescriptor project,
    required String relativePath,
    required String? content,
    required bool existedBeforeOperation,
  }) async {
    try {
      final exists = await _fileMutationAdapter.entryExists(
        project.rootPath,
        relativePath,
      );
      if (content == null) {
        if (!existedBeforeOperation && exists) {
          await _fileMutationAdapter.deleteEntry(
            project.rootPath,
            relativePath,
          );
        }
        return;
      }
      await _workspacePort.writeTextFile(
        project.rootPath,
        relativePath,
        content,
      );
    } catch (_) {
      // Projection recovery is best-effort; the SQLite snapshot above remains
      // authoritative when the filesystem itself is unavailable.
    }
  }

  bool _isStylePath(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (!lower.startsWith('assets/styles/') && !lower.startsWith('styles/')) {
      return false;
    }
    return lower.endsWith('.style.md') || lower.endsWith('.md');
  }

  bool _isForeshadowPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (!lower.startsWith('assets/foreshadows/') &&
        !lower.startsWith('world/foreshadows/')) {
      return false;
    }
    return lower.endsWith('.foreshadow.md') || lower.endsWith('.md');
  }

  String _stylePath(String styleId) => 'assets/styles/$styleId.style.md';

  String _foreshadowPath(String recordId) =>
      'assets/foreshadows/$recordId.foreshadow.md';

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
    ProjectDescriptor project, {
    required String preferredPath,
    required String legacyPath,
  }) async {
    if (await _fileMutationAdapter.entryExists(
      project.rootPath,
      preferredPath,
    )) {
      return preferredPath;
    }
    if (await _fileMutationAdapter.entryExists(project.rootPath, legacyPath)) {
      return legacyPath;
    }
    if (await _structuredContentBridgeService.loadStructuredDocument(
          project: project,
          documentPath: preferredPath,
        ) !=
        null) {
      return preferredPath;
    }
    if (await _structuredContentBridgeService.loadStructuredDocument(
          project: project,
          documentPath: legacyPath,
        ) !=
        null) {
      return legacyPath;
    }
    return '';
  }
}

class _AssetDocumentSnapshot {
  const _AssetDocumentSnapshot({
    required this.structuredDocument,
    required this.projectionContent,
    required this.projectionExisted,
  });

  final SqliteProjectBodyTextDocument? structuredDocument;
  final String? projectionContent;
  final bool projectionExisted;
}
