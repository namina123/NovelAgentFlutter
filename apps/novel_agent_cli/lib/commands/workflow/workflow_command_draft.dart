part of 'workflow_command.dart';

Future<int> _runDraft(WorkflowCommand command, List<String> args) async {
  // 中文注释: draft 子命令只负责项目打开、模型调用与结果输出；普通结果不再通过 CLI 兜底冒充正式项目落盘。
  final settings = await command._settingsRepository.load();
  final provider = settings.defaultProvider();
  if (provider == null) {
    command._printer.error('未找到可用 provider。');
    return 2;
  }
  final project = await _openProject(
    command,
    args,
    defaultProjectPath: settings.defaultProjectPath,
  );
  if (project == null) {
    return 2;
  }
  final prompt = await _prompt(command, args);
  if (prompt.trim().isEmpty) {
    command._printer.error('请通过 --prompt、命令末尾文本或管道输入提供创作需求。');
    return 2;
  }
  final title = _optionValue(args, '--title') ?? _titleFromPrompt(prompt);
  final executionProfile = command._modelExecutionProfileService.resolve(
    settings: settings,
    provider: provider,
    overrideModelId: _optionValue(args, '--model') ?? '',
  );
  final resolvedModelId = ValueReaders.stringValue(
    executionProfile['resolved_model_id'],
  );
  if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
    command._printer.error(
      '请先在 novel_agent_settings.json 或环境变量中配置真实的模型接口地址和模型名。',
    );
    return 2;
  }
  try {
    final useCase = command._generateDraftUseCaseFactory(
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
    command._printer.success('内容生成完成');
    command._printer.info('项目: ${project.name}');
    command._printer.info('模型: ${result.modelId}');
    command._printer.info('上下文文件: ${result.selectedPaths.length}');
    command._printer.info('工具调用: ${result.executedTools.length}');
    if (savedPath.isNotEmpty) {
      command._printer.info(
        '已保存: ${_formatWorkflowArtifactPath(command, savedPath)}',
      );
    } else {
      command._printer.info('本轮结果未正式保存；如需落盘，请通过正式交付工具或显式文件命令完成。');
    }
    command._printer.block('正文内容', result.draftMarkdown);
    return 0;
  } catch (error) {
    command._printer.error('内容生成失败: $error');
    return 1;
  }
}

Future<String> _prompt(WorkflowCommand command, List<String> args) async {
  // 中文注释: draft 提示词优先取显式参数，其次取位置文本，最后在非交互/管道场景下回落 stdin。
  final prompt = await command._automationInputService.resolveTextInput(
    args,
    optionNames: const <String>['--prompt'],
  );
  return prompt?.trim() ?? '';
}
