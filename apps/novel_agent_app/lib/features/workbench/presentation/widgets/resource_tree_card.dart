import 'package:flutter/material.dart';

import '../../../../../app/theme/theme_surface_spec.dart';
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
    // 中文注释: 文件树列表单独封装后，后续切到树控件或虚拟滚动时不需要碰资源面板外层结构。
    final surface = context.novelThemeSurfaces.panel;
    final listChildren = _buildEntryChildren(surface);
    final body = embeddedInScrollView
        ? _EmbeddedTreeBody(children: listChildren)
        : _ScrollableTreeBody(
            entries: entries,
            onEntrySelected: onEntrySelected,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '项目目录',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ),
            Text(
              '${entries.length} 项',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: surface.mutedForegroundColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (embeddedInScrollView) body else Expanded(child: body),
      ],
    );
  }

  List<Widget> _buildEntryChildren(ThemeSurfaceSpec surface) {
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
        widgets.add(
          Divider(
            height: 1,
            indent: 10,
            endIndent: 10,
            color: surface.borderColor.withValues(alpha: 0.35),
          ),
        );
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
        color: surface.backgroundColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(surface.radius),
      ),
      child: entries.isEmpty
          ? const ResourceTreeEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: entries.length,
              separatorBuilder: (_, index) => Divider(
                height: 1,
                indent: 10,
                endIndent: 10,
                color: surface.borderColor.withValues(alpha: 0.35),
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return ResourceTreeEntryTile(
                  entry: entry,
                  onPressed: () => onEntrySelected(entry.id),
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
        color: surface.backgroundColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(surface.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
