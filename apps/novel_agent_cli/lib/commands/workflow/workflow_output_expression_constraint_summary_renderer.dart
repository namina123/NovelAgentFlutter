import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class ExpressionConstraintSummaryRenderer {
  ExpressionConstraintSummaryRenderer({
    ExpressionConstraintStatusProjectionService?
    expressionConstraintStatusProjectionService,
  }) : _expressionConstraintStatusProjectionService =
           expressionConstraintStatusProjectionService ??
           const ExpressionConstraintStatusProjectionService();

  final ExpressionConstraintStatusProjectionService
  _expressionConstraintStatusProjectionService;

  JsonMap buildContract(JsonMap writingExecutionResult) {
    // 中文注释: 表达约束合同从共享写入结果投影而来，CLI 只做文本归纳。
    if (writingExecutionResult.isEmpty) {
      return const <String, Object?>{};
    }
    final constraints = ValueReaders.mapValue(
      writingExecutionResult['constraints'],
    );
    final projectionJson = ValueReaders.mapValue(
      writingExecutionResult['expression_constraint_projection'],
    );
    if (constraints.isEmpty && projectionJson.isEmpty) {
      return const <String, Object?>{};
    }
    final projection = projectionJson.isNotEmpty
        ? ExpressionConstraintStatusProjection.fromJson(projectionJson)
        : _expressionConstraintStatusProjectionService
              .fromConstraintSummaryJson(constraints);
    final summary = constraints.isEmpty
        ? const WritingExecutionConstraintSummary()
        : WritingExecutionConstraintSummary.fromJson(constraints);
    final riskSignals = summary.expressionConstraintGate.riskSignals.isNotEmpty
        ? summary.expressionConstraintGate.riskSignals
        : summary.continuityWatchItems;
    return <String, Object?>{
      'present': projection.present || constraints.isNotEmpty,
      'status_label': _expressionStatusLabel(projection),
      'policy_mode': _firstNonBlank(<String>[
        projection.policyMode,
        summary.expressionConstraintPolicyMode,
      ]),
      'review_missing':
          summary.expressionConstraintEvidenceMissing ||
          projection.evidenceMissing,
      'review_provided':
          summary.expressionConstraintReviewProvided ||
          projection.reviewProvided,
      'review_required':
          summary.expressionConstraintReviewRequired ||
          projection.reviewRequired,
      'violation_recorded':
          summary.expressionConstraintViolationRecorded ||
          riskSignals.isNotEmpty,
      'risk_signals': ValueReaders.deepCopyList(riskSignals.cast<Object?>()),
      'repair_required': summary.repairRequired || projection.blocksRepair,
      'suggested_adjust':
          projection.suggestStrengthen ||
          summary.expressionConstraintGate.adjustNextChapter ||
          (summary.reviewSuggested && !summary.repairRequired),
      'disabled': projection.disabled || summary.expressionConstraintDisabled,
      'summary': _firstNonBlank(<String>[projection.summary, summary.summary]),
    };
  }

  JsonMap buildChapterDeliveryContract(
    JsonMap result, {
    required JsonMap execution,
  }) {
    // 中文注释: 章节交付合同依旧读取生产侧投影，不在 CLI 中自己拼交付状态机。
    final directDelivery = ValueReaders.mapValue(result['chapter_delivery']);
    final nestedDelivery = ValueReaders.mapValue(execution['chapter_delivery']);
    final delivery = directDelivery.isNotEmpty
        ? directDelivery
        : nestedDelivery;
    final pathResolution = ValueReaders.mapValue(delivery['path_resolution']);
    final chapterPath = _firstNonBlank(<String>[
      ValueReaders.stringValue(delivery['chapter_path']),
      ValueReaders.stringValue(result['chapter_delivery_path']),
      ValueReaders.stringValue(execution['chapter_delivery_path']),
    ]);
    final deliveryState = _firstNonBlank(<String>[
      ValueReaders.stringValue(delivery['delivery_state']),
      ValueReaders.stringValue(result['chapter_delivery_state']),
      ValueReaders.stringValue(execution['chapter_delivery_state']),
    ]);
    final title = _firstNonBlank(<String>[
      ValueReaders.stringValue(delivery['title']),
      ValueReaders.stringValue(pathResolution['title']),
      ValueReaders.stringValue(
        ValueReaders.mapValue(delivery['submission'])['title'],
      ),
    ]);
    if (delivery.isEmpty &&
        pathResolution.isEmpty &&
        chapterPath.isEmpty &&
        deliveryState.isEmpty &&
        title.isEmpty) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'delivery_state': deliveryState,
      'chapter_path': chapterPath,
      'requested_path': _firstNonBlank(<String>[
        ValueReaders.stringValue(pathResolution['requested_path']),
        ValueReaders.stringValue(delivery['requested_chapter_path']),
      ]),
      'resolved_path': _firstNonBlank(<String>[
        ValueReaders.stringValue(pathResolution['resolved_path']),
        ValueReaders.stringValue(delivery['resolved_chapter_path']),
        chapterPath,
      ]),
      'title': title,
      'path_changed': ValueReaders.boolValue(pathResolution['path_changed']),
      'reason': ValueReaders.stringValue(pathResolution['reason']).trim(),
    };
  }

  List<String> renderSummaryLines(JsonMap contract) {
    // 中文注释: 表达约束摘要只做状态、复核、处置和风险信号的文字化。
    if (!ValueReaders.boolValue(contract['present'])) {
      return const <String>[];
    }
    final lines = <String>[];
    final policyMode = ValueReaders.stringValue(contract['policy_mode']).trim();
    final statusLabel = ValueReaders.stringValue(
      contract['status_label'],
    ).trim();
    final summary = ValueReaders.stringValue(contract['summary']).trim();
    final riskSignals = ValueReaders.stringList(contract['risk_signals']);
    if (statusLabel.isNotEmpty) {
      final policyLabel = _policyModeLabel(policyMode);
      lines.add(
        policyLabel.isEmpty
            ? '表达规则：$statusLabel'
            : '表达规则：$statusLabel（$policyLabel）',
      );
    }
    if (summary.isNotEmpty) {
      lines.add('表达规则摘要：$summary');
    }
    if (ValueReaders.boolValue(contract['review_missing'])) {
      lines.add('表达规则复核：缺少复核证据');
    } else if (ValueReaders.boolValue(contract['review_provided'])) {
      lines.add('表达规则复核：已记录复核证据');
    } else if (ValueReaders.boolValue(contract['review_required'])) {
      lines.add('表达规则复核：本轮要求复核');
    }
    if (ValueReaders.boolValue(contract['repair_required'])) {
      lines.add('表达规则处置：需要修补后再继续');
    } else if (ValueReaders.boolValue(contract['suggested_adjust'])) {
      lines.add('表达规则处置：建议后续章节加强');
    } else if (ValueReaders.boolValue(contract['disabled'])) {
      lines.add('表达规则处置：当前策略已关闭');
    }
    if (ValueReaders.boolValue(contract['violation_recorded'])) {
      lines.add(
        riskSignals.isEmpty
            ? '表达规则信号：已记录风险信号'
            : '表达规则信号：已记录风险信号（${riskSignals.join('、')}）',
      );
    }
    return lines;
  }

  List<String> renderChapterDeliverySummaryLines(JsonMap contract) {
    // 中文注释: 章节交付摘要只展示路径归一和标题口径，不参与实际写入判定。
    if (contract.isEmpty) {
      return const <String>[];
    }
    final lines = <String>[];
    final deliveryState = ValueReaders.stringValue(
      contract['delivery_state'],
    ).trim();
    final chapterPath = ValueReaders.stringValue(
      contract['chapter_path'],
    ).trim();
    final requestedPath = ValueReaders.stringValue(
      contract['requested_path'],
    ).trim();
    final resolvedPath = ValueReaders.stringValue(
      contract['resolved_path'],
    ).trim();
    final title = ValueReaders.stringValue(contract['title']).trim();
    final reason = ValueReaders.stringValue(contract['reason']).trim();
    final pathChanged = ValueReaders.boolValue(contract['path_changed']);
    if (deliveryState.isNotEmpty || chapterPath.isNotEmpty) {
      final parts = <String>[];
      if (deliveryState.isNotEmpty) {
        parts.add(_chapterDeliveryStateLabel(deliveryState));
      }
      if (chapterPath.isNotEmpty) {
        parts.add(chapterPath);
      }
      lines.add('章节交付：${parts.join(' | ')}');
    }
    if (requestedPath.isNotEmpty &&
        resolvedPath.isNotEmpty &&
        (pathChanged || requestedPath != resolvedPath)) {
      lines.add('路径诊断：请求 $requestedPath，已归一为 $resolvedPath');
    } else if (resolvedPath.isNotEmpty) {
      lines.add('章节路径：$resolvedPath');
    }
    if (title.isNotEmpty) {
      lines.add('标题口径：$title');
    }
    if (reason.isNotEmpty) {
      lines.add('路径说明：$reason');
    }
    return lines;
  }

  String _expressionStatusLabel(
    ExpressionConstraintStatusProjection projection,
  ) {
    if (projection.disabled) {
      return '已关闭';
    }
    if (projection.blocksRepair) {
      return '已阻塞修订';
    }
    if (projection.suggestStrengthen) {
      return '建议加强';
    }
    if (projection.applied) {
      return '已应用';
    }
    if (projection.technicalTurnExcluded) {
      return '本轮跳过';
    }
    if (projection.active) {
      return '已配置';
    }
    return projection.statusLabel.trim().isEmpty
        ? '状态待确认'
        : projection.statusLabel;
  }

  String _policyModeLabel(String policyMode) {
    return switch (policyMode.trim()) {
      ExpressionConstraintExecutionPolicyModes.disabled => '关闭',
      ExpressionConstraintExecutionPolicyModes.force => '强力约束',
      ExpressionConstraintExecutionPolicyModes.adaptive => '智能使用',
      _ => '',
    };
  }

  String _chapterDeliveryStateLabel(String state) {
    return switch (state.trim()) {
      ChapterDeliveryStateStatuses.delivered => '已交付',
      ChapterDeliveryStateStatuses.deliveredNeedsRepair => '交付后需修补',
      ChapterDeliveryStateStatuses.missingOutputRecoverable => '缺正文可恢复',
      ChapterDeliveryStateStatuses.invalidOutputRewriteRequired => '正文需重写',
      ChapterDeliveryStateStatuses.pathMismatchRecoverable => '路径需修正',
      ChapterDeliveryStateStatuses.waitingUserChoice => '等待用户确认',
      ChapterDeliveryStateStatuses.manualAttentionRequired => '需人工处理',
      ChapterDeliveryStateStatuses.hardFailure => '交付失败',
      _ => state.trim(),
    };
  }

  String _firstNonBlank(Iterable<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }
}
