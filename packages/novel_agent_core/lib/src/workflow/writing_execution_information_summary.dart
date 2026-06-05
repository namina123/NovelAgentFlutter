import '../common/json_types.dart';
import '../common/value_readers.dart';

class WritingExecutionInformationSummary {
  const WritingExecutionInformationSummary({
    this.present = false,
    this.activationReportId = '',
    this.activationPlanId = '',
    this.activationSource = '',
    this.activationSummary = '',
    this.budgetChars = 0,
    this.usedChars = 0,
    this.selectedItemCount = 0,
    this.omittedItemCount = 0,
    this.requiredOmittedItemCount = 0,
    this.truncatedItemCount = 0,
    this.changedPathCount = 0,
    this.riskCategory = '',
    this.reason = '',
    this.summary = '',
    this.changedPaths = const <String>[],
    this.waitingUser = false,
    this.requiresRepair = false,
    this.manualAttentionRequired = false,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String activationReportId;
  final String activationPlanId;
  final String activationSource;
  final String activationSummary;
  final int budgetChars;
  final int usedChars;
  final int selectedItemCount;
  final int omittedItemCount;
  final int requiredOmittedItemCount;
  final int truncatedItemCount;
  final int changedPathCount;
  final String riskCategory;
  final String reason;
  final String summary;
  final List<String> changedPaths;
  final bool waitingUser;
  final bool requiresRepair;
  final bool manualAttentionRequired;
  final JsonMap metadata;

  factory WritingExecutionInformationSummary.fromJson(JsonMap json) {
    // 中文注释: information summary 负责把激活和风险信号合并回读，避免上层重新解读 activation report 明细。
    return WritingExecutionInformationSummary(
      present: ValueReaders.boolValue(json['present']),
      activationReportId: ValueReaders.stringValue(
        json['activation_report_id'],
      ).trim(),
      activationPlanId: ValueReaders.stringValue(
        json['activation_plan_id'],
      ).trim(),
      activationSource: ValueReaders.stringValue(
        json['activation_source'],
      ).trim(),
      activationSummary: ValueReaders.stringValue(
        json['activation_summary'],
      ).trim(),
      budgetChars: ValueReaders.intValue(json['budget_chars']),
      usedChars: ValueReaders.intValue(json['used_chars']),
      selectedItemCount: ValueReaders.intValue(json['selected_item_count']),
      omittedItemCount: ValueReaders.intValue(json['omitted_item_count']),
      requiredOmittedItemCount: ValueReaders.intValue(
        json['required_omitted_item_count'],
      ),
      truncatedItemCount: ValueReaders.intValue(json['truncated_item_count']),
      changedPathCount: ValueReaders.intValue(json['changed_path_count']),
      riskCategory: ValueReaders.stringValue(json['risk_category']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      changedPaths: ValueReaders.stringList(json['changed_paths']),
      waitingUser: ValueReaders.boolValue(json['waiting_user']),
      requiresRepair: ValueReaders.boolValue(json['requires_repair']),
      manualAttentionRequired: ValueReaders.boolValue(
        json['manual_attention_required'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 这里输出的信息摘要只保留共享激活与风险结果，方便 ordinary/long task/deconstruction 统一消费。
    return <String, Object?>{
      'present': present,
      'activation_report_id': activationReportId,
      'activation_plan_id': activationPlanId,
      'activation_source': activationSource,
      'activation_summary': activationSummary,
      'budget_chars': budgetChars,
      'used_chars': usedChars,
      'selected_item_count': selectedItemCount,
      'omitted_item_count': omittedItemCount,
      'required_omitted_item_count': requiredOmittedItemCount,
      'truncated_item_count': truncatedItemCount,
      'changed_path_count': changedPathCount,
      'risk_category': riskCategory,
      'reason': reason,
      'summary': summary,
      'changed_paths': changedPaths,
      'waiting_user': waitingUser,
      'requires_repair': requiresRepair,
      'manual_attention_required': manualAttentionRequired,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: information 摘要校验只保证数量与标志位有效，不替代 information 生命周期或权限判断。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (budgetChars < 0 || usedChars < 0) {
      result.add('invalid_writing_execution_information_budget');
    }
    if (selectedItemCount < 0 ||
        omittedItemCount < 0 ||
        requiredOmittedItemCount < 0 ||
        truncatedItemCount < 0 ||
        changedPathCount < 0) {
      result.add('invalid_writing_execution_information_counts');
    }
    return result;
  }
}
