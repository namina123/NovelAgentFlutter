import 'package:novel_agent_core/novel_agent_core.dart';

import 'ecosystem_display_name_resolver_service.dart';
import '../../presentation/models/agent_ecosystem_view_data.dart';
import '../../presentation/models/project_skill_loadout_view_data.dart';
import '../models/agent_ecosystem_snapshot.dart';

class AgentEcosystemViewDataService {
  const AgentEcosystemViewDataService({
    AgentDisplayNameResolverService? agentDisplayNameResolverService,
    SkillDisplayNameResolverService? skillDisplayNameResolverService,
  }) : _agentDisplayNameResolverService =
           agentDisplayNameResolverService ??
           const AgentDisplayNameResolverService(),
       _skillDisplayNameResolverService =
           skillDisplayNameResolverService ??
           const SkillDisplayNameResolverService();

  final AgentDisplayNameResolverService _agentDisplayNameResolverService;
  final SkillDisplayNameResolverService _skillDisplayNameResolverService;

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
                  subtitle: item.subtitle,
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
    final isEditable = projectRelativePath.isNotEmpty;
    switch (tabId) {
      case 'skills':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: id,
          badge: ValueReaders.stringValue(entry['source_scope'], 'package'),
          description: _nonEmpty(
            ValueReaders.stringValue(entry['description']),
            ValueReaders.stringValue(entry['preferred_output']),
          ),
          sourcePath: sourcePath,
          projectRelativePath: projectRelativePath,
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '技能',
            sourceLabel: ValueReaders.stringValue(
              entry['source_scope'],
              'package',
            ),
            projectRelativePath: projectRelativePath,
            sourcePath: sourcePath,
          ),
        );
      case 'skill-groups':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: id,
          badge: ValueReaders.stringValue(entry['source'], 'builtin'),
          description: _groupDescription(entry, 'skills'),
          sourcePath: sourcePath,
          projectRelativePath: projectRelativePath,
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '技能组',
            sourceLabel: ValueReaders.stringValue(entry['source'], 'builtin'),
            projectRelativePath: projectRelativePath,
            sourcePath: sourcePath,
          ),
          memberLabels: ValueReaders.stringList(entry['skills'])
              .map(_skillDisplayNameResolverService.resolveIdFallback)
              .toList(growable: false),
        );
      case 'agent-groups':
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: id,
          badge: ValueReaders.stringValue(
            entry['orchestration'],
            ValueReaders.stringValue(entry['source'], 'builtin'),
          ),
          description: _groupDescription(entry, 'agents'),
          sourcePath: sourcePath,
          projectRelativePath: projectRelativePath,
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '智能体组',
            sourceLabel: ValueReaders.stringValue(
              entry['orchestration'],
              ValueReaders.stringValue(entry['source'], 'builtin'),
            ),
            projectRelativePath: projectRelativePath,
            sourcePath: sourcePath,
          ),
          memberLabels: _agentGroupMemberLabels(entry),
        );
      case 'agents':
      default:
        return EcosystemEntryViewData(
          id: id,
          kind: tabId,
          title: name,
          subtitle: id,
          badge: ValueReaders.stringValue(entry['source_scope'], 'builtin'),
          description: _nonEmpty(
            ValueReaders.stringValue(entry['description']),
            ValueReaders.stringValue(entry['role']),
          ),
          sourcePath: sourcePath,
          projectRelativePath: projectRelativePath,
          isEditable: isEditable,
          isSelected: isSelected,
          metadataRows: _metadataRowsForEntry(
            kindLabel: '智能体',
            sourceLabel: ValueReaders.stringValue(
              entry['source_scope'],
              'builtin',
            ),
            projectRelativePath: projectRelativePath,
            sourcePath: sourcePath,
          ),
        );
    }
  }

  List<EcosystemMetadataRow> _metadataRowsForEntry({
    required String kindLabel,
    required String sourceLabel,
    required String projectRelativePath,
    required String sourcePath,
  }) {
    final rows = <EcosystemMetadataRow>[
      EcosystemMetadataRow(label: '类型', value: kindLabel),
      EcosystemMetadataRow(label: '来源', value: sourceLabel),
    ];
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

  List<String> _agentGroupMemberLabels(JsonMap entry) {
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
          labels.add(title);
        }
      }
      if (labels.isNotEmpty) {
        return labels;
      }
    }
    return ValueReaders.stringList(entry['agents'])
        .map(_agentDisplayNameResolverService.resolveIdFallback)
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
}
