import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/confirmation_dialog.dart';
import '../../../../../shared/widgets/horizontal_overflow_scrollbar.dart';
import '../models/workbench_view_data.dart';
import 'workbench_visual_style.dart';

class DocumentTabStrip extends StatelessWidget {
  const DocumentTabStrip({
    super.key,
    required this.documents,
    required this.onSelected,
    required this.onClosed,
  });

  final List<DocumentTabViewData> documents;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onClosed;

  @override
  Widget build(BuildContext context) {
    final panelSurface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return SizedBox(
      height: 32,
      child: HorizontalOverflowScrollbar(
        builder: (context, controller) => ListView.separated(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
          itemCount: documents.length,
          separatorBuilder: (_, index) => const SizedBox(width: 1),
          itemBuilder: (context, index) {
            final document = documents[index];
            final isActive = document.isActive;
            final foreground = isActive
                ? panelSurface.foregroundColor
                : panelSurface.mutedForegroundColor;
            final descriptor = document.tooltip.trim().isNotEmpty
                ? document.tooltip
                : (document.relativePath.trim().isEmpty
                      ? document.title
                      : document.relativePath);
            return Tooltip(
              message: descriptor,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(document.id),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 104,
                      maxWidth: 220,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isActive
                              ? colors.accentColor.withValues(alpha: 0.9)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4, top: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 12,
                            color: foreground.withValues(
                              alpha: isActive ? 0.86 : 0.58,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: document.isDirty
                                  ? colors.warmStrongColor
                                  : foreground.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              document.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: visual.compactLabelFontSize - 0.1,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: foreground,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: document.isDirty ? '关闭 · 有未保存修改' : '关闭',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            onPressed: () async {
                              // 中文注释: 关闭有未保存修改的文档前必须确认——否则用户编辑半小时点个 X 就全丢了。
                              // 想保存的用户取消后可手动保存(工具栏保存/Ctrl+S)再关闭。
                              if (document.isDirty) {
                                final confirmed = await showConfirmationDialog(
                                  context,
                                  title: '关闭该文档？',
                                  message:
                                      '该文档有未保存的修改，关闭后这些修改将丢失。如需保留，请先取消并保存。',
                                  confirmLabel: '仍然关闭',
                                );
                                if (!confirmed) {
                                  return;
                                }
                              }
                              onClosed(document.id);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              size: 11,
                              color: foreground.withValues(
                                alpha: isActive ? 0.68 : 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
