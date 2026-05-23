import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../models/project_entry_view_data.dart';

class ProjectEntryTile extends StatelessWidget {
  const ProjectEntryTile({
    super.key,
    required this.entry,
    required this.onOpen,
  });

  final ProjectEntryViewData entry;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 单个项目条目只负责展示和打开动作，不关心弹层模式和创建流程。
    return Material(
      color: AppPalette.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onOpen(entry.path),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.line, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title,
                style: const TextStyle(
                  color: AppPalette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.path,
                style: const TextStyle(
                  color: AppPalette.mutedText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
