/// 约束类型分类器（constraint_type 单一真相源）。
///
/// `constraint_type` 是 propose_constraint_binding 工具里的自由字符串，历史上由两个
/// 服务各自判定：
/// - WritingExecutionConstraintBridgeService.\_isExpressionConstraint 用严格前缀匹配
///   （`expression_constraint` / `expression_constraint.*`）；
/// - NarrativePermissionPolicyService 用宽松子串匹配（`contains('expression')`）。
/// 于是出现"同一类型被权限策略判为高风险、却因 bridge 不识别而被静默丢弃"的
/// "accepted but never applied"故障（例如 agent 误发 `'expression'`）。
///
/// 这里把判定逻辑收口成单一分类器，让 bridge 与 permission policy 对"是否表达限制"
/// 给出一致答案。归一化只比较 canonical 小写形式；`expression_constraint.<preset>`
/// 这类前缀子类型仍然被识别为表达限制。
class ConstraintTypeClassifier {
  const ConstraintTypeClassifier();

  bool isExpressionConstraint(String constraintType) {
    final clean = constraintType.trim().toLowerCase();
    return clean == 'expression_constraint' ||
        clean.startsWith('expression_constraint.');
  }

  bool isChapterLengthConstraint(String constraintType) {
    final clean = constraintType.trim().toLowerCase();
    return clean == 'chapter_length' || clean == 'word_count';
  }

  /// 中文注释: “已被系统真正处理”的类型只有表达限制与章节字数两类；其余 constraint_type
  /// 会被 bridge 接收但不会有任何注入或字数效果，调用方据此可以给用户/日志提示。
  bool isRecognized(String constraintType) =>
      isExpressionConstraint(constraintType) ||
      isChapterLengthConstraint(constraintType);
}
