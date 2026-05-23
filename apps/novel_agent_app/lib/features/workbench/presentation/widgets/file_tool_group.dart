import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/compact_action_grid.dart';

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
    // 中文注释: 文件级工具独立成组，后续资源树替换成真实目录结构时无需动项目动作区域。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '文件工作区',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppPalette.mutedText,
          ),
        ),
        const SizedBox(height: 10),
        CompactActionGrid(
          children: [
            ActionButton(
              label: '新文件',
              icon: Icons.note_add_outlined,
              tone: ActionButtonTone.neutral,
              compact: true,
              onPressed: onCreateFileRequested,
            ),
            ActionButton(
              label: '新文件夹',
              icon: Icons.create_new_folder_outlined,
              tone: ActionButtonTone.neutral,
              compact: true,
              onPressed: onCreateFolderRequested,
            ),
            ActionButton(
              label: '导入',
              icon: Icons.file_upload_outlined,
              tone: ActionButtonTone.neutral,
              compact: true,
              onPressed: onImportRequested,
            ),
            ActionButton(
              label: '新章节',
              icon: Icons.library_add_outlined,
              tone: ActionButtonTone.warm,
              compact: true,
              onPressed: onCreateChapterRequested,
            ),
            ActionButton(
              label: '保存当前',
              icon: Icons.save_outlined,
              compact: true,
              onPressed: onSaveCurrentRequested,
            ),
          ],
        ),
      ],
    );
  }
}
