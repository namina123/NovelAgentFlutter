import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../tools/project_tool_path_policy.dart';

class FileReferenceExtractionStagingWorkspace
    implements ReferenceExtractionStagingWorkspace {
  FileReferenceExtractionStagingWorkspace({
    required String stagingRootPath,
    FileReferenceExtractionStagingRunCodecService? codecService,
    ProjectToolPathPolicy? toolPathPolicy,
  }) : _stagingRootPath = stagingRootPath,
       _codecService =
           codecService ?? FileReferenceExtractionStagingRunCodecService(),
       _toolPathPolicy = toolPathPolicy ?? ProjectToolPathPolicy();

  final String _stagingRootPath;
  final FileReferenceExtractionStagingRunCodecService _codecService;
  final ProjectToolPathPolicy _toolPathPolicy;
  final Map<String, ReferenceExtractionStagingRun> _memoryCache =
      <String, ReferenceExtractionStagingRun>{};

  @override
  Future<ReferenceExtractionStagingRun?> readRun(String runId) async {
    final cached = _memoryCache[runId];
    if (cached != null) {
      return cached;
    }
    final file = File(_runFilePath(runId));
    if (!await file.exists()) {
      return null;
    }
    final document = ValueReaders.mapValue(
      jsonDecode(await file.readAsString()),
    );
    final decoded = _codecService.decode(document);
    _memoryCache[runId] = decoded;
    return decoded;
  }

  @override
  Future<void> upsertRun(ReferenceExtractionStagingRun run) async {
    _memoryCache[run.runId] = run;
    final file = File(_runFilePath(run.runId));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_codecService.encode(run)),
    );
  }

  String _runFilePath(String runId) {
    final safeRunId = _toolPathPolicy.safeFileName(
      runId,
      fallback: 'reference_extraction_run',
      maxLength: 96,
    );
    return <String>[
      _stagingRootPath,
      '$safeRunId.json',
    ].join(Platform.pathSeparator);
  }
}

class FileReferenceExtractionStagingRunCodecService {
  FileReferenceExtractionStagingRunCodecService({
    AgentProfileMapperService? agentProfileMapperService,
    ProjectAgentGroupSelectionNormalizerService? selectionNormalizerService,
  }) : _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService(),
       _selectionNormalizerService =
           selectionNormalizerService ??
           const ProjectAgentGroupSelectionNormalizerService();

  final AgentProfileMapperService _agentProfileMapperService;
  final ProjectAgentGroupSelectionNormalizerService _selectionNormalizerService;

  JsonMap encode(ReferenceExtractionStagingRun run) {
    return <String, Object?>{
      'run_id': run.runId,
      'package_id': run.packageId,
      'package_version_id': run.packageVersionId,
      'source_document_title': run.sourceDocumentTitle,
      'source_language': run.sourceLanguage,
      'target_language': run.targetLanguage,
      'group_resolution': _encodeGroupResolution(run.groupResolution),
      'seed_snapshot': run.seedSnapshot.toJson(),
      'batch_plan': run.batchPlan?.toJson() ?? <String, Object?>{},
      'batch_progress': run.batchProgress?.toJson() ?? <String, Object?>{},
      'execution_discipline': run.executionDiscipline.toJson(),
      'run_status': run.runStatus,
      'delivery_decision': run.deliveryDecision.toJson(),
      'continuation_contexts': run.continuationContexts
          .map((item) => item.toJson())
          .toList(growable: false),
      'proposals': run.proposals.map(_encodeProposal).toList(growable: false),
      'omission_reports': run.omissionReports
          .map((item) => item.toJson())
          .toList(growable: false),
      'continuation_requests': run.continuationRequests
          .map((item) => item.toJson())
          .toList(growable: false),
      'coverage_ledger': run.coverageLedger?.toJson() ?? <String, Object?>{},
      'output_compression_risk': run.outputCompressionRisk.toJson(),
      'output_completion_status': run.outputCompletionStatus,
      'review_outcome': run.reviewOutcome == null
          ? <String, Object?>{}
          : _encodeReviewOutcome(run.reviewOutcome!),
      'finalized_snapshot':
          run.finalizedSnapshot?.toJson() ?? <String, Object?>{},
      'phase_records': run.phaseRecords
          .map(
            (record) => <String, Object?>{
              'phase_id': record.phaseId,
              'detail': record.detail,
            },
          )
          .toList(growable: false),
    };
  }

  ReferenceExtractionStagingRun decode(JsonMap json) {
    final groupResolution = _decodeGroupResolution(
      ValueReaders.mapValue(json['group_resolution']),
    );
    final phaseRecords = ValueReaders.mapList(json['phase_records'])
        .map(
          (item) => ReferenceExtractionPhaseRecord(
            phaseId: ValueReaders.stringValue(item['phase_id']).trim(),
            detail: ValueReaders.stringValue(item['detail']).trim(),
          ),
        )
        .toList(growable: false);
    final proposals = ValueReaders.mapList(
      json['proposals'],
    ).map(_decodeProposal).toList(growable: false);
    final batchPlanJson = ValueReaders.mapValue(json['batch_plan']);
    final batchProgressJson = ValueReaders.mapValue(json['batch_progress']);
    final coverageLedgerJson = ValueReaders.mapValue(json['coverage_ledger']);
    final reviewOutcomeJson = ValueReaders.mapValue(json['review_outcome']);
    final finalizedSnapshotJson = ValueReaders.mapValue(
      json['finalized_snapshot'],
    );
    return ReferenceExtractionStagingRun(
      runId: ValueReaders.stringValue(json['run_id']).trim(),
      packageId: ValueReaders.stringValue(json['package_id']).trim(),
      packageVersionId: ValueReaders.stringValue(
        json['package_version_id'],
      ).trim(),
      sourceDocumentTitle: ValueReaders.stringValue(
        json['source_document_title'],
      ).trim(),
      sourceLanguage: ValueReaders.stringValue(json['source_language']).trim(),
      targetLanguage: ValueReaders.stringValue(json['target_language']).trim(),
      groupResolution: groupResolution,
      seedSnapshot: _decodeSnapshot(
        ValueReaders.mapValue(json['seed_snapshot']),
      ),
      batchPlan: batchPlanJson.isEmpty
          ? null
          : ReferenceSourceBatchPlan.fromJson(batchPlanJson),
      batchProgress: batchProgressJson.isEmpty
          ? null
          : ReferenceSourceBatchProgress.fromJson(batchProgressJson),
      executionDiscipline: ReferenceExtractionExecutionDiscipline.fromJson(
        ValueReaders.mapValue(json['execution_discipline']),
      ),
      runStatus: ValueReaders.stringValue(
        json['run_status'],
        ReferenceExtractionRunStatuses.active,
      ).trim(),
      deliveryDecision: ReferenceExtractionDeliveryDecision.fromJson(
        ValueReaders.mapValue(json['delivery_decision']),
      ),
      continuationContexts: ValueReaders.mapList(json['continuation_contexts'])
          .map(ReferenceExtractionContinuationContext.fromJson)
          .toList(growable: false),
      proposals: proposals,
      omissionReports: ValueReaders.mapList(
        json['omission_reports'],
      ).map(OmissionReport.fromJson).toList(growable: false),
      continuationRequests: ValueReaders.mapList(
        json['continuation_requests'],
      ).map(ContinuationRequest.fromJson).toList(growable: false),
      coverageLedger: coverageLedgerJson.isEmpty
          ? null
          : OutputCoverageLedger.fromJson(coverageLedgerJson),
      outputCompressionRisk: OutputCompressionRisk.fromJson(
        ValueReaders.mapValue(json['output_compression_risk']),
      ),
      outputCompletionStatus: ValueReaders.stringValue(
        json['output_completion_status'],
        OutputCompletionStatuses.completed,
      ).trim(),
      reviewOutcome: reviewOutcomeJson.isEmpty
          ? null
          : _decodeReviewOutcome(reviewOutcomeJson),
      finalizedSnapshot: finalizedSnapshotJson.isEmpty
          ? null
          : _decodeSnapshot(finalizedSnapshotJson),
      phaseRecords: phaseRecords,
    );
  }

  JsonMap _encodeGroupResolution(
    ReferenceExtractionGroupResolution resolution,
  ) {
    return <String, Object?>{
      'selected_group': _encodeGroup(resolution.selectedGroup),
      'resolution_kind': resolution.resolutionKind,
      'execution_profile': <String, Object?>{
        'task_family_id': resolution.executionProfile.taskFamilyId,
        'execution_mode': resolution.executionProfile.executionMode,
        'instruction_profile_id':
            resolution.executionProfile.instructionProfileId,
        'tool_permission_profile_id':
            resolution.executionProfile.toolPermissionProfileId,
        'requires_reviewer': resolution.executionProfile.requiresReviewer,
        'strategy_profile': resolution.executionProfile.strategyProfile
            .toJson(),
        'metadata': ValueReaders.deepCopyMap(
          resolution.executionProfile.metadata,
        ),
      },
      'selection': _selectionNormalizerService.toDocument(resolution.selection),
    };
  }

  ReferenceExtractionGroupResolution _decodeGroupResolution(JsonMap json) {
    final executionProfile = ValueReaders.mapValue(json['execution_profile']);
    return ReferenceExtractionGroupResolution(
      selectedGroup: _decodeGroup(
        ValueReaders.mapValue(json['selected_group']),
      ),
      resolutionKind: ValueReaders.stringValue(json['resolution_kind']).trim(),
      executionProfile: ReferenceExtractionExecutionProfile(
        taskFamilyId: ValueReaders.stringValue(
          executionProfile['task_family_id'],
        ).trim(),
        executionMode: ValueReaders.stringValue(
          executionProfile['execution_mode'],
        ).trim(),
        instructionProfileId: ValueReaders.stringValue(
          executionProfile['instruction_profile_id'],
        ).trim(),
        toolPermissionProfileId: ValueReaders.stringValue(
          executionProfile['tool_permission_profile_id'],
        ).trim(),
        requiresReviewer: ValueReaders.boolValue(
          executionProfile['requires_reviewer'],
          true,
        ),
        strategyProfile: ReferenceExtractionStrategyProfile.fromJson(
          ValueReaders.mapValue(executionProfile['strategy_profile']),
        ),
        metadata: ValueReaders.deepCopyMap(
          ValueReaders.mapValue(executionProfile['metadata']),
        ),
      ),
      selection: _selectionNormalizerService.normalize(
        ValueReaders.mapValue(json['selection']),
      ),
    );
  }

  JsonMap _encodeGroup(ResolvedAgentGroupProfile group) {
    return <String, Object?>{
      'id': group.id,
      'name': group.name,
      'description': group.description,
      'orchestration': group.orchestration,
      'source': group.source,
      'enabled': group.enabled,
      'metadata': ValueReaders.deepCopyMap(group.metadata),
      'members': group.members
          .map(
            (member) => <String, Object?>{
              'profile': _agentProfileMapperService.toDocument(member.profile),
              'is_primary': member.isPrimary,
              'is_required': member.isRequired,
            },
          )
          .toList(growable: false),
    };
  }

  ResolvedAgentGroupProfile _decodeGroup(JsonMap json) {
    final members = ValueReaders.mapList(json['members'])
        .map(
          (memberJson) => ResolvedAgentGroupMemberProfile(
            profile: _agentProfileMapperService.fromDocument(
              ValueReaders.mapValue(memberJson['profile']),
            ),
            isPrimary: ValueReaders.boolValue(memberJson['is_primary']),
            isRequired: ValueReaders.boolValue(memberJson['is_required']),
          ),
        )
        .toList(growable: false);
    return ResolvedAgentGroupProfile(
      id: ValueReaders.stringValue(json['id']).trim(),
      name: ValueReaders.stringValue(json['name']).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      orchestration: ValueReaders.stringValue(json['orchestration']).trim(),
      members: members,
      source: ValueReaders.stringValue(json['source']).trim(),
      enabled: ValueReaders.boolValue(json['enabled'], true),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap _encodeProposal(ReferenceExtractionProposal proposal) {
    return <String, Object?>{
      'proposal_id': proposal.proposalId,
      'entry_id': proposal.entryId,
      'entry_namespace': proposal.entryNamespace,
      'entry_kind': proposal.entryKind,
      'title': proposal.title,
      'summary': proposal.summary,
      'payload': ValueReaders.deepCopyMap(proposal.payload),
      'source_refs': proposal.sourceRefs
          .map((item) => item.toJson())
          .toList(growable: false),
      'evidence_refs': proposal.evidenceRefs
          .map((item) => item.toJson())
          .toList(growable: false),
      'tags': ValueReaders.deepCopyList(proposal.tags.cast<Object?>()),
      'coverage_dimension_ids': ValueReaders.deepCopyList(
        proposal.coverageDimensionIds.cast<Object?>(),
      ),
      'confidence': proposal.confidence,
      'metadata': ValueReaders.deepCopyMap(proposal.metadata),
    };
  }

  ReferenceExtractionProposal _decodeProposal(JsonMap json) {
    return ReferenceExtractionProposal(
      proposalId: ValueReaders.stringValue(json['proposal_id']).trim(),
      entryId: ValueReaders.stringValue(json['entry_id']).trim(),
      entryNamespace: ValueReaders.stringValue(json['entry_namespace']).trim(),
      entryKind: ValueReaders.stringValue(json['entry_kind']).trim(),
      title: ValueReaders.stringValue(json['title']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      payload: ValueReaders.deepCopyMap(ValueReaders.mapValue(json['payload'])),
      sourceRefs: ValueReaders.mapList(
        json['source_refs'],
      ).map(InformationSourceRef.fromJson).toList(growable: false),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      tags: ValueReaders.stringList(json['tags']),
      coverageDimensionIds: ValueReaders.stringList(
        json['coverage_dimension_ids'],
      ),
      confidence: ValueReaders.doubleValue(json['confidence']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap _encodeReviewOutcome(ReferenceExtractionReviewOutcome outcome) {
    return <String, Object?>{
      'decisions': outcome.decisions
          .map(
            (decision) => <String, Object?>{
              'proposal_id': decision.proposalId,
              'disposition': decision.disposition,
              'rationale': decision.rationale,
            },
          )
          .toList(growable: false),
      'omission_reports': outcome.omissionReports
          .map((item) => item.toJson())
          .toList(growable: false),
      'continuation_requests': outcome.continuationRequests
          .map((item) => item.toJson())
          .toList(growable: false),
      'coverage_ledger':
          outcome.coverageLedger?.toJson() ?? <String, Object?>{},
      'output_compression_risk': outcome.outputCompressionRisk.toJson(),
      'output_completion_status': outcome.outputCompletionStatus,
    };
  }

  ReferenceExtractionReviewOutcome _decodeReviewOutcome(JsonMap json) {
    return ReferenceExtractionReviewOutcome(
      decisions: ValueReaders.mapList(json['decisions'])
          .map(
            (item) => ReferenceExtractionReviewDecision(
              proposalId: ValueReaders.stringValue(item['proposal_id']).trim(),
              disposition: ValueReaders.stringValue(item['disposition']).trim(),
              rationale: ValueReaders.stringValue(item['rationale']).trim(),
            ),
          )
          .toList(growable: false),
      omissionReports: ValueReaders.mapList(
        json['omission_reports'],
      ).map(OmissionReport.fromJson).toList(growable: false),
      continuationRequests: ValueReaders.mapList(
        json['continuation_requests'],
      ).map(ContinuationRequest.fromJson).toList(growable: false),
      coverageLedger: ValueReaders.mapValue(json['coverage_ledger']).isEmpty
          ? null
          : OutputCoverageLedger.fromJson(
              ValueReaders.mapValue(json['coverage_ledger']),
            ),
      outputCompressionRisk: OutputCompressionRisk.fromJson(
        ValueReaders.mapValue(json['output_compression_risk']),
      ),
      outputCompletionStatus: ValueReaders.stringValue(
        json['output_completion_status'],
        OutputCompletionStatuses.completed,
      ).trim(),
    );
  }

  ReferencePackageSnapshot _decodeSnapshot(JsonMap json) {
    return ReferencePackageSnapshot(
      packageRecord: ReferencePackageRecord.fromJson(
        ValueReaders.mapValue(json['package_record']),
      ),
      packageVersionRecord: ReferencePackageVersionRecord.fromJson(
        ValueReaders.mapValue(json['package_version_record']),
      ),
      entries: ValueReaders.mapList(
        json['entries'],
      ).map(ReferenceEntryRecord.fromJson).toList(growable: false),
      dependencies: ValueReaders.mapList(
        json['dependencies'],
      ).map(ReferenceDependencyRecord.fromJson).toList(growable: false),
      promotionRecords: ValueReaders.mapList(
        json['promotion_records'],
      ).map(ReferencePromotionRecord.fromJson).toList(growable: false),
    );
  }
}
