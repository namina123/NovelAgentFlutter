import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class WorkflowOutputSummaryService {
  WorkflowOutputSummaryService({
    InformationEvidenceProjectionService? informationEvidenceProjectionService,
    ExpressionConstraintStatusProjectionService?
    expressionConstraintStatusProjectionService,
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
    ReferenceExtractionSupervisorSignalService?
    referenceExtractionSupervisorSignalService,
  }) : _informationEvidenceProjectionService =
           informationEvidenceProjectionService ??
           const InformationEvidenceProjectionService(),
       _expressionConstraintStatusProjectionService =
           expressionConstraintStatusProjectionService ??
           const ExpressionConstraintStatusProjectionService(),
       _stopDiagnosisProjectionService =
           stopDiagnosisProjectionService ??
           const LongTaskStopDiagnosisProjectionService(),
       _referenceExtractionSupervisorSignalService =
           referenceExtractionSupervisorSignalService ??
           const ReferenceExtractionSupervisorSignalService();

  static const String _continuityRoot = '.novel_agent/continuity/';
  static const String _ledgerRoot = '.novel_agent/continuity/ledgers/';
  static const String _claimsRoot = '.novel_agent/continuity/claims/';
  static const String _reviewsRoot = '.novel_agent/continuity/reviews/';
  static const String _deliveriesRoot = '.novel_agent/continuity/deliveries/';
  static const String _knowledgeCardsRoot =
      '.novel_agent/information/knowledge_cards/';
  static const String _designElementsRoot =
      '.novel_agent/information/design_elements/';
  static const String _researchNotesRoot =
      '.novel_agent/information/research_notes/';
  static const String _referenceWorksRoot =
      '.novel_agent/information/reference_works/';
  final InformationEvidenceProjectionService
  _informationEvidenceProjectionService;
  final ExpressionConstraintStatusProjectionService
  _expressionConstraintStatusProjectionService;
  final LongTaskStopDiagnosisProjectionService _stopDiagnosisProjectionService;
  final ReferenceExtractionSupervisorSignalService
  _referenceExtractionSupervisorSignalService;

  JsonMap extractRunCenterContract(JsonMap result) {
    // 中文注释: CLI 只读取运行结果里已经投影好的 run center 合同，不再自己推断状态。
    final direct = ValueReaders.mapValue(
      result['long_task_run_center_contract'],
    );
    if (direct.isNotEmpty) {
      return direct;
    }
    final nested = ValueReaders.mapValue(result['run_center_contract']);
    if (nested.isNotEmpty) {
      return nested;
    }
    final record = ValueReaders.mapValue(result['record']);
    if (record.isNotEmpty) {
      return ValueReaders.mapValue(record['run_center_contract']);
    }
    return const <String, Object?>{};
  }

  List<String> runCenterBriefLines(JsonMap contract) {
    // 中文注释: CLI 的摘要只做“阶段/进度/当前任务/下一步”这类短信息提炼，不改运行逻辑。
    final lines = <String>[];
    final phaseLabel = ValueReaders.stringValue(contract['phase_label']).trim();
    final statusLabel = ValueReaders.stringValue(
      contract['status_label'],
    ).trim();
    final activeTask = ValueReaders.mapValue(contract['active_task']);
    final activeTaskTitle = ValueReaders.stringValue(
      activeTask['title'],
      ValueReaders.stringValue(contract['active_task_title']),
    ).trim();
    final progress = ValueReaders.mapValue(contract['progress']);
    final percent = ValueReaders.intValue(
      progress['overall_percent'],
      ValueReaders.intValue(progress['percent']),
    );
    final blocker = ValueReaders.stringValue(contract['blocker']).trim();
    final reason = ValueReaders.stringValue(contract['reason']).trim();
    final stopDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
      ValueReaders.mapValue(contract['stop_diagnosis']),
    );
    final nextAction = ValueReaders.stringValue(
      contract['recommended_action_label'],
    ).trim();
    final resumeBrief = ValueReaders.mapValue(contract['resume_brief']);
    if (statusLabel.isNotEmpty) {
      lines.add('状态：$statusLabel');
    }
    if (phaseLabel.isNotEmpty) {
      lines.add('阶段：$phaseLabel');
    }
    if (percent > 0) {
      lines.add('进度：$percent%');
    }
    if (activeTaskTitle.isNotEmpty) {
      lines.add('当前任务：$activeTaskTitle');
    }
    if (stopDiagnosis.present) {
      lines.add(_stopDiagnosisLine(stopDiagnosis));
    } else if (reason.isNotEmpty) {
      lines.add(_stopReasonLine(reason));
    } else if (blocker.isNotEmpty) {
      lines.add('阻塞原因：$blocker');
    }
    if (nextAction.isNotEmpty) {
      lines.add('下一步：$nextAction');
    }
    if (resumeBrief.isNotEmpty) {
      final title = ValueReaders.stringValue(
        resumeBrief['resume_title'],
      ).trim();
      final summary = ValueReaders.stringValue(
        resumeBrief['resume_summary'],
      ).trim();
      final lastStep = ValueReaders.stringValue(
        resumeBrief['last_step_summary'],
      ).trim();
      final nextActionSummary = ValueReaders.stringValue(
        resumeBrief['next_action_summary'],
      ).trim();
      if (title.isNotEmpty) {
        lines.add('恢复标题：$title');
      }
      if (summary.isNotEmpty) {
        lines.add(summary);
      }
      if (lastStep.isNotEmpty) {
        lines.add(lastStep);
      }
      if (nextActionSummary.isNotEmpty) {
        lines.add(nextActionSummary);
      }
    }
    return lines;
  }

  JsonMap extractNarrativeRuntimeContract(JsonMap result) {
    final execution = ValueReaders.mapValue(result['execution']);
    final runCenterContract = extractRunCenterContract(result);
    final checkpointReview = ValueReaders.mapValue(result['checkpoint_review']);
    final checkpointReviewBody = ValueReaders.mapValue(
      checkpointReview['review'],
    );
    final gateOutcome = ValueReaders.mapValue(result['gate_outcome']);
    final changedPaths = ValueReaders.stringList(result['changed_paths']);
    final activationReportPath = ValueReaders.stringValue(
      result['activation_report_path'],
      ValueReaders.stringValue(execution['activation_report_path']),
    ).trim();
    final activationReportSummary = ValueReaders.stringValue(
      result['activation_report_summary'],
      ValueReaders.stringValue(execution['activation_report_summary']),
    ).trim();
    final chapterDeliveryState = ValueReaders.stringValue(
      result['chapter_delivery_state'],
      ValueReaders.stringValue(execution['chapter_delivery_state']),
    ).trim();
    final chapterDeliveryPath = ValueReaders.stringValue(
      result['chapter_delivery_path'],
      ValueReaders.stringValue(execution['chapter_delivery_path']),
    ).trim();
    final reviewPath = ValueReaders.stringValue(
      checkpointReview['relative_path'],
      ValueReaders.stringValue(gateOutcome['review_report_path']),
    ).trim();
    final reviewSummary = ValueReaders.stringValue(
      checkpointReviewBody['summary'],
      ValueReaders.stringValue(gateOutcome['gate_reason']),
    ).trim();
    final directAnalysisInformation = ValueReaders.mapValue(
      result['analysis_information'],
    );
    final analysisInformation = directAnalysisInformation.isNotEmpty
        ? directAnalysisInformation
        : ValueReaders.mapValue(execution['analysis_information']);
    final writingExecutionResult = _writingExecutionResult(
      result,
      execution: execution,
    );
    final expressionConstraint = _expressionConstraintContract(
      writingExecutionResult,
    );
    final chapterDelivery = _chapterDeliveryContract(
      result,
      execution: execution,
    );
    final stopReason = _firstNonBlank(<String>[
      ValueReaders.stringValue(result['stop_reason']),
      ValueReaders.stringValue(execution['stop_reason']),
      ValueReaders.stringValue(
        ValueReaders.mapValue(result['record'])['stop_reason'],
      ),
    ]);
    final informationContract = _informationContract(
      changedPaths,
      checkpointReviewBody,
      analysisInformation,
    );
    final stopDiagnosis = _preferredNarrativeStopDiagnosis(
      result,
      execution: execution,
      runCenterContract: runCenterContract,
      stopReason: stopReason,
      reviewSummary: reviewSummary,
      informationSummary: ValueReaders.stringValue(
        informationContract['information_summary'],
      ),
    );
    return <String, Object?>{
      'activation_report_path': activationReportPath,
      'activation_report_summary': activationReportSummary,
      'chapter_delivery_state': chapterDeliveryState,
      'chapter_delivery_path': chapterDeliveryPath,
      'review_path': reviewPath,
      'review_summary': reviewSummary,
      'continuity_counts': _continuityCounts(changedPaths),
      'information_contract': informationContract,
      'expression_constraint_contract': expressionConstraint,
      'chapter_delivery_contract': chapterDelivery,
      'stop_reason': stopReason,
      'stop_diagnosis': stopDiagnosis.toJson(),
    };
  }

  LongTaskStopDiagnosisProjection _preferredNarrativeStopDiagnosis(
    JsonMap result, {
    required JsonMap execution,
    required JsonMap runCenterContract,
    required String stopReason,
    required String reviewSummary,
    required String informationSummary,
  }) {
    final contractDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
      ValueReaders.mapValue(runCenterContract['stop_diagnosis']),
    );
    if (contractDiagnosis.present) {
      return contractDiagnosis;
    }
    final directDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
      ValueReaders.mapValue(result['stop_diagnosis']),
    );
    if (directDiagnosis.present) {
      return directDiagnosis;
    }
    final executionDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
      ValueReaders.mapValue(execution['stop_diagnosis']),
    );
    if (executionDiagnosis.present) {
      return executionDiagnosis;
    }
    final stopOutcome = LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(result['stop_outcome']),
    );
    final recoveryState = LongTaskRecoveryState.fromJson(
      ValueReaders.mapValue(result['recovery_state']),
    );
    return _stopDiagnosisProjectionService.project(
      stopOutcome: stopOutcome,
      recoveryState: recoveryState,
      legacyReason: stopReason,
      note: _firstNonBlank(<String>[
        ValueReaders.stringValue(result['stop_note']),
        ValueReaders.stringValue(execution['stop_note']),
      ]),
      reviewSummary: reviewSummary,
      informationSummary: informationSummary,
      metadata: <String, Object?>{'source': 'workflow_output_summary'},
    );
  }

  List<String> narrativeBriefLines(JsonMap contract) {
    final lines = <String>[];
    final activationSummary = ValueReaders.stringValue(
      contract['activation_report_summary'],
    ).trim();
    final activationPath = ValueReaders.stringValue(
      contract['activation_report_path'],
    ).trim();
    final deliveryState = ValueReaders.stringValue(
      contract['chapter_delivery_state'],
    ).trim();
    final deliveryPath = ValueReaders.stringValue(
      contract['chapter_delivery_path'],
    ).trim();
    final reviewSummary = ValueReaders.stringValue(
      contract['review_summary'],
    ).trim();
    final reviewPath = ValueReaders.stringValue(contract['review_path']).trim();
    final continuityCounts = ValueReaders.mapValue(
      contract['continuity_counts'],
    );
    final informationContract = ValueReaders.mapValue(
      contract['information_contract'],
    );
    final expressionConstraintContract = ValueReaders.mapValue(
      contract['expression_constraint_contract'],
    );
    final chapterDeliveryContract = ValueReaders.mapValue(
      contract['chapter_delivery_contract'],
    );
    final stopReason = ValueReaders.stringValue(contract['stop_reason']).trim();
    final stopDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
      ValueReaders.mapValue(contract['stop_diagnosis']),
    );

    if (activationSummary.isNotEmpty || activationPath.isNotEmpty) {
      lines.add(
        activationSummary.isNotEmpty
            ? 'Activation：$activationSummary'
            : 'Activation：$activationPath',
      );
    }
    if (deliveryState.isNotEmpty || deliveryPath.isNotEmpty) {
      final parts = <String>[];
      if (deliveryState.isNotEmpty) {
        parts.add(deliveryState);
      }
      if (deliveryPath.isNotEmpty) {
        parts.add(deliveryPath);
      }
      lines.add('Delivery：${parts.join(' | ')}');
    }
    if (reviewSummary.isNotEmpty || reviewPath.isNotEmpty) {
      lines.add(
        reviewSummary.isNotEmpty
            ? 'Review：$reviewSummary'
            : 'Review：$reviewPath',
      );
    }
    final continuitySummary = _continuitySummaryLine(continuityCounts);
    if (continuitySummary.isNotEmpty) {
      lines.add(continuitySummary);
    }
    final informationSummary = _informationSummaryLines(informationContract);
    lines.addAll(informationSummary);
    lines.addAll(
      _expressionConstraintSummaryLines(expressionConstraintContract),
    );
    lines.addAll(_chapterDeliverySummaryLines(chapterDeliveryContract));
    if (stopDiagnosis.present) {
      lines.add(_stopDiagnosisLine(stopDiagnosis));
    } else if (stopReason.isNotEmpty) {
      lines.add(_stopReasonLine(stopReason));
    }
    return lines;
  }

  List<String> referenceExtractionBriefLines(
    ProjectReferenceExtractionResult result, {
    String strategyLabel = '',
  }) {
    final signal = _referenceExtractionSupervisorSignalService.build(result);
    final lifecycle = signal.lifecycleState;
    final lines = <String>['控制面：${_referenceLifecycleLabel(lifecycle)}'];
    final stopReasonLine = _referenceStopReasonLine(lifecycle.reason);
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

  JsonMap _writingExecutionResult(
    JsonMap result, {
    required JsonMap execution,
  }) {
    final direct = ValueReaders.mapValue(result['writing_execution_result']);
    if (direct.isNotEmpty) {
      return direct;
    }
    final nested = ValueReaders.mapValue(execution['writing_execution_result']);
    if (nested.isNotEmpty) {
      return nested;
    }
    if (ValueReaders.mapValue(result['constraints']).isNotEmpty ||
        ValueReaders.mapValue(
          result['expression_constraint_projection'],
        ).isNotEmpty) {
      return result;
    }
    final record = ValueReaders.mapValue(result['record']);
    final recordResult = ValueReaders.mapValue(
      record['writing_execution_result'],
    );
    if (recordResult.isNotEmpty) {
      return recordResult;
    }
    return ValueReaders.mapValue(record['last_writing_execution_result']);
  }

  JsonMap _expressionConstraintContract(JsonMap writingExecutionResult) {
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

  JsonMap _chapterDeliveryContract(
    JsonMap result, {
    required JsonMap execution,
  }) {
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

  List<String> _expressionConstraintSummaryLines(JsonMap contract) {
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

  List<String> _chapterDeliverySummaryLines(JsonMap contract) {
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

  JsonMap _continuityCounts(List<String> changedPaths) {
    var ledger = 0;
    var claims = 0;
    var reviews = 0;
    var deliveries = 0;
    for (final path in changedPaths) {
      final normalized = path.replaceAll('\\', '/').trim();
      if (normalized.startsWith(_ledgerRoot)) {
        ledger += 1;
      } else if (normalized.startsWith(_claimsRoot)) {
        claims += 1;
      } else if (normalized.startsWith(_reviewsRoot)) {
        reviews += 1;
      } else if (normalized.startsWith(_deliveriesRoot)) {
        deliveries += 1;
      }
    }
    final total = changedPaths
        .where(
          (path) =>
              path.replaceAll('\\', '/').trim().startsWith(_continuityRoot),
        )
        .length;
    return <String, Object?>{
      'total': total,
      'ledger': ledger,
      'claims': claims,
      'reviews': reviews,
      'deliveries': deliveries,
    };
  }

  String _continuitySummaryLine(JsonMap counts) {
    final total = ValueReaders.intValue(counts['total']);
    if (total <= 0) {
      return '';
    }
    final parts = <String>[];
    final ledger = ValueReaders.intValue(counts['ledger']);
    final claims = ValueReaders.intValue(counts['claims']);
    final reviews = ValueReaders.intValue(counts['reviews']);
    final deliveries = ValueReaders.intValue(counts['deliveries']);
    if (ledger > 0) {
      parts.add('ledger $ledger');
    }
    if (claims > 0) {
      parts.add('claims $claims');
    }
    if (reviews > 0) {
      parts.add('reviews $reviews');
    }
    if (deliveries > 0) {
      parts.add('deliveries $deliveries');
    }
    if (parts.isEmpty) {
      return 'Continuity：更新 $total 项';
    }
    return 'Continuity：${parts.join(' | ')}';
  }

  JsonMap _informationContract(
    List<String> changedPaths,
    JsonMap checkpointReviewBody,
    JsonMap analysisInformation,
  ) {
    final changedCounts = _informationChangedCounts(changedPaths);
    final artifactCounts = _analysisInformationCounts(analysisInformation);
    return <String, Object?>{
      'knowledge_count': _maxCount(
        ValueReaders.intValue(changedCounts['knowledge_count']),
        ValueReaders.intValue(artifactCounts['knowledge_count']),
      ),
      'design_count': _maxCount(
        ValueReaders.intValue(changedCounts['design_count']),
        ValueReaders.intValue(artifactCounts['design_count']),
      ),
      'research_count': _maxCount(
        ValueReaders.intValue(changedCounts['research_count']),
        ValueReaders.intValue(artifactCounts['research_count']),
      ),
      'reference_count': _maxCount(
        ValueReaders.intValue(changedCounts['reference_count']),
        ValueReaders.intValue(artifactCounts['reference_count']),
      ),
      'projection_paths': <Object?>[
        InformationProjectionDocument.knowledgeSummaryRelativePath,
        InformationProjectionDocument.designSummaryRelativePath,
        InformationProjectionDocument.researchSummaryRelativePath,
        InformationProjectionDocument.referenceBoundaryRelativePath,
      ],
      'information_summary': ValueReaders.stringValue(
        checkpointReviewBody['information_summary'],
      ).trim(),
    };
  }

  JsonMap _informationChangedCounts(List<String> changedPaths) {
    var knowledge = 0;
    var design = 0;
    var research = 0;
    var reference = 0;
    for (final path in changedPaths) {
      final normalized = path.replaceAll('\\', '/').trim();
      if (normalized.startsWith(_knowledgeCardsRoot)) {
        knowledge += 1;
      } else if (normalized.startsWith(_designElementsRoot)) {
        design += 1;
      } else if (normalized.startsWith(_researchNotesRoot)) {
        research += 1;
      } else if (normalized.startsWith(_referenceWorksRoot)) {
        reference += 1;
      }
    }
    return <String, Object?>{
      'knowledge_count': knowledge,
      'design_count': design,
      'research_count': research,
      'reference_count': reference,
    };
  }

  JsonMap _analysisInformationCounts(JsonMap analysisInformation) {
    return <String, Object?>{
      'knowledge_count': ValueReaders.stringList(
        analysisInformation['knowledge_card_ids'],
      ).length,
      'design_count': ValueReaders.stringList(
        analysisInformation['design_element_ids'],
      ).length,
      'research_count': ValueReaders.stringList(
        analysisInformation['research_note_ids'],
      ).length,
      'reference_count': ValueReaders.stringList(
        analysisInformation['reference_work_ids'],
      ).length,
    };
  }

  List<String> _informationSummaryLines(JsonMap contract) {
    if (contract.isEmpty) {
      return const <String>[];
    }
    final projection = _informationEvidenceProjectionService
        .fromWorkflowInformationContract(contract);
    return projection.userLines;
  }

  int _maxCount(int left, int right) {
    return left >= right ? left : right;
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

  String _stopReasonLine(String code) {
    final label = _stopReasonLabel(code);
    if (label.isEmpty || label == code.trim()) {
      return '停止原因：$code';
    }
    return '停止原因：$label（$code）';
  }

  String _stopDiagnosisLine(LongTaskStopDiagnosisProjection projection) {
    final label = projection.label.trim();
    final code = projection.code.trim();
    if (label.isEmpty) {
      return code.isEmpty ? '' : '停止原因：$code';
    }
    if (code.isEmpty || code == label) {
      return '停止原因：$label';
    }
    return '停止原因：$label（$code）';
  }

  String _stopReasonLabel(String code) {
    switch (code.trim()) {
      case 'max_steps':
      case 'max_seconds':
        return '预算边界已到';
      case 'completed':
      case 'no_runnable_task':
        return '当前目标已收尾';
      case 'waiting_user':
      case 'waiting_user_checkpoint':
      case 'waiting_user_choice':
      case 'waiting_gate':
      case 'information_waiting_user':
      case 'delivery_waiting_user_choice':
        return '等待用户确认';
      case 'failed_task':
      case 'delivery_repair_required':
      case 'information_repair_required':
        return '需修补后继续';
      case 'delivery_manual_attention':
      case 'content_quality_failed':
      case 'semantic_review_manual_attention':
      case 'chapter_gate_manual_attention':
        return '内容质量关口';
      case 'failed':
      case 'step_failed':
      case 'record_missing':
      case 'stale_running_task':
        return '技术失败';
      default:
        return code.trim();
    }
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

  String _referenceLifecycleLabel(ContinuousTaskLifecycleState lifecycle) {
    switch (lifecycle.reason.trim()) {
      case 'completed_publishable':
        return '已完成';
      case 'reference_coverage_followup_required':
        return '覆盖未完成';
      case 'reference_mount_confirmation_required':
        return '挂载等待确认';
      case 'reference_mount_incomplete':
        return '挂载未完成';
      case 'reference_continuity_conflict_requires_review':
        return '连续性待复核';
      default:
        return switch (lifecycle.runPhase) {
          ContinuousTaskRunPhases.running => '运行中',
          ContinuousTaskRunPhases.paused => '已暂停',
          ContinuousTaskRunPhases.waitingUser => '等待用户',
          ContinuousTaskRunPhases.manualAttention => '需人工处理',
          ContinuousTaskRunPhases.recovering => '恢复中',
          ContinuousTaskRunPhases.stopped => '已停止',
          _ => lifecycle.reason.trim().isEmpty ? '状态待确认' : lifecycle.reason,
        };
    }
  }

  String _referenceStopReasonLine(String reason) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      return '';
    }
    final label = switch (cleanReason) {
      'completed_publishable' => 'publishable 结果已完成',
      'reference_coverage_followup_required' => '覆盖不足，需继续提取',
      'reference_mount_confirmation_required' => '挂载需要显式确认',
      'reference_mount_incomplete' => '项目挂载未完成',
      'reference_continuity_conflict_requires_review' => '连续性冲突需要人工复核',
      _ => cleanReason,
    };
    return label == cleanReason
        ? '停止原因：$cleanReason'
        : '停止原因：$label（$cleanReason）';
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
