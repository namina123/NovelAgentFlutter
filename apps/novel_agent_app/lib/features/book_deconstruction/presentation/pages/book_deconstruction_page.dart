import 'package:flutter/material.dart';

import '../../../../shared/widgets/panel_surface.dart';
import '../../../../shared/widgets/workspace_page_scaffold.dart';
import '../../../../shared/widgets/workspace_pane_layout.dart';
import '../../application/controllers/book_deconstruction_controller.dart';
import '../../application/models/book_deconstruction_step_id.dart';
import '../contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';
import '../models/book_deconstruction_step_view_data.dart';
import '../widgets/book_deconstruction_import_panel.dart';
import '../widgets/book_deconstruction_preview_panel.dart';
import '../widgets/book_deconstruction_step_panel.dart';
import '../widgets/book_deconstruction_toolbar.dart';

class BookDeconstructionPage extends StatelessWidget {
  const BookDeconstructionPage({super.key, required this.controller});

  final BookDeconstructionController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final viewData = controller.viewData;
        return WorkspacePageScaffold(
          header: BookDeconstructionToolbar(
            controller: controller,
            viewData: viewData,
          ),
          statusText: viewData.status,
          isLoading: viewData.isLoading,
          body: LayoutBuilder(
            builder: (context, constraints) {
              // 中文注释: 宽屏保持三栏并排；窄屏不再硬塞三段竖排（每段都很小），
              // 改成"紧凑步骤条 + 当前阶段面板"，让当前正在做的事拿到完整空间。
              if (constraints.maxWidth >= 1240) {
                return WorkspacePaneLayout(
                  breakpoint: 1240,
                  leadingPaneWidth: 260,
                  trailingPaneWidth: 460,
                  trailingCompactHeight: 320,
                  leadingPane: PanelSurface(
                    showBorder: true,
                    padding: EdgeInsets.zero,
                    child: BookDeconstructionStepPanel(
                      viewData: viewData,
                      actionHandler: controller,
                    ),
                  ),
                  mainPane: PanelSurface(
                    showBorder: true,
                    padding: EdgeInsets.zero,
                    child: BookDeconstructionImportPanel(
                      viewData: viewData,
                      actionHandler: controller,
                    ),
                  ),
                  trailingPane: PanelSurface(
                    showBorder: true,
                    padding: EdgeInsets.zero,
                    child: BookDeconstructionPreviewPanel(
                      viewData: viewData,
                      actionHandler: controller,
                    ),
                  ),
                );
              }
              final showPreview =
                  viewData.activeStepId.trim() !=
                      BookDeconstructionStepId.importSource;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BookDeconstructionNarrowStepStrip(
                    viewData: viewData,
                    actionHandler: controller,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: PanelSurface(
                      showBorder: false,
                      padding: EdgeInsets.zero,
                      child: showPreview
                          ? BookDeconstructionPreviewPanel(
                              viewData: viewData,
                              actionHandler: controller,
                            )
                          : BookDeconstructionImportPanel(
                              viewData: viewData,
                              actionHandler: controller,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// 窄屏下的紧凑横向步骤条：三个步骤一字排开，可点选切换当前阶段。
class _BookDeconstructionNarrowStepStrip extends StatelessWidget {
  const _BookDeconstructionNarrowStepStrip({
    required this.viewData,
    required this.actionHandler,
  });

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = viewData.steps;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var index = 0; index < steps.length; index += 1)
            _NarrowStepChip(
              step: steps[index],
              index: index,
              isLast: index == steps.length - 1,
              theme: theme,
              onTap: () =>
                  actionHandler.onBookDeconstructionStepSelected(steps[index].id),
            ),
        ],
      ),
    );
  }
}

class _NarrowStepChip extends StatelessWidget {
  const _NarrowStepChip({
    required this.step,
    required this.index,
    required this.isLast,
    required this.theme,
    required this.onTap,
  });

  final BookDeconstructionStepViewData step;
  final int index;
  final bool isLast;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final isActive = step.isActive;
    final isComplete = step.isComplete;
    final badgeColor = isActive
        ? colorScheme.primary
        : (isComplete ? colorScheme.tertiary : colorScheme.outlineVariant);
    final labelColor = isActive
        ? colorScheme.onPrimary
        : (isComplete
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withValues(alpha: 0.12) : null,
          border: Border.all(
            color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? colorScheme.onPrimary
                      : colorScheme.surface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              step.title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: labelColor,
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
