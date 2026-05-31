import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/creative_rule_brief_renderer.dart';
import '../creative/expression_constraint_injection_policy_service.dart';
import '../creative/expression_constraint_review_projection_service.dart';
import '../creative/creative_rule_stack_resolver_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_path_policy_service.dart';
import 'long_task_transaction_context_service.dart';

class LongTaskPostprocessTransactionService {
  LongTaskPostprocessTransactionService({
    required LongTaskModeService modeService,
    required LongTaskPathPolicyService pathPolicyService,
    required LongTaskTransactionContextService contextService,
    CreativeRuleStackResolverService? creativeRuleStackResolverService,
    CreativeRuleBriefRenderer? creativeRuleBriefRenderer,
    ExpressionConstraintInjectionPolicyService?
    expressionConstraintInjectionPolicyService,
    ExpressionConstraintReviewProjectionService?
    expressionConstraintReviewProjectionService,
  }) : _modeService = modeService,
       _pathPolicyService = pathPolicyService,
       _contextService = contextService,
       _creativeRuleStackResolverService =
           creativeRuleStackResolverService ??
           CreativeRuleStackResolverService(),
       _creativeRuleBriefRenderer =
           creativeRuleBriefRenderer ?? const CreativeRuleBriefRenderer(),
       _expressionConstraintInjectionPolicyService =
           expressionConstraintInjectionPolicyService ??
           const ExpressionConstraintInjectionPolicyService(),
       _expressionConstraintReviewProjectionService =
           expressionConstraintReviewProjectionService ??
           const ExpressionConstraintReviewProjectionService();

  final LongTaskModeService _modeService;
  final LongTaskPathPolicyService _pathPolicyService;
  final LongTaskTransactionContextService _contextService;
  final CreativeRuleStackResolverService _creativeRuleStackResolverService;
  final CreativeRuleBriefRenderer _creativeRuleBriefRenderer;
  final ExpressionConstraintInjectionPolicyService
  _expressionConstraintInjectionPolicyService;
  final ExpressionConstraintReviewProjectionService
  _expressionConstraintReviewProjectionService;

  JsonMap buildPostprocessTransaction(
    JsonMap task,
    JsonMap execution,
    List<Object?> draftPaths, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 后处理事务包把正文后处理和修订复核的差异显式写出来，避免宿主层分支过重。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final cleanDraftPaths = _pathPolicyService.stringList(draftPaths);
    final fallbackCreativeRuleStack = _fallbackCreativeRuleStack(
      options,
      execution: execution,
    );
    final creativeRuleStack = _creativeRuleStackResolverService.resolve(
      rawStack: fallbackCreativeRuleStack,
      rawConstitution: ValueReaders.mapValue(options['project_constitution']),
      projectConstitutionMarkdown: ValueReaders.stringValue(
        options['project_constitution_markdown'],
        ValueReaders.stringValue(options['project_spec_markdown']),
      ),
      expressionConstraintProfiles: ValueReaders.objectList(
        options['expression_constraint_profiles'],
      ),
      projectExpressionConstraintBindings: ValueReaders.objectList(
        options['project_expression_constraint_bindings'],
      ),
      memorySections: ValueReaders.objectList(options['memory_sections']),
      projectFileContents: ValueReaders.mapValue(
        options['project_file_contents'],
      ),
      modeId: ValueReaders.stringValue(task['mode']),
      stageId: ValueReaders.stringValue(
        ValueReaders.mapValue(task['metadata'])['stage'],
      ),
    );
    final expressionConstraintMode = _expressionConstraintInjectionPolicyService
        .resolveMode(
          intent: 'review',
          taskType: taskType,
          phase: taskType == 'revision'
              ? 'revision_review'
              : 'chapter_postprocess',
          overrideModeId: ValueReaders.stringValue(
            options['expression_constraint_injection_mode'],
          ),
        );
    final briefCreativeRuleStack = _expressionConstraintInjectionPolicyService
        .projectBriefStack(
          creativeRuleStack,
          intent: 'review',
          taskType: taskType,
          phase: taskType == 'revision'
              ? 'revision_review'
              : 'chapter_postprocess',
          overrideModeId: ValueReaders.stringValue(
            options['expression_constraint_injection_mode'],
          ),
        );
    final expressionConstraintReview =
        _expressionConstraintReviewProjectionService.build(
          creativeRuleStack.expressionConstraints,
        );
    final transaction = <String, Object?>{
      'ok': true,
      'transaction_type': 'long_task_postprocess_step',
      'phase': taskType == 'revision'
          ? 'revision_review'
          : 'chapter_postprocess',
      'mode': _modeService.normalizeMode(
        ValueReaders.stringValue(task['mode']),
      ),
      'agent_role': taskType == 'revision'
          ? 'revision_reviewer'
          : 'postprocess_reviewer',
      'task_type': taskType,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title'], '未命名任务'),
      'chapter': ValueReaders.stringValue(task['chapter']),
      'goal': ValueReaders.stringValue(task['goal']),
      'draft_paths': cleanDraftPaths,
      'execution_path': ValueReaders.stringValue(execution['relative_path']),
      'project_templates': ValueReaders.mapValue(options['project_templates']),
      'creative_rule_stack': briefCreativeRuleStack.toJson(),
      'creative_rule_summary': _creativeRuleBriefRenderer.render(
        briefCreativeRuleStack,
      ),
      'review_focuses': expressionConstraintReview.reviewFocuses,
      'mini_recheck_items': expressionConstraintReview.miniRecheckItems,
      'expression_constraint_review': expressionConstraintReview.toJson(),
      'authenticity_pass_level':
          expressionConstraintReview.authenticityPassLevel,
      'expression_constraint_injection_mode':
          _expressionConstraintInjectionPolicyService.modeId(
            expressionConstraintMode,
          ),
    };
    if (taskType == 'revision') {
      final diffPath = _pathPolicyService.safeProjectPath(
        ValueReaders.stringValue(
          task['revision_diff_path'],
          ValueReaders.stringValue(execution['revision_diff_path']),
        ),
      );
      final reviewPath = _contextService.originalReviewPath(task);
      final targets = _contextService.revisionTargets(task, cleanDraftPaths);
      transaction['revision_targets'] = targets;
      transaction['original_review_path'] = reviewPath;
      transaction['revision_diff_path'] = diffPath;
      transaction['related_paths'] = _pathPolicyService.mergePaths(
        reviewPath.isEmpty ? const <Object?>[] : <Object?>[reviewPath],
        diffPath.isEmpty ? const <Object?>[] : <Object?>[diffPath],
      );
    }
    return transaction;
  }

  JsonMap _fallbackCreativeRuleStack(
    JsonMap options, {
    required JsonMap execution,
  }) {
    final rawStack = ValueReaders.mapValue(options['creative_rule_stack']);
    final contextPack = ValueReaders.mapValue(execution['context_pack']);
    final contextStack = ValueReaders.mapValue(
      contextPack['creative_rule_stack'],
    );
    final executionStack = contextStack.isNotEmpty
        ? contextStack
        : ValueReaders.mapValue(execution['creative_rule_stack']);
    if (rawStack.isEmpty) {
      return executionStack;
    }
    if (executionStack.isEmpty) {
      return rawStack;
    }
    return <String, Object?>{...executionStack, ...rawStack};
  }
}
