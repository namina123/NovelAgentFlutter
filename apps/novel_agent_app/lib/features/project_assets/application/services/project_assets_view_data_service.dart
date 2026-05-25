import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_snapshot.dart';

class ProjectAssetsViewDataService {
  const ProjectAssetsViewDataService();

  ProjectAssetsViewData build({
    required ProjectAssetsSnapshot snapshot,
    required String status,
  }) {
    // 中文注释: 资产页视图投影统一收口，避免控制器自己组装列表标题、编辑器和选中态。
    final activeTabId = snapshot.activeTabId;
    final entries = activeTabId == 'foreshadows'
        ? _foreshadowEntries(snapshot)
        : _styleEntries(snapshot);
    return ProjectAssetsViewData(
      title: ProjectAssetsViewData.initial().title,
      description: ProjectAssetsViewData.initial().description,
      status: status,
      activeTabId: activeTabId,
      tabs: ProjectAssetsViewData.initial().tabs,
      entries: entries,
      styleEditor: _styleEditor(snapshot),
      foreshadowEditor: _foreshadowEditor(snapshot),
    );
  }

  List<ProjectAssetEntryViewData> _styleEntries(ProjectAssetsSnapshot snapshot) {
    final selectedId = _selectedStyleId(snapshot);
    return snapshot.styles
        .map(
          (item) => ProjectAssetEntryViewData(
            id: ValueReaders.stringValue(item['id']),
            title: ValueReaders.stringValue(
              item['display_name'],
              ValueReaders.stringValue(item['id']),
            ),
            subtitle: ValueReaders.stringValue(item['genre']),
            badge: ValueReaders.boolValue(item['default_for_project'])
                ? '默认'
                : ValueReaders.stringValue(item['tone']),
            relativePath: ValueReaders.stringValue(item['relative_path']),
            isSelected: ValueReaders.stringValue(item['id']) == selectedId,
          ),
        )
        .toList(growable: false);
  }

  List<ProjectAssetEntryViewData> _foreshadowEntries(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedForeshadowId(snapshot);
    return snapshot.foreshadows
        .map(
          (item) => ProjectAssetEntryViewData(
            id: ValueReaders.stringValue(item['id']),
            title: ValueReaders.stringValue(
              item['title'],
              ValueReaders.stringValue(item['id']),
            ),
            subtitle: ValueReaders.stringValue(item['summary']),
            badge: ValueReaders.stringValue(item['status'], 'planted'),
            relativePath: ValueReaders.stringValue(item['relative_path']),
            isSelected: ValueReaders.stringValue(item['id']) == selectedId,
          ),
        )
        .toList(growable: false);
  }

  StyleProfileEditorViewData _styleEditor(ProjectAssetsSnapshot snapshot) {
    final selectedId = _selectedStyleId(snapshot);
    final selected = snapshot.styles.firstWhere(
      (item) => ValueReaders.stringValue(item['id']) == selectedId,
      orElse: () => const <String, Object?>{},
    );
    if (selected.isEmpty) {
      return StyleProfileEditorViewData.empty();
    }
    return StyleProfileEditorViewData(
      id: ValueReaders.stringValue(selected['id']),
      displayName: ValueReaders.stringValue(selected['display_name']),
      summary: ValueReaders.stringValue(selected['summary']),
      genre: ValueReaders.stringValue(selected['genre']),
      tone: ValueReaders.stringValue(selected['tone']),
      audience: ValueReaders.stringValue(selected['audience']),
      tagsText: ValueReaders.stringList(selected['tags']).join(', '),
      guardrailsText: ValueReaders.stringList(selected['guardrails']).join(
        ', ',
      ),
      examplePathsText: ValueReaders.stringList(selected['example_paths']).join(
        ', ',
      ),
      inheritedIdsText: ValueReaders.stringList(
        selected['inherited_from_ids'],
      ).join(', '),
      defaultForProject: ValueReaders.boolValue(selected['default_for_project']),
      relativePath: ValueReaders.stringValue(selected['relative_path']),
    );
  }

  ForeshadowRecordEditorViewData _foreshadowEditor(
    ProjectAssetsSnapshot snapshot,
  ) {
    final selectedId = _selectedForeshadowId(snapshot);
    final selected = snapshot.foreshadows.firstWhere(
      (item) => ValueReaders.stringValue(item['id']) == selectedId,
      orElse: () => const <String, Object?>{},
    );
    if (selected.isEmpty) {
      return ForeshadowRecordEditorViewData.empty();
    }
    return ForeshadowRecordEditorViewData(
      id: ValueReaders.stringValue(selected['id']),
      title: ValueReaders.stringValue(selected['title']),
      status: ValueReaders.stringValue(selected['status'], 'planted'),
      summary: ValueReaders.stringValue(selected['summary']),
      plantedChapterPath: ValueReaders.stringValue(
        selected['planted_chapter_path'],
      ),
      targetPayoffPath: ValueReaders.stringValue(
        selected['target_payoff_path'],
      ),
      relatedEntityIdsText: ValueReaders.stringList(
        selected['related_entity_ids'],
      ).join(', '),
      relatedPathsText: ValueReaders.stringList(selected['related_paths']).join(
        ', ',
      ),
      triggerConditionsText: ValueReaders.stringList(
        selected['trigger_conditions'],
      ).join(', '),
      payoffExpectationsText: ValueReaders.stringList(
        selected['payoff_expectations'],
      ).join(', '),
      tagsText: ValueReaders.stringList(selected['tags']).join(', '),
      notes: ValueReaders.stringValue(selected['notes']),
      relativePath: ValueReaders.stringValue(selected['relative_path']),
    );
  }

  String _selectedStyleId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedStyleId.trim().isNotEmpty) {
      return snapshot.selectedStyleId.trim();
    }
    if (snapshot.styles.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(snapshot.styles.first['id']);
  }

  String _selectedForeshadowId(ProjectAssetsSnapshot snapshot) {
    if (snapshot.selectedForeshadowId.trim().isNotEmpty) {
      return snapshot.selectedForeshadowId.trim();
    }
    if (snapshot.foreshadows.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(snapshot.foreshadows.first['id']);
  }
}
