import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/state/app_shell_project_open_controller.dart';

void main() {
  test('项目入口页新建作品会走正式创建链路', () async {
    var createRequested = false;
    var refreshed = false;
    String? selectedEntryId;
    String? openedProjectPath;
    var imported = false;

    final controller = AppShellProjectOpenController(
      startProjectCreationFromProjectOpen: () async {
        createRequested = true;
      },
      refreshProjectOpenView: ({bool forceRefresh = false}) async {
        refreshed = true;
        expect(forceRefresh, isTrue);
      },
      selectProjectOpenEntry: (entryId) {
        selectedEntryId = entryId;
      },
      openProjectFromProjectOpen: (projectPath) async {
        openedProjectPath = projectPath;
      },
      importLocalProjectFromProjectOpen: () async {
        imported = true;
      },
    );

    controller.onProjectOpenCreateRequested();
    await Future<void>.delayed(Duration.zero);

    expect(createRequested, isTrue);
    expect(refreshed, isFalse);
    expect(selectedEntryId, isNull);
    expect(openedProjectPath, isNull);
    expect(imported, isFalse);
  });

  test('项目入口页刷新不会阻塞当前调用链', () async {
    final refreshCompleter = Completer<void>();
    var refreshed = false;

    final controller = AppShellProjectOpenController(
      startProjectCreationFromProjectOpen: () async {},
      refreshProjectOpenView: ({bool forceRefresh = false}) async {
        refreshed = true;
        expect(forceRefresh, isTrue);
        await refreshCompleter.future;
      },
      selectProjectOpenEntry: (_) {},
      openProjectFromProjectOpen: (_) async {},
      importLocalProjectFromProjectOpen: () async {},
    );

    controller.onProjectOpenRefreshRequested();
    await Future<void>.delayed(Duration.zero);

    expect(refreshed, isTrue);

    refreshCompleter.complete();
  });
}
