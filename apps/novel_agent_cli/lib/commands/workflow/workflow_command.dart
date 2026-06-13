import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../output/terminal_printer.dart';
import 'workflow_output_summary_service.dart';

typedef CliGenerateDraftUseCaseFactory =
    GenerateDraftUseCase Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef CliLlmGatewayFactory =
    LlmGateway Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );

class WorkflowCommand {
  WorkflowCommand({
    required SettingsRepository settingsRepository,
    required ProjectRepository projectRepository,
    required SaveDraftUseCase saveDraftUseCase,
    required BuildModeGuidancePlanInputUseCase
    buildModeGuidancePlanInputUseCase,
    required LoadModeGuidanceStateUseCase loadModeGuidanceStateUseCase,
    required CliGenerateDraftUseCaseFactory generateDraftUseCaseFactory,
    required CliLlmGatewayFactory llmGatewayFactory,
    required ProjectWorkflowRuntimeService workflowRuntimeService,
    required ProjectReferenceExtractionRuntimeService
    referenceExtractionRuntimeService,
    required ProjectPendingResearchActionService pendingResearchActionService,
    required TerminalPrinter printer,
    ModelExecutionProfileService? modelExecutionProfileService,
    WorkflowOutputSummaryService? workflowOutputSummaryService,
    ProjectReferenceExtractionRequestBuilderService?
    referenceExtractionRequestBuilderService,
    ReferenceExtractionStrategyProfileOptionService?
    referenceExtractionStrategyProfileOptionService,
  }) : _settingsRepository = settingsRepository,
       _projectRepository = projectRepository,
       _saveDraftUseCase = saveDraftUseCase,
       _buildModeGuidancePlanInputUseCase = buildModeGuidancePlanInputUseCase,
       _loadModeGuidanceStateUseCase = loadModeGuidanceStateUseCase,
       _generateDraftUseCaseFactory = generateDraftUseCaseFactory,
       _llmGatewayFactory = llmGatewayFactory,
       _workflowRuntimeService = workflowRuntimeService,
       _referenceExtractionRuntimeService = referenceExtractionRuntimeService,
       _pendingResearchActionService = pendingResearchActionService,
       _printer = printer,
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _referenceExtractionRequestBuilderService =
           referenceExtractionRequestBuilderService ??
           const ProjectReferenceExtractionRequestBuilderService(),
       _referenceExtractionStrategyProfileOptionService =
           referenceExtractionStrategyProfileOptionService ??
           const ReferenceExtractionStrategyProfileOptionService(),
       _workflowOutputSummaryService =
           workflowOutputSummaryService ?? WorkflowOutputSummaryService();

  final SettingsRepository _settingsRepository;
  final ProjectRepository _projectRepository;
  final SaveDraftUseCase _saveDraftUseCase;
  final BuildModeGuidancePlanInputUseCase _buildModeGuidancePlanInputUseCase;
  final LoadModeGuidanceStateUseCase _loadModeGuidanceStateUseCase;
  final CliGenerateDraftUseCaseFactory _generateDraftUseCaseFactory;
  final CliLlmGatewayFactory _llmGatewayFactory;
  final ProjectWorkflowRuntimeService _workflowRuntimeService;
  final ProjectReferenceExtractionRuntimeService
  _referenceExtractionRuntimeService;
  final ProjectPendingResearchActionService _pendingResearchActionService;
  final TerminalPrinter _printer;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ProjectReferenceExtractionRequestBuilderService
  _referenceExtractionRequestBuilderService;
  final ReferenceExtractionStrategyProfileOptionService
  _referenceExtractionStrategyProfileOptionService;
  final WorkflowOutputSummaryService _workflowOutputSummaryService;

  Future<int> run(List<String> args) async {
    // 中文注释: workflow 命令从这里统一分发，确保 GUI 与 CLI 共享同一套长任务运行时而不是两套逻辑。
    final action = args.isEmpty ? 'help' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'draft':
        return _runDraft(rest);
      case 'extract-reference':
        return _runExtractReference(rest);
      case 'create':
        return _runCreate(rest);
      case 'list':
        return _runList(rest);
      case 'next':
        return _runNext(rest);
      case 'preflight':
        return _runPreflight(rest);
      case 'plan':
        return _runPlan(rest);
      case 'chain':
        return _runChain(rest);
      case 'prepare':
        return _runPrepare(rest);
      case 'run-once':
        return _runSelectedOnce(rest);
      case 'run-next':
        return _runNextOnce(rest);
      case 'run-queue':
        return _runQueue(rest);
      case 'guidance-status':
        return _runGuidanceStatus(rest);
      case 'create-from-guidance':
        return _runCreateFromGuidance(rest);
      case 'postprocess-once':
        return _runPostprocessOnce(rest);
      case 'postprocess-next':
        return _runPostprocessNext(rest);
      case 'complete-next':
        return _runCompleteAndNext(rest);
      case 'pause':
        return _runPause(rest);
      case 'resume':
        return _runResume(rest);
      case 'checkpoint-actions':
        return _runCheckpointActions(rest);
      case 'apply-checkpoint-action':
        return _runApplyCheckpointAction(rest);
      case 'revision-resolution':
        return _runRevisionResolution(rest);
      case 'apply-revision-resolution':
        return _runApplyRevisionResolution(rest);
      case 'accept-revision':
        return _runAcceptRevision(rest);
      case 'rollback-revision':
        return _runRollbackRevision(rest);
      case 'pending-research':
        return _runPendingResearch(rest);
      case 'help':
      case '--help':
      case '-h':
        _printHelp();
        return 0;
      default:
        _printer.error('未知 workflow 子命令: $action');
        _printHelp();
        return 2;
    }
  }

  Future<int> _runDraft(List<String> args) async {
    // 中文注释: draft 子命令统一负责设置加载、项目打开、模型调用与可选自动保存。
    final settings = await _settingsRepository.load();
    final provider = settings.defaultProvider();
    if (provider == null) {
      _printer.error('未找到可用 provider。');
      return 2;
    }
    final project = await _openProject(
      args,
      defaultProjectPath: settings.defaultProjectPath,
    );
    if (project == null) {
      return 2;
    }
    final prompt = _optionValue(args, '--prompt') ?? _joinedPositional(args);
    if (prompt.trim().isEmpty) {
      _printer.error('请通过 --prompt 或命令末尾文本提供创作需求。');
      return 2;
    }
    final title = _optionValue(args, '--title') ?? _titleFromPrompt(prompt);
    final noSave = args.contains('--no-save');
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      overrideModelId: _optionValue(args, '--model') ?? '',
    );
    final resolvedModelId = ValueReaders.stringValue(
      executionProfile['resolved_model_id'],
    );
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      _printer.error('请先在 novel_agent_settings.json 或环境变量中配置真实的模型接口地址和模型名。');
      return 2;
    }
    try {
      final useCase = _generateDraftUseCaseFactory(
        provider,
        settings.networkSettings,
      );
      final result = await useCase.execute(
        project: project,
        userPrompt: prompt,
        modelId: resolvedModelId,
        title: title,
        requestOptions: ValueReaders.mapValue(
          executionProfile['request_options'],
        ),
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
      _printer.success('内容生成完成');
      _printer.info('项目: ${project.name}');
      _printer.info('模型: ${result.modelId}');
      _printer.info('上下文文件: ${result.selectedPaths.length}');
      _printer.info('工具调用: ${result.executedTools.length}');
      if (savedPath.isNotEmpty) {
        _printer.info('已保存: $savedPath');
      }
      _printer.block('正文内容', result.draftMarkdown);
      return 0;
    } catch (error) {
      _printer.error('内容生成失败: $error');
      return 1;
    }
  }

  Future<int> _runCreate(List<String> args) async {
    // 中文注释: 长任务开局只生成计划与任务文件，方便 CLI 和 GUI 共用后续执行链。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService.createLongTaskWorkflow(
      context.project,
      _optionValue(args, '--mode') ??
          TaskRuntimeConstants.modeHumanOutlineAiDraft,
      options: <String, Object?>{
        'outline_path': _optionValue(args, '--outline') ?? 'outline/outline.md',
        'seed_prompt': _optionValue(args, '--seed') ?? '',
        'chapter_count': _intOption(args, '--chapters', 12),
        'checkpoint_interval': _intOption(args, '--checkpoint', 3),
      },
    );
    return _printWorkflowResult(result, success: '长任务队列已生成。');
  }

  Future<int> _runList(List<String> args) async {
    // 中文注释: 任务列表命令输出共享排序结果，便于终端快速核对当前项目队列。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final tasks = await _workflowRuntimeService.listWorkflowTasks(
      context.project,
    );
    if (tasks.isEmpty) {
      _printer.info('当前项目还没有任务。');
      return 0;
    }
    final lines = tasks
        .map(
          (task) =>
              '${ValueReaders.stringValue(task['status'])}'
              '｜${ValueReaders.stringValue(task['task_type'])}'
              '｜${ValueReaders.stringValue(task['title'])}'
              '｜${ValueReaders.stringValue(task['relative_path'])}',
        )
        .join('\n');
    _printer.block('任务列表', lines);
    return 0;
  }

  Future<int> _runNext(List<String> args) async {
    // 中文注释: 下一任务预览只显示共享调度层认定的下一条 runnable 任务。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final nextTask = await _workflowRuntimeService.nextWorkflowTask(
      context.project,
    );
    if (nextTask.isEmpty) {
      _printer.info('当前没有可运行任务。');
      return 0;
    }
    _printer.block('下一任务', _prettyJson(nextTask));
    return 0;
  }

  Future<int> _runPreflight(List<String> args) async {
    // 中文注释: 预检命令复用共享 preflight 规则，让 CLI 看到的阻塞原因和 GUI 完全一致。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService.taskQueuePreflight(
      context.project,
    );
    _printer.block('队列预检', _prettyJson(result));
    return ValueReaders.boolValue(result['runnable']) ? 0 : 1;
  }

  Future<int> _runPlan(List<String> args) async {
    // 中文注释: 单任务计划导出成 Markdown 文件，供先审阅再执行的终端流程使用。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.saveWorkflowTaskPlan(
      context.project,
      selector,
    );
    return _printWorkflowResult(result, success: '任务计划已生成。');
  }

  Future<int> _runChain(List<String> args) async {
    // 中文注释: 链路命令用于查看当前任务链结构和下一步位置，便于终端恢复现场。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService.workflowChainView(
      context.project,
    );
    _printer.block('任务链', _prettyJson(result));
    return 0;
  }

  Future<int> _runPrepare(List<String> args) async {
    // 中文注释: prepare 只生成执行包，不直接触发模型，适合先检查 prompt 和输出路径。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.prepareWorkflowTaskExecution(
      context.project,
      selector,
      contextSettings: context.settings.contextSettings,
    );
    return _printWorkflowResult(result, success: '执行包已准备完成。');
  }

  Future<int> _runSelectedOnce(List<String> args) async {
    // 中文注释: run-once 只推进指定任务一轮，方便终端精确控制节奏。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.runWorkflowTaskOnce(
      context.project,
      context.settings,
      selector,
    );
    return _printWorkflowResult(result, success: '当前任务已执行一轮。');
  }

  Future<int> _runNextOnce(List<String> args) async {
    // 中文注释: run-next 让共享调度层自己挑选下一可运行任务并推进一次。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService.runNextWorkflowTaskOnce(
      context.project,
      context.settings,
    );
    return _printWorkflowResult(result, success: '下一任务已执行一轮。');
  }

  Future<int> _runQueue(List<String> args) async {
    // 中文注释: run-queue 走共享受控连续运行逻辑，让 CLI 也遵守同样的安全停机规则。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService.runWorkflowTaskQueue(
      context.project,
      context.settings,
      options: <String, Object?>{'max_steps': _intOption(args, '--steps', 3)},
    );
    return _printWorkflowResult(result, success: '队列运行已推进。');
  }

  Future<int> _runGuidanceStatus(List<String> args) async {
    // 中文注释: guidance-status 只读取共享模式状态并输出，不触发任何模型或任务写入。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final modeId = _optionValue(args, '--mode') ?? 'seed_autopilot_novel';
    final state = await _loadModeGuidanceStateUseCase.execute(
      context.project,
      modeId: modeId,
      initializeIfMissing: false,
    );
    _printer.block('模式引导状态', _prettyJson(state.toJsonMap()));
    return 0;
  }

  Future<int> _runCreateFromGuidance(List<String> args) async {
    // 中文注释: create-from-guidance 直接把已收束的模式状态映射成共享任务骨架，CLI 不再要求用户重复手填同样信息。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final modeId = _optionValue(args, '--mode') ?? 'seed_autopilot_novel';
    final planInput = await _buildModeGuidancePlanInputUseCase.execute(
      context.project,
      modeId: modeId,
    );
    if (planInput == null) {
      _printer.error('当前项目还没有模式引导状态。');
      return 2;
    }
    if (!planInput.isReady) {
      _printer.error('当前模式信息尚未完成，缺失阶段：${planInput.missingFields.join(', ')}');
      return 2;
    }
    final result = await _workflowRuntimeService.createLongTaskWorkflow(
      context.project,
      planInput.runtimeMode,
      options: planInput.options,
    );
    return _printWorkflowResult(result, success: '已根据模式引导生成长任务队列。');
  }

  Future<int> _runPostprocessOnce(List<String> args) async {
    // 中文注释: 后处理单步不会改写正文规划，而是推进摘要、记忆和检查产物。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.runWorkflowTaskPostprocessOnce(
      context.project,
      context.settings,
      selector,
    );
    return _printWorkflowResult(result, success: '当前任务后处理已执行一轮。');
  }

  Future<int> _runPostprocessNext(List<String> args) async {
    // 中文注释: 自动选择下一条待后处理任务并推进一轮。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final result = await _workflowRuntimeService
        .runNextWorkflowTaskPostprocessOnce(context.project, context.settings);
    return _printWorkflowResult(result, success: '下一条后处理已执行一轮。');
  }

  Future<int> _runCompleteAndNext(List<String> args) async {
    // 中文注释: complete-next 用于人工确认后把当前任务标记完成，并尝试继续下一条。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.completeWorkflowTaskAndRunNext(
      context.project,
      context.settings,
      selector,
    );
    return _printWorkflowResult(result, success: '已完成当前任务，并尝试继续下一条。');
  }

  Future<int> _runPause(List<String> args) async {
    // 中文注释: 暂停优先使用命令参数指定运行记录，否则回退到最近一条长任务运行记录。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final runPath = await _resolveRunPath(context.project, args);
    if (runPath.isEmpty) {
      _printer.error('当前没有可暂停的长任务运行记录。');
      return 2;
    }
    final result = await _workflowRuntimeService.pauseLongTaskRun(
      context.project,
      runPath,
    );
    return _printWorkflowResult(result, success: '长任务运行已暂停。');
  }

  Future<int> _runResume(List<String> args) async {
    // 中文注释: 恢复长任务继续复用共享队列运行入口，不在 CLI 层另造一套继续逻辑。
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final runPath = await _resolveRunPath(context.project, args);
    if (runPath.isEmpty) {
      _printer.error('当前没有可恢复的长任务运行记录。');
      return 2;
    }
    final result = await _workflowRuntimeService.resumeLongTaskRun(
      context.project,
      context.settings,
      runPath,
    );
    return _printWorkflowResult(result, success: '长任务运行已恢复推进。');
  }

  Future<int> _runCheckpointActions(List<String> args) async {
    // 中文注释: checkpoint 动作合同只读取共享 runtime 输出，CLI 不自己重建动作判断。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final reviewPath = _optionValue(args, '--review') ?? '';
    if (reviewPath.trim().isEmpty) {
      _printer.error('请通过 --review 指定 checkpoint review 路径。');
      return 2;
    }
    final result = await _workflowRuntimeService
        .buildCheckpointReviewActionPackage(context.project, reviewPath.trim());
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.block('checkpoint 动作包', _prettyJson(result));
    return 0;
  }

  Future<int> _runApplyCheckpointAction(List<String> args) async {
    // 中文注释: checkpoint 动作应用统一转发给 runtime，CLI 只负责参数收集和结果展示。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final reviewPath = _optionValue(args, '--review') ?? '';
    final command = _optionValue(args, '--command') ?? '';
    if (reviewPath.trim().isEmpty || command.trim().isEmpty) {
      _printer.error('请通过 --review 和 --command 指定 checkpoint 动作。');
      return 2;
    }
    final result = await _workflowRuntimeService.applyCheckpointReviewAction(
      context.project,
      reviewPath.trim(),
      command.trim(),
    );
    return _printWorkflowResult(result, success: 'checkpoint 动作已应用。');
  }

  Future<int> _runRevisionResolution(List<String> args) async {
    // 中文注释: revision 收口合同也走共享 runtime，CLI 不重新推断当前能否返工或回滚。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择 revision 任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.buildRevisionResolution(
      context.project,
      selector,
    );
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.block('revision 收口动作', _prettyJson(result));
    return 0;
  }

  Future<int> _runApplyRevisionResolution(List<String> args) async {
    // 中文注释: revision 收口动作应用统一转发给 runtime，避免 CLI 与 GUI 各自实现一套分支。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    final command = _optionValue(args, '--command') ?? '';
    if (selector.isEmpty || command.trim().isEmpty) {
      _printer.error('请通过 --task 或 --id 选择 revision 任务，并通过 --command 指定动作。');
      return 2;
    }
    final result = await _workflowRuntimeService.applyRevisionResolutionAction(
      context.project,
      selector,
      command.trim(),
    );
    return _printWorkflowResult(result, success: 'revision 收口动作已应用。');
  }

  Future<int> _runAcceptRevision(List<String> args) async {
    // 中文注释: 接受修订结果只变更共享任务状态，不在 CLI 层直接操作 diff 文件。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择 revision 任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.acceptRevisionTask(
      context.project,
      selector,
    );
    return _printWorkflowResult(result, success: '修订结果已接受。');
  }

  Future<int> _runRollbackRevision(List<String> args) async {
    // 中文注释: 回滚修订依赖 revision diff 中的 backup 配对，这个过程完全交给共享 runtime 执行。
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final selector = await _taskSelectorFromArgs(context.project, args);
    if (selector.isEmpty) {
      _printer.error('请通过 --task 或 --id 选择 revision 任务。');
      return 2;
    }
    final result = await _workflowRuntimeService.rollbackRevisionTask(
      context.project,
      selector,
    );
    return _printWorkflowResult(result, success: '修订结果已回滚。');
  }

  Future<int> _runPendingResearch(List<String> args) async {
    // 中文注释: CLI 里的资料轻确认只分发到统一 action service，不新增第二套研究状态机。
    final action = args.isEmpty ? 'list' : args.first;
    final rest = args.isEmpty
        ? const <String>[]
        : args.skip(1).toList(growable: false);
    switch (action) {
      case 'list':
        return _runPendingResearchList(rest);
      case 'approve':
        return _runPendingResearchApprove(rest);
      case 'reject':
        return _runPendingResearchReject(rest);
      default:
        _printer.error('未知 pending-research 动作: $action');
        _printHelp();
        return 2;
    }
  }

  Future<int> _runExtractReference(List<String> args) async {
    if (args.contains('--list-strategies')) {
      _printReferenceExtractionStrategies();
      return 0;
    }
    final context = await _workflowContext(args, requireProvider: true);
    if (context == null) {
      return 2;
    }
    final provider = context.settings.defaultProvider();
    if (provider == null) {
      _printer.error('未找到可用 provider。');
      return 2;
    }
    final sourcePath =
        _optionValue(args, '--source') ??
        _optionValue(args, '--path') ??
        _joinedPositional(args);
    if (sourcePath.trim().isEmpty) {
      _printer.error('请通过 --source 提供待提取的原始文档路径。');
      return 2;
    }
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: context.settings,
      provider: provider,
      overrideModelId: _optionValue(args, '--model') ?? '',
    );
    final runtimeProfile = ValueReaders.mapValue(
      executionProfile['runtime_profile'],
    );
    final resolvedModelId = ValueReaders.stringValue(
      executionProfile['resolved_model_id'],
    );
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      _printer.error('请先配置真实模型接口地址和模型名。');
      return 2;
    }
    try {
      final gateway = _llmGatewayFactory(
        provider,
        context.settings.networkSettings,
      );
      final result = await _referenceExtractionRuntimeService.execute(
        project: context.project,
        llmGateway: gateway,
        modelId: resolvedModelId,
        request: _referenceExtractionRequestBuilderService.build(
          ProjectReferenceExtractionRequestInput(
            sourceFilePath: File(sourcePath).absolute.path,
            packageId: _optionValue(args, '--package-id') ?? '',
            displayName: _optionValue(args, '--display-name') ?? '',
            packageVersionId: _optionValue(args, '--version-id') ?? '',
            versionLabel: _optionValue(args, '--version-label') ?? '',
            sourceLanguage: _optionValue(args, '--source-language') ?? '',
            targetLanguage: _optionValue(args, '--target-language') ?? 'zh-CN',
            maxChapterEntries: _intOption(args, '--max-chapters', 6),
            maxEntityEntries: _intOption(args, '--max-entities', 6),
            exportBundle: !args.contains('--no-export'),
            attachToProject: !args.contains('--no-attach'),
            projectMountedEntries: !args.contains('--no-project-mount'),
            bundleOutputDirectory: _optionValue(args, '--bundle-dir') ?? '',
            strategyProfileId: _optionValue(args, '--strategy-profile') ?? '',
            availableContextChars: ValueReaders.intValue(
              runtimeProfile['context_length'],
            ),
          ),
        ),
      );
      _printer.success('参考资产提取完成。');
      _printer.info('项目: ${context.project.name}');
      _printer.info('模型: $resolvedModelId');
      final strategyLabel = _referenceExtractionStrategyLabel(
        result.strategyProfileId,
      );
      _printer.block(
        '参考提取摘要',
        _workflowOutputSummaryService
            .referenceExtractionBriefLines(result, strategyLabel: strategyLabel)
            .join('\n'),
      );
      if (result.bundleOutputDirectory.trim().isNotEmpty) {
        _printer.info('Bundle: ${result.bundleOutputDirectory}');
      }
      if (result.stagingRunPath.trim().isNotEmpty) {
        _printer.info('Staging: ${result.stagingRunPath}');
      }
      return 0;
    } catch (error) {
      _printer.error('参考资产提取失败: $error');
      return 1;
    }
  }

  Future<int> _runPendingResearchList(List<String> args) async {
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final records = await _pendingResearchActionService.list(context.project);
    if (records.isEmpty) {
      _printer.info('当前没有待处理的资料研究请求。');
      return 0;
    }
    final lines = records.map(_pendingResearchRecordLine).join('\n');
    _printer.block('待处理资料研究', lines);
    return 0;
  }

  Future<int> _runPendingResearchApprove(List<String> args) async {
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final requestId = _pendingResearchRequestId(args);
    if (requestId.isEmpty) {
      _printer.error('请通过 --request 或 --id 指定资料请求。');
      return 2;
    }
    final result = await _pendingResearchActionService.approve(
      context.project,
      requestId: requestId,
      actorId: 'novel_agent_cli',
      note: _optionValue(args, '--note') ?? '',
    );
    return _printPendingResearchActionResult(result, success: '资料研究请求已确认。');
  }

  Future<int> _runPendingResearchReject(List<String> args) async {
    final context = await _workflowContext(args);
    if (context == null) {
      return 2;
    }
    final requestId = _pendingResearchRequestId(args);
    if (requestId.isEmpty) {
      _printer.error('请通过 --request 或 --id 指定资料请求。');
      return 2;
    }
    final result = await _pendingResearchActionService.reject(
      context.project,
      requestId: requestId,
      actorId: 'novel_agent_cli',
      note: _optionValue(args, '--note') ?? '',
    );
    return _printPendingResearchActionResult(result, success: '资料研究请求已拒绝。');
  }

  Future<_WorkflowContext?> _workflowContext(
    List<String> args, {
    bool requireProvider = false,
  }) async {
    // 中文注释: 共享设置与项目打开逻辑集中在这里，避免每个子命令各自拼默认项目路径和 provider 校验。
    final settings = await _settingsRepository.load();
    if (requireProvider && settings.defaultProvider() == null) {
      _printer.error('未找到可用 provider。');
      return null;
    }
    final project = await _openProject(
      args,
      defaultProjectPath: settings.defaultProjectPath,
    );
    if (project == null) {
      return null;
    }
    return _WorkflowContext(project: project, settings: settings);
  }

  Future<ProjectDescriptor?> _openProject(
    List<String> args, {
    required String defaultProjectPath,
  }) async {
    final projectPath = _optionValue(args, '--project') ?? defaultProjectPath;
    final project = await _projectRepository.openByPath(projectPath);
    if (project == null) {
      _printer.error('项目不存在: $projectPath');
      return null;
    }
    return project;
  }

  Future<JsonMap> _taskSelectorFromArgs(
    ProjectDescriptor project,
    List<String> args,
  ) async {
    // 中文注释: 任务选择支持 path 与 id 两种方式，兼容旧项目里“路径定位”和“任务 id 定位”的双习惯。
    final taskPath =
        _optionValue(args, '--task') ?? _optionValue(args, '--path');
    if ((taskPath ?? '').trim().isNotEmpty) {
      return <String, Object?>{'relative_path': taskPath!.trim()};
    }
    final taskId = _optionValue(args, '--id');
    if ((taskId ?? '').trim().isNotEmpty) {
      return <String, Object?>{'task_id': taskId!.trim()};
    }
    final positional = _joinedPositional(args);
    if (positional.trim().isNotEmpty) {
      return <String, Object?>{'relative_path': positional.trim()};
    }
    final nextTask = await _workflowRuntimeService.nextWorkflowTask(project);
    if (nextTask.isNotEmpty) {
      return <String, Object?>{
        'relative_path': ValueReaders.stringValue(nextTask['relative_path']),
      };
    }
    return <String, Object?>{};
  }

  Future<String> _resolveRunPath(
    ProjectDescriptor project,
    List<String> args,
  ) async {
    final explicit = _optionValue(args, '--run') ?? '';
    if (explicit.trim().isNotEmpty) {
      return explicit.trim();
    }
    final runs = await _workflowRuntimeService.listLongTaskRuns(
      project,
      limit: 1,
    );
    if (runs.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(runs.first['relative_path']);
  }

  int _printWorkflowResult(JsonMap result, {required String success}) {
    // 中文注释: workflow 所有共享结果都从这里统一提炼终端输出口径，避免每个命令各写各的成功提示。
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      final response = ValueReaders.mapValue(result['response']);
      if (response.isNotEmpty) {
        _printer.block('响应摘要', _prettyJson(response));
      }
      return 1;
    }
    _printer.success(success);
    final relativePath = ValueReaders.stringValue(
      result['relative_path'],
      ValueReaders.stringValue(result['long_task_run_path']),
    );
    if (relativePath.trim().isNotEmpty) {
      _printer.info('项目路径: $relativePath');
    }
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.isNotEmpty) {
      for (final path in changedPaths) {
        _printer.info('已更新: $path');
      }
    }
    final outputPaths = ValueReaders.stringList(result['output_paths']);
    if (outputPaths.isNotEmpty) {
      for (final path in outputPaths) {
        _printer.info('输出: $path');
      }
    }
    final runCenterContract = _workflowOutputSummaryService
        .extractRunCenterContract(result);
    if (runCenterContract.isNotEmpty) {
      final briefLines = _workflowOutputSummaryService.runCenterBriefLines(
        runCenterContract,
      );
      if (briefLines.isNotEmpty) {
        _printer.block('长任务现场摘要', briefLines.join('\n'));
      }
    }
    final response = ValueReaders.mapValue(result['response']);
    final content = ValueReaders.stringValue(response['content']).trim();
    final narrativeContract = _workflowOutputSummaryService
        .extractNarrativeRuntimeContract(result);
    final narrativeLines = _workflowOutputSummaryService.narrativeBriefLines(
      narrativeContract,
    );
    if (narrativeLines.isNotEmpty) {
      _printer.block('开放叙事摘要', narrativeLines.join('\n'));
    }
    if (content.isNotEmpty) {
      _printer.block('模型输出', content);
    }
    final record = ValueReaders.mapValue(result['record']);
    if (record.isNotEmpty) {
      _printer.block('运行记录', _prettyJson(record));
    }
    return 0;
  }

  int _printPendingResearchActionResult(
    JsonMap result, {
    required String success,
  }) {
    if (!ValueReaders.boolValue(result['ok'])) {
      _printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
      return 1;
    }
    _printer.success(success);
    final requestId = ValueReaders.stringValue(result['request_id']).trim();
    final requestState = ValueReaders.stringValue(
      result['request_state'],
    ).trim();
    final actionStatus = ValueReaders.stringValue(
      result['action_status'],
    ).trim();
    if (requestId.isNotEmpty) {
      _printer.info('请求: $requestId');
    }
    if (requestState.isNotEmpty) {
      _printer.info('状态: ${_pendingResearchStateLabel(requestState)}');
    }
    if (actionStatus.isNotEmpty && actionStatus != 'updated') {
      _printer.info('结果: $actionStatus');
    }
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    if (changedPaths.isNotEmpty) {
      for (final path in changedPaths) {
        _printer.info('已更新: $path');
      }
    }
    return 0;
  }

  void _printHelp() {
    // 中文注释: workflow 帮助只展示已经接通的共享运行入口，避免 CLI 承诺不存在的子命令。
    _printer.block(
      'workflow help',
      [
        'workflow draft --prompt "写第一章开场" [--project 路径] [--title 标题] [--model 模型] [--no-save]',
        'workflow extract-reference --list-strategies',
        'workflow extract-reference --source D:/book.txt [--project 路径] [--model 模型] [--package-id id] [--display-name 标题] [--source-language en] [--target-language zh-CN] [--strategy-profile profile_id]',
        'workflow create --mode human_outline_ai_draft [--outline outline/outline.md] [--seed 创作说明] [--chapters 12] [--checkpoint 3] [--project 路径]',
        'workflow list [--project 路径]',
        'workflow next [--project 路径]',
        'workflow preflight [--project 路径]',
        'workflow chain [--project 路径]',
        'workflow guidance-status [--mode seed_autopilot_novel] [--project 路径]',
        'workflow create-from-guidance [--mode seed_autopilot_novel] [--project 路径]',
        'workflow plan --task tasks/xxx.json [--project 路径]',
        'workflow prepare --task tasks/xxx.json [--project 路径]',
        'workflow run-once --task tasks/xxx.json [--project 路径]',
        'workflow run-next [--project 路径]',
        'workflow run-queue [--steps 3] [--project 路径]',
        'workflow postprocess-once --task tasks/xxx.json [--project 路径]',
        'workflow postprocess-next [--project 路径]',
        'workflow complete-next --task tasks/xxx.json [--project 路径]',
        'workflow pause [--run tracking/long_task_runs/xxx.json] [--project 路径]',
        'workflow resume [--run tracking/long_task_runs/xxx.json] [--project 路径]',
        'workflow checkpoint-actions --review tracking/checkpoint_reviews/xxx.json [--project 路径]',
        'workflow apply-checkpoint-action --review tracking/checkpoint_reviews/xxx.json --command create_followup_review_tasks [--project 路径]',
        'workflow revision-resolution --task tasks/xxx.json [--project 路径]',
        'workflow apply-revision-resolution --task tasks/xxx.json --command create_followup_review_tasks [--project 路径]',
        'workflow accept-revision --task tasks/xxx.json [--project 路径]',
        'workflow rollback-revision --task tasks/xxx.json [--project 路径]',
        'workflow pending-research list [--project 路径]',
        'workflow pending-research approve --request research_request_xxx [--note 备注] [--project 路径]',
        'workflow pending-research reject --request research_request_xxx [--note 备注] [--project 路径]',
      ].join('\n'),
    );
  }

  void _printReferenceExtractionStrategies() {
    final options = _referenceExtractionStrategyProfileOptionService
        .listOptions();
    if (options.isEmpty) {
      _printer.info('当前没有可用的参考提取策略。');
      return;
    }
    final lines = options
        .map(
          (option) =>
              '${option.displayName}｜${option.profileId}\n'
              '  ${option.summary}\n'
              '  候选：${option.proposalCountLabel}｜类型：${option.entryKindsLabel}\n'
              '  审核：${option.reviewPolicyLabel}',
        )
        .join('\n');
    _printer.block('参考提取策略', lines);
  }

  String _referenceExtractionStrategyLabel(String profileId) {
    final option = _referenceExtractionStrategyProfileOptionService.optionById(
      profileId,
    );
    if (option == null) {
      return profileId.trim();
    }
    return '${option.displayName} (${option.profileId})';
  }

  String? _optionValue(List<String> args, String name) {
    // 中文注释: 轻量参数解析集中在命令类内部，当前阶段不为了少量选项提前引入命令框架。
    final index = args.indexOf(name);
    if (index < 0 || index + 1 >= args.length) {
      return null;
    }
    return args[index + 1].trim();
  }

  int _intOption(List<String> args, String name, int fallback) {
    final raw = _optionValue(args, name);
    if (raw == null) {
      return fallback;
    }
    return int.tryParse(raw.trim()) ?? fallback;
  }

  String _joinedPositional(List<String> args) {
    // 中文注释: 非选项文本会被拼成 prompt 或 path，方便快速调用 CLI 做一次性操作。
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
    // 中文注释: CLI 自动标题规则与 GUI 保持一致，确保两端自动生成的正文标题口径相同。
    final firstLine = prompt.split('\n').first.trim();
    if (firstLine.isEmpty) {
      return '新正文';
    }
    return firstLine.length > 24 ? firstLine.substring(0, 24) : firstLine;
  }

  String _pendingResearchRequestId(List<String> args) {
    final requestId =
        _optionValue(args, '--request') ?? _optionValue(args, '--id') ?? '';
    if (requestId.trim().isNotEmpty) {
      return requestId.trim();
    }
    return _joinedPositional(args).trim();
  }

  String _pendingResearchRecordLine(JsonMap record) {
    final requestId = ValueReaders.stringValue(record['request_id']).trim();
    final requestState = ValueReaders.stringValue(
      record['request_state'],
    ).trim();
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    final query = ValueReaders.stringValue(researchRequest['query']).trim();
    final reason = ValueReaders.stringValue(
      ValueReaders.mapValue(record['permission_decision'])['reason'],
      ValueReaders.stringValue(record['resolution_note']),
    ).trim();
    final parts = <String>[requestId, _pendingResearchStateLabel(requestState)];
    if (query.isNotEmpty) {
      parts.add(query);
    }
    if (reason.isNotEmpty) {
      parts.add(reason);
    }
    return parts.join('｜');
  }

  String _pendingResearchStateLabel(String requestState) {
    switch (requestState) {
      case ProjectPendingResearchRequestStates.awaitingUserConfirmation:
        return '等待确认';
      case ProjectPendingResearchRequestStates.pendingGatewayExecution:
        return '待处理';
      case ProjectPendingResearchRequestStates.pendingReview:
        return '待审核';
      case ProjectPendingResearchRequestStates.needsUserInfo:
        return '待补充信息';
      case ProjectPendingResearchRequestStates.rejected:
        return '已拒绝';
      case ProjectPendingResearchRequestStates.completed:
        return '已完成';
      default:
        return requestState;
    }
  }

  String _prettyJson(JsonMap value) {
    // 中文注释: 结构化结果统一做缩进输出，便于终端排查任务运行细节。
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

class _WorkflowContext {
  const _WorkflowContext({required this.project, required this.settings});

  final ProjectDescriptor project;
  final AppSettings settings;
}
