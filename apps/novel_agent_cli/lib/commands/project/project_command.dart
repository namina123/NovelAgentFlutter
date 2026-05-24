import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

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
    required ProjectRepository projectRepository,
    required TerminalPrinter printer,
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
       _projectRepository = projectRepository,
       _printer = printer;

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
  final ProjectRepository _projectRepository;
  final TerminalPrinter _printer;

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
        return 2;
    }
  }

  Future<int> _runSummary(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    // 中文注释: 项目摘要命令保留为最轻入口，便于快速确认工作区状态。
    final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
    final snapshot = await _loadProjectWorkspaceUseCase.execute(projectPath);
    if (snapshot == null) {
      _printer.error('项目不存在: $projectPath');
      return 2;
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
    final result = await _createProjectEntryUseCase.execute(
      project: project,
      relativePath: relativePath,
      content: content,
    );
    return _printResult(result);
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
    final result = await _importProjectFilesUseCase.execute(
      project: project,
      sourcePaths: sourcePaths,
      targetDirectory: _optionValue(args, '--target') ?? '',
    );
    return _printResult(result);
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
    await _updateProjectManifestUseCase.execute(
      project: project,
      title: _optionValue(args, '--title') ?? project.name,
      projectType: _optionValue(args, '--type') ?? project.projectType,
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
      _printer.info('已更新: $path');
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
      return 1;
    }
    _printer.success('生态包已导出。');
    _printer.info('项目路径: ${ValueReaders.stringValue(result["relative_path"])}');
    return 0;
  }

  Future<ProjectDescriptor?> _openProject(
    List<String> args, {
    required String defaultProjectPath,
  }) {
    final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
    return _projectRepository.openByPath(projectPath);
  }

  int _printResult(JsonMap result) {
    // 中文注释: 统一结果输出让 CLI 项目子命令保持相同的成功和失败口径。
    if (ValueReaders.boolValue(result['ok'])) {
      _printer.success(ValueReaders.stringValue(result['summary'], '操作完成。'));
      final relativePath = ValueReaders.stringValue(result['relative_path']);
      if (relativePath.trim().isNotEmpty) {
        _printer.info('项目路径: $relativePath');
      }
      for (final path in ValueReaders.stringList(result['imported_paths'])) {
        _printer.info('已导入: $path');
      }
      return 0;
    }
    _printer.error(ValueReaders.stringValue(result['error'], '项目操作失败。'));
    return 1;
  }

  void _printHelp() {
    // 中文注释: 项目命令帮助只覆盖已经接通的共享用例入口。
    _printer.block(
      'project help',
      [
        'project summary [--project 路径]',
        'project create-file --path chapters/ch01.md [--content 文本] [--project 路径]',
        'project create-folder --path world/sects [--project 路径]',
        'project import --source C:\\a.txt --source C:\\b.txt [--target assets] [--project 路径]',
        'project import-bundle --source C:\\bundle.customization.json [--overwrite true|false] [--allow-builtin-shadow true|false] [--project 路径]',
        'project generate-index [--project 路径]',
        'project save-bundle [--title 标题] [--description 描述] [--project 路径]',
        'project update-info --title 标题 [--type novel] [--genre 题材] [--premise 设定] [--notes 备注] [--project 路径]',
      ].join('\n'),
    );
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: 轻量参数解析集中在命令类内部，当前阶段不为了少量选项提前引入命令框架。
    final index = args.indexOf(name);
    if (index < 0 || index + 1 >= args.length) {
      return null;
    }
    return args[index + 1].trim();
  }

  List<String> _multiOptionValues(List<String> args, String name) {
    // 中文注释: 重复选项值集中解析，避免 import 等命令手写多套参数扫描逻辑。
    final result = <String>[];
    for (var index = 0; index < args.length; index += 1) {
      if (args[index] != name) {
        continue;
      }
      if (index + 1 >= args.length) {
        continue;
      }
      final value = args[index + 1].trim();
      if (value.isNotEmpty) {
        result.add(value);
      }
      index += 1;
    }
    return result;
  }

  bool _boolOption(List<String> args, String name, bool fallback) {
    final value = _optionValue(args, name);
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'yes' ||
        normalized == 'on';
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
}
