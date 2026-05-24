import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../contracts/project_collection_action_handler.dart';
import '../models/project_collection_view_data.dart';

class ProjectCollectionPage extends StatelessWidget {
  const ProjectCollectionPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectCollectionViewData viewData;
  final ProjectCollectionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntry();
    return AdaptivePageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: actionHandler.onProjectCollectionBackRequested,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
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
                onPressed: actionHandler.onProjectCollectionRefreshRequested,
              ),
              const SizedBox(width: 8),
              ActionButton(
                label: '新建',
                icon: Icons.add_rounded,
                compact: true,
                onPressed: actionHandler.onProjectCollectionCreateRequested,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PanelSurface(
                    child: ListView.separated(
                      itemCount: viewData.entries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = viewData.entries[index];
                        return Material(
                          color: entry.isSelected
                              ? AppPalette.accentSoft
                              : AppPalette.panel,
                          child: ListTile(
                            title: Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppPalette.text,
                              ),
                            ),
                            subtitle: Text(
                              '[${entry.badge}] ${entry.subtitle}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.mutedText,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                actionHandler.onProjectCollectionOpenRequested(
                                  entry.id,
                                );
                              },
                              icon: const Icon(Icons.open_in_new_rounded),
                            ),
                            onTap: () {
                              actionHandler.onProjectCollectionEntrySelected(
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
                        ? const Center(child: Text('暂无条目'))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SectionHeading(
                                title: selected.title,
                                subtitle: selected.description,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                selected.relativePath,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.mutedText,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                    viewData.detailBody.trim().isEmpty
                                        ? viewData.status
                                        : viewData.detailBody,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: AppPalette.text,
                                    ),
                                  ),
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

  ProjectCollectionEntryViewData? _selectedEntry() {
    for (final entry in viewData.entries) {
      if (entry.isSelected) {
        return entry;
      }
    }
    return viewData.entries.isEmpty ? null : viewData.entries.first;
  }
}
