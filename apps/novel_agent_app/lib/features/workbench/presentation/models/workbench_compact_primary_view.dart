import 'package:flutter/material.dart';

import '../widgets/workbench_desktop_section_id.dart';

enum WorkbenchCompactPrimaryView { workspace, document, conversation }

extension WorkbenchCompactPrimaryViewPresentation
    on WorkbenchCompactPrimaryView {
  String get label => switch (this) {
    WorkbenchCompactPrimaryView.workspace => '目录',
    WorkbenchCompactPrimaryView.document => '文档',
    WorkbenchCompactPrimaryView.conversation => '会话',
  };

  String get chromeTitle => switch (this) {
    WorkbenchCompactPrimaryView.workspace => '工作区',
    WorkbenchCompactPrimaryView.document => '编辑器',
    WorkbenchCompactPrimaryView.conversation => '协作',
  };

  String get summary => switch (this) {
    WorkbenchCompactPrimaryView.workspace => '资源与项目对象',
    WorkbenchCompactPrimaryView.document => '正文、预览与结构',
    WorkbenchCompactPrimaryView.conversation => '上下文与历史',
  };

  IconData get icon => switch (this) {
    WorkbenchCompactPrimaryView.workspace => Icons.space_dashboard_outlined,
    WorkbenchCompactPrimaryView.document => Icons.description_outlined,
    WorkbenchCompactPrimaryView.conversation => Icons.forum_outlined,
  };

  WorkbenchDesktopSectionId get sectionId => switch (this) {
    WorkbenchCompactPrimaryView.workspace =>
      WorkbenchDesktopSectionId.navigation,
    WorkbenchCompactPrimaryView.document =>
      WorkbenchDesktopSectionId.primaryCanvas,
    WorkbenchCompactPrimaryView.conversation =>
      WorkbenchDesktopSectionId.collaboration,
  };
}
