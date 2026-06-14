import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_view_data.dart';
import 'resource_tree_empty_state.dart';
import 'resource_tree_entry_tile.dart';

class ResourceTreeCard extends StatelessWidget {
  const ResourceTreeCard({
    super.key,
    required this.entries,
    required this.onEntrySelected,
    this.projectTypeId = '',
    this.embeddedInScrollView = false,
  });

  final List<ResourceEntryViewData> entries;
  final ValueChanged<String> onEntrySelected;
  final String projectTypeId;
  final bool embeddedInScrollView;

  @override
  Widget build(BuildContext context) {
    final listChildren = _buildEntryChildren();
    return embeddedInScrollView
        ? _EmbeddedTreeBody(children: listChildren)
        : _ScrollableTreeBody(
            entries: entries,
            projectTypeId: projectTypeId,
            onEntrySelected: onEntrySelected,
          );
  }

  List<Widget> _buildEntryChildren() {
    // 中文注释: 嵌入式树与滚动树共用同一套条目投影，避免 SQLite 标签和普通树显示分叉。
    if (entries.isEmpty) {
      return const <Widget>[ResourceTreeEmptyState()];
    }
    final widgets = <Widget>[];
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      widgets.add(
        ResourceTreeEntryTile(
          entry: entry,
          secondaryLabel: _secondaryLabelFor(entry),
          onPressed: () => onEntrySelected(entry.id),
        ),
      );
      if (index < entries.length - 1) {
        widgets.add(const SizedBox(height: 2));
      }
    }
    return widgets;
  }

  String _secondaryLabelFor(ResourceEntryViewData entry) {
    // 中文注释: 资源树的辅助说明只在 SQLite 项目里显式提示主事实源与只读投影，避免把老文件树再伪装成主入口。
    return _resourceTreeSecondaryLabelFor(
      entry: entry,
      projectTypeId: projectTypeId,
    );
  }
}

class _ScrollableTreeBody extends StatelessWidget {
  const _ScrollableTreeBody({
    required this.entries,
    required this.projectTypeId,
    required this.onEntrySelected,
  });

  final List<ResourceEntryViewData> entries;
  final String projectTypeId;
  final ValueChanged<String> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: entries.isEmpty
          ? const ResourceTreeEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == entries.length - 1 ? 0 : 2,
                  ),
                  child: ResourceTreeEntryTile(
                    entry: entry,
                    secondaryLabel: _resourceTreeSecondaryLabelFor(
                      entry: entry,
                      projectTypeId: projectTypeId,
                    ),
                    onPressed: () => onEntrySelected(entry.id),
                  ),
                );
              },
            ),
    );
  }
}

class _EmbeddedTreeBody extends StatelessWidget {
  const _EmbeddedTreeBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

String _resourceTreeSecondaryLabelFor({
  required ResourceEntryViewData entry,
  required String projectTypeId,
}) {
  // 中文注释: 二级标签只在 SQLite 项目中标出“摘要 / 来源身份 / 真相源 / 只读投影”，让资源树先把语义说清楚。
  final normalizedPath = entry.relativePath.trim().replaceAll('\\', '/');
  if (projectTypeId.trim() != 'sqlite_project_store' ||
      normalizedPath.isEmpty) {
    return '';
  }
  if (normalizedPath.startsWith('premise/sqlite_projection/')) {
    return '摘要：SQLite 语义投影 · 来源身份：SQLite 主事实源 · 真相源：sqlite_project_store · 只读投影';
  }
  if (normalizedPath == 'premise/project_brief.md') {
    return '摘要：SQLite 项目概览 · 来源身份：SQLite 主事实源 · 真相源：sqlite_project_store · 只读投影';
  }
  return '摘要：SQLite 主事实源内容 · 来源身份：SQLite 主事实源 · 真相源：sqlite_project_store · 只读投影';
}
