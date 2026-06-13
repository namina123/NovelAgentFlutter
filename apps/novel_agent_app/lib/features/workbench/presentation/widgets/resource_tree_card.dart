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
    this.embeddedInScrollView = false,
  });

  final List<ResourceEntryViewData> entries;
  final ValueChanged<String> onEntrySelected;
  final bool embeddedInScrollView;

  @override
  Widget build(BuildContext context) {
    final listChildren = _buildEntryChildren();
    return embeddedInScrollView
        ? _EmbeddedTreeBody(children: listChildren)
        : _ScrollableTreeBody(
            entries: entries,
            onEntrySelected: onEntrySelected,
          );
  }

  List<Widget> _buildEntryChildren() {
    if (entries.isEmpty) {
      return const <Widget>[ResourceTreeEmptyState()];
    }
    final widgets = <Widget>[];
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      widgets.add(
        ResourceTreeEntryTile(
          entry: entry,
          onPressed: () => onEntrySelected(entry.id),
        ),
      );
      if (index < entries.length - 1) {
        widgets.add(const SizedBox(height: 2));
      }
    }
    return widgets;
  }
}

class _ScrollableTreeBody extends StatelessWidget {
  const _ScrollableTreeBody({
    required this.entries,
    required this.onEntrySelected,
  });

  final List<ResourceEntryViewData> entries;
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
