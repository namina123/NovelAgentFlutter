import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../contracts/project_open_action_handler.dart';
import '../models/project_open_view_data.dart';

class ProjectOpenPage extends StatelessWidget {
  const ProjectOpenPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectOpenViewData viewData;
  final ProjectOpenActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntry();
    final panel = context.novelThemeSurfaces.panel;
    final optionTile = context.novelThemeSurfaces.optionTile;
    final colors = context.novelThemeColors;
    return AdaptivePageFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;
          final listPanel = PanelSurface(
            child: viewData.entries.isEmpty
                ? Center(
                    // 中文注释: 区分"正在加载"（首次刷新还没回来，给转圈）与"确实没有作品"，
                    // 避免冷启动瞬间看起来像空库/坏库。
                    child: viewData.hasLoaded
                        ? Text(
                            viewData.allowImportLocal
                                ? '还没有作品。先新建一部，或导入已有项目。'
                                : '还没有作品。先新建一部开始。',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: panel.mutedForegroundColor,
                              fontSize: 13,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const SizedBox(
                                height: 28,
                                width: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '正在加载作品列表...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: panel.mutedForegroundColor,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  )
                : ListView.separated(
                    itemCount: viewData.entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = viewData.entries[index];
                      return Material(
                        color: entry.isSelected
                            ? optionTile.highlightBackgroundColor
                            : optionTile.backgroundColor,
                        child: ListTile(
                          title: Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: optionTile.foregroundColor,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (!isNarrow)
                                      for (final badge in entry.sourceBadges)
                                        _BadgeChip(label: badge),
                                    if (entry.isCurrentProject)
                                      const _BadgeChip(label: '当前'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${entry.projectTypeLabel} · ${entry.storageLabel}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: optionTile.mutedForegroundColor,
                                  ),
                                ),
                                if (entry.lastModifiedLabel != '未知')
                                  Text(
                                    '最近修改：${entry.lastModifiedLabel}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: optionTile.mutedForegroundColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: '进入作品',
                            onPressed: () {
                              actionHandler.onProjectOpenOpenRequested(
                                entry.path,
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                          ),
                          onTap: () {
                            actionHandler.onProjectOpenEntrySelected(entry.id);
                          },
                          // 中文注释: 移动端(窄屏)详情面板被隐藏、没有"删除作品"按钮——
                          // 给每个条目加长按删除，让手机用户也能在应用内清理作品库。
                          onLongPress: () async {
                            final confirmed = await showConfirmationDialog(
                              context,
                              title: '删除该作品？',
                              message: '将永久删除目录：\n${entry.path}\n\n此操作不可恢复。'
                                  '${entry.isCurrentProject ? '\n\n这是当前正在使用的作品，删除后将自动返回项目启动器。' : ''}',
                              confirmLabel: '删除',
                            );
                            if (confirmed) {
                              actionHandler.onProjectOpenDeleteRequested(
                                entry.path,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          );
          final detailPanel = PanelSurface(
            child: selected == null
                ? const Center(child: Text('请选择一个作品'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeading(
                        title: selected.title,
                        subtitle:
                            '${selected.projectTypeLabel} · ${selected.storageLabel}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        selected.path,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: panel.mutedForegroundColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: '运行基准',
                        value: selected.runtimeBaselineLabel,
                      ),
                      _DetailRow(
                        label: '最近修改',
                        value: selected.lastModifiedLabel,
                      ),
                      _DetailRow(
                        label: '来源',
                        value: selected.sourceBadges.join(' / '),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionButton(
                              label: '删除作品',
                              icon: Icons.delete_outline_rounded,
                              tone: ActionButtonTone.danger,
                              compact: true,
                              onPressed: () async {
                                final confirmed = await showConfirmationDialog(
                                  context,
                                  title: '删除该作品？',
                                  message: '将永久删除目录：\n${selected.path}\n\n此操作不可恢复。'
                                      '${selected.isCurrentProject ? '\n\n这是当前正在使用的作品，删除后将自动返回项目启动器。' : ''}',
                                  confirmLabel: '删除',
                                );
                                if (!context.mounted || !confirmed) {
                                  return;
                                }
                                actionHandler.onProjectOpenDeleteRequested(
                                  selected.path,
                                );
                              },
                            ),
                            ActionButton(
                              label: '进入作品',
                              icon: Icons.arrow_forward_rounded,
                              compact: true,
                              onPressed: () {
                                actionHandler.onProjectOpenOpenRequested(
                                  selected.path,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isNarrow
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (isNarrow)
                    SectionHeading(
                      title: viewData.title,
                      subtitle: viewData.description,
                    )
                  else
                    Expanded(
                      child: SectionHeading(
                        title: viewData.title,
                        subtitle: viewData.description,
                      ),
                    ),
                  SizedBox(width: isNarrow ? 0 : 12, height: isNarrow ? 10 : 0),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionButton(
                        label: '刷新',
                        icon: Icons.refresh_rounded,
                        tone: ActionButtonTone.neutral,
                        compact: true,
                        onPressed: actionHandler.onProjectOpenRefreshRequested,
                      ),
                      if (viewData.allowImportLocal)
                        ActionButton(
                          label: '导入',
                          icon: Icons.folder_open_rounded,
                          tone: ActionButtonTone.neutral,
                          compact: true,
                          onPressed: actionHandler.onProjectOpenImportRequested,
                        ),
                      ActionButton(
                        label: '新建作品',
                        icon: Icons.add_rounded,
                        compact: true,
                        onPressed: actionHandler.onProjectOpenCreateRequested,
                      ),
                    ],
                  ),
                ],
              ),
              if (viewData.projectsRootPath.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                // 中文注释: 作品库根目录在移动端同样可见——用户在删除前需要知道作品落盘位置，
                // 窄屏不再隐藏这条信息（长路径会自然换行）。
                Text(
                  '项目目录：${viewData.projectsRootPath}',
                  style: TextStyle(
                    color: panel.mutedForegroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (viewData.status.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  viewData.status,
                  style: TextStyle(
                    color: colors.lineStrongColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: isNarrow
                    ? listPanel
                    : Row(
                        children: [
                          Expanded(flex: 5, child: listPanel),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: detailPanel),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  ProjectOpenEntryViewData? _selectedEntry() {
    for (final entry in viewData.entries) {
      if (entry.isSelected) {
        return entry;
      }
    }
    return viewData.entries.isEmpty ? null : viewData.entries.first;
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.86),
        border: Border.all(color: surface.borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: surface.mutedForegroundColor,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: surface.mutedForegroundColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: surface.foregroundColor),
            ),
          ),
        ],
      ),
    );
  }
}
