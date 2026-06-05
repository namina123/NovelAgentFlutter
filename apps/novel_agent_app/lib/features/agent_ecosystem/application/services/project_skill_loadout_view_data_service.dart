import 'package:novel_agent_core/novel_agent_core.dart';

import 'ecosystem_display_name_resolver_service.dart';
import '../../presentation/models/project_skill_loadout_view_data.dart';
import '../models/project_skill_loadout_workspace_snapshot.dart';

class ProjectSkillLoadoutViewDataService {
  ProjectSkillLoadoutViewDataService({
    AgentSkillLoadoutResolverService? resolverService,
    AgentDisplayNameResolverService? agentDisplayNameResolverService,
    SkillDisplayNameResolverService? skillDisplayNameResolverService,
    SkillCapabilityRequirementService? skillCapabilityRequirementService,
  }) : _resolverService = resolverService ?? AgentSkillLoadoutResolverService(),
       _agentDisplayNameResolverService =
           agentDisplayNameResolverService ??
           const AgentDisplayNameResolverService(),
       _skillDisplayNameResolverService =
           skillDisplayNameResolverService ??
           const SkillDisplayNameResolverService(),
       _skillCapabilityRequirementService =
           skillCapabilityRequirementService ??
           SkillCapabilityRequirementService();

  final AgentSkillLoadoutResolverService _resolverService;
  final AgentDisplayNameResolverService _agentDisplayNameResolverService;
  final SkillDisplayNameResolverService _skillDisplayNameResolverService;
  final SkillCapabilityRequirementService _skillCapabilityRequirementService;

  ProjectSkillLoadoutWorkspaceViewData build({
    required bool projectAvailable,
    required ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    required List<JsonMap> agents,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required String selectedAgentId,
    required String statusMessage,
  }) {
    // 中文注释: 这个投影层负责把 loadout 草稿、历史、解析结果压成页面可直接渲染的轻量结构。
    final browserItems = agents
        .map(
          (agent) => _browserItem(
            agent: agent,
            snapshot: snapshot,
            skills: skills,
            skillGroups: skillGroups,
            isSelected:
                ValueReaders.stringValue(agent['id']).trim() ==
                selectedAgentId.trim(),
          ),
        )
        .toList(growable: false);
    final detail = _detail(
      projectAvailable: projectAvailable,
      snapshot: snapshot,
      agents: agents,
      skills: skills,
      skillGroups: skillGroups,
      selectedAgentId: selectedAgentId,
    );
    return ProjectSkillLoadoutWorkspaceViewData(
      browserItems: browserItems,
      detail: detail,
      projectAvailable: projectAvailable,
      statusMessage: statusMessage,
    );
  }

  ProjectSkillLoadoutBrowserItemViewData _browserItem({
    required JsonMap agent,
    required ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required bool isSelected,
  }) {
    final agentId = ValueReaders.stringValue(agent['id']).trim();
    final resolved = _resolvedLoadout(
      agent: agent,
      snapshot: snapshot,
      skillGroups: skillGroups,
      availableSkillIds: _skillIds(skills),
      availableSkills: skills,
      agentId: agentId,
    );
    final draft = _draftFor(snapshot, agentId);
    final title = _agentDisplayNameResolverService.resolve(agent);
    return ProjectSkillLoadoutBrowserItemViewData(
      agentId: agentId,
      title: title,
      subtitle: agentId,
      badge: _sourceLabel(resolved.source),
      description:
          '${draft.skillGroupIds.length} 组 / ${draft.extraSkillIds.length} 额外 / ${draft.disabledSkillIds.length} 禁用 / ${resolved.finalSkillIds.length} 最终技能',
      isSelected: isSelected,
    );
  }

  ProjectSkillLoadoutDetailViewData? _detail({
    required bool projectAvailable,
    required ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    required List<JsonMap> agents,
    required List<JsonMap> skills,
    required List<JsonMap> skillGroups,
    required String selectedAgentId,
  }) {
    final cleanAgentId = selectedAgentId.trim();
    if (cleanAgentId.isEmpty) {
      return null;
    }
    JsonMap selectedAgent = const <String, Object?>{};
    for (final agent in agents) {
      if (ValueReaders.stringValue(agent['id']).trim() == cleanAgentId) {
        selectedAgent = agent;
        break;
      }
    }
    if (selectedAgent.isEmpty) {
      return null;
    }
    final skillNameById = _skillNameMap(skills);
    final skillGroupNameById = _skillGroupNameMap(skillGroups);
    final draft = _draftFor(snapshot, cleanAgentId);
    final saved = _savedFor(snapshot, cleanAgentId);
    final resolved = _resolvedLoadout(
      agent: selectedAgent,
      snapshot: snapshot,
      skillGroups: skillGroups,
      availableSkillIds: _skillIds(skills),
      availableSkills: skills,
      agentId: cleanAgentId,
    );
    final unavailableSkillIds = _unavailableSkillIds(resolved.issues);
    final historyEntries = snapshot.historyEntries
        .where((entry) => entry.agentId == cleanAgentId)
        .map(
          (entry) => ProjectSkillLoadoutHistoryItemViewData(
            id: entry.id,
            title: entry.title,
            subtitle: entry.createdAt,
            summary:
                '${entry.loadout.skillGroupIds.length} 组 / ${entry.loadout.extraSkillIds.length} 额外 / ${entry.loadout.disabledSkillIds.length} 禁用',
          ),
        )
        .toList(growable: false);
    return ProjectSkillLoadoutDetailViewData(
      agentId: cleanAgentId,
      agentName: _agentDisplayNameResolverService.resolve(selectedAgent),
      agentDescription: projectAvailable
          ? ValueReaders.stringValue(
              selectedAgent['description'],
              '当前项目内调整这个智能体的实际技能装载。',
            )
          : '请先创建或打开项目，才能调整项目级技能装载。',
      sourceLabel: _sourceLabel(resolved.source),
      summary:
          '技能组 ${draft.skillGroupIds.length} 个，额外技能 ${draft.extraSkillIds.length} 个，禁用技能 ${draft.disabledSkillIds.length} 个。',
      expressionConstraintSummary:
          '去 AI / 真实性 / 叙事边界这类内容不属于技能装载，请从“表达限制”进入项目级约束系统，并可继续按当前智能体定向绑定。',
      hasPendingChanges: !_sameLoadout(draft, saved),
      skillGroups: skillGroups
          .map(
            (group) => ProjectSkillLoadoutSelectableItemViewData(
              id: ValueReaders.stringValue(group['id']),
              title: _skillDisplayNameResolverService.resolveGroup(group),
              subtitle: ValueReaders.stringValue(group['description'], '技能组'),
              selected: draft.skillGroupIds.contains(
                ValueReaders.stringValue(group['id']),
              ),
            ),
          )
          .toList(growable: false),
      extraSkills: skills
          .map(
            (skill) => ProjectSkillLoadoutSelectableItemViewData(
              id: ValueReaders.stringValue(skill['id']),
              title: _skillDisplayNameResolverService.resolveSkill(skill),
              subtitle: ValueReaders.stringValue(
                skill['description'],
                ValueReaders.stringValue(skill['source_scope']),
              ),
              selected: draft.extraSkillIds.contains(
                ValueReaders.stringValue(skill['id']),
              ),
            ),
          )
          .toList(growable: false),
      resolvedSkills: _sortedResolvedSkills(
        resolved.entries
            .map(
              (entry) => ProjectSkillLoadoutResolvedSkillViewData(
                id: entry.skillId,
                title: skillNameById[entry.skillId] ?? entry.skillId,
                sourceSummary: _sourceSummary(
                  entry.sources,
                  skillGroupNameById: skillGroupNameById,
                ),
                enabled: entry.enabled,
                isUnavailable: unavailableSkillIds.contains(entry.skillId),
                statusLabel: unavailableSkillIds.contains(entry.skillId)
                    ? '当前不可用'
                    : (!entry.enabled ? '已停用' : '已启用'),
              ),
            )
            .toList(growable: false),
      ),
      historyEntries: historyEntries,
      issues: resolved.issues.map(_issueText).toList(growable: false),
      permissionBoundarySummary: _permissionBoundarySummary(
        resolved,
        skills: skills,
      ),
    );
  }

  AgentSkillLoadout _draftFor(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    String agentId,
  ) {
    return snapshot.draftLoadouts[agentId] ??
        snapshot.savedLoadouts.firstWhere(
          (item) => item.agentId == agentId,
          orElse: () => AgentSkillLoadout(
            agentId: agentId,
            source: AgentSkillLoadoutSource.projectSelection,
          ),
        );
  }

  AgentSkillLoadout? _savedFor(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    String agentId,
  ) {
    for (final loadout in snapshot.savedLoadouts) {
      if (loadout.agentId == agentId) {
        return loadout;
      }
    }
    return null;
  }

  ResolvedAgentSkillLoadout _resolvedLoadout({
    required JsonMap agent,
    required ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    required List<JsonMap> skillGroups,
    required List<String> availableSkillIds,
    required List<JsonMap> availableSkills,
    required String agentId,
  }) {
    return _resolverService.resolveAgentDocument(
      agent,
      loadout: _draftFor(snapshot, agentId),
      availableSkillGroups: skillGroups,
      availableSkillIds: availableSkillIds,
      availableSkills: availableSkills,
    );
  }

  Map<String, String> _skillNameMap(List<JsonMap> items) {
    return <String, String>{
      for (final item in items)
        ValueReaders.stringValue(item['id']): _skillDisplayNameResolverService
            .resolveSkill(item),
    };
  }

  Map<String, String> _skillGroupNameMap(List<JsonMap> items) {
    return <String, String>{
      for (final item in items)
        ValueReaders.stringValue(item['id']): _skillDisplayNameResolverService
            .resolveGroup(item),
    };
  }

  List<String> _skillIds(List<JsonMap> skills) {
    return skills
        .map((item) => ValueReaders.stringValue(item['id']).trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _sourceLabel(AgentSkillLoadoutSource source) {
    switch (source) {
      case AgentSkillLoadoutSource.historyRestore:
        return '历史恢复';
      case AgentSkillLoadoutSource.savedPreset:
        return '预设装载';
      case AgentSkillLoadoutSource.adHoc:
        return '临时装载';
      case AgentSkillLoadoutSource.projectSelection:
        return '项目装载';
      case AgentSkillLoadoutSource.agentDefault:
        return '默认声明';
    }
  }

  String _sourceSummary(
    List<ResolvedAgentSkillLoadoutEntrySource> sources, {
    required Map<String, String> skillGroupNameById,
  }) {
    final labels = <String>[];
    for (final source in sources) {
      switch (source.kind) {
        case ResolvedAgentSkillLoadoutEntrySourceKind.profileDirectSkill:
          labels.add('默认技能');
          break;
        case ResolvedAgentSkillLoadoutEntrySourceKind.profileSkillGroup:
          labels.add(
            '默认组:${skillGroupNameById[source.referenceId] ?? source.referenceId}',
          );
          break;
        case ResolvedAgentSkillLoadoutEntrySourceKind.loadoutDirectSkill:
          labels.add('额外技能');
          break;
        case ResolvedAgentSkillLoadoutEntrySourceKind.loadoutSkillGroup:
          labels.add(
            '项目组:${skillGroupNameById[source.referenceId] ?? source.referenceId}',
          );
          break;
      }
    }
    return labels.join(' / ');
  }

  String _issueText(AgentSkillLoadoutIssue issue) {
    if (issue.message.trim().isNotEmpty) {
      return issue.message.trim();
    }
    switch (issue.code) {
      case AgentSkillLoadoutIssueCode.missingSkillGroup:
        return '缺少技能组：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.unavailableSkill:
        return '当前不可用技能：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.builtinToolFiltered:
        return '已过滤内置工具技能：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.disabledSkillMissingTarget:
        return '禁用项没有命中任何技能：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.requiredCapabilityMissing:
        return '技能权限不匹配：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.optionalCapabilityUnavailable:
        return '技能可选权限当前不可用：${issue.subjectId}';
      case AgentSkillLoadoutIssueCode.degradedCapabilityRequirement:
        return '技能已降级为受限路径：${issue.subjectId}';
    }
  }

  String _permissionBoundarySummary(
    ResolvedAgentSkillLoadout resolved, {
    required List<JsonMap> skills,
  }) {
    final requirementBySkillId = _skillCapabilityRequirementService.indexBySkillId(
      skills,
    );
    var skillsWithCapabilityRequirements = 0;
    final requiredCapabilities = <String>{};
    final optionalCapabilities = <String>{};
    for (final entry in resolved.entries) {
      final requirement = requirementBySkillId[entry.skillId];
      if (requirement == null || requirement.isEmpty) {
        continue;
      }
      final required = ValueReaders.stringList(
        requirement['required_capabilities'],
      );
      final optional = ValueReaders.stringList(
        requirement['optional_capabilities'],
      );
      if (required.isEmpty && optional.isEmpty) {
        continue;
      }
      skillsWithCapabilityRequirements += 1;
      requiredCapabilities.addAll(required);
      optionalCapabilities.addAll(optional);
    }
    if (skillsWithCapabilityRequirements == 0) {
      return '当前装载没有额外权限需求；绑定或解绑技能时不会扩大默认权限边界。';
    }
    final parts = <String>[
      '当前装载有 $skillsWithCapabilityRequirements 个技能声明了权限边界',
      if (requiredCapabilities.isNotEmpty)
        '必需能力：${requiredCapabilities.map(_capabilityLabel).join('、')}',
      if (optionalCapabilities.isNotEmpty)
        '可选能力：${optionalCapabilities.map(_capabilityLabel).join('、')}',
    ];
    return '${parts.join('；')}。未授予的能力会自动转成降级或阻止装载。';
  }

  String _capabilityLabel(String capabilityId) {
    return const SkillCapabilityCatalogService().displayLabel(capabilityId);
  }

  bool _sameLoadout(AgentSkillLoadout left, AgentSkillLoadout? right) {
    if (right == null) {
      return left.isEmpty;
    }
    return _sameStringList(left.skillGroupIds, right.skillGroupIds) &&
        _sameStringList(left.extraSkillIds, right.extraSkillIds) &&
        _sameStringList(left.disabledSkillIds, right.disabledSkillIds);
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) {
        return false;
      }
    }
    return true;
  }

  Set<String> _unavailableSkillIds(List<AgentSkillLoadoutIssue> issues) {
    final ids = <String>{};
    for (final issue in issues) {
      if (issue.code != AgentSkillLoadoutIssueCode.unavailableSkill) {
        continue;
      }
      final skillId = issue.subjectId.trim();
      if (skillId.isNotEmpty) {
        ids.add(skillId);
      }
    }
    return ids;
  }

  List<ProjectSkillLoadoutResolvedSkillViewData> _sortedResolvedSkills(
    List<ProjectSkillLoadoutResolvedSkillViewData> items,
  ) {
    final next = List<ProjectSkillLoadoutResolvedSkillViewData>.from(items);
    next.sort((left, right) {
      final leftRank = _resolvedSkillRank(left);
      final rightRank = _resolvedSkillRank(right);
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
      return left.title.compareTo(right.title);
    });
    return next;
  }

  int _resolvedSkillRank(ProjectSkillLoadoutResolvedSkillViewData item) {
    if (item.isUnavailable) {
      return 2;
    }
    if (!item.enabled) {
      return 1;
    }
    return 0;
  }
}
