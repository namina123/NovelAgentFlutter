import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';

typedef CliGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(ProviderEndpointSettings provider);

class WorkflowCommand {
  const WorkflowCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required SaveDraftUseCase saveDraftUseCase,
    required CliGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required TerminalPrinter printer,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _saveDraftUseCase = saveDraftUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _printer = printer;

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final SaveDraftUseCase _saveDraftUseCase;
  final CliGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final TerminalPrinter _printer;

  Future<int> run(List<String> args) async {
    // 中文注释: workflow 命令当前先打通草稿生成最小闭环，让桌面端有真实可用的共享运行入口。
    final action = args.isEmpty ? 'help' : args.first;
    if (action == 'draft') {
      return _runDraft(args.skip(1).toList(growable: false));
    }
    _printHelp();
    return action == 'help' ? 0 : 2;
  }

  Future<int> _runDraft(List<String> args) async {
    // 中文注释: draft 子命令统一负责设置加载、项目打开、模型调用与可选自动保存。
    final settings = await _settingsRepository.load();
    final provider = settings.defaultProvider();
    if (provider == null) {
      _printer.error('未找到可用 provider。');
      return 2;
    }
    final projectPath =
        _optionValue(args, '--project') ?? settings.defaultProjectPath;
    final project = await _projectRepository.openByPath(projectPath);
    if (project == null) {
      _printer.error('项目不存在: $projectPath');
      return 2;
    }
    final prompt = _optionValue(args, '--prompt') ?? _joinedPositional(args);
    if (prompt.trim().isEmpty) {
      _printer.error('请通过 --prompt 或命令末尾文本提供创作需求。');
      return 2;
    }
    final title = _optionValue(args, '--title') ?? _titleFromPrompt(prompt);
    final noSave = args.contains('--no-save');
    final modelId = _optionValue(args, '--model');
    final resolvedModelId = modelId == null || modelId.trim().isEmpty
        ? (settings.defaultModelId.trim().isEmpty
              ? provider.modelId
              : settings.defaultModelId)
        : modelId;
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      _printer.error('请先在 novel_agent_settings.json 或环境变量中配置真实的模型接口地址和模型名。');
      return 2;
    }
    try {
      final useCase = _generateDraftUseCaseFactory(provider);
      final result = await useCase.execute(
        project: project,
        userPrompt: prompt,
        modelId: resolvedModelId,
        title: title,
      );
      var savedPath = result.writtenPaths.isEmpty
          ? ''
          : result.writtenPaths.first;
      if (savedPath.isEmpty && !noSave && settings.autoSaveDrafts) {
        savedPath = await _saveDraftUseCase.execute(
          project: project,
          content: result.draftMarkdown,
          title: title,
        );
      }
      _printer.success('草稿生成完成');
      _printer.info('项目: ${project.name}');
      _printer.info('模型: ${result.modelId}');
      _printer.info('上下文文件: ${result.selectedPaths.length}');
      _printer.info('工具调用: ${result.executedTools.length}');
      if (savedPath.isNotEmpty) {
        _printer.info('已保存: $savedPath');
      }
      _printer.block('草稿正文', result.draftMarkdown);
      return 0;
    } catch (error) {
      _printer.error('草稿生成失败: $error');
      return 1;
    }
  }

  void _printHelp() {
    // 中文注释: workflow 帮助只覆盖当前已经可用的子命令，避免暴露尚未接通的承诺接口。
    _printer.block(
      'workflow help',
      [
        'workflow draft --prompt "写第一章开场" [--project 路径] [--title 标题] [--model 模型] [--no-save]',
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

  String _joinedPositional(List<String> args) {
    // 中文注释: 非选项文本会被拼成 prompt，方便快速调用 CLI 做一次性生成。
    final parts = <String>[];
    for (var index = 0; index < args.length; index++) {
      final token = args[index];
      if (token.startsWith('--')) {
        if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
          index += 1;
        }
        continue;
      }
      parts.add(token);
    }
    return parts.join(' ').trim();
  }

  String _titleFromPrompt(String prompt) {
    // 中文注释: CLI 自动标题规则与 GUI 保持一致，确保两端生成的 drafts/ 命名口径相同。
    final firstLine = prompt.split('\n').first.trim();
    if (firstLine.isEmpty) {
      return '新草稿';
    }
    return firstLine.length > 24 ? firstLine.substring(0, 24) : firstLine;
  }
}
