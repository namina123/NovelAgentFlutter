import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';
import '../shared/cli_project_context_loader.dart';
import '../../output/terminal_printer.dart';

class TemplateCommand {
  const TemplateCommand({
    required ProjectPromptTemplateService promptTemplateService,
    required CliProjectContextLoader projectContextLoader,
    required TerminalPrinter printer,
    CliProjectArtifactLabelService? projectArtifactLabelService,
  }) : _promptTemplateService = promptTemplateService,
       _projectContextLoader = projectContextLoader,
       _printer = printer,
       _projectArtifactLabelService =
           projectArtifactLabelService ?? const CliProjectArtifactLabelService();

  final ProjectPromptTemplateService _promptTemplateService;
  final CliProjectContextLoader _projectContextLoader;
  final TerminalPrinter _printer;
  final CliProjectArtifactLabelService _projectArtifactLabelService;

  Future<int> run(List<String> args) async {
    // 中文注释: template 命令组只暴露模板浏览、预览和保存壳层，模板规则仍全部复用共享服务。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'list':
        return _runList(rest);
      case 'show':
        return _runShow(rest);
      case 'preview':
        return _runPreview(rest);
      case 'save':
        return _runSave(rest);
      case 'delete':
        return _runDelete(rest);
      case 'restore':
        return _runRestore(rest);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 template 子命令: $action');
        _printHelp();
        return CliExitCodes.invalidInput;
    }
  }

  Future<int> _runList(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final templates = await _promptTemplateService.listMergedTemplates(
      context.project,
    );
    if (templates.isEmpty) {
      _printer.info('当前没有模板。');
      return 0;
    }
    _printer.block(
      '模板列表',
      templates
          .map(
            (item) =>
                '${ValueReaders.stringValue(item['id'])}'
                '｜${ValueReaders.stringValue(item['scope'], 'project')}'
                '｜${ValueReaders.stringValue(item['name'])}',
          )
          .join('\n'),
    );
    return 0;
  }

  Future<int> _runShow(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final template = await _findTemplate(
      context.project,
      _optionValue(args, '--id') ?? '',
    );
    if (template == null) {
      _printer.error('模板不存在。');
      return CliExitCodes.executionFailure;
    }
    _printer.block('模板详情', _prettyJson(template));
    return 0;
  }

  Future<int> _runPreview(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final templateId = _optionValue(args, '--id') ?? '';
    if (templateId.trim().isEmpty) {
      _printer.error('请通过 --id 指定模板。');
      return 2;
    }
    final variablesText = _optionValue(args, '--vars') ?? '{}';
    JsonMap variables = const <String, Object?>{};
    try {
      variables = ValueReaders.mapValue(jsonDecode(variablesText));
    } catch (_) {
      _printer.error('--vars 必须是合法 JSON 对象。');
      return 2;
    }
    final preview = await _promptTemplateService.preview(
      context.project,
      templateId,
      variables,
    );
    if (!ValueReaders.boolValue(preview['ok'])) {
      _printer.error(ValueReaders.stringValue(preview['error'], '模板预览失败。'));
      return CliExitCodes.executionFailure;
    }
    _printer.block('模板预览', ValueReaders.stringValue(preview['content']));
    return 0;
  }

  Future<int> _runSave(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final templateId = _optionValue(args, '--id') ?? '';
    final content = _optionValue(args, '--content') ?? '';
    if (templateId.trim().isEmpty || content.trim().isEmpty) {
      _printer.error('请至少通过 --id 和 --content 提供模板信息。');
      return 2;
    }
    final result = await _promptTemplateService
        .saveTemplate(context.project, <String, Object?>{
          'id': templateId,
          'name': _optionValue(args, '--name') ?? templateId,
          'scope': _optionValue(args, '--scope') ?? 'project',
          'description': _optionValue(args, '--description') ?? '',
          'content': content,
        });
    return _printResult(result, success: '模板已保存。');
  }

  Future<int> _runDelete(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final templateId = _optionValue(args, '--id') ?? '';
    if (templateId.trim().isEmpty) {
      _printer.error('请通过 --id 指定模板。');
      return 2;
    }
    final result = await _promptTemplateService.deleteProjectTemplate(
      context.project,
      templateId,
    );
    return _printResult(result, success: '模板覆盖已删除。');
  }

  Future<int> _runRestore(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final templateId = _optionValue(args, '--id') ?? '';
    if (templateId.trim().isEmpty) {
      _printer.error('请通过 --id 指定模板。');
      return 2;
    }
    final result = await _promptTemplateService.restoreDefaultTemplate(
      context.project,
      templateId,
    );
    return _printResult(result, success: '已恢复内置模板。');
  }

  Future<_ProjectContext?> _projectContext(List<String> args) async {
    // 中文注释: template 命令与其他项目相关命令共用同一个项目加载入口，避免默认路径与项目打开逻辑重复散落。
    final context = await _projectContextLoader.load(args);
    if (context == null) {
      return null;
    }
    return _ProjectContext(context.project);
  }

  Future<JsonMap?> _findTemplate(
    ProjectDescriptor project,
    String templateId,
  ) async {
    if (templateId.trim().isEmpty) {
      return null;
    }
    final templates = await _promptTemplateService.listMergedTemplates(project);
    for (final template in templates) {
      if (ValueReaders.stringValue(template['id']) == templateId.trim()) {
        return template;
      }
    }
    return null;
  }

  int _printResult(JsonMap result, {required String success}) {
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.success(success);
    final path = ValueReaders.stringValue(result['relative_path']).trim();
    if (path.isNotEmpty) {
      _printer.info(_formatArtifactPath(path));
    }
    return 0;
  }

  String? _optionValue(List<String> args, String name) {
    return CliArguments(args).value(name);
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  String _formatArtifactPath(String relativePath) {
    return _projectArtifactLabelService.formatPath(relativePath);
  }

  void _printHelp() {
    CliHelpContract.printHelpBlock(_printer, 'template help', [
      'template list [--project 路径]',
      'template show --id review_report [--project 路径]',
      "template preview --id review_report --vars '{\"review_goal\":\"检查连续性\"}' [--project 路径]",
      'template save --id my_template --name 我的模板 --content "正文" [--description 说明] [--scope project] [--project 路径]',
      'template delete --id my_template [--project 路径]',
      'template restore --id review_report [--project 路径]',
    ]);
  }
}

class _ProjectContext {
  const _ProjectContext(this.project);

  final ProjectDescriptor project;
}
