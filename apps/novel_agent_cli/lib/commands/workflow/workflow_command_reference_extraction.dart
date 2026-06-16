part of 'workflow_command.dart';

Future<int> _runExtractReference(
  WorkflowCommand command,
  List<String> args,
) async {
  if (args.contains('--list-strategies')) {
    _printReferenceExtractionStrategies(command);
    return 0;
  }
  final context = await _workflowContext(command, args, requireProvider: true);
  if (context == null) {
    return 2;
  }
  final provider = context.settings.defaultProvider();
  if (provider == null) {
    command._printer.error('未找到可用 provider。');
    return 2;
  }
  final sourcePath =
      _optionValue(args, '--source') ??
      _optionValue(args, '--path') ??
      _joinedPositional(args);
  if (sourcePath.trim().isEmpty) {
    command._printer.error('请通过 --source 提供待提取的原始文档路径。');
    return 2;
  }
  final executionProfile = command._modelExecutionProfileService.resolve(
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
    command._printer.error('请先配置真实模型接口地址和模型名。');
    return 2;
  }
  try {
    final gateway = command._llmGatewayFactory(
      provider,
      context.settings.networkSettings,
    );
    final result = await command._referenceExtractionRuntimeService.execute(
      project: context.project,
      llmGateway: gateway,
      modelId: resolvedModelId,
      request: command._referenceExtractionRequestBuilderService.build(
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
    command._printer.success('参考资产提取完成。');
    command._printer.info('项目: ${context.project.name}');
    command._printer.info('模型: $resolvedModelId');
    final strategyLabel = _referenceExtractionStrategyLabel(
      command,
      result.strategyProfileId,
    );
    command._printer.block(
      '参考提取摘要',
      command._workflowOutputSummaryService
          .referenceExtractionBriefLines(result, strategyLabel: strategyLabel)
          .join('\n'),
    );
    if (result.bundleOutputDirectory.trim().isNotEmpty) {
      command._printer.info('Bundle: ${result.bundleOutputDirectory}');
    }
    if (result.stagingRunPath.trim().isNotEmpty) {
      command._printer.info('Staging: ${result.stagingRunPath}');
    }
    return 0;
  } catch (error) {
    command._printer.error('参考资产提取失败: $error');
    return 1;
  }
}
