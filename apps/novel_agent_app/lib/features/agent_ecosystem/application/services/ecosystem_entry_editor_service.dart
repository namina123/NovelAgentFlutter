import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/ecosystem_editor_view_data.dart';

class EcosystemEntryEditorService {
  EcosystemEntryEditorService({
    AgentMarkdownPackageParserService? agentParserService,
    SkillMarkdownPackageParserService? skillParserService,
    AgentGroupNormalizerService? agentGroupNormalizerService,
    SkillGroupNormalizerService? skillGroupNormalizerService,
    AgentProfileNormalizerService? agentProfileNormalizerService,
    AgentGroupValidatorService? agentGroupValidatorService,
    SkillGroupValidatorService? skillGroupValidatorService,
    AgentGroupMemberRoleService? agentGroupMemberRoleService,
    EcosystemAssetProposalService? proposalService,
    EcosystemAssetPathService? pathService,
  }) : _agentParserService =
           agentParserService ?? AgentMarkdownPackageParserService(),
       _skillParserService =
           skillParserService ?? SkillMarkdownPackageParserService(),
       _agentGroupNormalizerService =
           agentGroupNormalizerService ?? AgentGroupNormalizerService(),
       _skillGroupNormalizerService =
           skillGroupNormalizerService ?? SkillGroupNormalizerService(),
       _agentProfileNormalizerService =
           agentProfileNormalizerService ?? AgentProfileNormalizerService(),
       _agentGroupValidatorService =
           agentGroupValidatorService ?? AgentGroupValidatorService(),
       _skillGroupValidatorService =
           skillGroupValidatorService ?? SkillGroupValidatorService(),
       _agentGroupMemberRoleService =
           agentGroupMemberRoleService ?? const AgentGroupMemberRoleService(),
       _proposalService = proposalService ?? EcosystemAssetProposalService(),
       _pathService = pathService ?? EcosystemAssetPathService();

  final AgentMarkdownPackageParserService _agentParserService;
  final SkillMarkdownPackageParserService _skillParserService;
  final AgentGroupNormalizerService _agentGroupNormalizerService;
  final SkillGroupNormalizerService _skillGroupNormalizerService;
  final AgentProfileNormalizerService _agentProfileNormalizerService;
  final AgentGroupValidatorService _agentGroupValidatorService;
  final SkillGroupValidatorService _skillGroupValidatorService;
  final AgentGroupMemberRoleService _agentGroupMemberRoleService;
  final EcosystemAssetProposalService _proposalService;
  final EcosystemAssetPathService _pathService;

  EcosystemEditorViewData buildForEntry(
    JsonMap entry, {
    required String kind,
    String sourceContent = '',
  }) {
    // 中文注释: 编辑器默认值优先来自源文件解析，没有源文件时再退回条目快照字段。
    switch (kind) {
      case 'skills':
        return _decorateViewData(
          entry,
          _buildSkillEditor(entry, sourceContent),
        );
      case 'skill-groups':
        return _decorateViewData(
          entry,
          _buildSkillGroupEditor(entry, sourceContent),
        );
      case 'agent-groups':
        return _decorateViewData(
          entry,
          _buildAgentGroupEditor(entry, sourceContent),
        );
      case 'agents':
      default:
        return _decorateViewData(
          entry,
          _buildAgentEditor(entry, sourceContent),
        );
    }
  }

  EcosystemEditorReviewViewData reviewRequest(
    EcosystemEditorRequestViewData request,
  ) {
    final cleanId = _safeId(
      request.entryId.trim().isNotEmpty
          ? request.entryId
          : request.originalEntryId,
    );
    final assetPayload = _assetPayloadFromRequest(request, cleanId);
    final permissionBoundarySummary = _permissionBoundarySummary(
      request.kind,
      assetPayload,
    );
    final validationIssues = _validationIssues(request.kind, assetPayload);
    return EcosystemEditorReviewViewData(
      permissionBoundarySummary: permissionBoundarySummary,
      validationIssues: validationIssues,
      saveActionLabel: _saveActionLabelFor(
        kind: request.kind,
        originalRelativePath: request.originalRelativePath,
        isBuiltinEntry: _requestLooksBuiltin(request),
      ),
    );
  }

  ({
    String relativePath,
    String content,
    String oldRelativePath,
    bool deleteOldRelativePath,
    String statusMessage,
  })
  buildSavePlan(EcosystemEditorRequestViewData request) {
    // 中文注释: 非内置生态编辑统一落成 proposal 文件，避免编辑器直接绕过校验与确认进入正式安装目录。
    final cleanId = _safeId(request.entryId);
    final assetKind = _assetKindFor(request.kind);
    final assetPayload = _assetPayloadFromRequest(request, cleanId);
    final requiredCapabilities = _requiredCapabilitiesFor(request);
    final proposal = _proposalService.createDraft(
      assetKind: assetKind,
      assetId: cleanId,
      proposalId: _proposalIdFor(
        request.originalRelativePath,
        assetKind: assetKind,
        assetId: cleanId,
      ),
      version: ValueReaders.stringValue(assetPayload['version'], '1'),
      summary: _summaryFor(request, cleanId),
      riskNote: _riskNoteFor(request, requiredCapabilities),
      assetPayload: assetPayload,
      requiredCapabilities: requiredCapabilities,
      metadata: <String, Object?>{
        'origin_relative_path': request.originalRelativePath,
      },
    );
    final review = _proposalService.review(proposal);
    final relativePath = _pathService.proposalPath(
      kind: assetKind,
      proposalId: review.proposal.proposalId,
    );
    final oldRelativePath = _isProposalPath(request.originalRelativePath)
        ? request.originalRelativePath.trim()
        : '';
    final issuePreview = _reviewIssuePreview(review);
    final statusMessage = review.isValid
        ? (review.warnings.isEmpty
              ? '已保存为 validated proposal，等待确认安装。'
              : '已保存为 validated proposal，仍有 ${review.warnings.length} 条提醒：$issuePreview')
        : '已保存为 proposal，仍有 ${review.errors.length} 个校验问题待处理：$issuePreview';
    return (
      relativePath: relativePath,
      content: const JsonEncoder.withIndent(
        '  ',
      ).convert(review.proposal.toJson()),
      oldRelativePath: oldRelativePath,
      deleteOldRelativePath:
          oldRelativePath.isNotEmpty && oldRelativePath != relativePath,
      statusMessage: statusMessage,
    );
  }

  EcosystemEditorViewData _buildAgentEditor(
    JsonMap entry,
    String sourceContent,
  ) {
    final proposalPayload = _proposalAssetPayload(sourceContent);
    final parsed = proposalPayload.isNotEmpty
        ? _agentProfileNormalizerService.normalizeAgentProfile(proposalPayload)
        : sourceContent.trim().isEmpty
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
    final proposalPayload = _proposalAssetPayload(sourceContent);
    final parsed = proposalPayload.isNotEmpty
        ? _skillParserService.parsePackage(
            jsonEncode(proposalPayload),
            fallbackId: ValueReaders.stringValue(entry['id']),
          )
        : sourceContent.trim().isEmpty
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
    final proposalPayload = _proposalAssetPayload(sourceContent);
    final parsed = proposalPayload.isNotEmpty
        ? _skillGroupNormalizerService.normalizeSkillGroup(proposalPayload)
        : sourceContent.trim().isEmpty
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
    final proposalPayload = _proposalAssetPayload(sourceContent);
    final parsed = proposalPayload.isNotEmpty
        ? _agentGroupNormalizerService.normalizeAgentGroup(proposalPayload)
        : sourceContent.trim().isEmpty
        ? _agentGroupNormalizerService.normalizeAgentGroup(entry)
        : _agentGroupNormalizerService.normalizeAgentGroup(
            ValueReaders.mapValue(jsonDecode(sourceContent)),
          );
    final agentIds = _readAgentIdsFromGroup(parsed);
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
      agentsText: agentIds.join('\n'),
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
      primaryAgentIdText: _resolvedPrimaryAgentId(parsed, agentIds),
      requiredAgentIdsText: _joinLines(
        _readScopedIds(parsed, 'required_agent_ids'),
      ),
      optionalAgentIdsText: _joinLines(
        _readScopedIds(parsed, 'optional_agent_ids'),
      ),
    );
  }

  EcosystemEditorViewData _decorateViewData(
    JsonMap entry,
    EcosystemEditorViewData viewData,
  ) {
    final request = _requestFromViewData(viewData);
    final review = reviewRequest(request);
    final projectRelativePath = viewData.projectRelativePath.trim();
    final isBuiltinEntry = _isBuiltinEntry(
      entry,
      kind: viewData.kind,
      projectRelativePath: projectRelativePath,
    );
    return viewData.copyWith(
      isBuiltinEntry: isBuiltinEntry,
      sourceSummary: _sourceSummaryFor(
        kind: viewData.kind,
        isBuiltinEntry: isBuiltinEntry,
        projectRelativePath: projectRelativePath,
      ),
      permissionBoundarySummary: review.permissionBoundarySummary,
      validationIssues: review.validationIssues,
      saveActionLabel: _saveActionLabelFor(
        kind: viewData.kind,
        originalRelativePath: projectRelativePath,
        isBuiltinEntry: isBuiltinEntry,
      ),
      deleteActionLabel: _deleteActionLabelFor(projectRelativePath),
    );
  }

  EcosystemEditorRequestViewData _requestFromViewData(
    EcosystemEditorViewData viewData,
  ) {
    return EcosystemEditorRequestViewData(
      kind: viewData.kind,
      originalEntryId: viewData.entryId,
      originalRelativePath: viewData.projectRelativePath,
      entryId: viewData.entryId,
      name: viewData.name,
      description: viewData.description,
      role: viewData.role,
      objective: viewData.objective,
      bodyMarkdown: viewData.bodyMarkdown,
      skillsText: viewData.skillsText,
      skillGroupsText: viewData.skillGroupsText,
      agentsText: viewData.agentsText,
      activationHintsText: viewData.activationHintsText,
      inputsText: viewData.inputsText,
      outputsText: viewData.outputsText,
      canDoText: viewData.canDoText,
      mustNotDoText: viewData.mustNotDoText,
      knowledgeSourcesText: viewData.knowledgeSourcesText,
      requiredCapabilitiesText: viewData.requiredCapabilitiesText,
      optionalCapabilitiesText: viewData.optionalCapabilitiesText,
      preferredOutput: viewData.preferredOutput,
      orchestration: viewData.orchestration,
      enabled: viewData.enabled,
      primaryAgentIdText: viewData.primaryAgentIdText,
      requiredAgentIdsText: viewData.requiredAgentIdsText,
      optionalAgentIdsText: viewData.optionalAgentIdsText,
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

  EcosystemAssetKind _assetKindFor(String kind) {
    switch (kind) {
      case 'skills':
        return EcosystemAssetKind.skill;
      case 'skill-groups':
        return EcosystemAssetKind.skillGroup;
      case 'agent-groups':
        return EcosystemAssetKind.agentGroup;
      case 'agents':
      default:
        return EcosystemAssetKind.agent;
    }
  }

  JsonMap _assetPayloadFromRequest(
    EcosystemEditorRequestViewData request,
    String cleanId,
  ) {
    switch (request.kind) {
      case 'skills':
        return _skillParserService.parsePackage(
          jsonEncode(<String, Object?>{
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
            'source_scope': 'proposal',
          }),
          fallbackId: cleanId,
        );
      case 'skill-groups':
        return _skillGroupNormalizerService
            .normalizeSkillGroup(<String, Object?>{
              'id': cleanId,
              'name': request.name,
              'description': request.description,
              'version': '1',
              'source': 'proposal',
              'skills': _lines(request.skillsText),
            });
      case 'agent-groups':
        final agentIds = _lines(request.agentsText);
        final primaryAgentId = request.primaryAgentIdText.trim();
        final requiredAgentIds = _lines(request.requiredAgentIdsText);
        final optionalAgentIds = _lines(request.optionalAgentIdsText);
        return _agentGroupNormalizerService
            .normalizeAgentGroup(<String, Object?>{
              'id': cleanId,
              'name': request.name,
              'description': request.description,
              'version': '1',
              'source': 'proposal',
              'enabled': request.enabled,
              'orchestration': request.orchestration,
              'agents': agentIds,
              'primary_agent_id': primaryAgentId,
              'required_agent_ids': requiredAgentIds,
              'optional_agent_ids': optionalAgentIds,
              'member_roles': _memberRolesForRequest(
                agentIds: agentIds,
                primaryAgentId: primaryAgentId,
                requiredAgentIds: requiredAgentIds,
                optionalAgentIds: optionalAgentIds,
              ),
            });
      case 'agents':
      default:
        return _agentProfileNormalizerService
            .normalizeAgentProfile(<String, Object?>{
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
              'source_scope': 'proposal',
            });
    }
  }

  JsonMap _memberRolesForRequest({
    required List<String> agentIds,
    required String primaryAgentId,
    required List<String> requiredAgentIds,
    required List<String> optionalAgentIds,
  }) {
    final roles = <String, Object?>{};
    for (final agentId in agentIds) {
      if (agentId == primaryAgentId) {
        roles[agentId] = 'primary';
      } else if (optionalAgentIds.contains(agentId)) {
        roles[agentId] = 'optional';
      } else if (requiredAgentIds.contains(agentId)) {
        roles[agentId] = 'required';
      }
    }
    return roles;
  }

  List<String> _requiredCapabilitiesFor(
    EcosystemEditorRequestViewData request,
  ) {
    switch (request.kind) {
      case 'skills':
      case 'agents':
        return _lines(request.requiredCapabilitiesText);
      case 'skill-groups':
      case 'agent-groups':
      default:
        return const <String>[];
    }
  }

  String _summaryFor(EcosystemEditorRequestViewData request, String cleanId) {
    final description = request.description.trim();
    if (description.isNotEmpty) {
      return description;
    }
    final name = request.name.trim();
    if (name.isNotEmpty) {
      return '非内置${_kindLabel(request.kind)}草案：$name';
    }
    return '非内置${_kindLabel(request.kind)}草案：$cleanId';
  }

  String _riskNoteFor(
    EcosystemEditorRequestViewData request,
    List<String> requiredCapabilities,
  ) {
    final capabilityLabel = requiredCapabilities.isEmpty
        ? '未声明额外能力'
        : '声明能力需求：${requiredCapabilities.join('、')}';
    return '该${_kindLabel(request.kind)}来自非内置 proposal，安装前需人工确认；$capabilityLabel，且不会自动授予高风险权限。';
  }

  String _kindLabel(String kind) {
    switch (kind) {
      case 'skills':
        return '技能';
      case 'skill-groups':
        return '技能组';
      case 'agent-groups':
        return '智能体组';
      case 'agents':
      default:
        return '智能体';
    }
  }

  String _proposalIdFor(
    String originalRelativePath, {
    required EcosystemAssetKind assetKind,
    required String assetId,
  }) {
    final cleanPath = originalRelativePath.trim().replaceAll('\\', '/');
    if (_isProposalPath(cleanPath) && cleanPath.endsWith('.json')) {
      final fileName = cleanPath.split('/').last;
      return fileName.substring(0, fileName.length - '.json'.length);
    }
    return _pathService.defaultProposalId(kind: assetKind, assetId: assetId);
  }

  bool _isProposalPath(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .startsWith('.novel_agent/ecosystem/proposals/');
  }

  JsonMap _proposalAssetPayload(String sourceContent) {
    final text = sourceContent.trim();
    if (text.isEmpty || !text.startsWith('{')) {
      return const <String, Object?>{};
    }
    try {
      final decoded = ValueReaders.mapValue(jsonDecode(text));
      if (ValueReaders.stringValue(decoded['proposal_id']).trim().isEmpty) {
        return const <String, Object?>{};
      }
      final proposal = EcosystemAssetProposal.fromJson(decoded);
      return proposal.assetPayload;
    } catch (_) {
      return const <String, Object?>{};
    }
  }

  String _safeId(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'custom_entry' : result;
  }

  bool _isBuiltinEntry(
    JsonMap entry, {
    required String kind,
    required String projectRelativePath,
  }) {
    if (projectRelativePath.isNotEmpty) {
      return false;
    }
    final sourceScope = ValueReaders.stringValue(entry['source_scope']).trim();
    final source = ValueReaders.stringValue(entry['source']).trim();
    if (source == 'builtin' ||
        sourceScope == 'builtin' ||
        sourceScope == 'package') {
      return true;
    }
    return kind == 'skill-groups' || kind == 'agent-groups';
  }

  bool _requestLooksBuiltin(EcosystemEditorRequestViewData request) {
    return request.originalRelativePath.trim().isEmpty &&
        (request.kind == 'skill-groups' || request.kind == 'agent-groups');
  }

  String _sourceSummaryFor({
    required String kind,
    required bool isBuiltinEntry,
    required String projectRelativePath,
  }) {
    if (isBuiltinEntry && (kind == 'skill-groups' || kind == 'agent-groups')) {
      return '内置资产不能原地改写，复制后会保存为项目草案。';
    }
    if (_isProposalPath(projectRelativePath)) {
      return '当前编辑的是项目草案，保存后会继续写回 proposal，仍需确认安装。';
    }
    if (projectRelativePath.isNotEmpty) {
      return '当前条目来自项目覆盖，保存后会转成项目草案，避免绕过确认流程。';
    }
    return '当前编辑内容会保存为项目草案，安装前仍需确认。';
  }

  String _saveActionLabelFor({
    required String kind,
    required String originalRelativePath,
    required bool isBuiltinEntry,
  }) {
    if (isBuiltinEntry && (kind == 'skill-groups' || kind == 'agent-groups')) {
      return '复制为项目草案';
    }
    if (_isProposalPath(originalRelativePath)) {
      return '更新项目草案';
    }
    return '保存为项目草案';
  }

  String _deleteActionLabelFor(String projectRelativePath) {
    return _isProposalPath(projectRelativePath) ? '删除项目草案' : '删除项目覆盖';
  }

  String _permissionBoundarySummary(String kind, JsonMap payload) {
    switch (kind) {
      case 'skills':
      case 'agents':
        final required = ValueReaders.stringList(
          payload['required_capabilities'],
        );
        final optional = ValueReaders.stringList(
          payload['optional_capabilities'],
        );
        if (required.isEmpty && optional.isEmpty) {
          return '当前配置没有额外权限要求，会沿用默认安全边界。';
        }
        final labels = const SkillCapabilityCatalogService();
        final parts = <String>[];
        if (required.isNotEmpty) {
          parts.add('必需能力：${required.map(labels.displayLabel).join('、')}');
        }
        if (optional.isNotEmpty) {
          parts.add('可选能力：${optional.map(labels.displayLabel).join('、')}');
        }
        return '${parts.join('；')}。未满足的能力会在装载或运行时被阻止或降级。';
      case 'skill-groups':
        return '技能组只聚合技能，不会因为复制或绑定就自动扩大权限；真正的权限边界仍由成员技能声明决定。';
      case 'agent-groups':
        return '智能体组只定义成员与主次关系，不直接授予工具权限；真正的权限边界仍以成员技能装载和运行配置为准。';
      default:
        return '';
    }
  }

  List<String> _validationIssues(String kind, JsonMap payload) {
    switch (kind) {
      case 'skill-groups':
        return _reviewIssues(_skillGroupValidatorService.validate(payload));
      case 'agent-groups':
        return <String>[
          ..._reviewIssues(_agentGroupValidatorService.validate(payload)),
          ..._agentGroupConfigIssues(payload),
        ];
      default:
        return const <String>[];
    }
  }

  List<String> _reviewIssues(JsonMap review) {
    return <String>[
      ...ValueReaders.stringList(review['errors']),
      ...ValueReaders.stringList(review['warnings']),
    ];
  }

  List<String> _agentGroupConfigIssues(JsonMap group) {
    final agentIds = _readAgentIdsFromGroup(group);
    if (agentIds.isEmpty) {
      return const <String>[];
    }
    final issues = <String>[];
    final primaryCandidates = _readPrimaryAgentCandidates(group);
    if (primaryCandidates.isEmpty) {
      issues.add('还没有显式设置主智能体，当前只会回退到首成员。');
    }
    if (primaryCandidates.length > 1) {
      issues.add('检测到多个主智能体声明，请只保留一个 primary agent。');
    }
    if (primaryCandidates.isNotEmpty &&
        !agentIds.contains(_resolvedPrimaryAgentId(group, agentIds))) {
      issues.add('当前主智能体不在成员列表中，运行时无法正确落位。');
    }
    final requiredAgentIds = _readScopedIds(group, 'required_agent_ids');
    final optionalAgentIds = _readScopedIds(group, 'optional_agent_ids');
    final overlap = requiredAgentIds
        .where(optionalAgentIds.contains)
        .toList(growable: false);
    if (overlap.isNotEmpty) {
      issues.add('同一个成员不能同时标成必需和可选：${overlap.join('、')}。');
    }
    final unknownScopedIds = <String>{
      ...requiredAgentIds.where((item) => !agentIds.contains(item)),
      ...optionalAgentIds.where((item) => !agentIds.contains(item)),
    }.toList(growable: false);
    if (unknownScopedIds.isNotEmpty) {
      issues.add('以下成员不在当前组内，无法标记为必需或可选：${unknownScopedIds.join('、')}。');
    }
    return issues;
  }

  List<String> _readAgentIdsFromGroup(JsonMap group) {
    return ValueReaders.stringList(group['agents']);
  }

  String _resolvedPrimaryAgentId(JsonMap group, List<String> agentIds) {
    return _agentGroupMemberRoleService.resolvePrimaryAgentId(group, agentIds);
  }

  List<String> _readScopedIds(JsonMap group, String key) {
    final metadata = ValueReaders.mapValue(group['metadata']);
    final direct = ValueReaders.stringList(group[key]);
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.stringList(metadata[key]);
  }

  List<String> _readPrimaryAgentCandidates(JsonMap group) {
    final metadata = ValueReaders.mapValue(group['metadata']);
    final candidates = <String>{
      ValueReaders.stringValue(group['primary_agent_id']).trim(),
      ValueReaders.stringValue(metadata['primary_agent_id']).trim(),
    }..remove('');
    final memberRoles = ValueReaders.mapValue(group['member_roles']).isNotEmpty
        ? ValueReaders.mapValue(group['member_roles'])
        : ValueReaders.mapValue(metadata['member_roles']);
    memberRoles.forEach((key, value) {
      if (ValueReaders.stringValue(value).trim().toLowerCase() == 'primary') {
        candidates.add(key.trim());
      }
    });
    return candidates.toList(growable: false);
  }

  String _reviewIssuePreview(EcosystemAssetProposalReview review) {
    final issues = review.errors.isNotEmpty ? review.errors : review.warnings;
    if (issues.isEmpty) {
      return '';
    }
    return issues.take(3).join('；');
  }
}

class EcosystemEditorReviewViewData {
  const EcosystemEditorReviewViewData({
    required this.permissionBoundarySummary,
    required this.validationIssues,
    required this.saveActionLabel,
  });

  final String permissionBoundarySummary;
  final List<String> validationIssues;
  final String saveActionLabel;
}
