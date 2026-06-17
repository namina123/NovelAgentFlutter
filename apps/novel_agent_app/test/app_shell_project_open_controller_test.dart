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
      refreshProjectOpenView: () async {
        refreshed = true;
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
}
