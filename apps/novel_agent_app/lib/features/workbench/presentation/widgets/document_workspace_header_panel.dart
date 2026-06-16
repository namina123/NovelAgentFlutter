import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../contracts/document_workspace_action_handler.dart';
import '../models/workbench_view_data.dart';
import 'document_tab_strip.dart';
import 'document_toolbar_bar.dart';
import 'document_workspace_display_mode.dart';
import 'workbench_desktop_style.dart';

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
    final style = WorkbenchDesktopStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: style.canvasSectionColor.withValues(alpha: 0.025),
            border: Border(
              bottom: BorderSide(
                color: style.canvasSectionBorderColor.withValues(alpha: 0.1),
                width: AppChrome.borderWidth,
              ),
            ),
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
    );
  }
}
