import 'package:flutter/material.dart';

import '../../application/services/workbench_resource_identity_service.dart';
import '../models/resource_tree_entry_semantic_view_data.dart';
import '../services/resource_tree_entry_semantic_service.dart';
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
    this.resourceIdentityService = const WorkbenchResourceIdentityService(),
    this.semanticService = const ResourceTreeEntrySemanticService(),
  });

  final List<ResourceEntryViewData> entries;
  final ValueChanged<String> onEntrySelected;
  final String projectTypeId;
  final bool embeddedInScrollView;
  final WorkbenchResourceIdentityService resourceIdentityService;
  final ResourceTreeEntrySemanticService semanticService;

  @override
  Widget build(BuildContext context) {
    final listChildren = _buildEntryChildren();
    return embeddedInScrollView
        ? _EmbeddedTreeBody(children: listChildren)
        : _ScrollableTreeBody(
            entries: entries,
            projectTypeId: projectTypeId,
            onEntrySelected: onEntrySelected,
            semanticService: semanticService,
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
          semantic: _semanticFor(entry),
          onPressed: () => onEntrySelected(entry.id),
        ),
      );
      if (index < entries.length - 1) {
        widgets.add(const SizedBox(height: 2));
      }
    }
    return widgets;
  }

  ResourceTreeEntrySemanticViewData _semanticFor(ResourceEntryViewData entry) {
    return semanticService.resolve(
      relativePath: entry.relativePath,
      isDirectory: entry.isDirectory,
      projectTypeId: projectTypeId,
    );
  }
}

class _ScrollableTreeBody extends StatelessWidget {
  const _ScrollableTreeBody({
    required this.entries,
    required this.projectTypeId,
    required this.onEntrySelected,
    required this.semanticService,
  });

  final List<ResourceEntryViewData> entries;
  final String projectTypeId;
  final ValueChanged<String> onEntrySelected;
  final ResourceTreeEntrySemanticService semanticService;

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
                    semantic: semanticService.resolve(
                      relativePath: entry.relativePath,
                      isDirectory: entry.isDirectory,
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
