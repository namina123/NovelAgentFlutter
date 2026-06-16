import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'workflow_output_expression_constraint_summary_renderer.dart';
import 'workflow_output_run_center_summary_renderer.dart';
import 'workflow_output_stop_diagnosis_text_service.dart';

class NarrativeRuntimeSummaryRenderer {
  NarrativeRuntimeSummaryRenderer({
    InformationEvidenceProjectionService? informationEvidenceProjectionService,
    ExpressionConstraintSummaryRenderer? expressionConstraintSummaryRenderer,
    LongTaskStopDiagnosisProjectionService? stopDiagnosisProjectionService,
    RunCenterSummaryRenderer? runCenterSummaryRenderer,
    StopDiagnosisTextService? stopDiagnosisTextService,
  }) : _informationEvidenceProjectionService =
           informationEvidenceProjectionService ??
           const InformationEvidenceProjectionService(),
       _expressionConstraintSummaryRenderer =
           expressionConstraintSummaryRenderer ??
           ExpressionConstraintSummaryRenderer(),
       _stopDiagnosisProjectionService =
           stopDiagnosisProjectionService ??
           const LongTaskStopDiagnosisProjectionService(),
       _runCenterSummaryRenderer =
           runCenterSummaryRenderer ?? RunCenterSummaryRenderer(),
       _stopDiagnosisTextService =
           stopDiagnosisTextService ?? const StopDiagnosisTextService();

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
  final ExpressionConstraintSummaryRenderer
  _expressionConstraintSummaryRenderer;
  final LongTaskStopDiagnosisProjectionService _stopDiagnosisProjectionService;
  final RunCenterSummaryRenderer _runCenterSummaryRenderer;
  final StopDiagnosisTextService _stopDiagnosisTextService;

  JsonMap extractContract(JsonMap result) {
    // 中文注释: CLI 只读取生产侧已经投影好的 narrative 合同，不再自己在壳层里推断。
    final execution = ValueReaders.mapValue(result['execution']);
    final runCenterContract = _runCenterSummaryRenderer.extractContract(result);
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
    final expressionConstraint = _expressionConstraintSummaryRenderer
        .buildContract(writingExecutionResult);
    final chapterDelivery = _expressionConstraintSummaryRenderer
        .buildChapterDeliveryContract(result, execution: execution);
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

  List<String> renderLines(JsonMap contract) {
    // 中文注释: narrative 摘要把 activation、delivery、review、资料与表达约束信号串成一条可读短链。
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
      _expressionConstraintSummaryRenderer.renderSummaryLines(
        expressionConstraintContract,
      ),
    );
    lines.addAll(
      _expressionConstraintSummaryRenderer.renderChapterDeliverySummaryLines(
        chapterDeliveryContract,
      ),
    );
    if (stopDiagnosis.present) {
      lines.add(_stopDiagnosisTextService.renderDiagnosisLine(stopDiagnosis));
    } else if (stopReason.isNotEmpty) {
      lines.add(_stopDiagnosisTextService.renderGenericReasonLine(stopReason));
    }
    return lines;
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

  List<String> _informationSummaryLines(JsonMap contract) {
    if (contract.isEmpty) {
      return const <String>[];
    }
    final projection = _informationEvidenceProjectionService
        .fromWorkflowInformationContract(contract);
    return projection.userLines;
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

  int _maxCount(int left, int right) {
    return left >= right ? left : right;
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
