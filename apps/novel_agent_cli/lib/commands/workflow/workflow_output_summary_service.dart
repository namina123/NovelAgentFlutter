import 'package:novel_agent_core/novel_agent_core.dart';

class WorkflowOutputSummaryService {
  const WorkflowOutputSummaryService();

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
    if (reason.isNotEmpty) {
      lines.add('停止原因：$reason');
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
    final checkpointReview = ValueReaders.mapValue(result['checkpoint_review']);
    final checkpointReviewBody = ValueReaders.mapValue(checkpointReview['review']);
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
    return <String, Object?>{
      'activation_report_path': activationReportPath,
      'activation_report_summary': activationReportSummary,
      'chapter_delivery_state': chapterDeliveryState,
      'chapter_delivery_path': chapterDeliveryPath,
      'review_path': reviewPath,
      'review_summary': reviewSummary,
      'continuity_counts': _continuityCounts(changedPaths),
      'information_contract': _informationContract(
        changedPaths,
        checkpointReviewBody,
        analysisInformation,
      ),
    };
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
    final continuityCounts = ValueReaders.mapValue(contract['continuity_counts']);
    final informationContract = ValueReaders.mapValue(
      contract['information_contract'],
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
          (path) => path.replaceAll('\\', '/').trim().startsWith(_continuityRoot),
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
    final knowledge = ValueReaders.intValue(contract['knowledge_count']);
    final design = ValueReaders.intValue(contract['design_count']);
    final research = ValueReaders.intValue(contract['research_count']);
    final reference = ValueReaders.intValue(contract['reference_count']);
    final summary = ValueReaders.stringValue(
      contract['information_summary'],
    ).trim();
    final projectionPaths = ValueReaders.stringList(contract['projection_paths']);
    final lines = <String>[
      'Information：knowledge $knowledge | design $design | research $research | reference $reference',
    ];
    if (summary.isNotEmpty) {
      lines.add('Information Signal：$summary');
    }
    if (projectionPaths.isNotEmpty) {
      lines.add('Information Projections：${projectionPaths.join(' | ')}');
    }
    return lines;
  }

  int _maxCount(int left, int right) {
    return left >= right ? left : right;
  }
}
