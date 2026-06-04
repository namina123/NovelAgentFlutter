import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_transaction_contract_service.dart';

class LongTaskPostprocessPromptRenderer {
  LongTaskPostprocessPromptRenderer({
    required LongTaskTransactionContractService contractService,
  }) : _contractService = contractService;

  final LongTaskTransactionContractService _contractService;

  String renderPostprocessPrompt(JsonMap transaction) {
    // 中文注释: 后处理提示明确“不要重写正文”，把摘要、记忆和检查报告作为本轮唯一目标。
    final phase = ValueReaders.stringValue(transaction['phase']);
    final revision = phase == 'revision_review';
    final lines = <String>[
      revision
          ? '你正在执行 NOVEL Agent 的修复任务后处理。本轮目标只能有一个：判断当前修订是否可收口；不要继续重写正文，也不要顺手扩展任务范围。'
          : '你正在执行 NOVEL Agent 的章节任务后处理。请不要重写正文，优先读取已写入文件，再调用工具保存后处理结果。',
      '',
      '## 任务',
      '- 标题：${ValueReaders.stringValue(transaction['task_title'], '未命名任务')}',
      '- ID：${ValueReaders.stringValue(transaction['task_id'])}',
      '- 章节：${ValueReaders.stringValue(transaction['chapter'])}',
      '- 目标：${ValueReaders.stringValue(transaction['goal'])}',
      '- 执行包：${ValueReaders.stringValue(transaction['execution_path'])}',
    ];
    if (revision) {
      lines
        ..add(
          '- 修订目标：${_contractService.joinOrNone(ValueReaders.objectList(transaction['revision_targets']))}',
        )
        ..add(
          '- 原审稿报告：${ValueReaders.stringValue(transaction['original_review_path'], '暂无')}',
        )
        ..add(
          '- 修复 Diff：${ValueReaders.stringValue(transaction['revision_diff_path'], '暂无')}',
        )
        ..add('')
        ..add('## 后处理要求')
        ..add('1. 调用 read_project_file 读取每个修订目标。')
        ..add('2. 如果有原审稿报告或修复 Diff，调用 read_project_file 读取它们。')
        ..add(
          '3. 正式修订结论优先调用 submit_semantic_review，提交结构化 findings 和 recommended_disposition；不要把散文评语或普通检查报告冒充为正式审稿交付。',
        )
        ..add('4. 如果宿主还要求连续性报告，可把它当补充证据；但本轮唯一正式结论仍然围绕当前修订目标，不扩展成新写作任务。')
        ..add('5. 最终只简短说明修订是否通过、还有哪些风险、是否建议回滚。');
    } else {
      lines
        ..add(
          '- 已写入正文/场景路径：${_contractService.joinOrNone(ValueReaders.objectList(transaction['draft_paths']))}',
        )
        ..add('')
        ..add('## 后处理要求')
        ..add('1. 先调用 read_project_file 读取已写入正文。')
        ..add('2. 调用 summarize_context 保存章节摘要，scope 使用 chapter。')
        ..add(
          '3. 如果发现明确设定事实，调用 update_world_state；如果发现角色状态变化，调用 update_character_state。',
        )
        ..add(
          '4. 如果出现新的伏笔、伏笔推进/回收、明确时间顺序节点或关键关系变化，分别调用 update_foreshadow_state、update_timeline_state、update_relationship_state。',
        )
        ..add(
          '5. 如果本轮需要给出正式审稿结论，优先调用 submit_semantic_review；连续性报告、摘要或检查备注只能作为补充，不替代结构化审稿交付。',
        )
        ..add('6. 最终用简短 Markdown 告诉用户保存了哪些后处理产物，以及哪些内容需要人工确认。');
    }
    final creativeRuleSummary = ValueReaders.stringValue(
      transaction['creative_rule_summary'],
    ).trim();
    if (creativeRuleSummary.isNotEmpty) {
      lines
        ..add('')
        ..add('## 创作约束栈')
        ..add(creativeRuleSummary);
    }
    final reviewFocuses = ValueReaders.stringList(
      transaction['review_focuses'],
    );
    if (reviewFocuses.isNotEmpty) {
      lines
        ..add('')
        ..add('## 表达限制复核重点');
      for (final item in reviewFocuses) {
        final text = item.trim();
        if (text.isNotEmpty) {
          lines.add('- $text');
        }
      }
    }
    final authenticityPassLevel = ValueReaders.stringValue(
      transaction['authenticity_pass_level'],
    ).trim();
    if (authenticityPassLevel.isNotEmpty &&
        authenticityPassLevel != 'disabled') {
      lines
        ..add('')
        ..add('## 真实性复核强度')
        ..add('- 当前表达限制要求按 $authenticityPassLevel 强度执行真实性 / 去模板清理。');
    }
    final miniRecheckItems = ValueReaders.stringList(
      transaction['mini_recheck_items'],
    );
    if (miniRecheckItems.isNotEmpty) {
      lines
        ..add('')
        ..add('## Mini Recheck');
      for (final item in miniRecheckItems) {
        final text = item.trim();
        if (text.isNotEmpty) {
          lines.add('- $text');
        }
      }
    }
    final templates = ValueReaders.mapValue(transaction['project_templates']);
    final templateText = ValueReaders.stringValue(
      templates['review_report'],
    ).trim();
    if (templateText.isNotEmpty) {
      lines
        ..add('')
        ..add('## 项目审稿报告模板')
        ..add(templateText);
    }
    return lines.join('\n');
  }
}
