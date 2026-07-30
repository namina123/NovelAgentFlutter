import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../models/resource_tree_entry_semantic_view_data.dart';
import '../models/workbench_view_data.dart';

class ResourceTreeEntryTile extends StatelessWidget {
  const ResourceTreeEntryTile({
    super.key,
    required this.entry,
    required this.onPressed,
    this.semantic = const ResourceTreeEntrySemanticViewData(
      detailLabel: '',
      leadingIcon: Icons.description_outlined,
    ),
    this.onDeleteEntry,
    this.onRenameEntry,
  });

  final ResourceEntryViewData entry;
  final ResourceTreeEntrySemanticViewData semantic;
  final VoidCallback onPressed;
  // 中文注释: 传入删除/重命名回调时，条目尾部出现「⋯」操作菜单；不传则维持纯展示。
  final ValueChanged<ResourceEntryViewData>? onDeleteEntry;
  final void Function(ResourceEntryViewData entry, String nextName)?
  onRenameEntry;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final panelSurface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final canManage = onDeleteEntry != null || onRenameEntry != null;
    final hasSecondaryLabel = semantic.detailLabel.trim().isNotEmpty;
    final foreground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.foregroundColor;
    final mutedForeground = entry.isSelected
        ? optionSurface.highlightForegroundColor
        : panelSurface.mutedForegroundColor;
    final background = entry.isSelected
        ? optionSurface.highlightBackgroundColor.withValues(alpha: 0.14)
        : panelSurface.backgroundColor.withValues(alpha: 0.01);
    final borderColor = entry.isSelected
        ? optionSurface.highlightBorderColor.withValues(alpha: 0.14)
        : Colors.transparent;
    final toneColor = _toneColor(colors.accentColor);
    final chevron = entry.isDirectory
        ? (entry.hasChildren
              ? (entry.isExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded)
              : Icons.chevron_right_rounded)
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                minHeight: hasSecondaryLabel ? 40 : 32,
              ),
              padding: EdgeInsets.fromLTRB(
                8,
                hasSecondaryLabel ? 4 : 3,
                8,
                hasSecondaryLabel ? 4 : 3,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _DepthGuides(
                    depth: entry.depth,
                    color: panelSurface.borderColor.withValues(alpha: 0.045),
                  ),
                  SizedBox(width: entry.depth > 0 ? 1 : 0),
                  SizedBox(
                    width: 16,
                    child: chevron == null
                        ? const SizedBox.shrink()
                        : Icon(chevron, size: 14, color: mutedForeground),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    semantic.leadingIcon,
                    size: 15,
                    color: entry.isSelected
                        ? foreground
                        : toneColor.withValues(
                            alpha: entry.isDirectory ? 0.92 : 0.84,
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.2,
                                        fontWeight: entry.isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: foreground,
                                      ),
                                    ),
                                  ),
                                  if (semantic.hasBadge) ...[
                                    const SizedBox(width: 6),
                                    _SemanticBadge(
                                      label: semantic.badgeLabel,
                                      toneColor: toneColor,
                                      selected: entry.isSelected,
                                      foreground: foreground,
                                      mutedForeground: mutedForeground,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (entry.isDirectory && entry.childCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: panelSurface.backgroundColor
                                      .withValues(
                                        alpha: entry.isSelected ? 0.18 : 0.06,
                                      ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${entry.childCount}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: mutedForeground,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (semantic.detailLabel.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            semantic.detailLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                              color: mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    const SizedBox(width: 2),
                    _EntryMenuTrigger(
                      entry: entry,
                      iconColor: mutedForeground,
                      onDeleteEntry: onDeleteEntry,
                      onRenameEntry: onRenameEntry,
                    ),
                  ],
                ],
              ),
            ),
            if (entry.isSelected)
              Positioned(
                left: 2,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: colors.accentColor.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(Color accentColor) {
    switch (semantic.tone) {
      case ResourceTreeSemanticTone.blue:
        return const Color(0xFF4C7DFF);
      case ResourceTreeSemanticTone.teal:
        return const Color(0xFF0E8E7A);
      case ResourceTreeSemanticTone.amber:
        return const Color(0xFFB7791F);
      case ResourceTreeSemanticTone.green:
        return const Color(0xFF2F855A);
      case ResourceTreeSemanticTone.purple:
        return const Color(0xFF6B46C1);
      case ResourceTreeSemanticTone.rose:
        return const Color(0xFFB83280);
      case ResourceTreeSemanticTone.neutral:
        return accentColor;
    }
  }
}

class _SemanticBadge extends StatelessWidget {
  const _SemanticBadge({
    required this.label,
    required this.toneColor,
    required this.selected,
    required this.foreground,
    required this.mutedForeground,
  });

  final String label;
  final Color toneColor;
  final bool selected;
  final Color foreground;
  final Color mutedForeground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: selected
            ? foreground.withValues(alpha: 0.1)
            : toneColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? foreground.withValues(alpha: 0.12)
              : toneColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.2,
          fontWeight: FontWeight.w700,
          color: selected ? foreground : mutedForeground,
          height: 1.1,
        ),
      ),
    );
  }
}

class _DepthGuides extends StatelessWidget {
  const _DepthGuides({required this.depth, required this.color});

  final int depth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (depth <= 0) {
      return const SizedBox(width: 4);
    }
    return SizedBox(
      width: depth * 9,
      child: Row(
        children: List.generate(
          depth,
          (_) => Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(width: 1, height: 14, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ResourceEntryMenuAction { rename, delete }

/// 中文注释: 资源条目尾部的「⋯」操作菜单——长出在传入删除/重命名回调时。
/// 弹出 PopupMenu，再据选择走二次确认（删除）或输入框（重命名）；最终回调交给上层。
class _EntryMenuTrigger extends StatelessWidget {
  const _EntryMenuTrigger({
    required this.entry,
    required this.iconColor,
    required this.onDeleteEntry,
    required this.onRenameEntry,
  });

  final ResourceEntryViewData entry;
  final Color iconColor;
  final ValueChanged<ResourceEntryViewData>? onDeleteEntry;
  final void Function(ResourceEntryViewData entry, String nextName)?
  onRenameEntry;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ResourceEntryMenuAction>(
      tooltip: '资源操作',
      icon: Icon(Icons.more_horiz, size: 16, color: iconColor),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      splashRadius: 16,
      constraints: const BoxConstraints(minWidth: 128),
      itemBuilder: (context) => [
        if (onRenameEntry != null)
          const PopupMenuItem(
            value: _ResourceEntryMenuAction.rename,
            child: Text('重命名'),
          ),
        if (onDeleteEntry != null)
          const PopupMenuItem(
            value: _ResourceEntryMenuAction.delete,
            child: Text('删除'),
          ),
      ],
      onSelected: (action) => _handleAction(context, action),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    _ResourceEntryMenuAction action,
  ) async {
    switch (action) {
      case _ResourceEntryMenuAction.rename:
        final nextName = await showDialog<String>(
          context: context,
          builder: (_) => _RenameEntryDialog(
            initialName: _baseNameOf(entry.relativePath),
            title: entry.isDirectory ? '重命名文件夹' : '重命名文件',
          ),
        );
        final clean = nextName?.trim() ?? '';
        if (clean.isEmpty) {
          return;
        }
        onRenameEntry?.call(entry, clean);
        break;
      case _ResourceEntryMenuAction.delete:
        final confirmed = await showConfirmationDialog(
          context,
          title: entry.isDirectory ? '删除文件夹' : '删除文件',
          message: _deleteConfirmMessage(entry),
          confirmLabel: '删除',
        );
        if (confirmed) {
          onDeleteEntry?.call(entry);
        }
        break;
    }
  }

  String _deleteConfirmMessage(ResourceEntryViewData entry) {
    if (entry.isDirectory) {
      if (entry.childCount > 0) {
        return '将删除文件夹「${entry.title}」及其中的 ${entry.childCount} 项内容，'
            '并关闭对应的已打开标签。此操作不可撤销。';
      }
      return '将删除空文件夹「${entry.title}」。此操作不可撤销。';
    }
    return '将删除「${entry.title}」，并关闭对应标签'
        '（未保存的草稿会一并丢失）。此操作不可撤销。';
  }
}

String _baseNameOf(String relativePath) {
  final clean = relativePath.replaceAll('\\', '/');
  final slash = clean.lastIndexOf('/');
  return slash >= 0 ? clean.substring(slash + 1) : clean;
}

/// 中文注释: 重命名输入弹窗——预填当前文件/目录名，默认选中主名部分（去掉扩展名）
/// 以便整体替换；目录则全选。StatefulWidget 负责创建/释放 TextEditingController。
class _RenameEntryDialog extends StatefulWidget {
  const _RenameEntryDialog({required this.initialName, required this.title});

  final String initialName;
  final String title;

  @override
  State<_RenameEntryDialog> createState() => _RenameEntryDialogState();
}

class _RenameEntryDialogState extends State<_RenameEntryDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    final dot = widget.initialName.lastIndexOf('.');
    final selectionEnd = dot > 0 ? dot : widget.initialName.length;
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: selectionEnd.clamp(0, widget.initialName.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          hintText: '输入新的名称（可保留扩展名，如 .md）',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
