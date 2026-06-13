import 'package:novel_agent_core/novel_agent_core.dart';

import 'expression_constraint_status_projection.dart';

class ExpressionConstraintStatusProjectionService {
  const ExpressionConstraintStatusProjectionService();

  ExpressionConstraintStatusProjection fromWritingExecutionResult(
    JsonMap writingExecutionResult,
  ) {
    final existing = ValueReaders.mapValue(
      writingExecutionResult['expression_constraint_projection'],
    );
    if (existing.isNotEmpty) {
      return ExpressionConstraintStatusProjection.fromJson(existing);
    }
    return fromConstraintSummaryJson(
      ValueReaders.mapValue(writingExecutionResult['constraints']),
    );
  }

  ExpressionConstraintStatusProjection fromConstraintSummaryJson(
    JsonMap constraints,
  ) {
    if (constraints.isEmpty) {
      return const ExpressionConstraintStatusProjection();
    }
    return fromConstraintSummary(
      WritingExecutionConstraintSummary.fromJson(constraints),
    );
  }

  ExpressionConstraintStatusProjection fromConstraintSummary(
    WritingExecutionConstraintSummary summary,
  ) {
    final present =
        summary.present ||
        summary.expressionConstraintActive ||
        summary.expressionConstraintDisabled ||
        summary.expressionConstraintApplied ||
        summary.expressionConstraintSkipped ||
        summary.summary.trim().isNotEmpty;
    if (!present) {
      return const ExpressionConstraintStatusProjection();
    }
    final disabled =
        summary.expressionConstraintDisabled ||
        summary.expressionConstraintPolicyMode ==
            ExpressionConstraintExecutionPolicyModes.disabled;
    final blocksRepair =
        summary.repairRequired ||
        summary.expressionConstraintGate.repairRequired;
    final suggestStrengthen =
        !disabled &&
        !blocksRepair &&
        (summary.expressionConstraintRuntimeEscalated ||
            summary.expressionConstraintGate.adjustNextChapter ||
            (summary.reviewSuggested &&
                !summary.reminderOnly &&
                !summary.repairRequired));
    final status = _status(
      summary,
      disabled: disabled,
      blocksRepair: blocksRepair,
      suggestStrengthen: suggestStrengthen,
    );
    return ExpressionConstraintStatusProjection(
      present: present,
      status: status,
      statusLabel: _statusLabel(status),
      summary: _summary(
        summary,
        status: status,
        disabled: disabled,
        blocksRepair: blocksRepair,
        suggestStrengthen: suggestStrengthen,
      ),
      policyMode: summary.expressionConstraintPolicyMode,
      active: summary.expressionConstraintActive,
      applied: summary.expressionConstraintApplied,
      suggestStrengthen: suggestStrengthen,
      blocksRepair: blocksRepair,
      disabled: disabled,
      reviewRequired: summary.expressionConstraintReviewRequired,
      reviewProvided: summary.expressionConstraintReviewProvided,
      evidenceMissing: summary.expressionConstraintEvidenceMissing,
      runtimeEscalated: summary.expressionConstraintRuntimeEscalated,
      technicalTurnExcluded: summary.expressionConstraintTechnicalTurnExcluded,
      appliedReasons: summary.expressionConstraintAppliedReasons,
      skippedReasons: summary.expressionConstraintSkippedReasons,
    );
  }

  String _status(
    WritingExecutionConstraintSummary summary, {
    required bool disabled,
    required bool blocksRepair,
    required bool suggestStrengthen,
  }) {
    if (!summary.expressionConstraintActive && !disabled) {
      return 'inactive';
    }
    if (disabled) {
      return 'disabled';
    }
    if (blocksRepair) {
      return 'repair_blocked';
    }
    if (suggestStrengthen) {
      return 'suggest_strengthen';
    }
    if (summary.expressionConstraintApplied) {
      return 'applied';
    }
    if (summary.expressionConstraintSkipped ||
        summary.expressionConstraintTechnicalTurnExcluded) {
      return 'skipped';
    }
    return 'configured';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'inactive' => '未启用',
      'disabled' => '已关闭',
      'repair_blocked' => '阻塞修订',
      'suggest_strengthen' => '建议加强',
      'applied' => '已应用',
      'skipped' => '已跳过',
      _ => '已配置',
    };
  }

  String _summary(
    WritingExecutionConstraintSummary summary, {
    required String status,
    required bool disabled,
    required bool blocksRepair,
    required bool suggestStrengthen,
  }) {
    final provided = summary.summary.trim();
    if (provided.isNotEmpty) {
      return provided;
    }
    if (!summary.expressionConstraintActive && !disabled) {
      return '当前项目没有启用表达限制 binding。';
    }
    if (disabled) {
      return '表达限制当前已关闭。';
    }
    if (blocksRepair) {
      return '表达限制当前要求先修订后再继续。';
    }
    if (suggestStrengthen) {
      return '表达限制当前建议加强后续章节执行。';
    }
    if (summary.expressionConstraintApplied) {
      return '表达限制当前已按策略应用。';
    }
    if (status == 'skipped') {
      return '表达限制当前被策略跳过。';
    }
    return '表达限制当前已配置。';
  }
}
