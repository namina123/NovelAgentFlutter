import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_prompt_contract.dart';

class DraftPromptBuilderService {
  DraftPromptBuilderService({
    required ProjectPromptContract projectPromptContract,
  }) : _projectPromptContract = projectPromptContract;

  final ProjectPromptContract _projectPromptContract;

  String build({
    required JsonMap project,
    required JsonMap agent,
    required JsonMap contextPack,
    required String userPrompt,
    required String title,
    required String intent,
  }) {
    // 中文注释: 内容生成总提示词在 core 统一拼装，确保 GUI 和 CLI 走到同一套创作约束与上下文协议。
    final resolvedTitle = title.trim();
    final outputInstruction = resolvedTitle.isEmpty
        ? '请直接输出中文 Markdown 正文，不要解释流程，不要输出多余前言。'
        : '请围绕标题《$resolvedTitle》输出中文 Markdown 正文，不要解释流程，不要输出多余前言。';
    final creativeRuleSummary = ValueReaders.stringValue(
      contextPack['creative_rule_summary'],
    ).trim();
    final executionConstraintSummary = ValueReaders.stringValue(
      contextPack['execution_constraint_summary'],
    ).trim();
    return <String>[
      '# NOVEL Agent Draft Generation',
      '',
      _projectPromptContract.workspaceConvention(),
      '',
      _projectPromptContract.factAcquisitionGuidance(
        workflowId: 'draft',
        projectTypeId: ValueReaders.stringValue(
          project['project_type'],
          'novel',
        ),
        intent: intent,
      ),
      '',
      _projectPromptContract.toolDecisionContract(),
      '',
      _projectPromptContract.storageAwareToolGuidance(project),
      '',
      _projectPromptContract.domainToolGuidance(intent, agent: agent),
      '',
      _projectPromptContract.informationToolGuidance(intent, agent: agent),
      '',
      _projectPromptContract.agentInstructions(agent),
      if (creativeRuleSummary.isNotEmpty) ...[
        '',
        '## 高优先级创作约束',
        creativeRuleSummary,
      ],
      if (executionConstraintSummary.isNotEmpty) ...[
        '',
        '## 执行硬约束',
        executionConstraintSummary,
      ],
      '',
      '## 输出要求',
      outputInstruction,
      '你必须优先遵守项目规格、风格、设定与章节上下文；如信息不足，应在正文内保守推进，不得凭空写死长期设定。',
      '',
      '## 上下文包',
      ValueReaders.stringValue(contextPack['context_text']),
      '',
      '## 用户任务',
      _projectPromptContract.userTurnMessage(
        userPrompt,
        project,
        intent,
        agent: agent,
      ),
    ].join('\n');
  }
}
