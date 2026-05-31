import 'package:flutter/material.dart';

import '../widgets/workbench_desktop_section_id.dart';

enum WorkbenchCompactPrimaryView {
  workspace,
  document,
  conversation,
}

extension WorkbenchCompactPrimaryViewPresentation
    on WorkbenchCompactPrimaryView {
  String get label => switch (this) {
    WorkbenchCompactPrimaryView.workspace => '工作',
    WorkbenchCompactPrimaryView.document => '正文',
    WorkbenchCompactPrimaryView.conversation => '会话',
  };

  IconData get icon => switch (this) {
    WorkbenchCompactPrimaryView.workspace => Icons.space_dashboard_outlined,
    WorkbenchCompactPrimaryView.document => Icons.description_outlined,
    WorkbenchCompactPrimaryView.conversation => Icons.forum_outlined,
  };

  WorkbenchDesktopSectionId get sectionId => switch (this) {
    WorkbenchCompactPrimaryView.workspace => WorkbenchDesktopSectionId.navigation,
    WorkbenchCompactPrimaryView.document =>
      WorkbenchDesktopSectionId.primaryCanvas,
    WorkbenchCompactPrimaryView.conversation =>
      WorkbenchDesktopSectionId.collaboration,
  };
}
