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
    this.expandChild = false,
  });

  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final bool emphasized;
  final bool showBorder;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
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
        color: background.withValues(alpha: emphasized ? 0.64 : 0.2),
        borderRadius: BorderRadius.circular(visual.sectionRadius),
        border: showBorder
            ? Border(
                top: BorderSide(
                  color: surface.borderColor.withValues(alpha: 0.28),
                  width: surface.borderWidth,
                ),
              )
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
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.08,
                          color: emphasized
                              ? surface.foregroundColor
                              : surface.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ...trailingWidgets,
                ],
              ),
              SizedBox(height: visual.microGap + 2),
              Divider(
                height: 1,
                thickness: surface.borderWidth,
                color: surface.borderColor.withValues(alpha: 0.08),
              ),
              SizedBox(height: visual.compactGap + 1),
            ],
            expandChild ? Expanded(child: child) : child,
          ],
        ),
      ),
    );
  }
}
