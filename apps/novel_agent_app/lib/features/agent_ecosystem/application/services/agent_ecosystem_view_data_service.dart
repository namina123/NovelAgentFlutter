import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/agent_ecosystem_view_data.dart';
import '../models/agent_ecosystem_snapshot.dart';

class AgentEcosystemViewDataService {
  const AgentEcosystemViewDataService();

  AgentEcosystemViewData build(AgentEcosystemSnapshot snapshot) {
    // 中文注释: 生态页展示模型统一在这里投影，避免控制器自己处理每个 tab 的标题、徽标和描述文案。
    final activeTabId = snapshot.activeTabId;
    final rawEntries = snapshot.entriesForTab(activeTabId);
    final selectedEntryId = _resolvedSelectedEntryId(snapshot, rawEntries);
    final entries = rawEntries
        .map(
          (entry) => _mapEntry(
            activeTabId,
            entry,
            isSelected:
                ValueReaders.stringValue(entry['id']).trim() == selectedEntryId,
          ),
        )
        .toList(growable: false);
    return AgentEcosystemViewData(
      activeTabId: activeTabId,
      tabs: AgentEcosystemViewData.initial().tabs,
      entries: entries,
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
    final name = ValueReaders.stringValue(entry['name'], id).trim();
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
        );
    }
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
}
