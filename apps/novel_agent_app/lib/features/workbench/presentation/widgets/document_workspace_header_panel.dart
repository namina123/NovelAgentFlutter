import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../models/workbench_view_data.dart';
import 'document_tab_strip.dart';
import 'document_toolbar_bar.dart';
import 'document_workspace_display_mode.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class DocumentWorkspaceHeaderPanel extends StatelessWidget {
  const DocumentWorkspaceHeaderPanel({
    super.key,
    required this.documents,
    required this.onSelected,
    required this.onClosed,
    required this.onActionRequested,
    required this.onDisplayModeSelected,
    required this.selectedMode,
    required this.canRender,
    required this.hasDocument,
  });

  final List<DocumentTabViewData> documents;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onClosed;
  final ValueChanged<DocumentToolbarAction> onActionRequested;
  final ValueChanged<DocumentWorkspaceDisplayMode> onDisplayModeSelected;
  final DocumentWorkspaceDisplayMode selectedMode;
  final bool canRender;
  final bool hasDocument;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    final style = WorkbenchDesktopStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.canvasSectionColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(visual.surfaceRadius),
        border: Border.all(
          color: style.canvasSectionBorderColor.withValues(alpha: 0.12),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(visual.surfaceRadius),
              topRight: Radius.circular(visual.surfaceRadius),
            ),
            child: DocumentTabStrip(
              documents: documents,
              onSelected: onSelected,
              onClosed: onClosed,
            ),
          ),
          DocumentToolbarBar(
            onActionRequested: onActionRequested,
            onDisplayModeSelected: onDisplayModeSelected,
            selectedMode: selectedMode,
            canRender: canRender,
            hasDocument: hasDocument,
          ),
        ],
      ),
    );
  }
}
