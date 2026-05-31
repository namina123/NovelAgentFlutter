import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SectionHeading(
                  title: viewData.title,
                  subtitle: viewData.description,
                ),
              ),
              const SizedBox(width: 12),
              ActionButton(
                label: '刷新',
                icon: Icons.refresh_rounded,
                tone: ActionButtonTone.neutral,
                compact: true,
                onPressed: actionHandler.onProjectOpenRefreshRequested,
              ),
              if (viewData.allowImportLocal) ...[
                const SizedBox(width: 8),
                ActionButton(
                  label: '导入本地项目',
                  icon: Icons.folder_open_rounded,
                  tone: ActionButtonTone.neutral,
                  compact: true,
                  onPressed: actionHandler.onProjectOpenImportRequested,
                ),
              ],
              const SizedBox(width: 8),
              ActionButton(
                label: '新建项目',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: actionHandler.onProjectOpenCreateRequested,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (viewData.projectsRootPath.trim().isNotEmpty)
            Text(
              '默认项目目录：${viewData.projectsRootPath}',
              style: TextStyle(
                color: panel.mutedForegroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
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
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PanelSurface(
                    child: viewData.entries.isEmpty
                        ? Center(
                            child: Text(
                              '当前还没有可打开的项目。',
                              style: TextStyle(
                                color: panel.mutedForegroundColor,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: viewData.entries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final badge in entry.sourceBadges)
                                              _BadgeChip(label: badge),
                                            if (entry.isCurrentProject)
                                              const _BadgeChip(label: '当前项目'),
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
                                    onPressed: () {
                                      actionHandler.onProjectOpenOpenRequested(
                                        entry.path,
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new_rounded),
                                  ),
                                  onTap: () {
                                    actionHandler.onProjectOpenEntrySelected(
                                      entry.id,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: PanelSurface(
                    child: selected == null
                        ? const Center(child: Text('请选择一个项目'))
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
                                child: ActionButton(
                                  label: '打开项目',
                                  icon: Icons.arrow_forward_rounded,
                                  compact: true,
                                  onPressed: () {
                                    actionHandler.onProjectOpenOpenRequested(
                                      selected.path,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  const _DetailRow({
    required this.label,
    required this.value,
  });

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
              style: TextStyle(
                fontSize: 13,
                color: surface.foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
