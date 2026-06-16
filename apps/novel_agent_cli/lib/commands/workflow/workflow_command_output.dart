part of 'workflow_command.dart';

int _printWorkflowResult(
  WorkflowCommand command,
  JsonMap result, {
  required String success,
}) {
  // 中文注释: workflow 的共享运行结果只在这里统一投影到终端，避免各子命令重复写成功提示。
  if (!ValueReaders.boolValue(result['ok'])) {
    command._printer.error(ValueReaders.stringValue(result['error'], '执行失败。'));
    final response = ValueReaders.mapValue(result['response']);
    if (response.isNotEmpty) {
      command._printer.block('响应摘要', _prettyJson(response));
    }
    return 1;
  }
  command._printer.success(success);
  final relativePath = ValueReaders.stringValue(
    result['relative_path'],
    ValueReaders.stringValue(result['long_task_run_path']),
  );
  if (relativePath.trim().isNotEmpty) {
    command._printer.info(
      '项目路径: ${_formatWorkflowArtifactPath(command, relativePath)}',
    );
  }
  final changedPaths = ValueReaders.stringList(result['changed_paths']);
  if (changedPaths.isNotEmpty) {
    for (final path in changedPaths) {
      command._printer.info('已更新: ${_formatWorkflowArtifactPath(command, path)}');
    }
  }
  final outputPaths = ValueReaders.stringList(result['output_paths']);
  if (outputPaths.isNotEmpty) {
    for (final path in outputPaths) {
      command._printer.info('输出: ${_formatWorkflowArtifactPath(command, path)}');
    }
  }
  final runCenterContract = command._workflowOutputSummaryService
      .extractRunCenterContract(result);
  if (runCenterContract.isNotEmpty) {
    final briefLines = command._workflowOutputSummaryService
        .runCenterBriefLines(runCenterContract);
    if (briefLines.isNotEmpty) {
      command._printer.block('长任务现场摘要', briefLines.join('\n'));
    }
  }
  final response = ValueReaders.mapValue(result['response']);
  final content = ValueReaders.stringValue(response['content']).trim();
  final narrativeContract = command._workflowOutputSummaryService
      .extractNarrativeRuntimeContract(result);
  final narrativeLines = command._workflowOutputSummaryService
      .narrativeBriefLines(narrativeContract);
  if (narrativeLines.isNotEmpty) {
    command._printer.block('开放叙事摘要', narrativeLines.join('\n'));
  }
  if (content.isNotEmpty) {
    command._printer.block('模型输出', content);
  }
  final record = ValueReaders.mapValue(result['record']);
  if (record.isNotEmpty) {
    command._printer.block('运行记录', _prettyJson(record));
  }
  return 0;
}

void _printHelp(WorkflowCommand command) {
  // 中文注释: workflow 主帮助只展示用户层连续运行入口，避免主界面继续被 debug 颗粒度污染。
  CliHelpContract.printHelpBlock(command._printer, 'workflow help', [
    'workflow start [--mode human_outline_ai_draft] [--outline outline/outline.md] [--seed 创作说明] [--source D:/book.txt] [--project 路径]',
    'workflow status [--project 路径]',
    'workflow continue [--task tasks/xxx.json] [--project 路径]',
    'workflow pause [--run tracking/long_task_runs/xxx.json] [--project 路径]',
    'workflow resume [--run tracking/long_task_runs/xxx.json] [--project 路径]',
    'workflow inspect [--project 路径]',
    'workflow logs [--limit 10] [--project 路径]',
    'workflow debug ...',
  ]);
}

void _printDebugHelp(WorkflowCommand command) {
  // 中文注释: debug help 继续展示旧有细颗粒入口，但明确标注它们已经下沉到调试层。
  CliHelpContract.printHelpBlock(command._printer, 'workflow debug help', [
    'workflow debug draft --prompt "写第一章开场" [--project 路径] [--title 标题] [--model 模型] [--no-save]',
    'workflow debug extract-reference --list-strategies',
    'workflow debug extract-reference --source D:/book.txt [--project 路径] [--model 模型] [--package-id id] [--display-name 标题] [--source-language en] [--target-language zh-CN] [--strategy-profile profile_id]',
    'workflow debug create --mode human_outline_ai_draft [--outline outline/outline.md] [--seed 创作说明] [--chapters 12] [--checkpoint 3] [--project 路径]',
    'workflow debug list [--project 路径]',
    'workflow debug next [--project 路径]',
    'workflow debug preflight [--project 路径]',
    'workflow debug chain [--project 路径]',
    'workflow debug guidance-status [--mode seed_autopilot_novel] [--project 路径]',
    'workflow debug create-from-guidance [--mode seed_autopilot_novel] [--project 路径]',
    'workflow debug plan --task tasks/xxx.json [--project 路径]',
    'workflow debug prepare --task tasks/xxx.json [--project 路径]',
    'workflow debug run-once --task tasks/xxx.json [--project 路径]',
    'workflow debug run-next [--project 路径]',
    'workflow debug run-queue [--steps 3] [--project 路径]',
    'workflow debug postprocess-once --task tasks/xxx.json [--project 路径]',
    'workflow debug postprocess-next [--project 路径]',
    'workflow debug complete-next --task tasks/xxx.json [--project 路径]',
    'workflow debug pause [--run tracking/long_task_runs/xxx.json] [--project 路径]',
    'workflow debug resume [--run tracking/long_task_runs/xxx.json] [--project 路径]',
    'workflow debug checkpoint-actions --review tracking/checkpoint_reviews/xxx.json [--project 路径]',
    'workflow debug apply-checkpoint-action --review tracking/checkpoint_reviews/xxx.json --command create_followup_review_tasks [--project 路径]',
    'workflow debug revision-resolution --task tasks/xxx.json [--project 路径]',
    'workflow debug apply-revision-resolution --task tasks/xxx.json --command create_followup_review_tasks [--project 路径]',
    'workflow debug accept-revision --task tasks/xxx.json [--project 路径]',
    'workflow debug rollback-revision --task tasks/xxx.json [--project 路径]',
  ]);
}

void _printReferenceExtractionStrategies(WorkflowCommand command) {
  // 中文注释: reference extraction 的策略输出仍然消费共享 option service，不在 CLI 层造新词典。
  final options = command._referenceExtractionStrategyProfileOptionService
      .listOptions();
  if (options.isEmpty) {
    command._printer.info('当前没有可用的参考提取策略。');
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
  command._printer.block('参考提取策略', lines);
}

String _referenceExtractionStrategyLabel(
  WorkflowCommand command,
  String profileId,
) {
  // 中文注释: 策略 label 只是把共享 option 列表投影成文字，不参与策略判断。
  final option = command._referenceExtractionStrategyProfileOptionService
      .optionById(profileId);
  if (option == null) {
    return profileId.trim();
  }
  return '${option.displayName} (${option.profileId})';
}

String _prettyJson(JsonMap value) {
  // 中文注释: 结构化结果统一缩进输出，便于终端排查任务运行细节。
  return const JsonEncoder.withIndent('  ').convert(value);
}

String _formatWorkflowArtifactPath(
  WorkflowCommand command,
  String relativePath,
) {
  // 中文注释: workflow CLI 统一给正式资产补充身份标签，避免终端侧再次退回“只看裸路径”。
  return command._projectArtifactLabelService.formatPath(relativePath);
}
