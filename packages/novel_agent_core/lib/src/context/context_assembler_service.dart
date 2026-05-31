import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../creative/creative_rule_brief_renderer.dart';
import '../creative/creative_rule_context_section_service.dart';
import '../creative/expression_constraint_injection_mode.dart';
import '../creative/expression_constraint_injection_policy_service.dart';
import '../creative/creative_rule_stack_resolver_service.dart';
import '../assets/shared_narrative_asset_context_projection_service.dart';
import '../modes/mode_guidance_state.dart';
import 'context_budget_service.dart';
import 'context_project_file_section_service.dart';
import 'context_static_section_service.dart';

class ContextAssemblerService {
  ContextAssemblerService({
    required ContextBudgetService budgetService,
    required ContextStaticSectionService staticSectionService,
    required ContextProjectFileSectionService projectFileSectionService,
    CreativeRuleStackResolverService? creativeRuleStackResolverService,
    CreativeRuleContextSectionService? creativeRuleContextSectionService,
    CreativeRuleBriefRenderer? creativeRuleBriefRenderer,
    ExpressionConstraintInjectionPolicyService?
    expressionConstraintInjectionPolicyService,
    SharedNarrativeAssetContextProjectionService?
    sharedNarrativeAssetContextProjectionService,
  }) : _budgetService = budgetService,
       _staticSectionService = staticSectionService,
       _projectFileSectionService = projectFileSectionService,
       _creativeRuleStackResolverService =
           creativeRuleStackResolverService ??
           CreativeRuleStackResolverService(),
       _creativeRuleContextSectionService =
           creativeRuleContextSectionService ??
           const CreativeRuleContextSectionService(),
       _creativeRuleBriefRenderer =
           creativeRuleBriefRenderer ?? const CreativeRuleBriefRenderer(),
       _expressionConstraintInjectionPolicyService =
           expressionConstraintInjectionPolicyService ??
           const ExpressionConstraintInjectionPolicyService(),
       _sharedNarrativeAssetContextProjectionService =
           sharedNarrativeAssetContextProjectionService ??
           SharedNarrativeAssetContextProjectionService();

  final ContextBudgetService _budgetService;
  final ContextStaticSectionService _staticSectionService;
  final ContextProjectFileSectionService _projectFileSectionService;
  final CreativeRuleStackResolverService _creativeRuleStackResolverService;
  final CreativeRuleContextSectionService _creativeRuleContextSectionService;
  final CreativeRuleBriefRenderer _creativeRuleBriefRenderer;
  final ExpressionConstraintInjectionPolicyService
  _expressionConstraintInjectionPolicyService;
  final SharedNarrativeAssetContextProjectionService
  _sharedNarrativeAssetContextProjectionService;

  JsonMap assemble(JsonMap data) {
    // 中文注释: 上下文包组装统一在这一层完成，调用方只负责提供原材料，不再自己决定预算和排序。
    final contextSettings = _budgetService.normalize(
      ValueReaders.mapValue(data['context_settings']),
    );
    final modelProfile = ValueReaders.mapValue(data['model_profile']);
    final intent = ValueReaders.stringValue(data['intent'], 'draft');
    final fullCreativeRuleStack = _creativeRuleStackResolverService.resolve(
      rawStack: ValueReaders.mapValue(data['creative_rule_stack']),
      rawConstitution: ValueReaders.mapValue(data['project_constitution']),
      projectConstitutionMarkdown: ValueReaders.stringValue(
        data['project_constitution_markdown'],
        ValueReaders.stringValue(data['project_spec_markdown']),
      ),
      modeGuidanceState: _modeGuidanceState(data['mode_guidance_state']),
      expressionConstraintProfiles: ValueReaders.objectList(
        data['expression_constraint_profiles'],
      ),
      projectExpressionConstraintBindings: ValueReaders.objectList(
        data['project_expression_constraint_bindings'],
      ),
      styleProfiles: ValueReaders.objectList(data['style_profiles']),
      projectStyleBindings: ValueReaders.objectList(
        data['project_style_bindings'],
      ),
      memorySections: ValueReaders.objectList(data['memory_sections']),
      projectFileContents: ValueReaders.mapValue(data['project_file_contents']),
      agentId: ValueReaders.stringValue(
        ValueReaders.mapValue(data['agent'])['id'],
      ),
      modeId: ValueReaders.stringValue(data['mode_id']),
      stageId: ValueReaders.stringValue(data['stage_id']),
    );
    final expressionConstraintMode = _expressionConstraintInjectionPolicyService
        .resolveMode(
          intent: intent,
          overrideModeId: _expressionConstraintOverrideMode(
            data,
            contextSettings: contextSettings,
          ),
        );
    final briefCreativeRuleStack = _expressionConstraintInjectionPolicyService
        .projectBriefStack(
          fullCreativeRuleStack,
          intent: intent,
          overrideModeId: _expressionConstraintOverrideMode(
            data,
            contextSettings: contextSettings,
          ),
        );
    final sectionCreativeRuleStack = _expressionConstraintInjectionPolicyService
        .projectSectionStack(
          fullCreativeRuleStack,
          intent: intent,
          overrideModeId: _expressionConstraintOverrideMode(
            data,
            contextSettings: contextSettings,
          ),
        );
    final sections = candidateSections(
      data,
      contextSettings: contextSettings,
      creativeRuleStack: sectionCreativeRuleStack.toJson(),
      expressionConstraintInjectionMode: expressionConstraintMode,
    );
    final budgeted = _budgetService.applyBudget(
      sections,
      contextSettings,
      modelProfile: modelProfile,
    );
    final contextText = _budgetService.renderSectionsMarkdown(
      ValueReaders.objectList(budgeted['sections']),
    );
    final contextPack = <String, Object?>{
      'schema_version': 1,
      'id': 'context_pack_${DateTime.now().microsecondsSinceEpoch}',
      'intent': ValueReaders.stringValue(data['intent'], 'draft'),
      'created_at': DateTime.now().toIso8601String(),
      'summary': budgeted['summary'],
      'budget_chars': budgeted['budget_chars'],
      'used_chars': budgeted['used_chars'],
      'sections': budgeted['sections'],
      'omitted_sections': budgeted['omitted_sections'],
      'context_text': contextText,
      'creative_rule_stack': briefCreativeRuleStack.toJson(),
      'creative_rule_summary': _creativeRuleBriefRenderer.render(
        briefCreativeRuleStack,
      ),
      'expression_constraint_injection_mode':
          _expressionConstraintInjectionPolicyService.modeId(
            expressionConstraintMode,
          ),
    };
    contextPack['prompt_preview_markdown'] = _budgetService.previewMarkdown(
      contextPack,
      userPrompt: ValueReaders.stringValue(data['user_prompt']),
    );
    return contextPack;
  }

  List<JsonMap> candidateSections(
    JsonMap data, {
    required JsonMap contextSettings,
    JsonMap creativeRuleStack = const <String, Object?>{},
    ExpressionConstraintInjectionMode expressionConstraintInjectionMode =
        ExpressionConstraintInjectionMode.briefAndSections,
  }) {
    // 中文注释: 候选片段生成先按高价值固定片段、记忆片段、项目文件片段分层，再交给预算器裁剪。
    final project = ValueReaders.mapValue(data['project']);
    final projectFiles = ValueReaders.objectList(data['project_files']);
    final memorySections = ValueReaders.objectList(data['memory_sections'])
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    final stack = _creativeRuleStackResolverService.resolve(
      rawStack: creativeRuleStack,
    );
    final sections = <JsonMap>[];
    sections.addAll(_creativeRuleContextSectionService.buildSections(stack));
    sections.addAll(
      _staticSectionService.buildStaticSections(
        project: project,
        projectFiles: projectFiles,
        sessionContext: ValueReaders.stringValue(data['session_context']),
        currentFileBody: ValueReaders.stringValue(data['current_file_body']),
        currentFilePath: ValueReaders.stringValue(data['current_file_path']),
        intent: ValueReaders.stringValue(data['intent'], 'draft'),
        agent: ValueReaders.mapValue(data['agent']),
        optionalAgents: ValueReaders.objectList(data['optional_agents']),
      ),
    );
    sections.addAll(
      memorySections.where(
        (entry) =>
            !stack.consumedMemorySectionIds.contains(
              ValueReaders.stringValue(entry['id']),
            ) &&
            !_expressionConstraintInjectionPolicyService
                .shouldSuppressMemoryLayer(
                  ValueReaders.stringValue(entry['creative_layer']),
                  expressionConstraintInjectionMode,
                ),
      ),
    );
    final projectFilePlan =
        ValueReaders.objectList(data['project_file_section_plan'])
            .map(ValueReaders.mapValue)
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
    final projectFileContents = ValueReaders.mapValue(
      data['project_file_contents'],
    );
    if (projectFilePlan.isNotEmpty) {
      for (final sectionPlan in projectFilePlan) {
        final snippets = _projectFileSectionService.readPlannedSnippets(
          sectionPlan,
          projectFileContents: projectFileContents,
        );
        if (snippets.isEmpty) {
          continue;
        }
        sections.add(<String, Object?>{
          'id': ValueReaders.stringValue(sectionPlan['id']),
          'title': ValueReaders.stringValue(sectionPlan['title']),
          'source': ValueReaders.stringValue(sectionPlan['source']),
          'priority': ValueReaders.intValue(sectionPlan['priority'], 60),
          'content': snippets.join('\n\n'),
        });
      }
    } else {
      sections.addAll(
        _projectFileSectionService.buildProjectFileSections(
          projectFiles: projectFiles,
          projectFileContents: projectFileContents,
          contextSettings: contextSettings,
        ),
      );
    }
    sections.addAll(
      _sharedNarrativeAssetContextProjectionService.buildSections(
        projectFileContents: projectFileContents,
        focusPaths: _focusPaths(data, projectFilePlan),
      ),
    );
    return sections;
  }

  List<String> _focusPaths(JsonMap data, List<JsonMap> projectFilePlan) {
    // 中文注释: 焦点路径只收口当前正在看的文档与显式计划路径，避免共享资产片段无脑扩散。
    final paths = <String>[];
    void addPath(String value) {
      final clean = value.trim();
      if (clean.isNotEmpty && !paths.contains(clean)) {
        paths.add(clean);
      }
    }

    addPath(ValueReaders.stringValue(data['current_file_path']));
    addPath(ValueReaders.stringValue(data['active_document_path']));
    for (final plan in projectFilePlan) {
      for (final rawPath in ValueReaders.objectList(plan['paths'])) {
        addPath(ValueReaders.stringValue(rawPath));
      }
    }
    return paths;
  }

  String _expressionConstraintOverrideMode(
    JsonMap data, {
    required JsonMap contextSettings,
  }) {
    return ValueReaders.stringValue(
      data['expression_constraint_injection_mode'],
      ValueReaders.stringValue(
        contextSettings['expression_constraint_injection_mode'],
      ),
    );
  }

  ModeGuidanceState? _modeGuidanceState(Object? rawState) {
    // 中文注释: 上下文组装只接受已知结构的模式状态快照，避免把无约束 map 当成引导状态使用。
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
