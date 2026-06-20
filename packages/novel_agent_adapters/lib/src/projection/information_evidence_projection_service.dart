import 'package:novel_agent_core/novel_agent_core.dart';

import 'information_evidence_projection.dart';
import 'information_evidence_projection_item.dart';

class InformationEvidenceProjectionService {
  static const String _knowledgeCardsRoot =
      '.novel_agent/information/knowledge_cards/';
  static const String _designElementsRoot =
      '.novel_agent/information/design_elements/';
  static const String _researchNotesRoot =
      '.novel_agent/information/research_notes/';
  static const String _researchRequestsRoot =
      '.novel_agent/information/research_requests/';
  static const String _referenceWorksRoot =
      '.novel_agent/information/reference_works/';

  const InformationEvidenceProjectionService();

  static const List<String> defaultProjectionPaths = <String>[
    InformationProjectionDocument.knowledgeSummaryRelativePath,
    InformationProjectionDocument.designSummaryRelativePath,
    InformationProjectionDocument.researchSummaryRelativePath,
    InformationProjectionDocument.referenceBoundaryRelativePath,
  ];

  InformationEvidenceProjection fromWritingExecutionInformation(
    JsonMap information, {
    List<JsonMap> permissionRecords = const <JsonMap>[],
  }) {
    final changedPaths = ValueReaders.stringList(information['changed_paths']);
    final evidenceGate = ValueReaders.mapValue(information['evidence_gate']);
    return _project(
      contract: <String, Object?>{
        'present': ValueReaders.boolValue(information['present']),
        'summary': ValueReaders.stringValue(information['summary']).trim(),
        'risk_category': ValueReaders.stringValue(
          information['risk_category'],
        ).trim(),
        'reason': ValueReaders.stringValue(information['reason']).trim(),
        'projection_paths': _projectionPathsForChangedPaths(changedPaths),
        'knowledge_count': ValueReaders.intValue(
          _changedCounts(changedPaths)['knowledge_count'],
        ),
        'design_count': ValueReaders.intValue(
          _changedCounts(changedPaths)['design_count'],
        ),
        'research_count': ValueReaders.intValue(
          _changedCounts(changedPaths)['research_count'],
        ),
        'reference_count': ValueReaders.intValue(
          _changedCounts(changedPaths)['reference_count'],
        ),
        'pending_research_count': ValueReaders.intValue(
          evidenceGate['pending_research_count'],
          ValueReaders.intValue(information['pending_research_count']),
        ),
        'awaiting_confirmation_count': ValueReaders.intValue(
          evidenceGate['awaiting_confirmation_count'],
        ),
        'gateway_failure_count': ValueReaders.intValue(
          evidenceGate['gateway_failure_count'],
        ),
        'rigorous_source_insufficient_count': ValueReaders.intValue(
          evidenceGate['rigorous_source_insufficient_count'],
        ),
        'required_information_omitted_count': ValueReaders.intValue(
          evidenceGate['required_information_omitted_count'],
        ),
        'external_fact_unverified_count': ValueReaders.intValue(
          evidenceGate['external_fact_unverified_count'],
        ),
        'high_risk_reference_count': ValueReaders.intValue(
          ValueReaders.mapValue(
            information['metadata'],
          )['high_risk_reference_count'],
        ),
        'waiting_user': ValueReaders.boolValue(information['waiting_user']),
        'requires_repair': ValueReaders.boolValue(
          information['requires_repair'],
        ),
        'manual_attention_required': ValueReaders.boolValue(
          information['manual_attention_required'],
        ),
        'changed_path_count': changedPaths.length,
      },
      permissionRecords: permissionRecords,
    );
  }

  InformationEvidenceProjection fromToolResult(JsonMap result) {
    final changedPaths = _toolInformationChangedPaths(result);
    final changedCounts = _changedCounts(changedPaths);
    final analysisCounts = _analysisInformationCounts(
      _analysisInformation(result),
    );
    final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
    final payload = ValueReaders.mapValue(domainOutcome['outcome_payload']);
    final researchExecution = ValueReaders.mapValue(
      payload['research_execution'],
    );
    final sourceQualitySummary = ValueReaders.mapValue(
      ValueReaders.mapValue(
        researchExecution['gateway_summary'],
      )['source_quality_summary'],
    );
    final awaitingConfirmation =
        ValueReaders.boolValue(payload['requires_user_confirmation']) ||
        ValueReaders.boolValue(researchExecution['await_user_confirmation']);
    final executedResearch =
        ValueReaders.boolValue(payload['network_execution_performed']) ||
        ValueReaders.boolValue(payload['import_execution_performed']) ||
        ValueReaders.boolValue(researchExecution['executed_network']) ||
        ValueReaders.boolValue(researchExecution['executed_import']);
    final blocked = ValueReaders.boolValue(researchExecution['blocked']);
    final pendingResearch =
        ValueReaders.boolValue(payload['request_registered']) &&
        !executedResearch &&
        !awaitingConfirmation &&
        !blocked;
    final rigorousSourceInsufficient =
        ValueReaders.boolValue(
          sourceQualitySummary['requires_rigorous_sources'],
        ) &&
        !ValueReaders.boolValue(
          sourceQualitySummary['meets_source_requirement'],
          true,
        );
    final summary = _firstNonEmpty(<String>[
      ValueReaders.stringValue(
        ValueReaders.mapValue(
          ValueReaders.mapValue(result['checkpoint_review'])['review'],
        )['information_summary'],
      ).trim(),
      ValueReaders.stringValue(result['information_summary']).trim(),
      ValueReaders.stringValue(payload['research_execution_summary']).trim(),
      ValueReaders.stringValue(researchExecution['summary']).trim(),
    ]);
    final hasInformationContent =
        ValueReaders.intValue(changedCounts['knowledge_count']) > 0 ||
        ValueReaders.intValue(changedCounts['design_count']) > 0 ||
        ValueReaders.intValue(changedCounts['research_count']) > 0 ||
        ValueReaders.intValue(changedCounts['reference_count']) > 0 ||
        ValueReaders.intValue(analysisCounts['knowledge_count']) > 0 ||
        ValueReaders.intValue(analysisCounts['design_count']) > 0 ||
        ValueReaders.intValue(analysisCounts['research_count']) > 0 ||
        ValueReaders.intValue(analysisCounts['reference_count']) > 0 ||
        awaitingConfirmation ||
        executedResearch ||
        blocked ||
        pendingResearch ||
        rigorousSourceInsufficient ||
        summary.isNotEmpty;
    return _project(
      contract: <String, Object?>{
        'present': hasInformationContent,
        'summary': summary,
        'risk_category': awaitingConfirmation
            ? 'checkpoint_user'
            : blocked
            ? 'repair'
            : rigorousSourceInsufficient
            ? 'accept'
            : pendingResearch
            ? 'accept'
            : '',
        'projection_paths': hasInformationContent
            ? _projectionPathsForChangedPaths(changedPaths)
            : const <Object?>[],
        'knowledge_count': _maxCount(
          ValueReaders.intValue(changedCounts['knowledge_count']),
          ValueReaders.intValue(analysisCounts['knowledge_count']),
        ),
        'design_count': _maxCount(
          ValueReaders.intValue(changedCounts['design_count']),
          ValueReaders.intValue(analysisCounts['design_count']),
        ),
        'research_count': _maxCount(
          ValueReaders.intValue(changedCounts['research_count']),
          ValueReaders.intValue(analysisCounts['research_count']),
        ),
        'reference_count': _maxCount(
          ValueReaders.intValue(changedCounts['reference_count']),
          ValueReaders.intValue(analysisCounts['reference_count']),
        ),
        'pending_research_count': pendingResearch ? 1 : 0,
        'awaiting_confirmation_count': awaitingConfirmation ? 1 : 0,
        'gateway_failure_count': blocked ? 1 : 0,
        'rigorous_source_insufficient_count': rigorousSourceInsufficient
            ? 1
            : 0,
        'waiting_user': awaitingConfirmation,
        'requires_repair': blocked,
        'manual_attention_required': false,
        'changed_path_count': changedPaths.length,
      },
    );
  }

  InformationEvidenceProjection fromWorkflowInformationContract(
    JsonMap contract, {
    List<JsonMap> permissionRecords = const <JsonMap>[],
  }) {
    return _project(contract: contract, permissionRecords: permissionRecords);
  }

  InformationEvidenceProjection _project({
    required JsonMap contract,
    List<JsonMap> permissionRecords = const <JsonMap>[],
  }) {
    final knowledgeCount = ValueReaders.intValue(contract['knowledge_count']);
    final designCount = ValueReaders.intValue(contract['design_count']);
    final researchCount = ValueReaders.intValue(contract['research_count']);
    final referenceCount = ValueReaders.intValue(contract['reference_count']);
    final pendingResearchCount = ValueReaders.intValue(
      contract['pending_research_count'],
    );
    final awaitingConfirmationCount = _maxCount(
      ValueReaders.intValue(contract['awaiting_confirmation_count']),
      _userActionCount(permissionRecords, _isAwaitingConfirmationState),
    );
    final rejectedCount = _maxCount(
      ValueReaders.intValue(contract['rejected_count']),
      _userActionCount(permissionRecords, _isRejectedState),
    );
    final gatewayFailureCount = _maxCount(
      ValueReaders.intValue(contract['gateway_failure_count']),
      _userActionCount(permissionRecords, _isGatewayFailedState),
    );
    final rigorousSourceInsufficientCount = ValueReaders.intValue(
      contract['rigorous_source_insufficient_count'],
    );
    final requiredInformationOmittedCount = ValueReaders.intValue(
      contract['required_information_omitted_count'],
    );
    final externalFactUnverifiedCount = ValueReaders.intValue(
      contract['external_fact_unverified_count'],
    );
    final highRiskReferenceCount = ValueReaders.intValue(
      contract['high_risk_reference_count'],
    );
    final waitingUser =
        ValueReaders.boolValue(contract['waiting_user']) ||
        awaitingConfirmationCount > 0;
    final requiresRepair =
        ValueReaders.boolValue(contract['requires_repair']) ||
        gatewayFailureCount > 0 ||
        requiredInformationOmittedCount > 0 ||
        externalFactUnverifiedCount > 0;
    final manualAttentionRequired =
        ValueReaders.boolValue(contract['manual_attention_required']) ||
        highRiskReferenceCount > 0;
    final projectionPaths = ValueReaders.stringList(
      contract['projection_paths'],
    );
    final userActionItems = _userActionItems(permissionRecords);
    final status = _status(
      waitingUser: waitingUser,
      rejectedCount: rejectedCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
      manualAttentionRequired: manualAttentionRequired,
      requiresRepair: requiresRepair,
      pendingResearchCount: pendingResearchCount,
      researchCount: researchCount,
      changedPathCount: ValueReaders.intValue(contract['changed_path_count']),
      summary: ValueReaders.stringValue(
        contract['summary'],
        ValueReaders.stringValue(contract['information_summary']),
      ).trim(),
      present: ValueReaders.boolValue(contract['present']),
    );
    final statusLabel = _statusLabel(status);
    final summary = _summary(
      status: status,
      contract: contract,
      awaitingConfirmationCount: awaitingConfirmationCount,
      rejectedCount: rejectedCount,
      pendingResearchCount: pendingResearchCount,
      gatewayFailureCount: gatewayFailureCount,
      rigorousSourceInsufficientCount: rigorousSourceInsufficientCount,
      requiredInformationOmittedCount: requiredInformationOmittedCount,
      externalFactUnverifiedCount: externalFactUnverifiedCount,
    );
    final subtitle =
        'knowledge $knowledgeCount | design $designCount | '
        'research $researchCount | reference $referenceCount';
    final userLines = <String>[
      if (statusLabel.isNotEmpty) '资料状态：$statusLabel',
      if (summary.isNotEmpty) summary,
      if (projectionPaths.isNotEmpty) '资料摘要：${projectionPaths.join(' | ')}',
    ];
    final diagnosticLines = <String>[
      if (ValueReaders.stringValue(contract['risk_category']).trim().isNotEmpty)
        'risk_category=${ValueReaders.stringValue(contract['risk_category']).trim()}',
      if (ValueReaders.stringValue(contract['reason']).trim().isNotEmpty)
        'reason=${ValueReaders.stringValue(contract['reason']).trim()}',
      if (pendingResearchCount > 0)
        'pending_research_count=$pendingResearchCount',
      if (awaitingConfirmationCount > 0)
        'awaiting_confirmation_count=$awaitingConfirmationCount',
      if (rejectedCount > 0) 'rejected_count=$rejectedCount',
      if (gatewayFailureCount > 0) 'gateway_failure_count=$gatewayFailureCount',
      if (rigorousSourceInsufficientCount > 0)
        'rigorous_source_insufficient_count=$rigorousSourceInsufficientCount',
      if (requiredInformationOmittedCount > 0)
        'required_information_omitted_count=$requiredInformationOmittedCount',
      if (externalFactUnverifiedCount > 0)
        'external_fact_unverified_count=$externalFactUnverifiedCount',
    ];
    return InformationEvidenceProjection(
      present:
          ValueReaders.boolValue(contract['present']) ||
          userActionItems.isNotEmpty,
      status: status,
      statusLabel: statusLabel,
      summary: summary,
      subtitle: subtitle,
      knowledgeCount: knowledgeCount,
      designCount: designCount,
      researchCount: researchCount,
      referenceCount: referenceCount,
      projectionPaths: List<String>.unmodifiable(projectionPaths),
      projectionItems: List<InformationEvidenceProjectionItem>.unmodifiable(
        projectionPaths
            .map(_projectionItemForPath)
            .whereType<InformationEvidenceProjectionItem>(),
      ),
      userActionItems: List<InformationEvidenceProjectionItem>.unmodifiable(
        userActionItems,
      ),
      userLines: List<String>.unmodifiable(userLines),
      diagnosticLines: List<String>.unmodifiable(diagnosticLines),
    );
  }

  String _status({
    required bool waitingUser,
    required int rejectedCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
    required bool manualAttentionRequired,
    required bool requiresRepair,
    required int pendingResearchCount,
    required int researchCount,
    required int changedPathCount,
    required String summary,
    required bool present,
  }) {
    if (manualAttentionRequired) {
      return 'needs_attention';
    }
    if (waitingUser) {
      return 'waiting_confirmation';
    }
    if (rejectedCount > 0) {
      return 'rejected';
    }
    if (gatewayFailureCount > 0 || requiresRepair) {
      return 'needs_repair';
    }
    if (rigorousSourceInsufficientCount > 0) {
      return 'source_insufficient';
    }
    if (requiredInformationOmittedCount > 0 ||
        externalFactUnverifiedCount > 0 ||
        pendingResearchCount > 0) {
      return 'need_information';
    }
    if (researchCount > 0) {
      return 'executed_research';
    }
    if (changedPathCount > 0 || summary.isNotEmpty || present) {
      return 'information_changed';
    }
    return 'clear';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'needs_attention' => '需要留意',
      'waiting_confirmation' => '等待确认',
      'rejected' => '已拒绝',
      'needs_repair' => '需要处理',
      'source_insufficient' => '来源不足',
      'need_information' => '需要资料',
      'executed_research' => '已执行研究',
      'information_changed' => '已更新资料',
      _ => '无资料变更',
    };
  }

  String _summary({
    required String status,
    required JsonMap contract,
    required int awaitingConfirmationCount,
    required int rejectedCount,
    required int pendingResearchCount,
    required int gatewayFailureCount,
    required int rigorousSourceInsufficientCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
  }) {
    final provided = ValueReaders.stringValue(
      contract['summary'],
      ValueReaders.stringValue(contract['information_summary']),
    ).trim();
    if (provided.isNotEmpty) {
      return provided;
    }
    return switch (status) {
      'needs_attention' => '当前资料边界需要人工留意后再继续。',
      'waiting_confirmation' => '有 $awaitingConfirmationCount 项资料请求等待确认。',
      'rejected' => '有 $rejectedCount 项资料请求已拒绝，当前保留资料缺口。',
      'needs_repair' =>
        gatewayFailureCount > 0
            ? '有 $gatewayFailureCount 项资料请求执行失败，建议先修复后再继续。'
            : '当前资料证据仍需补齐后再继续。',
      'source_insufficient' =>
        '已补充资料，但有 $rigorousSourceInsufficientCount 项来源仍不足。',
      'need_information' => _needInformationSummary(
        pendingResearchCount: pendingResearchCount,
        requiredInformationOmittedCount: requiredInformationOmittedCount,
        externalFactUnverifiedCount: externalFactUnverifiedCount,
      ),
      'executed_research' => '已执行资料研究，并更新相关资料摘要。',
      'information_changed' => '已更新资料，可直接查看相关摘要。',
      _ => '当前没有新的资料状态变化。',
    };
  }

  String _needInformationSummary({
    required int pendingResearchCount,
    required int requiredInformationOmittedCount,
    required int externalFactUnverifiedCount,
  }) {
    final parts = <String>[];
    if (pendingResearchCount > 0) {
      parts.add('待补资料 $pendingResearchCount 项');
    }
    if (requiredInformationOmittedCount > 0) {
      parts.add('必要信息缺口 $requiredInformationOmittedCount 项');
    }
    if (externalFactUnverifiedCount > 0) {
      parts.add('外部事实待核验 $externalFactUnverifiedCount 项');
    }
    if (parts.isEmpty) {
      return '当前仍有资料缺口，建议补齐后再继续。';
    }
    return '当前仍有资料缺口：${parts.join('，')}。';
  }

  List<String> _defaultProjectionPaths() {
    return defaultProjectionPaths;
  }

  List<String> _projectionPathsForChangedPaths(List<String> changedPaths) {
    final present = changedPaths
        .map((path) => path.replaceAll('\\', '/').trim())
        .toSet();
    final paths = _defaultProjectionPaths()
        .where(present.contains)
        .toList(growable: false);
    return paths.isEmpty ? _defaultProjectionPaths() : paths;
  }

  InformationEvidenceProjectionItem? _projectionItemForPath(String path) {
    return switch (path) {
      InformationProjectionDocument.knowledgeSummaryRelativePath =>
        const InformationEvidenceProjectionItem(
          id: InformationProjectionDocument.knowledgeSummaryRelativePath,
          title: '项目知识摘要',
          relativePath:
              InformationProjectionDocument.knowledgeSummaryRelativePath,
          status: 'projection',
          subtitle: '资料摘要',
          summary: '打开当前 knowledge 卡片的可读摘要。',
        ),
      InformationProjectionDocument.designSummaryRelativePath =>
        const InformationEvidenceProjectionItem(
          id: InformationProjectionDocument.designSummaryRelativePath,
          title: '设计元素摘要',
          relativePath: InformationProjectionDocument.designSummaryRelativePath,
          status: 'projection',
          subtitle: '资料摘要',
          summary: '打开当前 design element 的可读摘要。',
        ),
      InformationProjectionDocument.researchSummaryRelativePath =>
        const InformationEvidenceProjectionItem(
          id: InformationProjectionDocument.researchSummaryRelativePath,
          title: '资料研究摘要',
          relativePath:
              InformationProjectionDocument.researchSummaryRelativePath,
          status: 'projection',
          subtitle: '资料摘要',
          summary: '打开当前 research note 的可读摘要。',
        ),
      InformationProjectionDocument.referenceBoundaryRelativePath =>
        const InformationEvidenceProjectionItem(
          id: InformationProjectionDocument.referenceBoundaryRelativePath,
          title: '引用作品边界',
          relativePath:
              InformationProjectionDocument.referenceBoundaryRelativePath,
          status: 'projection',
          subtitle: '资料摘要',
          summary: '打开当前 reference work 边界摘要。',
        ),
      _ => null,
    };
  }

  List<InformationEvidenceProjectionItem> _userActionItems(
    List<JsonMap> permissionRecords,
  ) {
    final items = <InformationEvidenceProjectionItem>[];
    for (final wrapped in permissionRecords) {
      final relativePath = ValueReaders.stringValue(
        wrapped['relative_path'],
      ).trim();
      final record = ValueReaders.mapValue(wrapped['record']);
      if (relativePath.isEmpty || record.isEmpty) {
        continue;
      }
      final item = _userActionItem(relativePath, record);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  InformationEvidenceProjectionItem? _userActionItem(
    String relativePath,
    JsonMap record,
  ) {
    if (relativePath.startsWith(_knowledgeCardsRoot)) {
      final card = ProjectKnowledgeCard.fromJson(record);
      if (card.lifecycleStatus != InformationLifecycleStatuses.proposed) {
        return null;
      }
      return InformationEvidenceProjectionItem(
        id: card.cardId,
        title: '知识待确认',
        relativePath: relativePath,
        status: card.lifecycleStatus,
        subtitle: '待确认',
        summary: card.summary.trim().isEmpty ? card.title : card.summary.trim(),
      );
    }
    if (relativePath.startsWith(_designElementsRoot)) {
      final card = DesignElementCard.fromJson(record);
      if (card.lifecycleStatus != InformationLifecycleStatuses.proposed) {
        return null;
      }
      return InformationEvidenceProjectionItem(
        id: card.designId,
        title: '设计待确认',
        relativePath: relativePath,
        status: card.lifecycleStatus,
        subtitle: '待确认',
        summary: card.designLabel,
      );
    }
    if (relativePath.startsWith(_referenceWorksRoot)) {
      final reference = ReferenceWorkRecord.fromJson(record);
      if (!reference.requiresConfirmation) {
        return null;
      }
      final summary = reference.allowedUsageSummary.trim().isEmpty
          ? reference.declaredUsageIntent
          : reference.allowedUsageSummary.trim();
      return InformationEvidenceProjectionItem(
        id: reference.referenceWorkId,
        title: '引用待确认',
        relativePath: relativePath,
        status: 'needs_user_confirmation',
        subtitle: '待确认',
        summary: summary,
      );
    }
    if (relativePath.startsWith(_researchRequestsRoot)) {
      final requestState = ValueReaders.stringValue(
        record['request_state'],
      ).trim();
      if (requestState.isEmpty || requestState == 'completed') {
        return null;
      }
      final researchRequest = ValueReaders.mapValue(record['research_request']);
      final query = ValueReaders.stringValue(researchRequest['query']).trim();
      final actionSummary = _firstNonEmpty(<String>[
        ValueReaders.stringValue(record['resolution_note']).trim(),
        ValueReaders.stringValue(record['blocked_reason']).trim(),
        ValueReaders.stringValue(
          ValueReaders.mapValue(record['permission_decision'])['reason'],
        ).trim(),
        query,
      ]);
      return InformationEvidenceProjectionItem(
        id: ValueReaders.stringValue(record['request_id'], relativePath),
        title: _researchRequestTitle(requestState),
        relativePath: relativePath,
        status: requestState,
        subtitle: _researchRequestSubtitle(requestState),
        summary: actionSummary.isEmpty ? '当前资料请求需要进一步处理。' : actionSummary,
      );
    }
    return null;
  }

  String _researchRequestTitle(String requestState) {
    return switch (requestState) {
      'awaiting_user_confirmation' => '资料待确认',
      'pending_gateway_execution' => '资料待处理',
      'needs_user_info' => '资料待补充',
      'gateway_failed' => '资料待修复',
      'rejected' => '资料已拒绝',
      _ => '资料请求',
    };
  }

  String _researchRequestSubtitle(String requestState) {
    return switch (requestState) {
      'awaiting_user_confirmation' => '等待确认',
      'pending_gateway_execution' => '需要资料',
      'needs_user_info' => '待补充',
      'gateway_failed' => '需要处理',
      'rejected' => '已拒绝',
      _ => requestState,
    };
  }

  int _userActionCount(
    List<JsonMap> permissionRecords,
    bool Function(String requestState) matcher,
  ) {
    var count = 0;
    for (final wrapped in permissionRecords) {
      final relativePath = ValueReaders.stringValue(
        wrapped['relative_path'],
      ).trim();
      if (!relativePath.startsWith(_researchRequestsRoot)) {
        continue;
      }
      final requestState = ValueReaders.stringValue(
        ValueReaders.mapValue(wrapped['record'])['request_state'],
      ).trim();
      if (matcher(requestState)) {
        count += 1;
      }
    }
    return count;
  }

  bool _isAwaitingConfirmationState(String requestState) {
    return requestState == 'awaiting_user_confirmation';
  }

  bool _isRejectedState(String requestState) {
    return requestState == 'rejected';
  }

  bool _isGatewayFailedState(String requestState) {
    return requestState == 'gateway_failed';
  }

  List<String> _toolInformationChangedPaths(JsonMap result) {
    final changedPaths = <String>[];

    void addPaths(Object? value) {
      for (final rawPath in ValueReaders.stringList(value)) {
        final normalized = rawPath.replaceAll('\\', '/').trim();
        if (normalized.isEmpty || changedPaths.contains(normalized)) {
          continue;
        }
        changedPaths.add(normalized);
      }
    }

    addPaths(result['changed_paths']);
    final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
    final persistence = ValueReaders.mapValue(
      ValueReaders.mapValue(domainOutcome['metadata'])['adapter_persistence'],
    );
    addPaths(persistence['changed_paths']);
    final researchExecution = ValueReaders.mapValue(
      ValueReaders.mapValue(
        domainOutcome['outcome_payload'],
      )['research_execution'],
    );
    addPaths(researchExecution['changed_paths']);
    return changedPaths;
  }

  JsonMap _analysisInformation(JsonMap result) {
    final direct = ValueReaders.mapValue(result['analysis_information']);
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.mapValue(
      ValueReaders.mapValue(result['execution'])['analysis_information'],
    );
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

  JsonMap _changedCounts(List<String> changedPaths) {
    var knowledge = 0;
    var design = 0;
    var research = 0;
    var reference = 0;
    for (final rawPath in changedPaths) {
      final normalized = rawPath.replaceAll('\\', '/').trim();
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

  int _maxCount(int left, int right) {
    return left >= right ? left : right;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final clean = value.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }
}
