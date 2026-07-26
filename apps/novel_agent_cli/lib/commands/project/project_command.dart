import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';
import '../shared/cli_project_context_loader.dart';
import '../../output/terminal_printer.dart';

typedef LoadAgentPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadAgentGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillPackages =
    Future<List<JsonMap>> Function(ProjectDescriptor project);
typedef LoadSkillGroups =
    Future<List<JsonMap>> Function(ProjectDescriptor project);

class ProjectCommand {
  const ProjectCommand({
    required LoadProjectWorkspaceUseCase loadProjectWorkspaceUseCase,
    required CreateProjectEntryUseCase createProjectEntryUseCase,
    required ImportProjectFilesUseCase importProjectFilesUseCase,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    required ProjectToolHostPort projectToolHostPort,
    required PreviewCustomizationBundleImportUseCase
    previewCustomizationBundleImportUseCase,
    required ImportCustomizationBundleUseCase importCustomizationBundleUseCase,
    required GenerateCustomizationIndexesUseCase
    generateCustomizationIndexesUseCase,
    required SaveCustomizationMarketIndexUseCase
    saveCustomizationMarketIndexUseCase,
    required SaveCustomizationBundleUseCase saveCustomizationBundleUseCase,
    required LoadAgentPackages loadAgentPackages,
    required LoadAgentGroups loadAgentGroups,
    required LoadSkillPackages loadSkillPackages,
    required LoadSkillGroups loadSkillGroups,
    required ProjectPackageLibraryService projectPackageLibraryService,
    required CliProjectContextLoader projectContextLoader,
    required TerminalPrinter printer,
    CliProjectArtifactLabelService? projectArtifactLabelService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
    ProjectContentPathPolicyService? contentPathPolicyService,
    SourceDocumentFormatCatalogService? sourceDocumentFormatCatalogService,
  }) : _loadProjectWorkspaceUseCase = loadProjectWorkspaceUseCase,
       _createProjectEntryUseCase = createProjectEntryUseCase,
       _importProjectFilesUseCase = importProjectFilesUseCase,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _projectToolHostPort = projectToolHostPort,
       _previewCustomizationBundleImportUseCase =
           previewCustomizationBundleImportUseCase,
       _importCustomizationBundleUseCase = importCustomizationBundleUseCase,
       _generateCustomizationIndexesUseCase =
           generateCustomizationIndexesUseCase,
       _saveCustomizationMarketIndexUseCase =
           saveCustomizationMarketIndexUseCase,
       _saveCustomizationBundleUseCase = saveCustomizationBundleUseCase,
       _loadAgentPackages = loadAgentPackages,
       _loadAgentGroups = loadAgentGroups,
       _loadSkillPackages = loadSkillPackages,
       _loadSkillGroups = loadSkillGroups,
       _projectPackageLibraryService = projectPackageLibraryService,
       _projectContextLoader = projectContextLoader,
       _printer = printer,
       _projectArtifactLabelService =
           projectArtifactLabelService ??
           const CliProjectArtifactLabelService(),
       _structuredContentBridgeService = structuredContentBridgeService,
       _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService(),
       _sourceDocumentFormatCatalogService =
           sourceDocumentFormatCatalogService ??
           const SourceDocumentFormatCatalogService();

  final LoadProjectWorkspaceUseCase _loadProjectWorkspaceUseCase;
  final CreateProjectEntryUseCase _createProjectEntryUseCase;
  final ImportProjectFilesUseCase _importProjectFilesUseCase;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final ProjectToolHostPort _projectToolHostPort;
  final PreviewCustomizationBundleImportUseCase
  _previewCustomizationBundleImportUseCase;
  final ImportCustomizationBundleUseCase _importCustomizationBundleUseCase;
  final GenerateCustomizationIndexesUseCase
  _generateCustomizationIndexesUseCase;
  final SaveCustomizationMarketIndexUseCase
  _saveCustomizationMarketIndexUseCase;
  final SaveCustomizationBundleUseCase _saveCustomizationBundleUseCase;
  final LoadAgentPackages _loadAgentPackages;
  final LoadAgentGroups _loadAgentGroups;
  final LoadSkillPackages _loadSkillPackages;
  final LoadSkillGroups _loadSkillGroups;
  final ProjectPackageLibraryService _projectPackageLibraryService;
  final CliProjectContextLoader _projectContextLoader;
  final TerminalPrinter _printer;
  final CliProjectArtifactLabelService _projectArtifactLabelService;
  final ProjectStructuredContentBridgeService? _structuredContentBridgeService;
  final ProjectContentPathPolicyService _contentPathPolicyService;
  final SourceDocumentFormatCatalogService _sourceDocumentFormatCatalogService;

  ProjectStructuredContentBridgeService
  get _structuredContentBridgeServiceOrDefault =>
      _structuredContentBridgeService ??
      ProjectStructuredContentBridgeService();

  Future<int> run(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: 项目命令复用共享项目用例，CLI 只负责参数解析和终端输出。
    final action = args.isEmpty ? 'summary' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'summary':
        return _runSummary(rest, defaultProjectPath: defaultProjectPath);
      case 'create-file':
        return _runCreateFile(rest, defaultProjectPath: defaultProjectPath);
      case 'create-folder':
        return _runCreateFolder(rest, defaultProjectPath: defaultProjectPath);
      case 'import':
        return _runImport(rest, defaultProjectPath: defaultProjectPath);
      case 'import-bundle':
        return _runImportBundle(rest, defaultProjectPath: defaultProjectPath);
      case 'preview-package':
        return _runPreviewPackage(rest, defaultProjectPath: defaultProjectPath);
      case 'import-package':
        return _runImportPackage(rest, defaultProjectPath: defaultProjectPath);
      case 'export-package':
        return _runExportPackage(rest, defaultProjectPath: defaultProjectPath);
      case 'generate-index':
        return _runGenerateIndex(rest, defaultProjectPath: defaultProjectPath);
      case 'save-bundle':
        return _runSaveBundle(rest, defaultProjectPath: defaultProjectPath);
      case 'update-info':
        return _runUpdateInfo(rest, defaultProjectPath: defaultProjectPath);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 project 子命令: $action');
        _printHelp();
        return CliExitCodes.invalidInput;
    }
  }

  Future<int> _runSummary(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: 项目摘要命令保留为最轻入口，便于快速确认工作区状态。
    final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
    ProjectWorkspaceSnapshot? snapshot;
    try {
      snapshot = await _loadProjectWorkspaceUseCase.execute(projectPath);
    } on ProjectManifestCorruptionException {
      _printer.error(CliProjectContextLoader.projectManifestCorruptionMessage);
      return CliExitCodes.invalidInput;
    }
    if (snapshot == null) {
      _printer.error('项目不存在: $projectPath');
      return CliExitCodes.invalidInput;
    }
    _printer.success('已打开项目: ${snapshot.project.name}');
    _printer.info('根目录: ${snapshot.project.rootPath}');
    _printer.info('资源条目: ${snapshot.entries.length}');
    final tree = ProjectPromptContract().projectTreeSummary(snapshot.entries);
    _printer.block('项目目录', tree);
    return 0;
  }

  Future<int> _runCreateFile(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final relativePath = _optionValue(args, '--path') ?? '';
    if (relativePath.trim().isEmpty) {
      _printer.error('请通过 --path 指定项目内相对路径。');
      return 2;
    }
    final content = _optionValue(args, '--content') ?? '';
    final primarySourceSnapshots = <String, SqliteProjectBodyTextDocument?>{};
    final result = await _createProjectEntryUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: content,
      prepareFileWrite:
          ({required project, required relativePath, required content}) {
            return _prepareCreatedFilePrimarySource(
              project: project,
              relativePath: relativePath,
              content: content,
              snapshots: primarySourceSnapshots,
            );
          },
      rollbackPreparedFileWrite:
          ({required project, required relativePath, required content}) {
            return _restoreCreatedFilePrimarySource(
              project: project,
              relativePath: relativePath,
              snapshots: primarySourceSnapshots,
            );
          },
    );
    return _printResult(result);
  }

  Future<void> _prepareCreatedFilePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    final snapshot = await _structuredContentBridgeServiceOrDefault
        .loadStructuredDocument(project: project, documentPath: relativePath);
    await _persistCreatedFilePrimarySource(
      project: project,
      relativePath: relativePath,
      content: content,
    );
    snapshots[relativePath] = snapshot;
  }

  Future<void> _restoreCreatedFilePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    if (!snapshots.containsKey(relativePath)) {
      return;
    }
    await _structuredContentBridgeServiceOrDefault.restoreStructuredDocument(
      project: project,
      documentPath: relativePath,
      snapshot: snapshots.remove(relativePath),
    );
  }

  Future<void> _persistCreatedFilePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required String content,
  }) {
    // 中文注释: CLI 新建的可编辑文本在 SQLite 项目先进入主库，随后才创建 Markdown 投影。
    final documentKind = _importedDocumentKind(project, relativePath);
    return _structuredContentBridgeServiceOrDefault.persistStructuredDocument(
      project: project,
      documentPath: relativePath,
      documentKind: documentKind,
      title: relativePath,
      content: content,
    );
  }

  Future<int> _runCreateFolder(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final relativePath = _optionValue(args, '--path') ?? '';
    if (relativePath.trim().isEmpty) {
      _printer.error('请通过 --path 指定项目内相对路径。');
      return 2;
    }
    final result = await _createProjectEntryUseCase.execute(
      project: project,
      relativePath: relativePath,
      isFolder: true,
    );
    return _printResult(result);
  }

  Future<int> _runImport(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final sourcePaths = _multiOptionValues(args, '--source');
    if (sourcePaths.isEmpty) {
      _printer.error('请至少通过 --source 提供一个外部文件路径。');
      return 2;
    }
    final primarySourceSnapshots = <String, SqliteProjectBodyTextDocument?>{};
    final result = await _importProjectFilesUseCase.execute(
      project: project,
      sourcePaths: sourcePaths,
      targetDirectory:
          _optionValue(args, '--target') ??
          const ProjectStorageStrategyPathPolicyService()
              .defaultImportTargetDirectory(project.storageStrategy),
      prepareImportedFile:
          ({required project, required sourcePath, required relativePath}) {
            return _prepareImportedFilePrimarySource(
              project: project,
              sourcePath: sourcePath,
              relativePath: relativePath,
              snapshots: primarySourceSnapshots,
            );
          },
      rollbackPreparedImportedFile:
          ({required project, required sourcePath, required relativePath}) {
            return _restoreImportedFilePrimarySource(
              project: project,
              relativePath: relativePath,
              snapshots: primarySourceSnapshots,
            );
          },
    );
    return _printResult(result);
  }

  Future<void> _prepareImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String sourcePath,
    required String relativePath,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    final snapshot = await _structuredContentBridgeServiceOrDefault
        .loadStructuredDocument(project: project, documentPath: relativePath);
    final persisted = await _persistImportedFilePrimarySource(
      project: project,
      sourcePath: sourcePath,
      relativePath: relativePath,
    );
    if (persisted) {
      snapshots[relativePath] = snapshot;
    }
  }

  Future<void> _restoreImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String relativePath,
    required Map<String, SqliteProjectBodyTextDocument?> snapshots,
  }) async {
    if (!snapshots.containsKey(relativePath)) {
      return;
    }
    await _structuredContentBridgeServiceOrDefault.restoreStructuredDocument(
      project: project,
      documentPath: relativePath,
      snapshot: snapshots.remove(relativePath),
    );
  }

  Future<bool> _persistImportedFilePrimarySource({
    required ProjectDescriptor project,
    required String sourcePath,
    required String relativePath,
  }) async {
    // 中文注释: 导入附件可能是二进制；仅将已有统一 reader 支持的文本格式同步到 SQLite 主事实源。
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return false;
    }
    if (!_sourceDocumentFormatCatalogService.supportsPath(sourcePath)) {
      return false;
    }
    final content = await _projectToolHostPort.readExternalTextFile(sourcePath);
    if (content == null) {
      return false;
    }
    final documentKind = _importedDocumentKind(project, relativePath);
    await _structuredContentBridgeServiceOrDefault.persistStructuredDocument(
      project: project,
      documentPath: relativePath,
      documentKind: documentKind,
      title: relativePath,
      content: content,
    );
    return true;
  }

  String _importedDocumentKind(ProjectDescriptor project, String relativePath) {
    final normalizedPath = relativePath.trim().replaceAll('\\', '/');
    final inferredKind = _contentPathPolicyService.inferContentTypeFromPath(
      normalizedPath,
    );
    if (project.projectType.trim() == 'knowledge_base' &&
        normalizedPath.startsWith('imports/') &&
        !normalizedPath.startsWith('imports/analysis/') &&
        !normalizedPath.startsWith('imports/source_original/') &&
        !normalizedPath.startsWith('imports/derived/')) {
      return 'knowledge';
    }
    return inferredKind;
  }

  Future<int> _runUpdateInfo(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    if (_optionValue(args, '--type') != null) {
      _printer.error('项目类型请通过专用转换流程修改，update-info 只更新项目元数据。');
      return 2;
    }
    await _updateProjectManifestUseCase.execute(
      project: project,
      title: _optionValue(args, '--title') ?? project.name,
      genre: _optionValue(args, '--genre') ?? '',
      premise: _optionValue(args, '--premise') ?? '',
      notes: _optionValue(args, '--notes') ?? '',
    );
    _printer.success('项目信息已更新。');
    return 0;
  }

  Future<int> _runImportBundle(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final sourcePath =
        _optionValue(args, '--source') ?? _optionValue(args, '--path') ?? '';
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source 指定生态包绝对路径。');
      return 2;
    }
    final bundleContent = await _projectToolHostPort.readExternalTextFile(
      sourcePath,
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      _printer.error('生态包文件不存在或不是可读文本。');
      return 2;
    }
    final projectAgents = await _loadAgentPackages(project);
    final projectSkills = await _loadSkillPackages(project);
    final projectSkillGroups = await _loadSkillGroups(project);
    final projectAgentGroups = await _loadAgentGroups(project);
    final preview = _previewCustomizationBundleImportUseCase.execute(
      bundleContent: bundleContent!,
      overwrite: _boolOption(args, '--overwrite', true),
      allowBuiltinShadow: _boolOption(args, '--allow-builtin-shadow', true),
      projectAgents: _projectScopedEntries(projectAgents, project),
      projectSkills: _projectScopedEntries(projectSkills, project),
      projectSkillGroups: _projectScopedEntries(projectSkillGroups, project),
      projectAgentGroups: _projectScopedEntries(projectAgentGroups, project),
      builtinAgents: _builtinScopedEntries(projectAgents, project),
      builtinSkills: _builtinScopedEntries(projectSkills, project),
      builtinSkillGroups: _builtinScopedEntries(projectSkillGroups, project),
      builtinAgentGroups: _builtinScopedEntries(projectAgentGroups, project),
    );
    _printer.block('生态包预检', _previewText(preview));
    if (!ValueReaders.boolValue(preview['ok'])) {
      _printer.error(ValueReaders.stringValue(preview['error'], '生态包预检失败。'));
      return 1;
    }
    final result = await _importCustomizationBundleUseCase.execute(
      project: project,
      bundleContent: bundleContent,
      overwrite: _boolOption(args, '--overwrite', true),
      allowBuiltinShadow: _boolOption(args, '--allow-builtin-shadow', true),
      builtinAgentIds: _idsOf(_builtinScopedEntries(projectAgents, project)),
      builtinSkillIds: _idsOf(_builtinScopedEntries(projectSkills, project)),
      builtinSkillGroupIds: _idsOf(
        _builtinScopedEntries(projectSkillGroups, project),
      ),
      builtinAgentGroupIds: _idsOf(
        _builtinScopedEntries(projectAgentGroups, project),
      ),
    );
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '生态包导入失败。'));
      return 1;
    }
    _printer.success(
      '生态包导入完成：${ValueReaders.stringList(result["changed_paths"]).length} 个文件，跳过 ${ValueReaders.stringList(result["skipped_paths"]).length} 个条目。',
    );
    return 0;
  }

  Future<int> _runPreviewPackage(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final sourcePath = _requiredSourcePath(args);
    if (sourcePath == null) {
      return 2;
    }
    final preview = await _projectPackageLibraryService.previewImport(
      project,
      sourcePath: sourcePath,
      overwrite: _boolOption(args, '--overwrite', false),
    );
    return _printBundlePreview(preview, title: '项目包预检');
  }

  Future<int> _runImportPackage(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final sourcePath = _requiredSourcePath(args);
    if (sourcePath == null) {
      return 2;
    }
    return _runBundleImportFlow(
      preview: await _projectPackageLibraryService.previewImport(
        project,
        sourcePath: sourcePath,
        overwrite: _boolOption(args, '--overwrite', false),
      ),
      plan: await _projectPackageLibraryService.buildImportWritePlan(
        project,
        sourcePath: sourcePath,
        overwrite: _boolOption(args, '--overwrite', false),
      ),
      result: await _projectPackageLibraryService.importBundle(
        project,
        sourcePath: sourcePath,
        overwrite: _boolOption(args, '--overwrite', false),
      ),
      previewTitle: '项目包预检',
      planTitle: '项目包写入计划',
      success: '项目包已导入。',
    );
  }

  Future<int> _runExportPackage(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final targetPath = _requiredTargetPath(args);
    if (targetPath == null) {
      return 2;
    }
    final result = await _projectPackageLibraryService.exportBundle(
      project,
      targetDirectoryPath: targetPath,
      title: _optionValue(args, '--title') ?? '',
      description: _optionValue(args, '--description') ?? '',
    );
    return _printExportResult(result, success: '项目包目录已导出。');
  }

  Future<int> _runGenerateIndex(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final rootPaths = await _generateCustomizationIndexesUseCase.execute(
      project,
    );
    final marketIndexResult = await _saveCustomizationMarketIndexUseCase
        .execute(project);
    final changedPaths = <String>[
      ...rootPaths,
      ...ValueReaders.stringList(marketIndexResult['changed_paths']),
    ];
    _printer.success('已生成生态索引。');
    for (final path in changedPaths) {
      _printer.info('已更新: ${_formatProjectArtifactPath(path)}');
    }
    return 0;
  }

  Future<int> _runSaveBundle(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final project = await _openProject(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final agents = _projectScopedEntries(
      await _loadAgentPackages(project),
      project,
    );
    final skills = _projectScopedEntries(
      await _loadSkillPackages(project),
      project,
    );
    final skillGroups = _projectScopedEntries(
      await _loadSkillGroups(project),
      project,
    );
    final agentGroups = _projectScopedEntries(
      await _loadAgentGroups(project),
      project,
    );
    final result = await _saveCustomizationBundleUseCase.execute(
      project: project,
      agents: agents,
      skills: skills,
      skillGroups: skillGroups,
      agentGroups: agentGroups,
      title: _optionValue(args, '--title') ?? '',
      description: _optionValue(args, '--description') ?? '',
    );
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '生态包导出失败。'));
      return CliExitCodes.executionFailure;
    }
    _printer.success('生态包已导出。');
    _printer.info(
      '项目路径: ${_formatProjectArtifactPath(ValueReaders.stringValue(result["relative_path"]))}',
    );
    return 0;
  }

  Future<ProjectDescriptor?> _openProject(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: 项目打开统一转交给 shared loader，命令层不再直接依赖 settings 和 project repository。
    final context = await _projectContextLoader.load(
      args,
      defaultProjectPath: defaultProjectPath,
    );
    if (context == null) {
      return null;
    }
    return context.project;
  }

  int _printResult(JsonMap result) {
    // 中文注释: 统一结果输出让 CLI 项目子命令保持相同的成功和失败口径。
    if (ValueReaders.boolValue(result['ok'])) {
      _printer.success(ValueReaders.stringValue(result['summary'], '操作完成。'));
      final relativePath = ValueReaders.stringValue(result['relative_path']);
      if (relativePath.trim().isNotEmpty) {
        _printer.info('项目路径: ${_formatProjectArtifactPath(relativePath)}');
      }
      for (final path in ValueReaders.stringList(result['imported_paths'])) {
        _printer.info('已导入: ${_formatProjectArtifactPath(path)}');
      }
      return 0;
    }
    _printer.error(ValueReaders.stringValue(result['error'], '项目操作失败。'));
    return 1;
  }

  Future<int> _runBundleImportFlow({
    required JsonMap preview,
    required JsonMap plan,
    required JsonMap result,
    required String previewTitle,
    required String planTitle,
    required String success,
  }) async {
    final previewCode = _printBundlePreview(preview, title: previewTitle);
    if (previewCode != 0) {
      return previewCode;
    }
    if (!ValueReaders.boolValue(plan['ok'])) {
      _printer.error(ValueReaders.stringValue(plan['error'], '写入计划生成失败。'));
      return 1;
    }
    _printer.block(
      planTitle,
      _prettyJson(ValueReaders.mapValue(plan['write_plan'])),
    );
    return _printResult(<String, Object?>{...result, 'summary': success});
  }

  int _printBundlePreview(JsonMap response, {required String title}) {
    if (!ValueReaders.boolValue(response['ok'])) {
      _printer.error(ValueReaders.stringValue(response['error'], '导入预检失败。'));
      return 1;
    }
    _printer.block(
      title,
      _prettyJson(ValueReaders.mapValue(response['preview'])),
    );
    return 0;
  }

  int _printExportResult(JsonMap result, {required String success}) {
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '导出失败。'));
      return 1;
    }
    _printer.success(success);
    _printer.info(
      ValueReaders.stringValue(
        result['export_directory_path'],
        ValueReaders.stringValue(result['bundle_file_path']),
      ),
    );
    return 0;
  }

  void _printHelp() {
    // 中文注释: 项目命令帮助只覆盖已经接通的共享用例入口。
    CliHelpContract.printHelpBlock(_printer, 'project help', [
      'project summary [--project 路径]',
      'project create-file --path chapters/ch01.md [--content 文本] [--project 路径]',
      'project create-folder --path world/sects [--project 路径]',
      'project import --source C:\\a.txt --source C:\\b.txt [--target assets] [--project 路径]',
      'project import-bundle --source C:\\bundle.customization.json [--overwrite true|false] [--allow-builtin-shadow true|false] [--project 路径]',
      'project preview-package --source C:\\bundle_dir [--overwrite true|false] [--project 路径]',
      'project import-package --source C:\\bundle_dir [--overwrite true|false] [--project 路径]',
      'project export-package --target C:\\exports [--title 标题] [--description 描述] [--project 路径]',
      'project generate-index [--project 路径]',
      'project save-bundle [--title 标题] [--description 描述] [--project 路径]',
      'project update-info --title 标题 [--genre 题材] [--premise 设定] [--notes 备注] [--project 路径]',
    ]);
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: project 命令现在只转发到共享 parser，不再自己扫描 token。
    return CliArguments(args).value(name);
  }

  String? _requiredSourcePath(List<String> args) {
    final sourcePath =
        _optionValue(args, '--source') ?? _optionValue(args, '--path') ?? '';
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source 指定 bundle 目录或 bundle.json 路径。');
      return null;
    }
    return sourcePath;
  }

  String? _requiredTargetPath(List<String> args) {
    final targetPath =
        _optionValue(args, '--target') ?? _optionValue(args, '--dir') ?? '';
    if (targetPath.trim().isEmpty) {
      _printer.error('请通过 --target 指定导出根目录。');
      return null;
    }
    return targetPath;
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  List<String> _multiOptionValues(List<String> args, String name) {
    // 中文注释: 多值参数统一交给共享 parser 处理，避免 import 场景重复散落 token 扫描。
    return CliArguments(args).values(name);
  }

  bool _boolOption(List<String> args, String name, bool fallback) {
    return CliArguments(args).boolValue(name, fallback);
  }

  List<JsonMap> _projectScopedEntries(
    List<JsonMap> entries,
    ProjectDescriptor project,
  ) {
    final result = <JsonMap>[];
    final projectRoot = Directory(project.rootPath).absolute.path.toLowerCase();
    for (final entry in entries) {
      final entryFilePath = ValueReaders.stringValue(
        entry['entry_file_path'],
      ).trim();
      if (entryFilePath.isEmpty) {
        continue;
      }
      final absolute = File(entryFilePath).absolute.path.toLowerCase();
      if (!absolute.startsWith(projectRoot)) {
        continue;
      }
      result.add(ValueReaders.deepCopyMap(entry));
    }
    return result;
  }

  List<JsonMap> _builtinScopedEntries(
    List<JsonMap> entries,
    ProjectDescriptor project,
  ) {
    final result = <JsonMap>[];
    final projectRoot = Directory(project.rootPath).absolute.path.toLowerCase();
    for (final entry in entries) {
      final entryFilePath = ValueReaders.stringValue(
        entry['entry_file_path'],
      ).trim();
      if (entryFilePath.isEmpty) {
        continue;
      }
      final absolute = File(entryFilePath).absolute.path.toLowerCase();
      if (absolute.startsWith(projectRoot)) {
        continue;
      }
      result.add(ValueReaders.deepCopyMap(entry));
    }
    return result;
  }

  List<String> _idsOf(List<JsonMap> entries) {
    final result = <String>[];
    for (final entry in entries) {
      final id = ValueReaders.stringValue(entry['id']).trim();
      if (id.isNotEmpty && !result.contains(id)) {
        result.add(id);
      }
    }
    return result;
  }

  String _previewText(JsonMap preview) {
    if (preview.isEmpty) {
      return '';
    }
    final summary = ValueReaders.mapValue(preview['summary']);
    final lines = <String>[
      '标题：${ValueReaders.stringValue(preview["title"], "生态包")}',
      '总计 ${ValueReaders.intValue(summary["total"])} 项；新增 ${ValueReaders.intValue(summary["new"])}；项目冲突 ${ValueReaders.intValue(summary["project_conflicts"])}；覆盖 ${ValueReaders.intValue(summary["will_overwrite"])}；跳过 ${ValueReaders.intValue(summary["skipped"])}；内置遮蔽 ${ValueReaders.intValue(summary["builtin_overrides"])}；已阻止内置遮蔽 ${ValueReaders.intValue(summary["blocked_builtin_overrides"])}。',
    ];
    final items = ValueReaders.objectList(
      preview['items'],
    ).map(ValueReaders.mapValue).toList(growable: false);
    final visibleCount = items.length < 8 ? items.length : 8;
    for (var index = 0; index < visibleCount; index += 1) {
      final item = items[index];
      lines.add(
        '- ${ValueReaders.stringValue(item["kind"])}/${ValueReaders.stringValue(item["id"])}: ${ValueReaders.stringValue(item["status"])} -> ${ValueReaders.stringValue(item["action"])}',
      );
    }
    if (items.length > visibleCount) {
      lines.add('- 其余 ${items.length - visibleCount} 项已省略。');
    }
    return lines.join('\n');
  }

  String _formatProjectArtifactPath(String relativePath) {
    // 中文注释: project CLI 统一在终端补充正式资产身份，避免不同子命令又各自打印裸路径。
    return _projectArtifactLabelService.formatPath(relativePath);
  }
}
