import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';

class AssetCommand {
  const AssetCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required ProjectAssetLibraryService assetLibraryService,
    required TerminalPrinter printer,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _assetLibraryService = assetLibraryService,
       _printer = printer;

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final ProjectAssetLibraryService _assetLibraryService;
  final TerminalPrinter _printer;

  Future<int> run(List<String> args) async {
    // 中文注释: asset 命令组只暴露项目资产入口，具体 frontmatter 与 bundle 规则全部复用共享服务。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'list':
        return _runList(rest);
      case 'show':
        return _runShow(rest);
      case 'save-style':
        return _runSaveStyle(rest);
      case 'save-foreshadow':
        return _runSaveForeshadow(rest);
      case 'delete-style':
        return _runDeleteStyle(rest);
      case 'delete-foreshadow':
        return _runDeleteForeshadow(rest);
      case 'import-bundle':
        return _runImportBundle(rest);
      case 'export-bundle':
        return _runExportBundle(rest);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 asset 子命令: $action');
        _printHelp();
        return 2;
    }
  }

  Future<int> _runList(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final kind = _optionValue(args, '--kind') ?? 'style';
    final items = kind == 'foreshadow'
        ? await _assetLibraryService.listForeshadows(context.project)
        : await _assetLibraryService.listStyles(context.project);
    if (items.isEmpty) {
      _printer.info('当前没有${kind == "foreshadow" ? "伏笔" : "风格"}资产。');
      return 0;
    }
    _printer.block(
      '资产列表',
      items
          .map((item) {
            final title = kind == 'foreshadow'
                ? ValueReaders.stringValue(item['title'])
                : ValueReaders.stringValue(item['display_name']);
            final path = ValueReaders.stringValue(item['relative_path']);
            return '${ValueReaders.stringValue(item['id'])}｜$title｜$path';
          })
          .join('\n'),
    );
    return 0;
  }

  Future<int> _runShow(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final kind = _optionValue(args, '--kind') ?? 'style';
    final assetId = _optionValue(args, '--id') ?? '';
    if (assetId.trim().isEmpty) {
      _printer.error('请通过 --id 指定资产。');
      return 2;
    }
    final items = kind == 'foreshadow'
        ? await _assetLibraryService.listForeshadows(context.project)
        : await _assetLibraryService.listStyles(context.project);
    for (final item in items) {
      if (ValueReaders.stringValue(item['id']) == assetId.trim()) {
        _printer.block('资产详情', _prettyJson(item));
        return 0;
      }
    }
    _printer.error('未找到对应资产。');
    return 1;
  }

  Future<int> _runSaveStyle(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _assetLibraryService.saveStyle(
      context.project,
      <String, Object?>{
        'id': _optionValue(args, '--id') ?? '',
        'display_name': _optionValue(args, '--name') ?? '',
        'summary': _optionValue(args, '--summary') ?? '',
        'genre': _optionValue(args, '--genre') ?? '',
        'tone': _optionValue(args, '--tone') ?? '',
        'audience': _optionValue(args, '--audience') ?? '',
        'tags': _commaList(_optionValue(args, '--tags')),
        'guardrails': _commaList(_optionValue(args, '--guardrails')),
        'example_paths': _commaList(_optionValue(args, '--examples')),
        'inherited_from_ids': _commaList(_optionValue(args, '--inherits')),
        'default_for_project': _boolOption(args, '--default', false),
      },
    );
    return _printResult(result, success: '风格资产已保存。');
  }

  Future<int> _runSaveForeshadow(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _assetLibraryService.saveForeshadow(
      context.project,
      <String, Object?>{
        'id': _optionValue(args, '--id') ?? '',
        'title': _optionValue(args, '--title') ?? '',
        'status': _optionValue(args, '--status') ?? 'planted',
        'summary': _optionValue(args, '--summary') ?? '',
        'planted_chapter_path': _optionValue(args, '--planted') ?? '',
        'target_payoff_path': _optionValue(args, '--payoff') ?? '',
        'related_entity_ids': _commaList(_optionValue(args, '--entities')),
        'related_paths': _commaList(_optionValue(args, '--paths')),
        'trigger_conditions': _commaList(_optionValue(args, '--triggers')),
        'payoff_expectations': _commaList(_optionValue(args, '--expectations')),
        'tags': _commaList(_optionValue(args, '--tags')),
        'notes': _optionValue(args, '--notes') ?? '',
      },
    );
    return _printResult(result, success: '伏笔资产已保存。');
  }

  Future<int> _runDeleteStyle(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final assetId = _optionValue(args, '--id') ?? '';
    if (assetId.trim().isEmpty) {
      _printer.error('请通过 --id 指定风格。');
      return 2;
    }
    final result = await _assetLibraryService.deleteStyle(
      context.project,
      assetId,
    );
    return _printResult(result, success: '风格资产已删除。');
  }

  Future<int> _runDeleteForeshadow(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final assetId = _optionValue(args, '--id') ?? '';
    if (assetId.trim().isEmpty) {
      _printer.error('请通过 --id 指定伏笔。');
      return 2;
    }
    final result = await _assetLibraryService.deleteForeshadow(
      context.project,
      assetId,
    );
    return _printResult(result, success: '伏笔资产已删除。');
  }

  Future<int> _runImportBundle(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final sourcePath =
        _optionValue(args, '--source') ?? _optionValue(args, '--path') ?? '';
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source 指定资产包绝对路径。');
      return 2;
    }
    final bundleContent = await _assetLibraryService.readExternalBundle(
      sourcePath,
    );
    if ((bundleContent ?? '').trim().isEmpty) {
      _printer.error('资产包文件不存在或不可读。');
      return 2;
    }
    final styles = await _assetLibraryService.listStyles(context.project);
    final foreshadows = await _assetLibraryService.listForeshadows(
      context.project,
    );
    final preview = _assetLibraryService.previewImportBundle(
      context.project,
      bundleContent: bundleContent!,
      currentStyles: styles,
      currentForeshadows: foreshadows,
      overwrite: _boolOption(args, '--overwrite', false),
    );
    _printer.block('资产包预检', _prettyJson(preview));
    if (!ValueReaders.boolValue(preview['ok'])) {
      _printer.error('资产包预检失败。');
      return 1;
    }
    final result = await _assetLibraryService.importBundle(
      context.project,
      bundleContent: bundleContent,
      overwrite: _boolOption(args, '--overwrite', true),
    );
    return _printResult(result, success: '资产包已导入。');
  }

  Future<int> _runExportBundle(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _assetLibraryService.exportBundle(
      context.project,
      title: _optionValue(args, '--title') ?? '',
      description: _optionValue(args, '--description') ?? '',
    );
    return _printResult(result, success: '资产包已导出。');
  }

  Future<_ProjectContext?> _projectContext(List<String> args) async {
    final settings = await _settingsRepository.load();
    final projectPath =
        _optionValue(args, '--project') ?? settings.defaultProjectPath;
    if (projectPath.trim().isEmpty) {
      _printer.error('请通过 --project 指定项目路径。');
      return null;
    }
    final project = await _projectRepository.openByPath(projectPath);
    if (project == null) {
      _printer.error('项目不存在: $projectPath');
      return null;
    }
    return _ProjectContext(project);
  }

  int _printResult(JsonMap result, {required String success}) {
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.success(success);
    final path = ValueReaders.stringValue(
      result['relative_path'],
      ValueReaders.stringList(result['changed_paths']).join('、'),
    ).trim();
    if (path.isNotEmpty) {
      _printer.info(path);
    }
    return 0;
  }

  List<String> _commaList(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return const <String>[];
    }
    return value!
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
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

  String? _optionValue(List<String> args, String name) {
    for (var index = 0; index < args.length - 1; index += 1) {
      if (args[index] == name) {
        return args[index + 1];
      }
    }
    return null;
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  void _printHelp() {
    _printer.block(
      'asset help',
      [
        'asset list [--kind style|foreshadow] [--project 路径]',
        'asset show --kind style --id serial_style [--project 路径]',
        'asset save-style --id serial_style --name 连载风格 --summary "保持克制" [--genre 都市] [--tone 冷静] [--tags 悬疑,克制] [--project 路径]',
        'asset save-foreshadow --id tower_secret --title 高塔秘密 --summary "第一卷埋下" [--status planted] [--planted chapters/ch01.md] [--payoff chapters/ch21.md] [--project 路径]',
        'asset delete-style --id serial_style [--project 路径]',
        'asset delete-foreshadow --id tower_secret [--project 路径]',
        'asset import-bundle --source C:\\bundle.asset_bundle.json [--overwrite true|false] [--project 路径]',
        'asset export-bundle [--title 资产包标题] [--description 描述] [--project 路径]',
      ].join('\n'),
    );
  }
}

class _ProjectContext {
  const _ProjectContext(this.project);

  final ProjectDescriptor project;
}
