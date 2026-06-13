import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/open_narrative_state_record_document_service.dart';
import '../storage/project_information_path_service.dart';
import '../storage/project_json_document_service.dart';
import 'project_information_import_collection_result.dart';
import 'project_information_import_collection_service.dart';
import 'project_information_research_coordinator_result.dart';
import 'project_information_research_execution_budget.dart';
import 'project_pending_research_action_service.dart';
import 'project_research_gateway_run_result.dart';
import 'project_research_gateway_service.dart';

class ProjectInformationResearchCoordinatorService {
  ProjectInformationResearchCoordinatorService({
    required ProjectWorkspacePort workspacePort,
    ProjectResearchGatewayService? gatewayService,
    ProjectInformationImportCollectionService? importCollectionService,
    ProjectInformationPathService? pathService,
    ProjectJsonDocumentService? jsonDocumentService,
    OpenNarrativeStateRecordDocumentService? recordDocumentService,
    InformationCollectionPolicyService? collectionPolicyService,
    InformationPermissionPolicyService? permissionPolicyService,
    InformationResearchExecutionDecisionService? executionDecisionService,
  }) : _gatewayService =
           gatewayService ??
           ProjectResearchGatewayService(workspacePort: workspacePort),
       _importCollectionService =
           importCollectionService ??
           ProjectInformationImportCollectionService(workspacePort: workspacePort),
       _pathService = pathService ?? ProjectInformationPathService(),
       _jsonDocumentService =
           jsonDocumentService ??
           ProjectJsonDocumentService(workspacePort: workspacePort),
       _recordDocumentService =
           recordDocumentService ??
           OpenNarrativeStateRecordDocumentService(workspacePort: workspacePort),
       _collectionPolicyService =
           collectionPolicyService ??
           const InformationCollectionPolicyService(),
       _permissionPolicyService =
           permissionPolicyService ??
           const InformationPermissionPolicyService(),
       _executionDecisionService =
           executionDecisionService ??
           const InformationResearchExecutionDecisionService();

  final ProjectResearchGatewayService _gatewayService;
  final ProjectInformationImportCollectionService _importCollectionService;
  final ProjectInformationPathService _pathService;
  final ProjectJsonDocumentService _jsonDocumentService;
  final OpenNarrativeStateRecordDocumentService _recordDocumentService;
  final InformationCollectionPolicyService _collectionPolicyService;
  final InformationPermissionPolicyService _permissionPolicyService;
  final InformationResearchExecutionDecisionService _executionDecisionService;

  Future<ProjectInformationResearchCoordinatorResult> processPendingRequest(
    ProjectDescriptor project, {
    required String requestId,
    required HostInformationPermissionContext hostPermissionContext,
    ProjectInformationResearchExecutionBudget budget =
        const ProjectInformationResearchExecutionBudget(),
  }) async {
    final record = await _readRecord(project, requestId);
    if (record.isEmpty) {
      return ProjectInformationResearchCoordinatorResult(
        requestId: requestId,
        requestState: 'missing',
        blocked: true,
        blockedReason: 'pending research request 不存在。',
        summary: '未找到待研究请求：$requestId',
      );
    }

    final collectionRequest = _collectionRequestFromRecord(record);
    final approvedForExecution = _isApprovedForExecution(record);
    final permissionDecision = _permissionDecisionFor(
      record,
      collectionRequest,
      approvedForExecution: approvedForExecution,
    );
    final decision = _executionDecisionService.decide(
      request: collectionRequest,
      hostPermissionContext: _effectiveHostContextForDecision(
        hostPermissionContext,
        approvedForExecution: approvedForExecution,
        request: collectionRequest,
      ),
      permissionDecision: permissionDecision,
    );
    final changedPaths = <String>[];
    final generatedResearchNoteIds = <String>[];
    ProjectInformationImportCollectionResult? importResult;
    ProjectResearchGatewayRunResult? gatewayResult;

    if (decision.blocked) {
      final state = _currentRequestState(record);
      final persistedState = await _persistDecisionState(
        project,
        requestId: requestId,
        record: record,
        requestState: state,
        decision: decision,
        changedPaths: changedPaths,
      );
      return ProjectInformationResearchCoordinatorResult(
        requestId: requestId,
        requestState: persistedState,
        blocked: true,
        blockedReason: decision.reason,
        summary: decision.reason.isEmpty ? '当前研究请求不可执行。' : decision.reason,
        changedPaths: changedPaths.toSet().toList(growable: false),
        executionDecision: decision.toJson(),
      );
    }

    if (decision.autoExecuteImport && !_importAlreadyExecuted(record)) {
      importResult = await _executeImport(
        project,
        requestId: requestId,
        record: record,
        request: decision.effectiveRequest,
      );
      changedPaths.addAll(importResult.changedPaths);
      if (importResult.researchNote != null) {
        generatedResearchNoteIds.add(importResult.researchNote!.researchId);
      }
      record.addAll(
        await _writeImportExecution(
          project,
          requestId: requestId,
          record: record,
          importResult: importResult,
          decision: decision,
          changeCollector: changedPaths,
        ),
      );
    }

    if (decision.autoExecuteNetwork) {
      gatewayResult = await _gatewayService.processPendingRequest(
        project,
        requestId: requestId,
        allowGatewayExecution: budget.allowGatewayExecution,
        searchLimit: budget.searchLimit,
        fetchMaxChars: budget.fetchMaxChars,
        permissionDecisionOverride: _gatewayPermissionOverride(
          approvedForExecution,
        ),
      );
      changedPaths.addAll(gatewayResult.changedPaths);
      if (gatewayResult.generatedResearchNote != null) {
        generatedResearchNoteIds.add(gatewayResult.generatedResearchNote!.researchId);
      }
    }

    final effectiveAwaitUserConfirmation =
        !decision.autoExecuteNetwork && decision.awaitUserConfirmation;
    final requestState = _resolveFinalRequestState(
      originalRecord: record,
      importResult: importResult,
      gatewayResult: gatewayResult,
      awaitUserConfirmation: effectiveAwaitUserConfirmation,
    );
    if (gatewayResult == null) {
      await _persistDecisionState(
        project,
        requestId: requestId,
        record: record,
        requestState: requestState,
        decision: decision,
        changedPaths: changedPaths,
        importResult: importResult,
      );
    }

    final blockedReason = _firstNonEmpty(<String>[
      gatewayResult?.blockedReason ?? '',
      importResult?.blockedReason ?? '',
      decision.reason,
    ]);
    final summary = _buildSummary(
      importResult: importResult,
      gatewayResult: gatewayResult,
      awaitUserConfirmation: effectiveAwaitUserConfirmation,
      blockedReason: blockedReason,
      requestState: requestState,
    );
    return ProjectInformationResearchCoordinatorResult(
      requestId: requestId,
      requestState: gatewayResult?.requestState.trim().isNotEmpty == true
          ? gatewayResult!.requestState
          : requestState,
      executedNetwork: gatewayResult?.executed ?? false,
      executedImport: importResult?.saved ?? false,
      awaitUserConfirmation: effectiveAwaitUserConfirmation,
      blocked:
          decision.blocked ||
          (!effectiveAwaitUserConfirmation &&
              !(gatewayResult?.executed ?? false) &&
              !(importResult?.saved ?? false) &&
              blockedReason.isNotEmpty),
      summary: summary,
      changedPaths: changedPaths.toSet().toList(growable: false),
      blockedReason: blockedReason,
      gatewaySummary: gatewayResult?.gatewaySummary ?? const <String, Object?>{},
      importSummary: _importSummary(importResult),
      executionDecision: decision.toJson(),
      generatedResearchNoteIds: generatedResearchNoteIds.toSet().toList(
        growable: false,
      ),
    );
  }

  Future<JsonMap> _readRecord(ProjectDescriptor project, String requestId) {
    return _jsonDocumentService.readJsonMap(
      project.rootPath,
      _pathService.researchRequestPath(requestId),
    );
  }

  InformationCollectionRequest _collectionRequestFromRecord(JsonMap record) {
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    return _collectionPolicyService.normalize(
      InformationCollectionRequest.fromJson(researchRequest),
    );
  }

  InformationPermissionDecision _permissionDecisionFor(
    JsonMap record,
    InformationCollectionRequest request, {
    required bool approvedForExecution,
  }) {
    if (approvedForExecution && request.requiresNetwork) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
        reason: 'pending research request 已由用户或上游动作批准执行。',
        policyRef: 'adapter.pending_research.approved_execution_override',
      );
    }
    final researchRequest = ValueReaders.mapValue(record['research_request']);
    return _permissionPolicyService.decideExternalResearchRequest(
      query: request.query,
      requestedBy: ValueReaders.stringValue(researchRequest['requested_by']),
      userGrantedNetworkAccess: request.userGrantedNetworkAccess,
      metadata: <String, Object?>{
        ...request.metadata,
        'purpose': request.purpose,
        'requested_depth': request.requestedDepth,
        'reference_relationship': request.referenceRelationship,
        'collection_mode': request.collectionMode,
        'information_domain': request.informationDomain,
        'source_requirements': request.sourceRequirements.toJson(),
        'extraction_policy': request.extractionPolicy.toJson(),
      },
    );
  }

  bool _isApprovedForExecution(JsonMap record) {
    final latestAction = ValueReaders.mapValue(
      ValueReaders.mapValue(record['metadata'])['latest_pending_research_action'],
    );
    return ValueReaders.stringValue(latestAction['command']).trim() ==
        ProjectPendingResearchActionCommands.approve;
  }

  HostInformationPermissionContext _effectiveHostContextForDecision(
    HostInformationPermissionContext hostPermissionContext, {
    required bool approvedForExecution,
    required InformationCollectionRequest request,
  }) {
    if (!approvedForExecution || !request.requiresNetwork) {
      return hostPermissionContext;
    }
    return hostPermissionContext.copyWith(
      allowNetwork: true,
      metadata: <String, Object?>{
        ...hostPermissionContext.metadata,
        'approved_pending_research_execution_override': true,
      },
    );
  }

  bool _importAlreadyExecuted(JsonMap record) {
    return ValueReaders.boolValue(record['import_execution_performed']);
  }

  Future<ProjectInformationImportCollectionResult> _executeImport(
    ProjectDescriptor project, {
    required String requestId,
    required JsonMap record,
    required InformationCollectionRequest request,
  }) async {
    final importArgs = _extractImportArgs(request);
    final metadata = <String, Object?>{
      ...request.metadata,
      'request_id': requestId,
      'research_request_record_id': requestId,
    };
    if (importArgs.relativePath.isNotEmpty) {
      return _importCollectionService.collectProjectFile(
        project,
        relativePath: importArgs.relativePath,
        query: request.query,
        purpose: request.purpose,
        requestedDepth: request.requestedDepth,
        informationDomain: request.informationDomain,
        referenceRelationship: request.referenceRelationship,
        sourceRequirements: request.sourceRequirements.toJson(),
        extractionPolicy: request.extractionPolicy.toJson(),
        targetRefs: request.targetRefs,
        metadata: metadata,
      );
    }
    return _importCollectionService.collectText(
      project,
      query: request.query,
      sourceText: importArgs.sourceText,
      sourceKind: importArgs.sourceKind,
      sourceRef: importArgs.sourceRef,
      sourceTitle: importArgs.sourceTitle,
      purpose: request.purpose,
      requestedDepth: request.requestedDepth,
      informationDomain: request.informationDomain,
      referenceRelationship: request.referenceRelationship,
      sourceRequirements: request.sourceRequirements.toJson(),
      extractionPolicy: request.extractionPolicy.toJson(),
      targetRefs: request.targetRefs,
      metadata: metadata,
    );
  }

  _ProjectImportArgs _extractImportArgs(InformationCollectionRequest request) {
    final metadata = request.metadata;
    final unknownFields = ValueReaders.mapValue(
      metadata[OpenJsonContractCodecService.unknownFieldsMetadataKey],
    );
    String readString(String key) {
      final direct = ValueReaders.stringValue(metadata[key]).trim();
      if (direct.isNotEmpty) {
        return direct;
      }
      return ValueReaders.stringValue(unknownFields[key]).trim();
    }

    final relativePath = readString('import_relative_path');
    final sourceText = readString('source_text');
    final sourceRef = readString('source_ref');
    final sourceTitle = readString('source_title');
    final sourceKind = readString('source_kind');
    return _ProjectImportArgs(
      relativePath: relativePath,
      sourceText: sourceText,
      sourceRef: sourceRef,
      sourceTitle: sourceTitle,
      sourceKind: sourceKind.isEmpty ? 'imported_text' : sourceKind,
    );
  }

  Future<JsonMap> _writeImportExecution(
    ProjectDescriptor project, {
    required String requestId,
    required JsonMap record,
    required ProjectInformationImportCollectionResult importResult,
    required InformationResearchExecutionDecision decision,
    required List<String> changeCollector,
  }) async {
    final noteId = importResult.researchNote?.researchId ?? '';
    final requestState = importResult.saved
        ? (decision.autoExecuteNetwork
              ? ProjectPendingResearchRequestStates.pendingGatewayExecution
              : decision.awaitUserConfirmation
              ? ProjectPendingResearchRequestStates.awaitingUserConfirmation
              : ProjectPendingResearchRequestStates.completed)
        : _currentRequestState(record);
    final updatedRecord = <String, Object?>{
      ...record,
      'request_state': requestState,
      'import_execution_performed': importResult.saved,
      if (noteId.isNotEmpty) 'generated_import_research_note_id': noteId,
      'import_summary': _importSummary(importResult),
      'execution_decision': decision.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: _pathService.researchRequestPath(requestId),
      document: updatedRecord,
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    changeCollector
      ..add(_pathService.researchRequestPath(requestId))
      ..add(_pathService.researchRequestsIndexPath());
    return updatedRecord;
  }

  Future<String> _persistDecisionState(
    ProjectDescriptor project, {
    required String requestId,
    required JsonMap record,
    required String requestState,
    required InformationResearchExecutionDecision decision,
    required List<String> changedPaths,
    ProjectInformationImportCollectionResult? importResult,
  }) async {
    final updatedRecord = <String, Object?>{
      ...record,
      'request_state': requestState,
      'execution_decision': decision.toJson(),
      if (importResult != null) 'import_summary': _importSummary(importResult),
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _recordDocumentService.writeIndexedRecord(
      rootPath: project.rootPath,
      recordPath: _pathService.researchRequestPath(requestId),
      document: updatedRecord,
      indexPath: _pathService.researchRequestsIndexPath(),
      fieldName: 'research_request_ids',
      recordId: requestId,
    );
    changedPaths
      ..add(_pathService.researchRequestPath(requestId))
      ..add(_pathService.researchRequestsIndexPath());
    return requestState;
  }

  InformationPermissionDecision? _gatewayPermissionOverride(
    bool approvedForExecution,
  ) {
    if (approvedForExecution) {
      return const InformationPermissionDecision(
        disposition: InformationPermissionDispositions.autoAccept,
        reason: 'pending research request 已被批准执行 gateway。',
        policyRef: 'adapter.pending_research.gateway_approved_override',
      );
    }
    return null;
  }

  String _resolveFinalRequestState({
    required JsonMap originalRecord,
    required ProjectInformationImportCollectionResult? importResult,
    required ProjectResearchGatewayRunResult? gatewayResult,
    required bool awaitUserConfirmation,
  }) {
    if (gatewayResult != null && gatewayResult.requestState.trim().isNotEmpty) {
      return gatewayResult.requestState.trim();
    }
    if (importResult != null && importResult.saved) {
      if (awaitUserConfirmation) {
        return ProjectPendingResearchRequestStates.awaitingUserConfirmation;
      }
      return ProjectPendingResearchRequestStates.completed;
    }
    return _currentRequestState(originalRecord);
  }

  String _currentRequestState(JsonMap record) {
    return ValueReaders.stringValue(record['request_state']).trim();
  }

  JsonMap _importSummary(ProjectInformationImportCollectionResult? result) {
    if (result == null) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'saved': result.saved,
      'summary': result.summary,
      'blocked_reason': result.blockedReason,
      'changed_paths': result.changedPaths,
      if (result.researchNote != null)
        'research_note_id': result.researchNote!.researchId,
    };
  }

  String _buildSummary({
    required ProjectInformationImportCollectionResult? importResult,
    required ProjectResearchGatewayRunResult? gatewayResult,
    required bool awaitUserConfirmation,
    required String blockedReason,
    required String requestState,
  }) {
    final parts = <String>[
      if (importResult != null && importResult.summary.trim().isNotEmpty)
        importResult.summary.trim(),
      if (gatewayResult != null && gatewayResult.summary.trim().isNotEmpty)
        gatewayResult.summary.trim(),
      if (awaitUserConfirmation) '导入部分已处理，联网研究仍等待用户确认。',
      if (partsMissing(importResult, gatewayResult, awaitUserConfirmation) &&
          blockedReason.isNotEmpty)
        blockedReason,
      if (partsMissing(importResult, gatewayResult, awaitUserConfirmation) &&
          blockedReason.isEmpty)
        'research request 当前状态：$requestState',
    ];
    return parts.where((entry) => entry.trim().isNotEmpty).join(' ');
  }

  bool partsMissing(
    ProjectInformationImportCollectionResult? importResult,
    ProjectResearchGatewayRunResult? gatewayResult,
    bool awaitUserConfirmation,
  ) {
    return importResult == null && gatewayResult == null && !awaitUserConfirmation;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }
}

class _ProjectImportArgs {
  const _ProjectImportArgs({
    required this.relativePath,
    required this.sourceText,
    required this.sourceRef,
    required this.sourceTitle,
    required this.sourceKind,
  });

  final String relativePath;
  final String sourceText;
  final String sourceRef;
  final String sourceTitle;
  final String sourceKind;
}
