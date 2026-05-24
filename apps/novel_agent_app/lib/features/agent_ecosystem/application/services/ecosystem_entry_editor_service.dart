import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/ecosystem_editor_view_data.dart';

class EcosystemEntryEditorService {
  EcosystemEntryEditorService({
    AgentMarkdownPackageParserService? agentParserService,
    SkillMarkdownPackageParserService? skillParserService,
    AgentMarkdownPackageRendererService? agentRendererService,
    SkillMarkdownPackageRendererService? skillRendererService,
    AgentGroupFileCodecService? agentGroupCodecService,
    SkillGroupFileCodecService? skillGroupCodecService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
    AgentProfileNormalizerService? agentProfileNormalizerService,
  }) : _agentParserService =
           agentParserService ?? AgentMarkdownPackageParserService(),
       _skillParserService =
           skillParserService ?? SkillMarkdownPackageParserService(),
       _agentRendererService =
           agentRendererService ?? AgentMarkdownPackageRendererService(),
       _skillRendererService =
           skillRendererService ?? SkillMarkdownPackageRendererService(),
       _agentGroupCodecService =
           agentGroupCodecService ?? AgentGroupFileCodecService(),
       _skillGroupCodecService =
           skillGroupCodecService ?? SkillGroupFileCodecService(),
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService(),
       _agentProfileNormalizerService =
           agentProfileNormalizerService ?? AgentProfileNormalizerService();

  final AgentMarkdownPackageParserService _agentParserService;
  final SkillMarkdownPackageParserService _skillParserService;
  final AgentMarkdownPackageRendererService _agentRendererService;
  final SkillMarkdownPackageRendererService _skillRendererService;
  final AgentGroupFileCodecService _agentGroupCodecService;
  final SkillGroupFileCodecService _skillGroupCodecService;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;
  final AgentProfileNormalizerService _agentProfileNormalizerService;

  EcosystemEditorViewData buildForEntry(
    JsonMap entry, {
    required String kind,
    String sourceContent = '',
  }) {
    // 中文注释: 编辑器默认值优先来自源文件解析，没有源文件时再退回条目快照字段。
    switch (kind) {
      case 'skills':
        return _buildSkillEditor(entry, sourceContent);
      case 'skill-groups':
        return _buildSkillGroupEditor(entry, sourceContent);
      case 'agent-groups':
        return _buildAgentGroupEditor(entry, sourceContent);
      case 'agents':
      default:
        return _buildAgentEditor(entry, sourceContent);
    }
  }

  ({String relativePath, String content, String oldRelativePath}) buildSavePlan(
    EcosystemEditorRequestViewData request,
  ) {
    // 中文注释: 保存计划只产出目标相对路径与渲染文本，真正写盘仍由控制器和宿主端口负责。
    final cleanId = _safeId(request.entryId);
    switch (request.kind) {
      case 'skills':
        return (
          relativePath: 'skills/$cleanId/SKILL.md',
          content: _skillRendererService.renderPackage(<String, Object?>{
            'id': cleanId,
            'name': request.name,
            'description': request.description,
            'activation_hints': _lines(request.activationHintsText),
            'inputs': _lines(request.inputsText),
            'outputs': _lines(request.outputsText),
            'required_capabilities': _lines(request.requiredCapabilitiesText),
            'optional_capabilities': _lines(request.optionalCapabilitiesText),
            'preferred_output': request.preferredOutput,
            'instruction_markdown': request.bodyMarkdown,
            'source': 'project_package',
          }),
          oldRelativePath: request.originalRelativePath,
        );
      case 'skill-groups':
        return (
          relativePath: 'skill_groups/$cleanId/skill_group.json',
          content: _skillGroupCodecService.encodeSkillGroup(<String, Object?>{
            'id': cleanId,
            'name': request.name,
            'description': request.description,
            'source': 'project',
            'skills': _lines(request.skillsText),
          }),
          oldRelativePath: request.originalRelativePath,
        );
      case 'agent-groups':
        return (
          relativePath: 'agent_groups/$cleanId/agent_group.json',
          content: _agentGroupCodecService.encodeAgentGroup(<String, Object?>{
            'id': cleanId,
            'name': request.name,
            'description': request.description,
            'source': 'project',
            'enabled': request.enabled,
            'orchestration': request.orchestration,
            'agents': _lines(request.agentsText),
          }),
          oldRelativePath: request.originalRelativePath,
        );
      case 'agents':
      default:
        return (
          relativePath: 'agents/$cleanId/AGENT.md',
          content: _agentRendererService.renderPackage(<String, Object?>{
            'id': cleanId,
            'name': request.name,
            'description': request.description,
            'role': request.role,
            'objective': request.objective,
            'can_do': _lines(request.canDoText),
            'must_not_do': _lines(request.mustNotDoText),
            'knowledge_sources': _lines(request.knowledgeSourcesText),
            'required_capabilities': _lines(request.requiredCapabilitiesText),
            'optional_capabilities': _lines(request.optionalCapabilitiesText),
            'preferred_output': request.preferredOutput,
            'skills': _lines(request.skillsText),
            'skill_groups': _lines(request.skillGroupsText),
            'operating_manual_markdown': request.bodyMarkdown,
            'system_prompt': request.bodyMarkdown,
            'source': 'project_package',
            'source_scope': 'project',
          }),
          oldRelativePath: request.originalRelativePath,
        );
    }
  }

  EcosystemEditorViewData _buildAgentEditor(
    JsonMap entry,
    String sourceContent,
  ) {
    final parsed = sourceContent.trim().isEmpty
        ? _agentProfileNormalizerService.normalizeAgentProfile(entry)
        : _agentParserService.parsePackage(
            sourceContent,
            fallbackId: ValueReaders.stringValue(entry['id']),
          );
    return EcosystemEditorViewData(
      kind: 'agents',
      title: '编辑智能体',
      entryId: ValueReaders.stringValue(parsed['id']),
      name: ValueReaders.stringValue(parsed['name']),
      description: ValueReaders.stringValue(parsed['description']),
      role: ValueReaders.stringValue(parsed['role']),
      objective: ValueReaders.stringValue(parsed['objective']),
      bodyMarkdown: ValueReaders.stringValue(
        parsed['operating_manual_markdown'],
        ValueReaders.stringValue(parsed['system_prompt']),
      ),
      badge: ValueReaders.stringValue(
        entry['source_scope'],
        ValueReaders.stringValue(entry['badge']),
      ),
      projectRelativePath: ValueReaders.stringValue(
        entry['project_relative_path'],
      ),
      skillsText: _joinLines(parsed['skills']),
      skillGroupsText: _joinLines(parsed['skill_groups']),
      agentsText: '',
      activationHintsText: '',
      inputsText: '',
      outputsText: '',
      canDoText: _joinLines(parsed['can_do']),
      mustNotDoText: _joinLines(parsed['must_not_do']),
      knowledgeSourcesText: _joinLines(parsed['knowledge_sources']),
      requiredCapabilitiesText: _joinLines(parsed['required_capabilities']),
      optionalCapabilitiesText: _joinLines(parsed['optional_capabilities']),
      preferredOutput: ValueReaders.stringValue(parsed['preferred_output']),
      orchestration: 'supervised',
      enabled: ValueReaders.boolValue(parsed['enabled_by_default']),
      statusMessage: '',
      isProjectEntry: ValueReaders.stringValue(
        entry['project_relative_path'],
      ).trim().isNotEmpty,
    );
  }

  EcosystemEditorViewData _buildSkillEditor(
    JsonMap entry,
    String sourceContent,
  ) {
    final parsed = sourceContent.trim().isEmpty
        ? _skillParserService.parsePackage(
            jsonEncode(entry),
            fallbackId: ValueReaders.stringValue(entry['id']),
          )
        : _skillParserService.parsePackage(
            sourceContent,
            fallbackId: ValueReaders.stringValue(entry['id']),
          );
    return EcosystemEditorViewData(
      kind: 'skills',
      title: '编辑技能',
      entryId: ValueReaders.stringValue(parsed['id']),
      name: ValueReaders.stringValue(parsed['name']),
      description: ValueReaders.stringValue(parsed['description']),
      role: '',
      objective: '',
      bodyMarkdown: ValueReaders.stringValue(parsed['instruction_markdown']),
      badge: ValueReaders.stringValue(
        entry['source_scope'],
        ValueReaders.stringValue(entry['badge']),
      ),
      projectRelativePath: ValueReaders.stringValue(
        entry['project_relative_path'],
      ),
      skillsText: '',
      skillGroupsText: '',
      agentsText: '',
      activationHintsText: _joinLines(parsed['activation_hints']),
      inputsText: _joinLines(parsed['inputs']),
      outputsText: _joinLines(parsed['outputs']),
      canDoText: '',
      mustNotDoText: '',
      knowledgeSourcesText: '',
      requiredCapabilitiesText: _joinLines(parsed['required_capabilities']),
      optionalCapabilitiesText: _joinLines(parsed['optional_capabilities']),
      preferredOutput: ValueReaders.stringValue(parsed['preferred_output']),
      orchestration: 'supervised',
      enabled: false,
      statusMessage: '',
      isProjectEntry: ValueReaders.stringValue(
        entry['project_relative_path'],
      ).trim().isNotEmpty,
    );
  }

  EcosystemEditorViewData _buildSkillGroupEditor(
    JsonMap entry,
    String sourceContent,
  ) {
    final parsed = sourceContent.trim().isEmpty
        ? _skillGroupNormalizerService.normalizeSkillGroup(entry)
        : _skillGroupNormalizerService.normalizeSkillGroup(
            ValueReaders.mapValue(jsonDecode(sourceContent)),
          );
    return EcosystemEditorViewData(
      kind: 'skill-groups',
      title: '编辑技能组',
      entryId: ValueReaders.stringValue(parsed['id']),
      name: ValueReaders.stringValue(parsed['name']),
      description: ValueReaders.stringValue(parsed['description']),
      role: '',
      objective: '',
      bodyMarkdown: '',
      badge: ValueReaders.stringValue(entry['source'], 'builtin'),
      projectRelativePath: ValueReaders.stringValue(
        entry['project_relative_path'],
      ),
      skillsText: _joinLines(parsed['skills']),
      skillGroupsText: '',
      agentsText: '',
      activationHintsText: '',
      inputsText: '',
      outputsText: '',
      canDoText: '',
      mustNotDoText: '',
      knowledgeSourcesText: '',
      requiredCapabilitiesText: '',
      optionalCapabilitiesText: '',
      preferredOutput: '',
      orchestration: 'supervised',
      enabled: false,
      statusMessage: '',
      isProjectEntry: ValueReaders.stringValue(
        entry['project_relative_path'],
      ).trim().isNotEmpty,
    );
  }

  EcosystemEditorViewData _buildAgentGroupEditor(
    JsonMap entry,
    String sourceContent,
  ) {
    final parsed = sourceContent.trim().isEmpty
        ? _agentGroupNormalizerService.normalizeAgentGroup(entry)
        : _agentGroupNormalizerService.normalizeAgentGroup(
            ValueReaders.mapValue(jsonDecode(sourceContent)),
          );
    return EcosystemEditorViewData(
      kind: 'agent-groups',
      title: '编辑智能体组',
      entryId: ValueReaders.stringValue(parsed['id']),
      name: ValueReaders.stringValue(parsed['name']),
      description: ValueReaders.stringValue(parsed['description']),
      role: '',
      objective: '',
      bodyMarkdown: '',
      badge: ValueReaders.stringValue(entry['source'], 'builtin'),
      projectRelativePath: ValueReaders.stringValue(
        entry['project_relative_path'],
      ),
      skillsText: '',
      skillGroupsText: '',
      agentsText: _joinLines(parsed['agents']),
      activationHintsText: '',
      inputsText: '',
      outputsText: '',
      canDoText: '',
      mustNotDoText: '',
      knowledgeSourcesText: '',
      requiredCapabilitiesText: '',
      optionalCapabilitiesText: '',
      preferredOutput: '',
      orchestration: ValueReaders.stringValue(
        parsed['orchestration'],
        'supervised',
      ),
      enabled: ValueReaders.boolValue(parsed['enabled']),
      statusMessage: '',
      isProjectEntry: ValueReaders.stringValue(
        entry['project_relative_path'],
      ).trim().isNotEmpty,
    );
  }

  List<String> _lines(String rawText) {
    return rawText
        .split(RegExp(r'\r?\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String _joinLines(Object? rawValue) {
    return ValueReaders.stringList(rawValue).join('\n');
  }

  String _safeId(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'custom_entry' : result;
  }
}
