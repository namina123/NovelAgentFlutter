import '../continuity/narrative_state/constraint_binding_applies_to.dart';
import '../workflow/writing_execution_constraint_summary.dart';

class ExpressionConstraintExecutionPolicyResolutionContext {
  const ExpressionConstraintExecutionPolicyResolutionContext({
    this.overrideMode = '',
    this.intent = 'draft',
    this.taskType = '',
    this.phase = '',
    this.appliesTo = ConstraintBindingAppliesTo.writing,
    this.projectTypeId = '',
    this.agentId = '',
    this.modeId = '',
    this.stageId = 'draft',
    this.hasBindings = false,
    this.recentSummaries = const <WritingExecutionConstraintSummary>[],
  });

  final String overrideMode;
  final String intent;
  final String taskType;
  final String phase;
  final String appliesTo;
  final String projectTypeId;
  final String agentId;
  final String modeId;
  final String stageId;
  final bool hasBindings;
  final List<WritingExecutionConstraintSummary> recentSummaries;

  ExpressionConstraintExecutionPolicyResolutionContext copyWith({
    String? overrideMode,
    String? intent,
    String? taskType,
    String? phase,
    String? appliesTo,
    String? projectTypeId,
    String? agentId,
    String? modeId,
    String? stageId,
    bool? hasBindings,
    List<WritingExecutionConstraintSummary>? recentSummaries,
  }) {
    // 中文注释: resolver 上下文会在 bridge、普通写作和长任务入口之间复用，这里提供统一 copy 入口。
    return ExpressionConstraintExecutionPolicyResolutionContext(
      overrideMode: overrideMode ?? this.overrideMode,
      intent: intent ?? this.intent,
      taskType: taskType ?? this.taskType,
      phase: phase ?? this.phase,
      appliesTo: appliesTo ?? this.appliesTo,
      projectTypeId: projectTypeId ?? this.projectTypeId,
      agentId: agentId ?? this.agentId,
      modeId: modeId ?? this.modeId,
      stageId: stageId ?? this.stageId,
      hasBindings: hasBindings ?? this.hasBindings,
      recentSummaries: recentSummaries ?? this.recentSummaries,
    );
  }
}
