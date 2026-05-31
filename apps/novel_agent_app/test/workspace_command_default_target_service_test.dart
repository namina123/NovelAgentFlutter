import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workspace_command_default_target_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('workspace command defaults use modern visible directories', () {
    // 中文注释: 工作区默认命令目标目录要和 core 的正式目录约定保持一致，不能继续落回 drafts/world。
    final service = WorkspaceCommandDefaultTargetService();

    expect(service.createFileDirectory(), 'chapters');
    expect(service.createFolderParentDirectory(), 'assets');
    expect(service.importTargetDirectory(), 'assets');
  });
}
