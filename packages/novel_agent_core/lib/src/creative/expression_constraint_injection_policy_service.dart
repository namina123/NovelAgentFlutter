import 'creative_rule_stack.dart';
import 'expression_constraint_execution_policy.dart';
import 'expression_constraint_injection_mode.dart';

class ExpressionConstraintInjectionPolicyService {
  const ExpressionConstraintInjectionPolicyService();

  ExpressionConstraintInjectionMode resolveMode({
    ExpressionConstraintExecutionPolicy? executionPolicy,
    String policyMode = '',
    String policyInjectionStrength = '',
    String intent = '',
    String taskType = '',
    String phase = '',
    String overrideModeId = '',
  }) {
    final explicitPolicyMode = _modeFromExecutionPolicy(
      executionPolicy,
      policyMode: policyMode,
      policyInjectionStrength: policyInjectionStrength,
    );
    if (explicitPolicyMode != null) {
      return explicitPolicyMode;
    }
    final overrideMode = _parseMode(overrideModeId);
    if (overrideMode != null) {
      return overrideMode;
    }
    final normalizedIntent = intent.trim().toLowerCase();
    final normalizedTaskType = taskType.trim().toLowerCase();
    final normalizedPhase = phase.trim().toLowerCase();
    if (_needsSections(
      normalizedIntent,
      taskType: normalizedTaskType,
      phase: normalizedPhase,
    )) {
      return ExpressionConstraintInjectionMode.briefAndSections;
    }
    if (_needsBrief(
      normalizedIntent,
      taskType: normalizedTaskType,
      phase: normalizedPhase,
    )) {
      return ExpressionConstraintInjectionMode.briefOnly;
    }
    return ExpressionConstraintInjectionMode.disabled;
  }

  CreativeRuleStack projectBriefStack(
    CreativeRuleStack stack, {
    ExpressionConstraintExecutionPolicy? executionPolicy,
    String policyMode = '',
    String policyInjectionStrength = '',
    String intent = '',
    String taskType = '',
    String phase = '',
    String overrideModeId = '',
  }) {
    final mode = resolveMode(
      executionPolicy: executionPolicy,
      policyMode: policyMode,
      policyInjectionStrength: policyInjectionStrength,
      intent: intent,
      taskType: taskType,
      phase: phase,
      overrideModeId: overrideModeId,
    );
    if (mode == ExpressionConstraintInjectionMode.disabled) {
      return stack.copyWith(
        expressionConstraints: const [],
        expressionConstraintBindings: const [],
      );
    }
    return stack;
  }

  CreativeRuleStack projectSectionStack(
    CreativeRuleStack stack, {
    ExpressionConstraintExecutionPolicy? executionPolicy,
    String policyMode = '',
    String policyInjectionStrength = '',
    String intent = '',
    String taskType = '',
    String phase = '',
    String overrideModeId = '',
  }) {
    final mode = resolveMode(
      executionPolicy: executionPolicy,
      policyMode: policyMode,
      policyInjectionStrength: policyInjectionStrength,
      intent: intent,
      taskType: taskType,
      phase: phase,
      overrideModeId: overrideModeId,
    );
    if (mode != ExpressionConstraintInjectionMode.briefAndSections) {
      return stack.copyWith(
        expressionConstraints: const [],
        expressionConstraintBindings: const [],
      );
    }
    return stack;
  }

  bool shouldSuppressMemoryLayer(
    String layer,
    ExpressionConstraintInjectionMode mode,
  ) {
    final normalizedLayer = layer.trim().toLowerCase();
    return normalizedLayer == 'expression_constraint' &&
        mode != ExpressionConstraintInjectionMode.briefAndSections;
  }

  String modeId(ExpressionConstraintInjectionMode mode) {
    return switch (mode) {
      ExpressionConstraintInjectionMode.disabled => 'disabled',
      ExpressionConstraintInjectionMode.briefOnly => 'brief_only',
      ExpressionConstraintInjectionMode.briefAndSections =>
        'brief_and_sections',
    };
  }

  ExpressionConstraintInjectionMode? _parseMode(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'disabled':
      case 'none':
        return ExpressionConstraintInjectionMode.disabled;
      case 'brief_only':
      case 'briefonly':
        return ExpressionConstraintInjectionMode.briefOnly;
      case 'brief_and_sections':
      case 'briefandsections':
      case 'sections':
        return ExpressionConstraintInjectionMode.briefAndSections;
      default:
        return null;
    }
  }

  ExpressionConstraintInjectionMode? _modeFromExecutionPolicy(
    ExpressionConstraintExecutionPolicy? executionPolicy, {
    String policyMode = '',
    String policyInjectionStrength = '',
  }) {
    // 中文注释: 当上游已经解析出 execution policy 时，这里只负责把 policy 映射成注入形态，不再次承担技术轮次排除。
    final resolvedPolicyMode = policyMode.trim().toLowerCase().isNotEmpty
        ? policyMode.trim().toLowerCase()
        : executionPolicy?.mode.trim().toLowerCase() ?? '';
    final resolvedInjectionStrength =
        policyInjectionStrength.trim().toLowerCase().isNotEmpty
        ? policyInjectionStrength.trim().toLowerCase()
        : executionPolicy?.injectionStrength.trim().toLowerCase() ?? '';
    if (resolvedPolicyMode ==
            ExpressionConstraintExecutionPolicyModes.disabled ||
        resolvedInjectionStrength ==
            ExpressionConstraintInjectionStrengths.none) {
      return ExpressionConstraintInjectionMode.disabled;
    }
    if (resolvedInjectionStrength ==
            ExpressionConstraintInjectionStrengths.brief ||
        resolvedInjectionStrength ==
            ExpressionConstraintInjectionStrengths.none) {
      return ExpressionConstraintInjectionMode.briefOnly;
    }
    if (resolvedInjectionStrength ==
            ExpressionConstraintInjectionStrengths.sections ||
        resolvedInjectionStrength ==
            ExpressionConstraintInjectionStrengths.full ||
        resolvedPolicyMode == ExpressionConstraintExecutionPolicyModes.force) {
      return ExpressionConstraintInjectionMode.briefAndSections;
    }
    return null;
  }

  bool _needsSections(
    String intent, {
    String taskType = '',
    String phase = '',
  }) {
    if (intent == 'draft') {
      return true;
    }
    if (intent == 'workflow_task') {
      return taskType.isEmpty ||
          taskType == 'chapter' ||
          taskType == 'revision';
    }
    return phase == 'rewrite_after_review' || phase == 'revision_rewrite';
  }

  bool _needsBrief(String intent, {String taskType = '', String phase = ''}) {
    if (_needsSections(intent, taskType: taskType, phase: phase)) {
      return true;
    }
    if (phase == 'chapter_postprocess' || phase == 'revision_review') {
      return true;
    }
    return intent == 'review' ||
        intent == 'outline' ||
        intent == 'setting' ||
        intent == 'summary' ||
        intent == 'revision' ||
        taskType == 'planning' ||
        taskType == 'review' ||
        taskType == 'checkpoint' ||
        taskType == 'world_update' ||
        taskType == 'summary';
  }
}
