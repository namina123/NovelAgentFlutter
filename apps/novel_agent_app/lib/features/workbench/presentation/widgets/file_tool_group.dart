import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';

class FileToolGroup extends StatelessWidget {
  const FileToolGroup({
    super.key,
    required this.onCreateFileRequested,
    required this.onCreateFolderRequested,
    required this.onImportRequested,
    required this.onCreateChapterRequested,
    required this.onSaveCurrentRequested,
  });

  final VoidCallback onCreateFileRequested;
  final VoidCallback onCreateFolderRequested;
  final VoidCallback onImportRequested;
  final VoidCallback onCreateChapterRequested;
  final VoidCallback onSaveCurrentRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文件级工具条固定为单行，主动作保留 4 个一级按钮，低频动作收进溢出菜单。
    final surface = context.novelThemeSurfaces.toolRow;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 180;
        final rowChildren = <Widget>[
          ToolbarIconButton(
            icon: Icons.note_add_outlined,
            tooltip: '新文件',
            dense: true,
            onPressed: onCreateFileRequested,
          ),
          SizedBox(width: compact ? 4 : 6),
          ToolbarIconButton(
            icon: Icons.file_upload_outlined,
            tooltip: '导入文件',
            dense: true,
            onPressed: onImportRequested,
          ),
        ];
        if (compact) {
          rowChildren.add(const SizedBox(width: 4));
        } else {
          rowChildren.addAll([
            const SizedBox(width: 6),
            ToolbarIconButton(
              icon: Icons.library_add_outlined,
              tooltip: '新章节',
              tone: ToolbarIconTone.warm,
              dense: true,
              onPressed: onCreateChapterRequested,
            ),
            const SizedBox(width: 6),
            ToolbarIconButton(
              icon: Icons.save_outlined,
              tooltip: '保存当前文档',
              tone: ToolbarIconTone.accent,
              dense: true,
              onPressed: onSaveCurrentRequested,
            ),
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: surface.borderColor.withValues(alpha: 0.34),
            ),
          ]);
        }
        rowChildren.add(
          _FileToolOverflowButton(
            compact: compact,
            onCreateFolderRequested: onCreateFolderRequested,
            onCreateChapterRequested: onCreateChapterRequested,
            onSaveCurrentRequested: onSaveCurrentRequested,
          ),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              top: BorderSide(
                color: surface.borderColor.withValues(alpha: 0.22),
              ),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 4 : 8,
              8,
              compact ? 4 : 8,
              8,
            ),
            child: HorizontalOverflowScrollbar(
              builder: (context, controller) => SingleChildScrollView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                primary: false,
                child: Row(
                  key: const ValueKey<String>('file_tool_group_primary_row'),
                  mainAxisSize: MainAxisSize.min,
                  children: rowChildren,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FileToolOverflowButton extends StatelessWidget {
  const _FileToolOverflowButton({
    required this.onCreateFolderRequested,
    required this.onCreateChapterRequested,
    required this.onSaveCurrentRequested,
    required this.compact,
  });

  final VoidCallback onCreateFolderRequested;
  final VoidCallback onCreateChapterRequested;
  final VoidCallback onSaveCurrentRequested;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final chrome = context.novelToolbarChrome;
    final menuSurface = context.novelThemeSurfaces.panel;
    return Tooltip(
      message: '更多文件操作',
      child: PopupMenuButton<_FileToolOverflowAction>(
        key: const ValueKey<String>('file_tool_group_overflow_button'),
        onSelected: (action) {
          switch (action) {
            case _FileToolOverflowAction.createFolder:
              onCreateFolderRequested();
              break;
            case _FileToolOverflowAction.createChapter:
              onCreateChapterRequested();
              break;
            case _FileToolOverflowAction.saveCurrent:
              onSaveCurrentRequested();
              break;
          }
        },
        itemBuilder: (context) {
          return [
            if (compact)
              const PopupMenuItem<_FileToolOverflowAction>(
                value: _FileToolOverflowAction.createChapter,
                child: Text('新章节'),
              ),
            if (compact)
              const PopupMenuItem<_FileToolOverflowAction>(
                value: _FileToolOverflowAction.saveCurrent,
                child: Text('保存当前文档'),
              ),
            PopupMenuItem<_FileToolOverflowAction>(
              value: _FileToolOverflowAction.createFolder,
              child: Text('新文件夹'),
            ),
          ];
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.panelBackground,
            border: Border.all(
              color: colors.lineColor,
              width: chrome.borderWidth,
            ),
            borderRadius: BorderRadius.circular(chrome.radius),
          ),
          child: SizedBox.square(
            dimension: chrome.buttonSize,
            child: Icon(
              Icons.more_horiz_rounded,
              size: chrome.iconSize,
              color: menuSurface.foregroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

enum _FileToolOverflowAction { createFolder, createChapter, saveCurrent }
