import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_mode_guidance_asset_sqlite_store.dart';
import 'project_json_document_service.dart';
import 'project_mode_guidance_sqlite_store.dart';

class ProjectModeGuidanceRepository implements ModeGuidanceStatePort {
  ProjectModeGuidanceRepository({
    required ProjectWorkspacePort workspacePort,
    ProjectJsonDocumentService? jsonDocumentService,
    ProjectModeGuidanceSqliteStore? sqliteStore,
    ProjectModeGuidanceAssetSqliteStore? assetSqliteStore,
    ModeGuidanceSummaryMarkdownRenderer? summaryMarkdownRenderer,
    ModeGuidanceProjectionDocumentService? projectionDocumentService,
    ModeGuidanceWorkspacePathService? workspacePathService,
    ModeGuidanceAssetBundleBuilderService? assetBundleBuilderService,
  }) : _workspacePort = workspacePort,
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _sqliteStore = sqliteStore ?? ProjectModeGuidanceSqliteStore(),
       _assetSqliteStore =
           assetSqliteStore ?? ProjectModeGuidanceAssetSqliteStore(),
       _summaryMarkdownRenderer =
           summaryMarkdownRenderer ?? ModeGuidanceSummaryMarkdownRenderer(),
       _projectionDocumentService =
           projectionDocumentService ??
           const ModeGuidanceProjectionDocumentService(),
       _workspacePathService =
           workspacePathService ?? const ModeGuidanceWorkspacePathService(),
       _assetBundleBuilderService =
           assetBundleBuilderService ??
           const ModeGuidanceAssetBundleBuilderService();

  final ProjectWorkspacePort _workspacePort;
  final ProjectJsonDocumentService _jsonDocumentService;
  final ProjectModeGuidanceSqliteStore _sqliteStore;
  final ProjectModeGuidanceAssetSqliteStore _assetSqliteStore;
  final ModeGuidanceSummaryMarkdownRenderer _summaryMarkdownRenderer;
  final ModeGuidanceProjectionDocumentService _projectionDocumentService;
  final ModeGuidanceWorkspacePathService _workspacePathService;
  final ModeGuidanceAssetBundleBuilderService _assetBundleBuilderService;

  @override
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    // 中文注释: 读取优先走隐藏 JSON，损坏或缺失时再回退 SQLite 索引恢复。
    final jsonPath = _workspacePathService.hiddenStateJsonPath(modeId);
    final document = await _jsonDocumentService.readJsonMap(
      project.rootPath,
      jsonPath,
    );
    if (document.isNotEmpty) {
      return ModeGuidanceState.fromJsonMap(document);
    }
    return _sqliteStore.load(project.rootPath, modeId);
  }

  @override
  Future<void> save(ProjectDescriptor project, ModeGuidanceState state) async {
    // 中文注释: 保存时同时写隐藏 JSON、可读 Markdown 和 SQLite 投影，满足恢复、浏览与索引三种诉求。
    final jsonPath = _workspacePathService.hiddenStateJsonPath(state.modeId);
    final markdownPath = _workspacePathService.summaryMarkdownPath(
      state.modeId,
    );
    await _jsonDocumentService.writeJsonMap(
      project.rootPath,
      jsonPath,
      state.toJsonMap(),
    );
    await _workspacePort.writeTextFile(
      project.rootPath,
      markdownPath,
      _summaryMarkdownRenderer.render(state),
    );
    final projectedDocuments = _projectionDocumentService.buildDocuments(state);
    for (final entry in projectedDocuments.entries) {
      await _workspacePort.writeTextFile(
        project.rootPath,
        entry.key,
        entry.value.trimRight() + '\n',
      );
    }
    await _sqliteStore.save(
      project.rootPath,
      state,
      markdownPath: markdownPath,
      statePath: jsonPath,
    );
    final assetBundle = _assetBundleBuilderService.build(state);
    await _assetSqliteStore.save(
      project.rootPath,
      assetBundle,
      statePath: jsonPath,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
    );
  }
}
