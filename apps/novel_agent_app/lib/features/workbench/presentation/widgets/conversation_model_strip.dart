import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../models/selector_option_view_data.dart';

class ConversationModelStrip extends StatelessWidget {
  const ConversationModelStrip({
    super.key,
    required this.modelLabel,
    required this.modelOptions,
    required this.onModelSelected,
    this.showSurface = true,
  });

  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final ValueChanged<String> onModelSelected;
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    final content = PopupMenuButton<String>(
      enabled: modelOptions.isNotEmpty,
      tooltip: '模型',
      onSelected: onModelSelected,
      itemBuilder: (context) {
        return modelOptions
            .map(
              (option) => PopupMenuItem<String>(
                value: option.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      option.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (option.note.trim().isNotEmpty)
                      Text(option.note, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            )
            .toList(growable: false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: surface.borderColor.withValues(alpha: 0.18),
            width: AppChrome.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 13,
                color: colors.mutedTextColor.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  modelLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                    color: colors.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: colors.mutedTextColor,
              ),
            ],
          ),
        ),
      ),
    );
    if (!showSurface) {
      return content;
    }
    return PanelSurface(
      role: PanelSurfaceRole.inputDock,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: content,
    );
  }
}
