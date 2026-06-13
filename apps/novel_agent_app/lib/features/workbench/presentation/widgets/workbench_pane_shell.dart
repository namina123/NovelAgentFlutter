import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import 'workbench_desktop_section_id.dart';
import 'workbench_desktop_section_spec_resolver.dart';

class WorkbenchPaneShell extends StatelessWidget {
  const WorkbenchPaneShell({
    super.key,
    required this.child,
    required this.sectionId,
    this.showLeftOuterBorder = false,
    this.showRightOuterBorder = false,
  });

  final Widget child;
  final WorkbenchDesktopSectionId sectionId;
  final bool showLeftOuterBorder;
  final bool showRightOuterBorder;

  static const WorkbenchDesktopSectionSpecResolver _specResolver =
      WorkbenchDesktopSectionSpecResolver();

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作台栏位壳只负责分栏边界和底色，不再额外制造一层内框卡片。
    final spec = _specResolver.resolve(context, sectionId);
    final borderSide = BorderSide(
      color: spec.borderColor,
      width: AppChrome.borderWidth,
    );
    final radius = Radius.circular(spec.radius);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: showLeftOuterBorder ? radius : Radius.zero,
        bottomLeft: showLeftOuterBorder ? radius : Radius.zero,
        topRight: showRightOuterBorder ? radius : Radius.zero,
        bottomRight: showRightOuterBorder ? radius : Radius.zero,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              spec.innerFrameColor,
              spec.backgroundColor.withValues(alpha: 0.98),
            ],
          ),
          border: Border(
            left: showLeftOuterBorder ? borderSide : BorderSide.none,
            right: showRightOuterBorder ? borderSide : BorderSide.none,
          ),
        ),
        child: child,
      ),
    );
  }
}
