import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
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
    return Row(
      key: const ValueKey<String>('file_tool_group_primary_row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ToolbarIconButton(
          icon: Icons.note_add_outlined,
          tooltip: '新文件',
          dense: true,
          onPressed: onCreateFileRequested,
        ),
        const SizedBox(width: 6),
        ToolbarIconButton(
          icon: Icons.file_upload_outlined,
          tooltip: '导入文件',
          dense: true,
          onPressed: onImportRequested,
        ),
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
        const SizedBox(width: 6),
        _FileToolOverflowButton(
          onCreateFolderRequested: onCreateFolderRequested,
        ),
      ],
    );
  }
}

class _FileToolOverflowButton extends StatelessWidget {
  const _FileToolOverflowButton({required this.onCreateFolderRequested});

  final VoidCallback onCreateFolderRequested;

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
          }
        },
        itemBuilder: (context) {
          return const [
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

enum _FileToolOverflowAction { createFolder }
