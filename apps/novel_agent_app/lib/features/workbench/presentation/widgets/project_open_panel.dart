import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/project_entry_view_data.dart';
import 'project_entry_tile.dart';

class ProjectOpenPanel extends StatelessWidget {
  const ProjectOpenPanel({
    super.key,
    required this.projectsRootPath,
    required this.entries,
    required this.status,
    required this.onRefreshRequested,
    required this.onProjectOpened,
  });

  final String projectsRootPath;
  final List<ProjectEntryViewData> entries;
  final String status;
  final VoidCallback onRefreshRequested;
  final ValueChanged<String> onProjectOpened;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 打开项目面板只承接默认目录扫描结果和打开动作，不处理新建项目表单。
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelHeader(
          title: '打开项目',
          actionLabel: '刷新',
          onActionPressed: onRefreshRequested,
        ),
        const SizedBox(height: 8),
        Text(
          '扫描位置：$projectsRootPath',
          style: TextStyle(color: colors.mutedTextColor, fontSize: 12),
        ),
        if (status.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              color: colors.lineStrongColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    '默认项目目录下还没有可打开的项目。',
                    style: TextStyle(
                      color: colors.mutedTextColor,
                      fontSize: 13,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return ProjectEntryTile(
                      entry: entries[index],
                      onOpen: onProjectOpened,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目弹层头部抽成小部件，避免打开/创建两个面板重复堆标题和辅助按钮。
    final colors = context.novelThemeColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: colors.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(onPressed: onActionPressed, child: Text(actionLabel)),
      ],
    );
  }
}
