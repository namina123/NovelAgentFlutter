import 'package:novel_agent_adapters/novel_agent_adapters.dart';

import 'workflow_output_stop_diagnosis_text_service.dart';

class ReferenceExtractionSummaryRenderer {
  ReferenceExtractionSummaryRenderer({
    ReferenceExtractionSupervisorSignalService?
    referenceExtractionSupervisorSignalService,
    StopDiagnosisTextService? stopDiagnosisTextService,
  }) : _referenceExtractionSupervisorSignalService =
           referenceExtractionSupervisorSignalService ??
           const ReferenceExtractionSupervisorSignalService(),
       _stopDiagnosisTextService =
           stopDiagnosisTextService ?? const StopDiagnosisTextService();

  final ReferenceExtractionSupervisorSignalService
  _referenceExtractionSupervisorSignalService;
  final StopDiagnosisTextService _stopDiagnosisTextService;

  List<String> renderLines(
    ProjectReferenceExtractionResult result, {
    String strategyLabel = '',
  }) {
    // 中文注释: 参考提取摘要只消费生产侧 supervisor signal 和 result 合同，不在 CLI 里重建提取状态机。
    final signal = _referenceExtractionSupervisorSignalService.build(result);
    final lifecycle = signal.lifecycleState;
    final lines = <String>[
      '控制面：${_stopDiagnosisTextService.renderReferenceLifecycleLabel(lifecycle)}',
    ];
    final stopReasonLine = _stopDiagnosisTextService
        .renderReferenceStopReasonLine(lifecycle.reason);
    if (stopReasonLine.isNotEmpty) {
      lines.add(stopReasonLine);
    }
    if (strategyLabel.trim().isNotEmpty) {
      lines.add('策略：$strategyLabel');
    }
    final packageLabel = '${result.packageId}@${result.packageVersionId}';
    lines.add('资料包：$packageLabel');
    lines.add('覆盖：${_referenceCoverageSummary(result)}');
    lines.add('挂载：${_referenceMountSummary(result)}');
    lines.add('连续性：${_referenceContinuitySummary(result)}');
    lines.add('资料产物：${_referenceArtifactSummary(result)}');
    final projectionSummary = _projectionSummary(
      result.generatedProjectionPaths,
    );
    if (projectionSummary.isNotEmpty) {
      lines.add('轻投影：$projectionSummary');
    }
    return lines;
  }

  String _referenceCoverageSummary(ProjectReferenceExtractionResult result) {
    final parts = <String>[];
    if (result.batchCount > 0) {
      parts.add('批次 ${result.completedBatchCount}/${result.batchCount} 完成');
    }
    if (result.batchCoverageRatio > 0) {
      parts.add('coverage ${(result.batchCoverageRatio * 100).round()}%');
    }
    if (result.coverageRequiresFollowup || result.needsContinuation) {
      parts.add('待补覆盖 ${result.uncoveredCoverageDimensionIds.length} 维');
    } else if (result.uncoveredCoverageDimensionIds.isEmpty) {
      parts.add('当前无补提信号');
    }
    if (result.followupSegmentIds.isNotEmpty) {
      parts.add('followup segment ${result.followupSegmentIds.length} 段');
    }
    return parts.join(' | ');
  }

  String _referenceMountSummary(ProjectReferenceExtractionResult result) {
    if (!result.attachToProjectRequested &&
        !result.projectMountedEntriesRequested) {
      return '未请求挂载';
    }
    final parts = <String>[];
    parts.add(switch (result.projectMountStatus) {
      ProjectReferenceMountStatuses.applied => '已挂载到项目',
      ProjectReferenceMountStatuses.attachedOnly => '仅登记 attachment，未生成项目投影',
      ProjectReferenceMountStatuses.denied => '等待挂载确认',
      ProjectReferenceMountStatuses.missingAttachment => '挂载缺少 attachment',
      ProjectReferenceMountStatuses.missingPackage => '挂载缺少 package',
      ProjectReferenceMountStatuses.notRequested => '未请求挂载',
      _ => result.projectMountStatus,
    });
    if (result.generatedProjectionPaths.isNotEmpty) {
      parts.add('投影 ${result.generatedProjectionPaths.length} 个');
    }
    if (result.projectMountWarningCodes.isNotEmpty) {
      parts.add('warning: ${result.projectMountWarningCodes.join('、')}');
    }
    return parts.join(' | ');
  }

  String _referenceContinuitySummary(ProjectReferenceExtractionResult result) {
    if (result.conflictClusterCount == 0 &&
        result.reviewAlertCount == 0 &&
        result.canonDecisionCount == 0) {
      return '当前无连续性冲突或 review alert';
    }
    final parts = <String>[
      'conflicts ${result.conflictClusterCount}',
      'decisions ${result.canonDecisionCount}',
      'alerts ${result.reviewAlertCount}',
    ];
    if (result.requiresManualContinuityReview) {
      parts.add('需人工复核');
    }
    if (result.unresolvedConflictCount > 0) {
      parts.add('未决 ${result.unresolvedConflictCount}');
    }
    return parts.join(' | ');
  }

  String _referenceArtifactSummary(ProjectReferenceExtractionResult result) {
    return [
      'knowledge ${result.knowledgeCardIds.length}',
      'design ${result.designElementIds.length}',
      'research ${result.researchNoteIds.length}',
      'reference ${result.referenceWorkIds.length}',
    ].join(' | ');
  }

  String _projectionSummary(List<String> paths) {
    if (paths.isEmpty) {
      return '';
    }
    if (paths.length <= 3) {
      return paths.join(' | ');
    }
    return '${paths.take(2).join(' | ')} | 另 ${paths.length - 2} 个入口';
  }
}
