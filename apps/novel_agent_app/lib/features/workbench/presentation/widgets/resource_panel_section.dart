import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

class ResourcePanelSection extends StatelessWidget {
  const ResourcePanelSection({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(10),
    this.emphasized = false,
    this.showBorder = false,
  });

  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final bool emphasized;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 资源面板的内层分区统一用一套轻量壳，避免项目动作、目录树、底部入口各写各的边框和底色。
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    final background = visual.sectionBackground(
      surface,
      emphasized: emphasized,
    );
    final trailingWidget = trailing;
    final trailingWidgets = trailingWidget == null
        ? const <Widget>[]
        : <Widget>[trailingWidget];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: showBorder
            ? Border.all(color: surface.borderColor, width: surface.borderWidth)
            : null,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || trailing != null) ...[
              Row(
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: visual.compactLabelFontSize,
                          fontWeight: FontWeight.w700,
                          color: emphasized
                              ? surface.foregroundColor
                              : surface.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ...trailingWidgets,
                ],
              ),
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
