import '../continuity/narrative_state/constraint_binding_applies_to.dart';
import 'expression_constraint_review_projection.dart';
import '../workflow/writing_execution_constraint_summary.dart';
import 'expression_constraint_execution_policy.dart';
import 'expression_constraint_execution_policy_resolution.dart';
import 'expression_constraint_execution_policy_resolution_context.dart';

class ExpressionConstraintExecutionPolicyResolverService {
  const ExpressionConstraintExecutionPolicyResolverService();

  ExpressionConstraintExecutionPolicyResolution resolve(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: resolver 只做“当前这一轮是否应用、应用多强、为何跳过”的纯决策，不渲染 prompt 也不读正文。
    final normalized = _normalizeContext(context);
    final requestedMode = _resolvedRequestedMode(normalized.overrideMode);
    final basePolicy = _basePolicyForMode(requestedMode);
    final whySkipped = <String>[];
    final whyApplied = <String>[];

    if (requestedMode == ExpressionConstraintExecutionPolicyModes.disabled) {
      whySkipped.add('policy_disabled');
      return _buildResolution(
        policy: basePolicy,
        applied: false,
        runtimeEscalated: false,
        technicalTurnExcluded: false,
        whyApplied: whyApplied,
        whySkipped: whySkipped,
        context: normalized,
      );
    }

    if (!normalized.hasBindings) {
      whySkipped.add('no_expression_constraint_bindings');
      return _buildResolution(
        policy: basePolicy,
        applied: false,
        runtimeEscalated: false,
        technicalTurnExcluded: false,
        whyApplied: whyApplied,
        whySkipped: whySkipped,
        context: normalized,
      );
    }

    final pathResolutionTurn = _isPathResolutionTurn(normalized);
    if (pathResolutionTurn) {
      whySkipped.add('path_resolution_turn');
    }
    final toolProtocolTurn = _isToolProtocolTurn(normalized);
    if (toolProtocolTurn) {
      whySkipped.add('tool_protocol_turn');
    }
    final researchExecutionTurn = _isResearchExecutionTurn(normalized);
    if (researchExecutionTurn) {
      whySkipped.add('research_execution_turn');
    }
    final orchestrationTurn = _isWorkflowOrchestrationTurn(normalized);
    if (orchestrationTurn) {
      whySkipped.add('workflow_orchestration_turn');
    }
    if (whySkipped.isNotEmpty) {
      return _buildResolution(
        policy: basePolicy,
        applied: false,
        runtimeEscalated: false,
        technicalTurnExcluded: true,
        whyApplied: whyApplied,
        whySkipped: whySkipped,
        context: normalized,
      );
    }

    var resolvedPolicy = _policyForTurn(basePolicy, normalized);
    var runtimeEscalated = false;
    if (resolvedPolicy.isAdaptive &&
        resolvedPolicy.allowRuntimeEscalation &&
        _supportsRuntimeEscalation(normalized) &&
        _shouldEscalateFromRecentSummaries(normalized.recentSummaries)) {
      resolvedPolicy = resolvedPolicy.copyWith(
        injectionStrength: ExpressionConstraintInjectionStrengths.full,
        reviewRequirement:
            ExpressionConstraintReviewRequirements.alwaysForWriting,
        violationDisposition: ExpressionConstraintViolationDispositions.repair,
      );
      runtimeEscalated = true;
      whyApplied.add('recent_violation_escalation');
    }

    whyApplied.add('has_expression_constraint_bindings');
    whyApplied.add(_turnReason(normalized));
    whyApplied.add('policy_mode_${resolvedPolicy.mode}');
    return _buildResolution(
      policy: resolvedPolicy,
      applied: true,
      runtimeEscalated: runtimeEscalated,
      technicalTurnExcluded: false,
      whyApplied: whyApplied,
      whySkipped: whySkipped,
      context: normalized,
    );
  }

  ExpressionConstraintExecutionPolicyResolutionContext _normalizeContext(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 上下文标准化只做大小写和缺省值清洗，避免把调用点噪音带进策略判断。
    return ExpressionConstraintExecutionPolicyResolutionContext(
      overrideMode: context.overrideMode.trim().toLowerCase(),
      intent: context.intent.trim().toLowerCase().isEmpty
          ? 'draft'
          : context.intent.trim().toLowerCase(),
      taskType: context.taskType.trim().toLowerCase(),
      phase: context.phase.trim().toLowerCase(),
      appliesTo: context.appliesTo.trim().toLowerCase().isEmpty
          ? ConstraintBindingAppliesTo.writing
          : context.appliesTo.trim().toLowerCase(),
      projectTypeId: context.projectTypeId.trim(),
      agentId: context.agentId.trim(),
      modeId: context.modeId.trim(),
      stageId: context.stageId.trim().toLowerCase().isEmpty
          ? 'draft'
          : context.stageId.trim().toLowerCase(),
      hasBindings: context.hasBindings,
      recentSummaries: List<WritingExecutionConstraintSummary>.unmodifiable(
        context.recentSummaries,
      ),
    );
  }

  String _resolvedRequestedMode(String overrideMode) {
    // 中文注释: override 只接受已知三档，未知值回落到 adaptive，避免 resolver 因脏输入崩掉。
    return switch (overrideMode) {
      ExpressionConstraintExecutionPolicyModes.disabled =>
        ExpressionConstraintExecutionPolicyModes.disabled,
      ExpressionConstraintExecutionPolicyModes.force =>
        ExpressionConstraintExecutionPolicyModes.force,
      _ => ExpressionConstraintExecutionPolicyModes.adaptive,
    };
  }

  ExpressionConstraintExecutionPolicy _basePolicyForMode(String mode) {
    // 中文注释: 这里把用户选择的三档映射成基础 policy 模板，后续按当前轮次做轻量重排。
    return switch (mode) {
      ExpressionConstraintExecutionPolicyModes.disabled =>
        const ExpressionConstraintExecutionPolicy.disabled(),
      ExpressionConstraintExecutionPolicyModes.force =>
        const ExpressionConstraintExecutionPolicy.force(),
      _ => ExpressionConstraintExecutionPolicy.defaultAdaptive,
    };
  }

  ExpressionConstraintExecutionPolicy _policyForTurn(
    ExpressionConstraintExecutionPolicy basePolicy,
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: turn 级 policy 只调整用户可见文本的强度，不在这里做 path/tool/research 等排除判定。
    if (basePolicy.isForce) {
      return basePolicy.copyWith(
        injectionStrength: _forceInjectionStrength(context),
        reviewRequirement: _forceReviewRequirement(context),
        violationDisposition: _forceViolationDisposition(context),
      );
    }
    return basePolicy.copyWith(
      injectionStrength: _adaptiveInjectionStrength(context),
      reviewRequirement: _adaptiveReviewRequirement(context),
      violationDisposition: _adaptiveViolationDisposition(context),
    );
  }

  String _adaptiveInjectionStrength(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: adaptive 下正文和修订优先 sections，规划、审稿和总结优先 brief。
    if (_isPrimaryWritingTurn(context)) {
      return ExpressionConstraintInjectionStrengths.sections;
    }
    if (_isUserVisibleTextTurn(context)) {
      return ExpressionConstraintInjectionStrengths.brief;
    }
    return ExpressionConstraintInjectionStrengths.none;
  }

  String _adaptiveReviewRequirement(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: adaptive 对正文/修订及用户可见分析文本仍保留 review 要求，但 review 任务本身不再二次强挂表达限制复核 gate。
    if (context.appliesTo == ConstraintBindingAppliesTo.review ||
        context.intent == 'review' ||
        context.taskType == 'review') {
      return ExpressionConstraintReviewRequirements.none;
    }
    if (_isUserVisibleTextTurn(context)) {
      return ExpressionConstraintReviewRequirements.whenApplied;
    }
    return ExpressionConstraintReviewRequirements.none;
  }

  String _adaptiveViolationDisposition(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: adaptive 默认优先提醒或下章回调，正文/修订也先不直接升级成 repair。
    if (_isPrimaryWritingTurn(context)) {
      return ExpressionConstraintViolationDispositions.adjustNext;
    }
    return ExpressionConstraintViolationDispositions.remind;
  }

  String _forceInjectionStrength(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: force 对用户可见文本统一强执行，但仍由外层技术轮次排除保护协议面。
    if (_isUserVisibleTextTurn(context)) {
      return ExpressionConstraintInjectionStrengths.full;
    }
    return ExpressionConstraintInjectionStrengths.none;
  }

  String _forceReviewRequirement(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: force 的核心是强注入，不把正文轮天然升级成“必须另有独立审稿证据”；否则真实长任务会因缺 review 旁证反复停住。
    if (_isPrimaryWritingTurn(context)) {
      return ExpressionConstraintReviewRequirements.none;
    }
    if (_isUserVisibleTextTurn(context)) {
      return ExpressionConstraintReviewRequirements.alwaysForWriting;
    }
    return ExpressionConstraintReviewRequirements.none;
  }

  String _forceViolationDisposition(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: force 下的偏离默认按 repair 处理，保证它和 adaptive 的处置差异足够明确。
    if (_isUserVisibleTextTurn(context)) {
      return ExpressionConstraintViolationDispositions.repair;
    }
    return ExpressionConstraintViolationDispositions.remind;
  }

  bool _isToolProtocolTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 工具协议轮次必须排除，避免去 AI 规则污染 tool schema、参数和协议文案。
    return context.intent == 'tool' ||
        context.intent == 'chat' ||
        context.intent == 'user_options' ||
        context.taskType == 'tool' ||
        context.taskType == 'tool_only' ||
        context.phase == 'tool_protocol' ||
        context.phase == 'tool_round' ||
        context.stageId == 'tool_protocol';
  }

  bool _isResearchExecutionTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: research execution 轮次属于信息纪律域，表达限制不应混进去抢研究协议。
    return context.intent == 'research' ||
        context.taskType == 'research' ||
        context.phase == 'research_execution' ||
        context.stageId == 'research_execution';
  }

  bool _isPathResolutionTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: path resolution 轮次只处理路径合同，必须和表达风格约束彻底分离。
    return context.taskType == 'path_resolution' ||
        context.phase == 'path_resolution' ||
        context.stageId == 'path_resolution';
  }

  bool _isWorkflowOrchestrationTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 长任务规划、检查点和状态维护是调度合同，不是正文/成品文本交付，force 也不能把它们升级成表达复核 gate。
    final taskType = context.taskType;
    if (taskType == 'checkpoint') {
      return true;
    }
    if (context.intent == 'workflow_task' &&
        (taskType == 'planning' || taskType == 'world_update')) {
      return true;
    }
    if ((taskType == 'planning' || taskType == 'world_update') &&
        (context.stageId == 'planning' ||
            context.stageId == 'checkpoint' ||
            context.stageId == 'world_update')) {
      return true;
    }
    return context.phase == 'workflow_planning' ||
        context.phase == 'task_planning' ||
        context.phase == 'queue_planning' ||
        context.phase == 'checkpoint_presenter';
  }

  bool _isPrimaryWritingTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 主写作轮次包括正文草拟与返工修订，是 adaptive 需要更强执行的核心场景。
    if (context.appliesTo == ConstraintBindingAppliesTo.review ||
        context.appliesTo == ConstraintBindingAppliesTo.explanation ||
        context.appliesTo == ConstraintBindingAppliesTo.deconstruction ||
        context.intent == 'review' ||
        context.intent == 'outline' ||
        context.intent == 'setting' ||
        context.intent == 'summary' ||
        context.taskType == 'planning' ||
        context.taskType == 'review' ||
        context.taskType == 'checkpoint' ||
        context.taskType == 'world_update' ||
        context.taskType == 'summary' ||
        context.phase == 'chapter_postprocess' ||
        context.phase == 'revision_review') {
      return false;
    }
    return context.appliesTo == ConstraintBindingAppliesTo.writing ||
        context.appliesTo == ConstraintBindingAppliesTo.repair ||
        context.intent == 'draft' ||
        context.intent == 'revision' ||
        context.intent == 'workflow_task' &&
            (context.taskType.isEmpty ||
                context.taskType == 'chapter' ||
                context.taskType == 'revision') ||
        context.phase == 'rewrite_after_review' ||
        context.phase == 'revision_rewrite' ||
        context.stageId == 'draft' ||
        context.stageId == 'chapter_write' ||
        context.stageId == 'revision';
  }

  bool _isUserVisibleTextTurn(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 用户可见文本包括正文、修订、审稿总结、解说和规划文本，但不含技术协议轮次。
    if (_isPrimaryWritingTurn(context)) {
      return true;
    }
    if (context.appliesTo == ConstraintBindingAppliesTo.review ||
        context.appliesTo == ConstraintBindingAppliesTo.explanation ||
        context.appliesTo == ConstraintBindingAppliesTo.deconstruction) {
      return true;
    }
    return context.intent == 'review' ||
        context.intent == 'outline' ||
        context.intent == 'setting' ||
        context.intent == 'summary' ||
        context.taskType == 'review' ||
        context.taskType == 'summary' ||
        context.phase == 'chapter_postprocess' ||
        context.phase == 'revision_review';
  }

  bool _supportsRuntimeEscalation(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: 运行时升级只在正文/修订这类连续写作轮次生效，避免把规划或研究摘要误升级成强修复。
    return _isPrimaryWritingTurn(context);
  }

  bool _shouldEscalateFromRecentSummaries(
    List<WritingExecutionConstraintSummary> recentSummaries,
  ) {
    // 中文注释: 这里仅根据最近几章结构化约束摘要判断是否升级，不重新扫描正文也不替代 gate。
    var riskyCount = 0;
    for (final summary in recentSummaries.take(3)) {
      if (_isRiskyRecentSummary(summary)) {
        riskyCount += 1;
      }
    }
    return riskyCount >= 2;
  }

  bool _isRiskyRecentSummary(WritingExecutionConstraintSummary summary) {
    // 中文注释: 连续风险以 review 缺证据、硬 gate、返修要求和明显表达限制失效为主。
    if (!summary.expressionConstraintActive &&
        summary.expressionConstraintBindingCount <= 0) {
      return false;
    }
    if (summary.expressionConstraintEvidenceMissing ||
        summary.expressionConstraintReviewRequired &&
            !summary.expressionConstraintReviewProvided) {
      return true;
    }
    if (summary.repairRequired || summary.hardConstraintTriggered) {
      return true;
    }
    if (summary.hardGateReasons.any(
      (reason) => reason.contains('expression_constraint'),
    )) {
      return true;
    }
    if (summary.expressionConstraintGate.repairRequired ||
        summary.expressionConstraintGate.adjustNextChapter) {
      return true;
    }
    if (summary.expressionConstraintViolationRecorded &&
        summary.reviewSuggested &&
        (summary.authenticityPassLevel ==
                ExpressionConstraintReviewProjection.authenticityAggressive ||
            summary.expressionConstraintRuntimeEscalated ||
            summary.expressionConstraintViolationDisposition ==
                ExpressionConstraintViolationDispositions.repair)) {
      return true;
    }
    return summary.contentQualityRisk && summary.reviewSuggested;
  }

  String _turnReason(
    ExpressionConstraintExecutionPolicyResolutionContext context,
  ) {
    // 中文注释: turn reason 只返回一条主解释，方便后续 GUI/CLI 摘要用人话展示。
    if (_isPrimaryWritingTurn(context)) {
      return 'primary_writing_turn';
    }
    if (context.appliesTo == ConstraintBindingAppliesTo.review ||
        context.intent == 'review' ||
        context.taskType == 'review') {
      return 'review_turn';
    }
    if (context.intent == 'outline' || context.taskType == 'planning') {
      return 'planning_turn';
    }
    if (context.intent == 'summary' ||
        context.taskType == 'summary' ||
        context.appliesTo == ConstraintBindingAppliesTo.explanation) {
      return 'user_visible_summary_turn';
    }
    if (context.appliesTo == ConstraintBindingAppliesTo.deconstruction) {
      return 'deconstruction_turn';
    }
    return 'general_user_visible_turn';
  }

  ExpressionConstraintExecutionPolicyResolution _buildResolution({
    required ExpressionConstraintExecutionPolicy policy,
    required bool applied,
    required bool runtimeEscalated,
    required bool technicalTurnExcluded,
    required List<String> whyApplied,
    required List<String> whySkipped,
    required ExpressionConstraintExecutionPolicyResolutionContext context,
  }) {
    // 中文注释: 统一组装 resolution，保证 whyApplied/whySkipped 和上下文元数据总是同源可解释。
    return ExpressionConstraintExecutionPolicyResolution(
      policy: policy,
      applied: applied,
      runtimeEscalated: runtimeEscalated,
      technicalTurnExcluded: technicalTurnExcluded,
      whyApplied: List<String>.unmodifiable(whyApplied),
      whySkipped: List<String>.unmodifiable(whySkipped),
      metadata: <String, Object?>{
        'override_mode': context.overrideMode,
        'intent': context.intent,
        'task_type': context.taskType,
        'phase': context.phase,
        'applies_to': context.appliesTo,
        'project_type_id': context.projectTypeId,
        'agent_id': context.agentId,
        'mode_id': context.modeId,
        'stage_id': context.stageId,
        'has_bindings': context.hasBindings,
        'recent_summary_count': context.recentSummaries.length,
      },
    );
  }
}
