import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../shared/cli_arguments.dart';
import '../shared/cli_exit_codes.dart';
import '../shared/cli_help_contract.dart';
import '../shared/cli_project_artifact_label_service.dart';
import '../shared/cli_project_context_loader.dart';
import '../../output/terminal_printer.dart';

class ReviewCommand {
  const ReviewCommand({
    required ProjectReviewReportService reviewReportService,
    required CliProjectContextLoader projectContextLoader,
    required TerminalPrinter printer,
    CliProjectArtifactLabelService? projectArtifactLabelService,
  }) : _reviewReportService = reviewReportService,
       _projectContextLoader = projectContextLoader,
       _printer = printer,
       _projectArtifactLabelService =
           projectArtifactLabelService ?? const CliProjectArtifactLabelService();

  final ProjectReviewReportService _reviewReportService;
  final CliProjectContextLoader _projectContextLoader;
  final TerminalPrinter _printer;
  final CliProjectArtifactLabelService _projectArtifactLabelService;

  Future<int> run(List<String> args) async {
    // 中文注释: review 命令组只做参数解析和终端输出，审稿报告的读取与任务生成仍走共享服务。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'list':
        return _runList(rest);
      case 'show':
        return _runShow(rest);
      case 'types':
        return _runTypes();
      case 'create-task':
        return _runCreateTask(rest);
      case 'repair-task':
        return _runRepairTask(rest);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 review 子命令: $action');
        _printHelp();
        return CliExitCodes.invalidInput;
    }
  }

  Future<int> _runList(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final reports = await _reviewReportService.listReports(
      context.project,
      filters: <String, Object?>{
        'review_type': _optionValue(args, '--type') ?? '',
        'scope': _optionValue(args, '--scope') ?? '',
        'source_path': _optionValue(args, '--source') ?? '',
      },
      limit: _intOption(args, '--limit', 50),
    );
    if (reports.isEmpty) {
      _printer.info('当前没有审稿报告。');
      return 0;
    }
    _printer.block(
      '审稿报告',
      reports
          .map(
            (report) =>
                '${ValueReaders.stringValue(report['review_type_label'])}'
                '｜${ValueReaders.intValue(report['issue_count'])} 条'
                '｜${ValueReaders.stringValue(report['title'])}'
                '｜${_formatArtifactPath(ValueReaders.stringValue(report['markdown_path']))}',
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
    final path = _optionValue(args, '--path') ?? '';
    if (path.trim().isEmpty) {
      _printer.error('请通过 --path 指定 reviews/ 下的 Markdown 或 JSON 路径。');
      return 2;
    }
    final loaded = await _reviewReportService.loadReport(context.project, path);
    if (!ValueReaders.boolValue(loaded['ok'])) {
      _printer.error(ValueReaders.stringValue(loaded['error'], '审稿报告不存在。'));
      return CliExitCodes.executionFailure;
    }
    final markdownBody = ValueReaders.stringValue(
      loaded['markdown_body'],
    ).trim();
    if (markdownBody.isNotEmpty) {
      _printer.block('审稿详情', markdownBody);
      return 0;
    }
    _printer.block(
      '审稿详情',
      _prettyJson(ValueReaders.mapValue(loaded['report'])),
    );
    return 0;
  }

  int _runTypes() {
    final types = _reviewReportService.listReviewTypeDefs();
    _printer.block(
      '审稿类型',
      types
          .map(
            (item) =>
                '${ValueReaders.stringValue(item['id'])}｜${ValueReaders.stringValue(item['name'])}',
          )
          .join('\n'),
    );
    return 0;
  }

  Future<int> _runCreateTask(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final sourcePath = _optionValue(args, '--source-path') ?? '';
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source-path 指定需要审稿的项目内路径。');
      return 2;
    }
    final result = await _reviewReportService
        .createReviewTask(context.project, <String, Object?>{
          'source_path': sourcePath,
          'review_type':
              _optionValue(args, '--type') ?? ReviewTypeConstants.general,
          'scope': _optionValue(args, '--scope') ?? 'chapter',
          'title': _optionValue(args, '--title') ?? '',
          'goal': _optionValue(args, '--goal') ?? '',
        });
    return _printResult(result, success: '审稿任务已创建。');
  }

  Future<int> _runRepairTask(List<String> args) async {
    final context = await _projectContext(args);
    if (context == null) {
      return 2;
    }
    final path = _optionValue(args, '--path') ?? '';
    if (path.trim().isEmpty) {
      _printer.error('请通过 --path 指定审稿报告路径。');
      return 2;
    }
    final result = await _reviewReportService.createReviewRepairTask(
      context.project,
      path,
    );
    return _printResult(result, success: '修复任务已创建。');
  }

  Future<_ProjectContext?> _projectContext(List<String> args) async {
    // 中文注释: review 命令直接复用 shared 项目上下文加载，避免重复实现 settings/project 打开逻辑。
    final context = await _projectContextLoader.load(args);
    if (context == null) {
      return null;
    }
    return _ProjectContext(context.project);
  }

  int _printResult(JsonMap result, {required String success}) {
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.success(success);
    final path = ValueReaders.stringValue(
      result['relative_path'],
      ValueReaders.stringValue(result['review_report_path']),
    ).trim();
    if (path.isNotEmpty) {
      _printer.info(_formatArtifactPath(path));
    }
    return 0;
  }

  String? _optionValue(List<String> args, String name) {
    return CliArguments(args).value(name);
  }

  int _intOption(List<String> args, String name, int fallback) {
    return CliArguments(args).intValue(name, fallback);
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  String _formatArtifactPath(String relativePath) {
    return _projectArtifactLabelService.formatPath(relativePath);
  }

  void _printHelp() {
    CliHelpContract.printHelpBlock(_printer, 'review help', [
      'review list [--type continuity] [--scope chapter] [--source chapters/01.md] [--project 路径]',
      'review show --path reviews/continuity/chapter_01.md [--project 路径]',
      'review types',
      'review create-task --source-path chapters/01.md [--type continuity] [--project 路径]',
      'review repair-task --path reviews/continuity/chapter_01.md [--project 路径]',
    ]);
  }
}

class _ProjectContext {
  const _ProjectContext(this.project);

  final ProjectDescriptor project;
}
