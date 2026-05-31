import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/creative_rule_brief_renderer.dart';
import '../creative/creative_rule_context_section_service.dart';
import '../creative/expression_constraint_injection_policy_service.dart';
import '../creative/creative_rule_stack_resolver_service.dart';
import '../modes/mode_guidance_state.dart';
import 'chapter_length_profile_resolver_service.dart';
import 'long_task_mode_service.dart';
import 'long_task_mode_strategy_service.dart';
import 'long_task_transaction_context_service.dart';
import 'long_task_transaction_contract_service.dart';

class LongTaskTaskTransactionService {
  LongTaskTaskTransactionService({
    required LongTaskModeService modeService,
    required LongTaskModeStrategyService strategyService,
    required LongTaskTransactionContextService contextService,
    required LongTaskTransactionContractService contractService,
    ChapterLengthProfileResolverService? chapterLengthProfileResolverService,
    CreativeRuleStackResolverService? creativeRuleStackResolverService,
    CreativeRuleBriefRenderer? creativeRuleBriefRenderer,
    CreativeRuleContextSectionService? creativeRuleContextSectionService,
    ExpressionConstraintInjectionPolicyService?
    expressionConstraintInjectionPolicyService,
  }) : _modeService = modeService,
       _strategyService = strategyService,
       _contextService = contextService,
       _contractService = contractService,
       _chapterLengthProfileResolverService =
           chapterLengthProfileResolverService ??
           const ChapterLengthProfileResolverService(),
       _creativeRuleStackResolverService =
           creativeRuleStackResolverService ??
           CreativeRuleStackResolverService(),
       _creativeRuleBriefRenderer =
           creativeRuleBriefRenderer ?? const CreativeRuleBriefRenderer(),
       _creativeRuleContextSectionService =
           creativeRuleContextSectionService ??
           const CreativeRuleContextSectionService(),
       _expressionConstraintInjectionPolicyService =
           expressionConstraintInjectionPolicyService ??
           const ExpressionConstraintInjectionPolicyService();

  final LongTaskModeService _modeService;
  final LongTaskModeStrategyService _strategyService;
  final LongTaskTransactionContextService _contextService;
  final LongTaskTransactionContractService _contractService;
  final ChapterLengthProfileResolverService
  _chapterLengthProfileResolverService;
  final CreativeRuleStackResolverService _creativeRuleStackResolverService;
  final CreativeRuleBriefRenderer _creativeRuleBriefRenderer;
  final CreativeRuleContextSectionService _creativeRuleContextSectionService;
  final ExpressionConstraintInjectionPolicyService
  _expressionConstraintInjectionPolicyService;

  JsonMap buildTaskTransaction(
    JsonMap task, {
    JsonMap runRecord = const <String, Object?>{},
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 模型单步事务包把任务、模式策略和项目模板揉成纯数据合同，供 GUI/CLI 共用。
    final taskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        task['mode'],
        ValueReaders.stringValue(runRecord['mode']),
      ),
    );
    final metadata = ValueReaders.mapValue(task['metadata']);
    final stage = ValueReaders.stringValue(metadata['stage']);
    final chapterLengthProfile = _chapterLengthProfileResolverService
        .resolveFromTask(task);
    final chapterLengthPolicy = _chapterLengthProfileResolverService
        .resolvePolicyFromTask(task);
    final creativeRuleStack = _creativeRuleStackResolverService.resolve(
      rawStack: ValueReaders.mapValue(options['creative_rule_stack']),
      rawConstitution: ValueReaders.mapValue(options['project_constitution']),
      projectConstitutionMarkdown: ValueReaders.stringValue(
        options['project_constitution_markdown'],
        ValueReaders.stringValue(options['project_spec_markdown']),
      ),
      modeGuidanceState: _modeGuidanceState(options['mode_guidance_state']),
      expressionConstraintProfiles: ValueReaders.objectList(
        options['expression_constraint_profiles'],
      ),
      projectExpressionConstraintBindings: ValueReaders.objectList(
        options['project_expression_constraint_bindings'],
      ),
      styleProfiles: ValueReaders.objectList(options['style_profiles']),
      projectStyleBindings: ValueReaders.objectList(
        options['project_style_bindings'],
      ),
      memorySections: ValueReaders.objectList(options['memory_sections']),
      projectFileContents: ValueReaders.mapValue(
        options['project_file_contents'],
      ),
      agentId: ValueReaders.stringValue(options['agent_id']),
      modeId: mode,
      stageId: stage,
    );
    final expressionConstraintMode = _expressionConstraintInjectionPolicyService
        .resolveMode(
          intent: 'workflow_task',
          taskType: taskType,
          overrideModeId: ValueReaders.stringValue(
            options['expression_constraint_injection_mode'],
          ),
        );
    final briefCreativeRuleStack = _expressionConstraintInjectionPolicyService
        .projectBriefStack(
          creativeRuleStack,
          intent: 'workflow_task',
          taskType: taskType,
          overrideModeId: ValueReaders.stringValue(
            options['expression_constraint_injection_mode'],
          ),
        );
    final sectionCreativeRuleStack = _expressionConstraintInjectionPolicyService
        .projectSectionStack(
          creativeRuleStack,
          intent: 'workflow_task',
          taskType: taskType,
          overrideModeId: ValueReaders.stringValue(
            options['expression_constraint_injection_mode'],
          ),
        );
    return <String, Object?>{
      'ok': true,
      'transaction_type': 'long_task_model_step',
      'phase': 'model_step',
      'mode': mode,
      'strategy': _strategyService.modeStrategy(mode),
      'agent_role': _contextService.roleForTask(task, runMode: mode),
      'task_type': taskType,
      'task_id': ValueReaders.stringValue(task['id']),
      'task_title': ValueReaders.stringValue(task['title'], '未命名任务'),
      'chapter': ValueReaders.stringValue(task['chapter']),
      'goal': ValueReaders.stringValue(task['goal']),
      'brief': ValueReaders.stringValue(task['brief']),
      'source_paths': ValueReaders.stringList(task['source_paths']),
      'output_paths': ValueReaders.stringList(task['output_paths']),
      'proposed_output_paths': ValueReaders.mapValue(
        task['proposed_output_paths'],
      ),
      'tool_hint': ValueReaders.stringValue(task['tool_hint']),
      'metadata': metadata,
      'chapter_word_constraints': _chapterLengthProfileResolverService
          .buildPromptConstraintMap(chapterLengthProfile),
      'chapter_length_profile': chapterLengthProfile.toJson(),
      'chapter_length_distribution_policy': chapterLengthPolicy.toJson(),
      'creative_rule_stack': briefCreativeRuleStack.toJson(),
      'creative_rule_summary': _creativeRuleBriefRenderer.render(
        briefCreativeRuleStack,
      ),
      'expression_constraint_injection_mode':
          _expressionConstraintInjectionPolicyService.modeId(
            expressionConstraintMode,
          ),
      'expression_constraint_prompt_sections':
          _creativeRuleContextSectionService
              .buildSections(sectionCreativeRuleStack)
              .where(
                (section) =>
                    ValueReaders.stringValue(section['creative_layer']) ==
                    'expression_constraint',
              )
              .toList(growable: false),
      'context_needs': _contextService.commonContextNeeds(task),
      'tool_contracts': _contractService.toolContractsForTask(task),
      'instructions': _contractService.primaryInstructionsForTask(task),
      'skill_routing': _contractService.skillRoutingForTask(task),
      'postprocess_plan': _contractService.postprocessPlanForTask(task),
      'project_templates': ValueReaders.mapValue(options['project_templates']),
      'review_type': ValueReaders.stringValue(
        metadata['review_type'],
        'general',
      ),
      'review_focuses': ValueReaders.stringList(metadata['review_focuses']),
      'authenticity_pass_level': ValueReaders.stringValue(
        metadata['authenticity_pass_level'],
      ),
      'mini_recheck_items': ValueReaders.stringList(
        metadata['mini_recheck_items'],
      ),
      'single_step_boundary': _contractService.singleStepBoundary(
        task,
        runMode: mode,
      ),
      'allows_stream_guidance': ValueReaders.boolValue(
        options['allow_stream_guidance'],
        true,
      ),
      'run_id': ValueReaders.stringValue(runRecord['id']),
    };
  }

  ModeGuidanceState? _modeGuidanceState(Object? rawState) {
    // 中文注释: 事务构建只接受正式模式状态对象或它的 JSON 形态，避免任意 map 混入创作约束解析。
    if (rawState is ModeGuidanceState) {
      return rawState;
    }
    if (rawState is Map<Object?, Object?>) {
      final mapped = <String, Object?>{};
      for (final entry in rawState.entries) {
        final key = entry.key?.toString().trim() ?? '';
        if (key.isEmpty) {
          continue;
        }
        mapped[key] = entry.value;
      }
      if (mapped.isNotEmpty) {
        return ModeGuidanceState.fromJsonMap(mapped);
      }
    }
    return null;
  }
}
