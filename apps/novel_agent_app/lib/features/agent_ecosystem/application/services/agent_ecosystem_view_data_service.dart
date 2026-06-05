import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/runtime_exposure_policy_service.dart';
import 'ecosystem_display_name_resolver_service.dart';
import '../../presentation/models/agent_ecosystem_view_data.dart';
import '../../presentation/models/project_skill_loadout_view_data.dart';
import '../models/agent_ecosystem_snapshot.dart';

class AgentEcosystemViewDataService {
  AgentEcosystemViewDataService({
    AgentDisplayNameResolverService? agentDisplayNameResolverService,
    SkillDisplayNameResolverService? skillDisplayNameResolverService,
    AgentGroupMemberRoleService? agentGroupMemberRoleService,
    AgentGroupValidatorService? agentGroupValidatorService,
    SkillGroupValidatorService? skillGroupValidatorService,
    RuntimeExposurePolicyService? runtimeExposurePolicyService,
    RuntimeExposureTier exposureTier = RuntimeExposureTier.standard,
  }) : _agentDisplayNameResolverService =
           agentDisplayNameResolverService ??
           const AgentDisplayNameResolverService(),
       _skillDisplayNameResolverService =
           skillDisplayNameResolverService ??
           const SkillDisplayNameResolverService(),
       _agentGroupMemberRoleService =
           agentGroupMemberRoleService ?? const AgentGroupMemberRoleService(),
       _agentGroupValidatorService =
           agentGroupValidatorService ?? AgentGroupValidatorService(),
       _skillGroupValidatorService =
           skillGroupValidatorService ?? SkillGroupValidatorService(),
       _runtimeExposurePolicyService =
           runtimeExposurePolicyService ?? const RuntimeExposurePolicyService(),
       _exposureTier = exposureTier;

  final AgentDisplayNameResolverService _agentDisplayNameResolverService;
  final SkillDisplayNameResolverService _skillDisplayNameResolverService;
  final AgentGroupMemberRoleService _agentGroupMemberRoleService;
  final AgentGroupValidatorService _agentGroupValidatorService;
  final SkillGroupValidatorService _skillGroupValidatorService;
  final RuntimeExposurePolicyService _runtimeExposurePolicyService;
  final RuntimeExposureTier _exposureTier;

  AgentEcosystemViewData build(
    AgentEcosystemSnapshot snapshot, {
    ProjectSkillLoadoutWorkspaceViewData? projectSkillLoadoutViewData,
  }) {
    // 中文注释: 生态页展示模型统一在这里投影，避免控制器自己处理每个 tab 的标题、徽标和描述文案。
    final activeTabId = snapshot.activeTabId;
    final rawEntries = snapshot.entriesForTab(activeTabId);
    final selectedEntryId = _resolvedSelectedEntryId(snapshot, rawEntries);
    final entries =
        activeTabId == 'skill-loadouts' && projectSkillLoadoutViewData != null
        ? projectSkillLoadoutViewData.browserItems
              .map(
                (item) => EcosystemEntryViewData(
                  id: item.agentId,
                  kind: activeTabId,
                  title: item.title,
                  subtitle: _projectedSubtitle(item.agentId, item.subtitle),
                  badge: item.badge,
                  description: item.description,
                  sourcePath: '',
                  projectRelativePath: '',
                  isEditable: false,
                  isSelected: item.isSelected,
                ),
              )
              .toList(growable: false)
        : rawEntries
              .map(
                (entry) => _mapEntry(
                  activeTabId,
                  entry,
                  isSelected:
                      ValueReaders.stringValue(entry['id']).trim() ==
                      selectedEntryId,
                ),
              )
              .toList(growable: false);
    return AgentEcosystemViewData(
      activeTabId: activeTabId,
      tabs: AgentEcosystemViewData.initial().tabs,
      entries: entries,
      projectSkillLoadoutViewData: projectSkillLoadoutViewData,
    );
  }

  String _resolvedSelectedEntryId(
    AgentEcosystemSnapshot snapshot,
    List<JsonMap> rawEntries,
  ) {
    final currentSelection = snapshot.selectedEntryIdForTab(
      snapshot.activeTabId,
    );
    if (currentSelection.trim().isNotEmpty) {
      return currentSelection;
    }
    if (rawEntries.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(rawEntries.first['id']).trim();
  }

  EcosystemEntryViewData _mapEntry(
    String tabId,
    JsonMap entry, {
    required bool isSelected,
  }) {
    final id = ValueReaders.stringValue(entry['id']).trim();
    final name = _entryDisplayName(tabId, entry, fallbackId: id);
    final sourcePath = ValueReaders.stringValue(
      entry['entry_file_path'],
    ).trim();
    final projectRelativePath = ValueReaders.stringValue(
      entry['project_relative_path'],
    ).trim();
    final sourceLabel = _sourceLabel(
      entry,
      sourcePath: sourcePath,
      projectRelativePath: projectRelativePath,
    );
    final canDuplicateBuiltin = _canDuplicateBuiltin(
      tabId,
      entry,
      projectRelativePath: projectRelativePath,
    );
    final isEditable = projectRelativePath.isNotEmpty || canDuplicateBuiltin;
    final exposesInternal = _runtimeExposurePolicyService
        .exposesInternalRuntimeTerms(_exposureTier);
    final exposesSource = _runtimeExposurePolicyService.exposesFileSystemSource(
      _exposureTier,
    );
    final permissionBoundarySummary = _permissionBoundarySummary(tabId, entry);
    final validationIssues = _validationIssues(tabId, entry);
    switch (tabId) {
      case 'skills':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: _projectedSubtitle(id, id),
          badge: sourceLabel,
          description: _nonEmpty(
            ValueReaders.stringValue(entry['description']),
            ValueReaders.stringValue(entry['preferred_output']),
          ),
          sourcePath: exposesSource ? sourcePath : '',
          projectRelativePath: exposesSource ? projectRelativePath : '',
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '技能',
            sourceLabel: sourceLabel,
            projectRelativePath: exposesSource ? projectRelativePath : '',
            sourcePath: exposesSource ? sourcePath : '',
            includeInternalRows: exposesInternal,
          ),
          permissionBoundarySummary: permissionBoundarySummary,
          validationIssues: validationIssues,
          canDuplicateBuiltin: canDuplicateBuiltin,
        );
      case 'skill-groups':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: _projectedSubtitle(id, id),
          badge: sourceLabel,
          description: _groupDescription(entry, 'skills'),
          sourcePath: exposesSource ? sourcePath : '',
          projectRelativePath: exposesSource ? projectRelativePath : '',
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '技能组',
            sourceLabel: sourceLabel,
            projectRelativePath: exposesSource ? projectRelativePath : '',
            sourcePath: exposesSource ? sourcePath : '',
            includeInternalRows: exposesInternal,
          ),
          memberLabels: ValueReaders.stringList(entry['skills'])
              .map(_skillDisplayNameResolverService.resolveIdFallback)
              .toList(growable: false),
          permissionBoundarySummary: permissionBoundarySummary,
          validationIssues: validationIssues,
          canDuplicateBuiltin: canDuplicateBuiltin,
        );
      case 'agent-groups':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: _projectedSubtitle(id, id),
          badge: sourceLabel,
          description: _groupDescription(entry, 'agents'),
          sourcePath: exposesSource ? sourcePath : '',
          projectRelativePath: exposesSource ? projectRelativePath : '',
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '智能体组',
            sourceLabel: sourceLabel,
            projectRelativePath: exposesSource ? projectRelativePath : '',
            sourcePath: exposesSource ? sourcePath : '',
            includeInternalRows: exposesInternal,
          ),
          memberLabels: _agentGroupMemberLabels(entry),
          permissionBoundarySummary: permissionBoundarySummary,
          validationIssues: validationIssues,
          canDuplicateBuiltin: canDuplicateBuiltin,
        );
      case 'agents':
      default:
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: _projectedSubtitle(id, id),
          badge: sourceLabel,
          description: _nonEmpty(
            ValueReaders.stringValue(entry['description']),
            ValueReaders.stringValue(entry['role']),
          ),
          sourcePath: exposesSource ? sourcePath : '',
          projectRelativePath: exposesSource ? projectRelativePath : '',
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '智能体',
            sourceLabel: sourceLabel,
            projectRelativePath: exposesSource ? projectRelativePath : '',
            sourcePath: exposesSource ? sourcePath : '',
            includeInternalRows: exposesInternal,
          ),
          permissionBoundarySummary: permissionBoundarySummary,
          validationIssues: validationIssues,
          canDuplicateBuiltin: canDuplicateBuiltin,
        );
    }
  }

  List<EcosystemMetadataRow> _metadataRowsForEntry({
    required String kindLabel,
    required String sourceLabel,
    required String projectRelativePath,
    required String sourcePath,
    required bool includeInternalRows,
  }) {
    final rows = <EcosystemMetadataRow>[
      EcosystemMetadataRow(label: '类型', value: kindLabel),
      EcosystemMetadataRow(label: '来源', value: sourceLabel),
    ];
    if (!includeInternalRows) {
      return rows;
    }
    if (projectRelativePath.trim().isNotEmpty) {
      rows.add(
        EcosystemMetadataRow(label: '项目内路径', value: projectRelativePath),
      );
    }
    if (sourcePath.trim().isNotEmpty &&
        sourcePath.trim() != projectRelativePath.trim()) {
      rows.add(EcosystemMetadataRow(label: '源文件', value: sourcePath));
    }
    return rows;
  }

  String _projectedSubtitle(String rawId, String fallback) {
    if (_runtimeExposurePolicyService.exposesInternalRuntimeTerms(
      _exposureTier,
    )) {
      return fallback.trim().isNotEmpty ? fallback : rawId;
    }
    return '';
  }

  List<String> _agentGroupMemberLabels(JsonMap entry) {
    final memberIds = _readMemberAgentIds(entry);
    final primaryAgentId = _resolvedPrimaryAgentId(entry, memberIds);
    final rawMembers = entry['members'] is List<Object?>
        ? entry['members'] as List<Object?>
        : const <Object?>[];
    if (rawMembers.isNotEmpty) {
      final labels = <String>[];
      for (final rawMember in rawMembers) {
        final member = ValueReaders.mapValue(rawMember);
        final displayName = _agentDisplayNameResolverService.resolve(member);
        final agentId = ValueReaders.stringValue(
          member['agent_id'],
          ValueReaders.stringValue(member['id']),
        );
        final title = displayName.trim().isNotEmpty
            ? displayName.trim()
            : agentId.trim();
        if (title.isNotEmpty) {
          labels.add(
            _agentGroupMemberRoleService.isPrimaryMember(
                  agentId,
                  primaryAgentId: primaryAgentId,
                )
                ? '$title · 主智能体'
                : title,
          );
        }
      }
      if (labels.isNotEmpty) {
        return labels;
      }
    }
    return memberIds
        .map((agentId) {
          final title = _agentDisplayNameResolverService.resolveIdFallback(
            agentId,
          );
          return _agentGroupMemberRoleService.isPrimaryMember(
                agentId,
                primaryAgentId: primaryAgentId,
              )
              ? '$title · 主智能体'
              : title;
        })
        .toList(growable: false);
  }

  String _groupDescription(JsonMap entry, String itemKey) {
    final description = ValueReaders.stringValue(entry['description']).trim();
    if (description.isNotEmpty) {
      return description;
    }
    final items = ValueReaders.stringList(entry[itemKey]);
    if (items.isEmpty) {
      return '当前分组没有条目。';
    }
    return '包含 ${items.length} 项：${items.join('、')}';
  }

  String _nonEmpty(String primary, String fallback) {
    return primary.trim().isNotEmpty ? primary.trim() : fallback.trim();
  }

  String _entryDisplayName(
    String tabId,
    JsonMap entry, {
    required String fallbackId,
  }) {
    switch (tabId) {
      case 'skills':
        return _skillDisplayNameResolverService.resolveSkill(entry);
      case 'skill-groups':
        return _skillDisplayNameResolverService.resolveGroup(entry);
      case 'agent-groups':
      case 'agents':
      default:
        final label = _agentDisplayNameResolverService.resolve(entry);
        return label.trim().isNotEmpty ? label : fallbackId;
    }
  }

  String _sourceLabel(
    JsonMap entry, {
    required String sourcePath,
    required String projectRelativePath,
  }) {
    if (_isBuiltinEntry(
      entry,
      sourcePath: sourcePath,
      projectRelativePath: projectRelativePath,
    )) {
      return '内置资产';
    }
    if (_isProposalPath(projectRelativePath)) {
      return '项目草案';
    }
    if (projectRelativePath.isNotEmpty) {
      return '项目覆盖';
    }
    return '非内置资产';
  }

  bool _canDuplicateBuiltin(
    String tabId,
    JsonMap entry, {
    required String projectRelativePath,
  }) {
    if (projectRelativePath.isNotEmpty) {
      return false;
    }
    if (tabId != 'skill-groups' && tabId != 'agent-groups') {
      return false;
    }
    return _isBuiltinEntry(
      entry,
      sourcePath: ValueReaders.stringValue(entry['entry_file_path']).trim(),
      projectRelativePath: projectRelativePath,
    );
  }

  bool _isBuiltinEntry(
    JsonMap entry, {
    required String sourcePath,
    required String projectRelativePath,
  }) {
    if (projectRelativePath.isNotEmpty) {
      return false;
    }
    final sourceScope = ValueReaders.stringValue(entry['source_scope']).trim();
    final source = ValueReaders.stringValue(entry['source']).trim();
    if (_builtinLikeSource(sourceScope) || _builtinLikeSource(source)) {
      return true;
    }
    return sourcePath.isEmpty;
  }

  bool _builtinLikeSource(String value) {
    return value == 'builtin' || value == 'package';
  }

  bool _isProposalPath(String relativePath) {
    return relativePath
        .replaceAll('\\', '/')
        .startsWith('.novel_agent/ecosystem/proposals/');
  }

  String _permissionBoundarySummary(String tabId, JsonMap entry) {
    switch (tabId) {
      case 'skills':
      case 'agents':
        return _capabilitySummary(entry);
      case 'skill-groups':
        return '技能组只定义一组可复用技能，不会因为复制或绑定就自动扩大权限；实际权限边界仍由成员技能声明决定。';
      case 'agent-groups':
        return '智能体组只定义协作成员与主次关系，不直接授予工具权限；真正的权限边界仍以每个成员的技能装载与运行配置为准。';
      default:
        return '';
    }
  }

  String _capabilitySummary(JsonMap entry) {
    final required = ValueReaders.stringList(entry['required_capabilities']);
    final optional = ValueReaders.stringList(entry['optional_capabilities']);
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
  }

  List<String> _validationIssues(String tabId, JsonMap entry) {
    switch (tabId) {
      case 'skill-groups':
        return _reviewIssues(_skillGroupValidatorService.validate(entry));
      case 'agent-groups':
        return <String>[
          ..._reviewIssues(_agentGroupValidatorService.validate(entry)),
          ..._agentGroupConfigIssues(entry),
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

  List<String> _agentGroupConfigIssues(JsonMap entry) {
    final memberIds = _readMemberAgentIds(entry);
    if (memberIds.isEmpty) {
      return const <String>[];
    }
    final issues = <String>[];
    final primaryCandidates = _readPrimaryAgentCandidates(entry);
    if (primaryCandidates.isEmpty) {
      issues.add('还没有显式设置主智能体，当前只会回退到首成员。');
    }
    if (primaryCandidates.length > 1) {
      issues.add('检测到多个主智能体声明，请只保留一个 primary agent。');
    }
    final resolvedPrimary = _resolvedPrimaryAgentId(entry, memberIds);
    if (primaryCandidates.isNotEmpty &&
        resolvedPrimary.isNotEmpty &&
        !memberIds.contains(resolvedPrimary)) {
      issues.add('当前主智能体不在成员列表中，运行时无法正确落位。');
    }
    final requiredIds = _readScopedIds(entry, 'required_agent_ids');
    final optionalIds = _readScopedIds(entry, 'optional_agent_ids');
    final overlap = requiredIds
        .where(optionalIds.contains)
        .toList(growable: false);
    if (overlap.isNotEmpty) {
      issues.add('同一个成员不能同时标成必需和可选：${overlap.join('、')}。');
    }
    final unknownScopedIds = <String>{
      ...requiredIds.where((item) => !memberIds.contains(item)),
      ...optionalIds.where((item) => !memberIds.contains(item)),
    }.toList(growable: false);
    if (unknownScopedIds.isNotEmpty) {
      issues.add('以下成员不在当前组内，无法标记为必需或可选：${unknownScopedIds.join('、')}。');
    }
    return issues;
  }

  String _resolvedPrimaryAgentId(JsonMap entry, List<String> memberIds) {
    return _agentGroupMemberRoleService.resolvePrimaryAgentId(entry, memberIds);
  }

  List<String> _readPrimaryAgentCandidates(JsonMap entry) {
    final metadata = ValueReaders.mapValue(entry['metadata']);
    final candidates = <String>{
      ValueReaders.stringValue(entry['primary_agent_id']).trim(),
      ValueReaders.stringValue(metadata['primary_agent_id']).trim(),
    }..remove('');
    final memberRoles = ValueReaders.mapValue(entry['member_roles']).isNotEmpty
        ? ValueReaders.mapValue(entry['member_roles'])
        : ValueReaders.mapValue(metadata['member_roles']);
    memberRoles.forEach((key, value) {
      if (ValueReaders.stringValue(value).trim().toLowerCase() == 'primary') {
        candidates.add(key.trim());
      }
    });
    final rawMembers = entry['members'] is List<Object?>
        ? entry['members'] as List<Object?>
        : const <Object?>[];
    for (final rawMember in rawMembers) {
      final member = ValueReaders.mapValue(rawMember);
      final role = ValueReaders.stringValue(
        member['role'],
      ).trim().toLowerCase();
      if (role == 'primary') {
        final agentId = ValueReaders.stringValue(
          member['agent_id'],
          ValueReaders.stringValue(member['id']),
        ).trim();
        if (agentId.isNotEmpty) {
          candidates.add(agentId);
        }
      }
    }
    return candidates.toList(growable: false);
  }

  List<String> _readMemberAgentIds(JsonMap entry) {
    final rawMembers = entry['members'] is List<Object?>
        ? entry['members'] as List<Object?>
        : const <Object?>[];
    final ids = <String>[];
    for (final rawMember in rawMembers) {
      final member = ValueReaders.mapValue(rawMember);
      final agentId = ValueReaders.stringValue(
        member['agent_id'],
        ValueReaders.stringValue(member['id']),
      ).trim();
      if (agentId.isNotEmpty) {
        ids.add(agentId);
      }
    }
    if (ids.isNotEmpty) {
      return ids;
    }
    return ValueReaders.stringList(entry['agents']);
  }

  List<String> _readScopedIds(JsonMap entry, String key) {
    final metadata = ValueReaders.mapValue(entry['metadata']);
    final direct = ValueReaders.stringList(entry[key]);
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.stringList(metadata[key]);
  }
}
