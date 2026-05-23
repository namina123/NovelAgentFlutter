import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'context_budget_service.dart';
import 'context_project_file_section_service.dart';
import 'context_static_section_service.dart';

class ContextAssemblerService {
  ContextAssemblerService({
    required ContextBudgetService budgetService,
    required ContextStaticSectionService staticSectionService,
    required ContextProjectFileSectionService projectFileSectionService,
  }) : _budgetService = budgetService,
       _staticSectionService = staticSectionService,
       _projectFileSectionService = projectFileSectionService;

  final ContextBudgetService _budgetService;
  final ContextStaticSectionService _staticSectionService;
  final ContextProjectFileSectionService _projectFileSectionService;

  JsonMap assemble(JsonMap data) {
    // 中文注释: 上下文包组装统一在这一层完成，调用方只负责提供原材料，不再自己决定预算和排序。
    final contextSettings = _budgetService.normalize(
      ValueReaders.mapValue(data['context_settings']),
    );
    final modelProfile = ValueReaders.mapValue(data['model_profile']);
    final sections = candidateSections(data, contextSettings: contextSettings);
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
  }) {
    // 中文注释: 候选片段生成先按高价值固定片段、记忆片段、项目文件片段分层，再交给预算器裁剪。
    final project = ValueReaders.mapValue(data['project']);
    final projectFiles = ValueReaders.objectList(data['project_files']);
    final sections = <JsonMap>[];
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
        projectSpecMarkdown: ValueReaders.stringValue(
          data['project_spec_markdown'],
        ),
      ),
    );
    sections.addAll(
      ValueReaders.objectList(
        data['memory_sections'],
      ).map(ValueReaders.mapValue).where((entry) => entry.isNotEmpty),
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
    return sections;
  }
}
