import 'package:flutter/material.dart';

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
    // 中文注释: 文件级工具也改为紧凑工具条，避免左栏在窄宽度下被按钮块严重挤占。
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ToolbarIconButton(
          icon: Icons.note_add_outlined,
          tooltip: '新文件',
          onPressed: onCreateFileRequested,
        ),
        ToolbarIconButton(
          icon: Icons.create_new_folder_outlined,
          tooltip: '新文件夹',
          onPressed: onCreateFolderRequested,
        ),
        ToolbarIconButton(
          icon: Icons.file_upload_outlined,
          tooltip: '导入文件',
          onPressed: onImportRequested,
        ),
        ToolbarIconButton(
          icon: Icons.library_add_outlined,
          tooltip: '新章节',
          tone: ToolbarIconTone.warm,
          onPressed: onCreateChapterRequested,
        ),
        ToolbarIconButton(
          icon: Icons.save_outlined,
          tooltip: '保存当前文档',
          tone: ToolbarIconTone.accent,
          onPressed: onSaveCurrentRequested,
        ),
      ],
    );
  }
}
