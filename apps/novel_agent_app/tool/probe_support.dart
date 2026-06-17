import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';

typedef ProbeResultValidator =
    Future<Map<String, Object?>> Function(DraftGenerationResult result);

class ProbeApiConfig {
  const ProbeApiConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
    required this.sourceLabel,
  });

  final String baseUrl;
  final String apiKey;
  final String modelId;
  final String sourceLabel;
}

final class ProbeReportCategories {
  static const String success = 'success';
  static const String technicalFailure = 'technical_failure';
  static const String contractConflict = 'contract_conflict';
  static const String waitingUser = 'waiting_user';
  static const String budgetFailure = 'budget_failure';
  static const String policyDisabled = 'policy_disabled';
  static const String pathFailure = 'path_failure';
  static const String contentQualityFailure = 'content_quality_failure';
  static const String informationQualityFailure = 'information_quality_failure';
}

Future<ProbeApiConfig> loadProbeApiConfig({
  String probeName = 'novel_agent_app_probe',
  bool requireRealProbeOptIn = true,
  bool allowLegacyTestApi = false,
  bool allowTempSettingsFallback = false,
  String? repoRootOverride,
  Directory? startDirectory,
  Map<String, String>? environment,
}) async {
  // 中文注释: app 侧真实探针默认只走 local/env 显式配置入口，旧 test_api/temp 兼容回退必须由调用方明确声明。
  final config = await loadLocalProbeApiConfig(
    probeName: probeName,
    requireRealProbeOptIn: requireRealProbeOptIn,
    allowLegacyTestApi: allowLegacyTestApi,
    allowTempSettingsFallback: allowTempSettingsFallback,
    repoRootOverride: repoRootOverride,
    startDirectory: startDirectory,
    environment: environment,
  );
  return ProbeApiConfig(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    modelId: config.modelId,
    sourceLabel: config.sourceLabel,
  );
}

Directory buildProbeWorkspaceDirectory({
  required String repoRoot,
  required String probeName,
  required String runId,
}) {
  return Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}${probeName}_workspace${Platform.pathSeparator}${safeProbeTimestamp(runId)}',
  );
}

String safeProbeTimestamp(String value) {
  return value.replaceAll(':', '-').replaceAll('.', '-');
}

List<ProjectExpressionConstraintBinding> defaultProbeExpressionBindings({
  String idPrefix = 'probe',
  List<String> targetStageIds = const <String>['draft'],
}) {
  // 中文注释: 真实探针要测去 AI/表达限制时必须显式写入项目 binding；内置 profile 只代表库可用，不代表项目已启用。
  final prefix = idPrefix.trim().isEmpty ? 'probe' : idPrefix.trim();
  return <ProjectExpressionConstraintBinding>[
    ProjectExpressionConstraintBinding(
      id: '${prefix}_de_ai_binding',
      profileId: 'de_ai',
      displayName: 'Probe de-AI',
      defaultForProject: true,
      targetStageIds: targetStageIds,
      weight: 160,
    ),
    ProjectExpressionConstraintBinding(
      id: '${prefix}_low_jargon_binding',
      profileId: 'low_jargon_narration',
      displayName: 'Probe low jargon narration',
      defaultForProject: true,
      targetStageIds: targetStageIds,
      weight: 140,
    ),
  ];
}

JsonMap buildProbeExpressionConstraintSetupReport({
  required List<ExpressionConstraintProfile> loadedProfiles,
  required List<ProjectExpressionConstraintBinding> savedBindings,
}) {
  final availableProfileIds = loadedProfiles
      .map((profile) => profile.id)
      .where((id) => id.trim().isNotEmpty)
      .toList(growable: false);
  final bindingProfileIds = savedBindings
      .map((binding) => binding.profileId)
      .where((id) => id.trim().isNotEmpty)
      .toList(growable: false);
  final missingProfileIds = bindingProfileIds
      .where((profileId) => !availableProfileIds.contains(profileId))
      .toList(growable: false);
  return <String, Object?>{
    'available_profile_ids': availableProfileIds,
    'saved_binding_ids': savedBindings
        .map((binding) => binding.id)
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false),
    'saved_binding_profile_ids': bindingProfileIds,
    'saved_binding_count': savedBindings.length,
    'missing_profile_ids': missingProfileIds,
    'ok': missingProfileIds.isEmpty && savedBindings.isNotEmpty,
  };
}

String mergeProbeSessionContext(String base, String extra) {
  final parts = <String>[];
  if (base.trim().isNotEmpty) {
    parts.add(base.trim());
  }
  if (extra.trim().isNotEmpty) {
    parts.add(extra.trim());
  }
  return parts.join('\n\n');
}

Future<Map<String, Object?>> runDraftProbeCase({
  required GenerateDraftUseCase useCase,
  required ProjectDescriptor project,
  required String modelId,
  required String prompt,
  required ProbeResultValidator validator,
}) async {
  // 中文注释: 真实 probe 只消费 production 合同，不再在探针层补私有 retry/repair 逻辑。
  final phases = <String>[];
  try {
    final result = await useCase.execute(
      project: project,
      userPrompt: prompt,
      modelId: modelId,
      title: 'Mode Probe',
      requestOptions: const <String, Object?>{'stream': true},
      contextSettings: const <String, Object?>{},
      modelProfile: const <String, Object?>{},
      onProgress: (progress) {
        phases.add(progress.phase);
      },
    );
    final validation = await validator(result);
    final ok = ValueReaders.boolValue(validation['ok']);
    return <String, Object?>{
      ...validation,
      'ok': ok,
      'report_category': classifyDraftProbeReportCategory(
        ok: ok,
        result: result,
        validation: validation,
      ),
      'progress_phases': phases,
      'executed_tools': result.executedTools,
      'written_paths': result.writtenPaths,
      'changed_paths': result.changedPaths,
      'waiting_for_user_choice': result.waitingForUserChoice,
      'reasoning_content': result.reasoningContent,
      'tool_error_summary': result.toolErrorSummary,
      'draft_markdown': result.draftMarkdown,
    };
  } catch (error, stackTrace) {
    final summary = '$error';
    return <String, Object?>{
      'ok': false,
      'summary': summary,
      'stack_trace': '$stackTrace',
      'progress_phases': phases,
      'report_category': classifyDraftProbeReportCategory(
        ok: false,
        errorSummary: summary,
      ),
    };
  }
}

String classifyDraftProbeReportCategory({
  required bool ok,
  DraftGenerationResult? result,
  JsonMap validation = const <String, Object?>{},
  String errorSummary = '',
}) {
  final explicitCategory = ValueReaders.stringValue(
    validation['report_category'],
    ValueReaders.stringValue(validation['probe_failure_category']),
  ).trim();
  if (explicitCategory.isNotEmpty) {
    return explicitCategory;
  }
  if (ok) {
    return ProbeReportCategories.success;
  }
  if (_validationSignalsPathFailure(validation)) {
    return ProbeReportCategories.pathFailure;
  }
  if (_validationSignalsPolicyDisabled(validation)) {
    return ProbeReportCategories.policyDisabled;
  }
  if (_validationSignalsInformationFailure(validation)) {
    return ProbeReportCategories.informationQualityFailure;
  }
  if (_validationSignalsContractConflict(validation)) {
    return ProbeReportCategories.contractConflict;
  }
  final stopDiagnosis = _resolveProbeStopDiagnosis(validation);
  final stopCategory = ValueReaders.stringValue(
    stopDiagnosis['category'],
  ).trim();
  final stopCode = ValueReaders.stringValue(stopDiagnosis['code']).trim();
  if (stopCategory == LongTaskStopOutcomeCategories.waitingUser ||
      ValueReaders.boolValue(validation['waiting_for_user_choice']) ||
      (result?.waitingForUserChoice ?? false)) {
    return ProbeReportCategories.waitingUser;
  }
  if (stopCategory == LongTaskStopOutcomeCategories.budgetExhausted) {
    return ProbeReportCategories.budgetFailure;
  }
  if (stopCategory == LongTaskStopOutcomeCategories.technicalFailure ||
      stopCategory == LongTaskStopOutcomeCategories.recoveryExhausted) {
    return ProbeReportCategories.technicalFailure;
  }
  if (_stopDiagnosisSignalsInformationQualityFailure(
    stopCategory: stopCategory,
    stopCode: stopCode,
  )) {
    return ProbeReportCategories.informationQualityFailure;
  }
  if (stopCategory == LongTaskStopOutcomeCategories.deliveryFailure ||
      stopCategory == LongTaskStopOutcomeCategories.constraintGatePause ||
      stopCategory == LongTaskStopOutcomeCategories.manualAttention) {
    return ProbeReportCategories.contentQualityFailure;
  }
  final summary = [
    errorSummary,
    ValueReaders.stringValue(validation['summary']),
    result?.toolErrorSummary ?? '',
  ].join(' ').toLowerCase();
  if (_isBudgetLikeFailureSummary(summary)) {
    return ProbeReportCategories.budgetFailure;
  }
  if (errorSummary.trim().isNotEmpty || (result?.stoppedByToolError ?? false)) {
    return ProbeReportCategories.technicalFailure;
  }
  return ProbeReportCategories.contentQualityFailure;
}

JsonMap buildInformationProbeAssessment({
  String probeLabel = 'information_probe',
  JsonMap activationReport = const <String, Object?>{},
  Iterable<Object?> changedPaths = const <Object?>[],
  Iterable<Object?> toolNames = const <Object?>[],
  JsonMap informationSignal = const <String, Object?>{},
  bool requireInformationActivation = false,
  bool requireInformationArtifacts = false,
  bool explicitNoInformationChange = false,
  bool allowRequiredInformationOmission = true,
}) {
  final activationSourceKinds = _collectInformationActivationSourceKinds(
    activationReport,
  );
  final informationChangedPaths = _collectInformationChangedPaths(changedPaths);
  final informationToolNames = _collectInformationToolNames(toolNames);
  final requiredInformationOmitted = _hasRequiredInformationOmission(
    activationReport,
  );
  final informationSignalCategory = ValueReaders.stringValue(
    informationSignal['category'],
  );
  final failureReasons = <String>[];
  if (requireInformationActivation && activationSourceKinds.isEmpty) {
    failureReasons.add('缺少 information activation sections');
  }
  if (requireInformationArtifacts &&
      !explicitNoInformationChange &&
      informationChangedPaths.isEmpty &&
      informationToolNames.isEmpty) {
    failureReasons.add('缺少 information changed paths 或 information tools');
  }
  if (!allowRequiredInformationOmission && requiredInformationOmitted) {
    failureReasons.add('存在 required information omitted 信号');
  }
  final ok = failureReasons.isEmpty;
  final expectationMode =
      requireInformationActivation ||
          requireInformationArtifacts ||
          !allowRequiredInformationOmission
      ? 'enforced'
      : 'observe_only';
  final summary = ok
      ? expectationMode == 'observe_only'
            ? 'information probe observation collected'
            : 'information probe expectations satisfied'
      : failureReasons.join('；');
  return <String, Object?>{
    'ok': ok,
    'probe_label': probeLabel,
    'expectation_mode': expectationMode,
    'require_information_activation': requireInformationActivation,
    'require_information_artifacts': requireInformationArtifacts,
    'explicit_no_information_change': explicitNoInformationChange,
    'allow_required_information_omission': allowRequiredInformationOmission,
    'has_information_activation': activationSourceKinds.isNotEmpty,
    'activation_source_kinds': activationSourceKinds,
    'information_changed_paths': informationChangedPaths,
    'information_tool_names': informationToolNames,
    'required_information_omitted': requiredInformationOmitted,
    'information_signal_category': informationSignalCategory,
    'report_category': ok
        ? ProbeReportCategories.success
        : ProbeReportCategories.informationQualityFailure,
    'summary': summary,
  };
}

JsonMap buildExpressionConstraintProbeReport({
  JsonMap writingExecutionResult = const <String, Object?>{},
  JsonMap chapterDelivery = const <String, Object?>{},
  JsonMap writingExecutionSignal = const <String, Object?>{},
  String stopReason = '',
  String stopSummary = '',
}) {
  final result = ValueReaders.deepCopyMap(writingExecutionResult);
  final constraints = WritingExecutionConstraintSummary.fromJson(
    ValueReaders.mapValue(result['constraints']),
  );
  final statusProjection = const ExpressionConstraintStatusProjectionService()
      .fromWritingExecutionResult(result);
  final gate = constraints.expressionConstraintGate;
  final pathResolution = _buildProbePathResolutionReport(
    writingExecutionResult: result,
    chapterDelivery: chapterDelivery,
  );
  final reviewSummary = _expressionConstraintReviewSummary(constraints, gate);
  final stopDiagnosis = _resolveProbeWritingExecutionStopDiagnosis(
    writingExecutionResult: result,
    writingExecutionSignal: writingExecutionSignal,
    stopReason: stopReason,
    stopSummary: stopSummary,
    reviewSummary: reviewSummary,
  );
  final present =
      statusProjection.present ||
      pathResolution['present'] == true ||
      stopDiagnosis['present'] == true;
  return <String, Object?>{
    'present': present,
    'status_projection': statusProjection.toJson(),
    'policy_mode': constraints.expressionConstraintPolicyMode,
    'injection_strength': constraints.expressionConstraintInjectionStrength,
    'injection_mode': constraints.expressionConstraintInjectionMode,
    'review_requirement': constraints.expressionConstraintReviewRequirement,
    'review_required': constraints.expressionConstraintReviewRequired,
    'review_provided': constraints.expressionConstraintReviewProvided,
    'evidence_missing': constraints.expressionConstraintEvidenceMissing,
    'violation_recorded':
        constraints.expressionConstraintViolationRecorded || gate.present,
    'risk_signals': ValueReaders.deepCopyList(gate.riskSignals),
    'disposition': gate.recommendedDisposition,
    'gate_severity': gate.severity,
    'gate_reason': gate.reason,
    'gate_summary': gate.summary,
    'applied_reasons': ValueReaders.deepCopyList(
      constraints.expressionConstraintAppliedReasons,
    ),
    'skipped_reasons': ValueReaders.deepCopyList(
      constraints.expressionConstraintSkippedReasons,
    ),
    'path_resolution': pathResolution,
    'stop_reason': stopDiagnosis,
    'stop_diagnosis': stopDiagnosis,
    'summary': reviewSummary,
  };
}

bool _isBudgetLikeFailureSummary(String summary) {
  return summary.contains('context length') ||
      summary.contains('maximum context') ||
      summary.contains('token limit') ||
      summary.contains('max tokens') ||
      summary.contains('budget') ||
      summary.contains('quota') ||
      summary.contains('rate limit') ||
      summary.contains('insufficient_quota') ||
      summary.contains('too many requests') ||
      summary.contains('余额') ||
      summary.contains('额度') ||
      summary.contains('上下文长度');
}

JsonMap _resolveProbeWritingExecutionSignal({
  required JsonMap writingExecutionResult,
  required JsonMap writingExecutionSignal,
  required String stopReason,
  required String stopSummary,
}) {
  final explicit = ValueReaders.mapValue(writingExecutionSignal);
  if (explicit.isNotEmpty) {
    return explicit;
  }
  if (writingExecutionResult.isNotEmpty) {
    try {
      final executionResult = const WritingExecutionResultCodecService()
          .fromJson(writingExecutionResult);
      final signal = const LongTaskWritingExecutionSignalService()
          .signalFromWritingExecutionResult(
            executionResult,
            stopReason: stopReason,
            fallbackNote: stopSummary,
          );
      return signal;
    } catch (_) {
      // 中文注释: probe 报告不能因为历史/半成品 payload 解码失败而中断，失败时回退到显式 stop reason。
    }
  }
  return const <String, Object?>{};
}

JsonMap _resolveProbeWritingExecutionStopDiagnosis({
  required JsonMap writingExecutionResult,
  required JsonMap writingExecutionSignal,
  required String stopReason,
  required String stopSummary,
  required String reviewSummary,
}) {
  final signal = _resolveProbeWritingExecutionSignal(
    writingExecutionResult: writingExecutionResult,
    writingExecutionSignal: writingExecutionSignal,
    stopReason: stopReason,
    stopSummary: stopSummary,
  );
  return _probeStopReasonProjection(
    signal,
    fallbackCode: stopReason,
    fallbackSummary: stopSummary,
    reviewSummary: stopSummary.trim().isNotEmpty ? '' : reviewSummary,
    informationSummary: stopSummary.trim().isNotEmpty
        ? ''
        : ValueReaders.stringValue(
            WritingExecutionInformationSummary.fromJson(
              ValueReaders.mapValue(writingExecutionResult['information']),
            ).summary,
          ),
  );
}

JsonMap _probeStopReasonProjection(
  JsonMap signal, {
  required String fallbackCode,
  required String fallbackSummary,
  String reviewSummary = '',
  String informationSummary = '',
}) {
  final rawCode = ValueReaders.stringValue(signal['legacy_stop_reason']).trim();
  final preferredCode = fallbackCode.trim().isNotEmpty
      ? fallbackCode.trim()
      : rawCode;
  final rawSummary = ValueReaders.stringValue(
    signal['note'],
    ValueReaders.stringValue(signal['summary']),
  ).trim();
  final preferredSummary = fallbackSummary.trim().isNotEmpty
      ? fallbackSummary.trim()
      : rawSummary;
  final stopOutcome = LongTaskStopOutcome.fromJson(
    ValueReaders.mapValue(signal['stop_outcome']),
  );
  final outcomeForProjection = preferredCode.isEmpty
      ? stopOutcome
      : const LongTaskStopOutcome();
  final diagnosis = const LongTaskStopDiagnosisProjectionService().project(
    stopOutcome: outcomeForProjection,
    legacyReason: preferredCode,
    note: preferredSummary,
    reviewSummary: reviewSummary,
    informationSummary: informationSummary,
    metadata: <String, Object?>{'source': 'probe_support'},
  );
  return <String, Object?>{
    'present': diagnosis.present,
    'code': diagnosis.code,
    'category': diagnosis.category,
    'label': diagnosis.label,
    'summary': diagnosis.summary,
    'next_action': ValueReaders.stringValue(signal['next_action']).trim(),
    'run_status': ValueReaders.stringValue(signal['run_status']).trim(),
    'blocks_progress': ValueReaders.boolValue(signal['blocks_progress']),
    'requires_user_action': ValueReaders.boolValue(
      signal['requires_user_action'],
    ),
    'delivery_state': ValueReaders.stringValue(signal['delivery_state']).trim(),
    'information_risk_category': ValueReaders.stringValue(
      signal['information_risk_category'],
    ).trim(),
    'stop_outcome': stopOutcome.toJson(),
  };
}

JsonMap _buildProbePathResolutionReport({
  required JsonMap writingExecutionResult,
  required JsonMap chapterDelivery,
}) {
  final delivery = WritingExecutionDeliverySummary.fromJson(
    ValueReaders.mapValue(writingExecutionResult['delivery']),
  );
  final projectedDelivery = ValueReaders.mapValue(chapterDelivery);
  final projectedSubmission = ValueReaders.mapValue(
    projectedDelivery['submission'],
  );
  final projectedPathResolution = ValueReaders.mapValue(
    projectedDelivery['path_resolution'],
  );
  final deliveryMetadata = delivery.metadata;
  final fallbackPathResolution = ValueReaders.mapValue(
    deliveryMetadata['path_resolution'],
  );
  final requestedPath = ValueReaders.stringValue(
    projectedDelivery['requested_chapter_path'],
    ValueReaders.stringValue(
      projectedPathResolution['requested_path'],
      ValueReaders.stringValue(
        fallbackPathResolution['requested_path'],
        delivery.chapterPath,
      ),
    ),
  ).trim();
  final resolvedPath = ValueReaders.stringValue(
    projectedDelivery['resolved_chapter_path'],
    ValueReaders.stringValue(
      projectedPathResolution['resolved_path'],
      ValueReaders.stringValue(
        fallbackPathResolution['resolved_path'],
        delivery.resolvedChapterPath,
      ),
    ),
  ).trim();
  final chapterPath = ValueReaders.stringValue(
    projectedDelivery['chapter_path'],
    delivery.chapterPath,
  ).trim();
  final title = ValueReaders.stringValue(
    projectedDelivery['title'],
    ValueReaders.stringValue(
      projectedPathResolution['title'],
      ValueReaders.stringValue(
        fallbackPathResolution['title'],
        ValueReaders.stringValue(projectedSubmission['title']),
      ),
    ),
  ).trim();
  final pathChanged =
      ValueReaders.boolValue(projectedPathResolution['path_changed']) ||
      ValueReaders.boolValue(fallbackPathResolution['path_changed']) ||
      (requestedPath.isNotEmpty &&
          resolvedPath.isNotEmpty &&
          requestedPath != resolvedPath);
  final present =
      chapterPath.isNotEmpty ||
      requestedPath.isNotEmpty ||
      resolvedPath.isNotEmpty ||
      title.isNotEmpty ||
      delivery.present ||
      projectedPathResolution.isNotEmpty ||
      fallbackPathResolution.isNotEmpty;
  return <String, Object?>{
    'present': present,
    'chapter_path': chapterPath,
    'requested_path': requestedPath,
    'resolved_path': resolvedPath,
    'title': title,
    'delivery_state': ValueReaders.stringValue(
      projectedDelivery['delivery_state'],
      delivery.state,
    ).trim(),
    'delivery_reason': delivery.reason,
    'blocks_progress': delivery.blocksProgress,
    'path_changed': pathChanged,
    'path_failure':
        delivery.state == ChapterDeliveryStateStatuses.pathMismatchRecoverable,
    'reason': ValueReaders.stringValue(
      projectedPathResolution['reason'],
      ValueReaders.stringValue(fallbackPathResolution['reason']),
    ).trim(),
  };
}

String _expressionConstraintReviewSummary(
  WritingExecutionConstraintSummary constraints,
  ExpressionConstraintGateSignal gate,
) {
  final gateSummary = gate.summary.trim();
  if (gateSummary.isNotEmpty) {
    return gateSummary;
  }
  final projectionSummary = const ExpressionConstraintStatusProjectionService()
      .fromConstraintSummary(constraints)
      .summary
      .trim();
  if (projectionSummary.isNotEmpty) {
    return projectionSummary;
  }
  if (constraints.summary.trim().isNotEmpty) {
    return constraints.summary.trim();
  }
  return '';
}

bool _validationSignalsInformationFailure(JsonMap validation) {
  if (validation.isEmpty) {
    return false;
  }
  final informationProbe = ValueReaders.mapValue(
    validation['information_probe'],
  );
  if (informationProbe.isNotEmpty &&
      !ValueReaders.boolValue(informationProbe['ok'], true)) {
    return true;
  }
  if (!ValueReaders.boolValue(validation['information_quality_ok'], true)) {
    return true;
  }
  if (!ValueReaders.boolValue(validation['information_probe_ok'], true)) {
    return true;
  }
  return false;
}

bool _validationSignalsContractConflict(JsonMap validation) {
  final viewmodel = ValueReaders.mapValue(validation['viewmodel']);
  final workbenchVm = ValueReaders.mapValue(
    viewmodel['workbench_information_viewmodel'],
  );
  final fileCounts = ValueReaders.mapValue(viewmodel['project_file_counts']);
  final hasWorkbenchContent = ValueReaders.boolValue(
    workbenchVm['has_content'],
  );
  final chapterFiles = ValueReaders.intValue(fileCounts['chapter_files']);
  final researchNotes = ValueReaders.intValue(fileCounts['research_notes']);
  final researchRequests = ValueReaders.intValue(
    fileCounts['research_requests'],
  );
  final fileEvidencePresent =
      chapterFiles > 0 || researchNotes > 0 || researchRequests > 0;
  if (fileEvidencePresent && !hasWorkbenchContent) {
    return true;
  }
  if (!fileEvidencePresent && hasWorkbenchContent) {
    return true;
  }
  if (fileEvidencePresent &&
      ValueReaders.mapValue(validation['information_probe']).isNotEmpty &&
      !ValueReaders.boolValue(
        ValueReaders.mapValue(validation['information_probe'])['ok'],
        true,
      )) {
    return true;
  }
  return false;
}

bool _validationSignalsPathFailure(JsonMap validation) {
  final pathResolution = _resolveProbePathResolution(validation);
  if (ValueReaders.boolValue(pathResolution['path_failure'])) {
    return true;
  }
  final deliveryState = ValueReaders.stringValue(
    pathResolution['delivery_state'],
  ).trim();
  final reason = ValueReaders.stringValue(pathResolution['reason']).trim();
  return deliveryState ==
          ChapterDeliveryStateStatuses.pathMismatchRecoverable ||
      reason == 'path_mismatch' ||
      reason == 'chapter_path_mismatch';
}

bool _validationSignalsPolicyDisabled(JsonMap validation) {
  final expressionReport = _resolveExpressionConstraintReport(validation);
  if (expressionReport.isEmpty) {
    return false;
  }
  final statusProjection = ValueReaders.mapValue(
    expressionReport['status_projection'],
  );
  return ValueReaders.boolValue(statusProjection['disabled']) ||
      ValueReaders.stringValue(statusProjection['status']).trim() ==
          'disabled' ||
      ValueReaders.stringValue(expressionReport['policy_mode']).trim() ==
          ExpressionConstraintExecutionPolicyModes.disabled;
}

JsonMap _resolveProbeStopDiagnosis(JsonMap validation) {
  final direct = LongTaskStopDiagnosisProjection.fromJson(
    ValueReaders.mapValue(validation['stop_diagnosis']),
  );
  if (direct.present) {
    return direct.toJson();
  }
  final runCenter = ValueReaders.mapValue(validation['run_center_contract']);
  final runCenterDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
    ValueReaders.mapValue(runCenter['stop_diagnosis']),
  );
  if (runCenterDiagnosis.present) {
    return runCenterDiagnosis.toJson();
  }
  final longTaskRunCenter = ValueReaders.mapValue(
    validation['long_task_run_center_contract'],
  );
  final longTaskRunCenterDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
    ValueReaders.mapValue(longTaskRunCenter['stop_diagnosis']),
  );
  if (longTaskRunCenterDiagnosis.present) {
    return longTaskRunCenterDiagnosis.toJson();
  }
  final expressionReport = _resolveExpressionConstraintReport(validation);
  final expressionDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
    ValueReaders.mapValue(expressionReport['stop_diagnosis']),
  );
  if (expressionDiagnosis.present) {
    return expressionDiagnosis.toJson();
  }
  final legacyExpressionDiagnosis = LongTaskStopDiagnosisProjection.fromJson(
    ValueReaders.mapValue(expressionReport['stop_reason']),
  );
  if (legacyExpressionDiagnosis.present) {
    return legacyExpressionDiagnosis.toJson();
  }
  return const <String, Object?>{};
}

JsonMap _resolveExpressionConstraintReport(JsonMap validation) {
  final report = ValueReaders.mapValue(
    validation['expression_constraint_report'],
  );
  if (report.isNotEmpty) {
    return report;
  }
  return ValueReaders.mapValue(validation['probe_execution_report']);
}

JsonMap _resolveProbePathResolution(JsonMap validation) {
  final expressionReport = _resolveExpressionConstraintReport(validation);
  final pathResolution = ValueReaders.mapValue(
    expressionReport['path_resolution'],
  );
  if (pathResolution.isNotEmpty) {
    return pathResolution;
  }
  return ValueReaders.mapValue(validation['path_resolution']);
}

bool _stopDiagnosisSignalsInformationQualityFailure({
  required String stopCategory,
  required String stopCode,
}) {
  if (stopCategory.isEmpty || stopCode.isEmpty) {
    return false;
  }
  return stopCode.startsWith('information_') &&
      stopCategory != LongTaskStopOutcomeCategories.technicalFailure &&
      stopCategory != LongTaskStopOutcomeCategories.deliveryFailure;
}

List<String> _collectInformationActivationSourceKinds(
  JsonMap activationReport,
) {
  final sourceKinds = <String>{};
  final metadata = ValueReaders.mapValue(activationReport['metadata']);
  final candidateSections = <Map<String, Object?>>[
    ...ValueReaders.mapList(activationReport['items']),
    ...ValueReaders.mapList(metadata['selected_context_sections']),
    ...ValueReaders.mapList(metadata['omitted_context_sections']),
    ...ValueReaders.mapList(metadata['truncated_context_sections']),
  ];
  for (final section in candidateSections) {
    final metadata = ValueReaders.mapValue(section['metadata']);
    final sourceKind = ValueReaders.stringValue(
      section['source_kind'],
      ValueReaders.stringValue(
        section['source'],
        ValueReaders.stringValue(metadata['source_kind']),
      ),
    ).trim();
    if (_informationActivationSourceKinds.contains(sourceKind)) {
      sourceKinds.add(sourceKind);
    }
  }
  return sourceKinds.toList(growable: false);
}

List<String> _collectInformationChangedPaths(Iterable<Object?> changedPaths) {
  final result = <String>{};
  for (final entry in changedPaths) {
    final path = entry?.toString().trim() ?? '';
    if (path.isEmpty) {
      continue;
    }
    if (_isInformationChangedPath(path)) {
      result.add(path);
    }
  }
  return result.toList(growable: false);
}

List<String> _collectInformationToolNames(Iterable<Object?> toolNames) {
  final result = <String>{};
  for (final entry in toolNames) {
    final toolName = entry?.toString().trim() ?? '';
    if (_informationToolNames.contains(toolName)) {
      result.add(toolName);
    }
  }
  return result.toList(growable: false);
}

bool _hasRequiredInformationOmission(JsonMap activationReport) {
  final metadata = ValueReaders.mapValue(activationReport['metadata']);
  final candidateSections = <Map<String, Object?>>[
    ...ValueReaders.mapList(activationReport['items']),
    ...ValueReaders.mapList(metadata['omitted_context_sections']),
  ];
  for (final section in candidateSections) {
    final sectionMetadata = ValueReaders.mapValue(section['metadata']);
    final omitted = ValueReaders.boolValue(section['omitted']);
    final required = ValueReaders.boolValue(
      section['required'],
      ValueReaders.boolValue(sectionMetadata['required']),
    );
    final sourceKind = ValueReaders.stringValue(
      section['source_kind'],
      ValueReaders.stringValue(
        section['source'],
        ValueReaders.stringValue(sectionMetadata['source_kind']),
      ),
    ).trim();
    if (omitted &&
        required &&
        _informationActivationSourceKinds.contains(sourceKind)) {
      return true;
    }
  }
  return false;
}

bool _isInformationChangedPath(String path) {
  return path.startsWith('.novel_agent/information/') ||
      path == 'knowledge/项目知识摘要.md' ||
      path == 'knowledge/设计元素摘要.md' ||
      path == 'research/资料研究摘要.md' ||
      path == 'references/引用作品边界.md';
}

const Set<String> _informationActivationSourceKinds = <String>{
  'project_knowledge_card',
  'project_design_element',
  'project_research_note',
  'project_reference_work',
};

const Set<String> _informationToolNames = <String>{
  NarrativeDomainToolNames.requestExternalResearch,
  NarrativeDomainToolNames.submitResearchNote,
  NarrativeDomainToolNames.proposeKnowledgeCard,
  NarrativeDomainToolNames.proposeDesignElement,
  NarrativeDomainToolNames.linkInformationEvidence,
  NarrativeDomainToolNames.proposeReferenceWork,
};
