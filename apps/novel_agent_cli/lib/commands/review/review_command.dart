import 'dart:convert';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';

class ReviewCommand {
  const ReviewCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required ProjectReviewReportService reviewReportService,
    required TerminalPrinter printer,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _reviewReportService = reviewReportService,
       _printer = printer;

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final ProjectReviewReportService _reviewReportService;
  final TerminalPrinter _printer;

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
        return 2;
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
                '｜${ValueReaders.stringValue(report['markdown_path'])}',
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
      _printer.error(
        ValueReaders.stringValue(loaded['error'], '审稿报告不存在。'),
      );
      return 1;
    }
    final markdownBody = ValueReaders.stringValue(loaded['markdown_body']).trim();
    if (markdownBody.isNotEmpty) {
      _printer.block('审稿详情', markdownBody);
      return 0;
    }
    _printer.block('审稿详情', _prettyJson(ValueReaders.mapValue(loaded['report'])));
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
    final result = await _reviewReportService.createReviewTask(
      context.project,
      <String, Object?>{
        'source_path': sourcePath,
        'review_type': _optionValue(args, '--type') ?? ReviewTypeConstants.general,
        'scope': _optionValue(args, '--scope') ?? 'chapter',
        'title': _optionValue(args, '--title') ?? '',
        'goal': _optionValue(args, '--goal') ?? '',
      },
    );
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
    final settings = await _settingsRepository.load();
    final projectPath = _optionValue(args, '--project') ?? settings.defaultProjectPath;
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
      ValueReaders.stringValue(result['review_report_path']),
    ).trim();
    if (path.isNotEmpty) {
      _printer.info(path);
    }
    return 0;
  }

  String? _optionValue(List<String> args, String name) {
    for (var index = 0; index < args.length - 1; index += 1) {
      if (args[index] == name) {
        return args[index + 1];
      }
    }
    return null;
  }

  int _intOption(List<String> args, String name, int fallback) {
    return int.tryParse((_optionValue(args, name) ?? '').trim()) ?? fallback;
  }

  String _prettyJson(JsonMap value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  void _printHelp() {
    _printer.block(
      'review help',
      [
        'review list [--type continuity] [--scope chapter] [--source chapters/01.md] [--project 路径]',
        'review show --path reviews/continuity/chapter_01.md [--project 路径]',
        'review types',
        'review create-task --source-path chapters/01.md [--type continuity] [--project 路径]',
        'review repair-task --path reviews/continuity/chapter_01.md [--project 路径]',
      ].join('\n'),
    );
  }
}

class _ProjectContext {
  const _ProjectContext(this.project);

  final ProjectDescriptor project;
}
