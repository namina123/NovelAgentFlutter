import 'package:novel_agent_core/novel_agent_core.dart';

abstract class ProjectSourceOriginalArchiveStore {
  Future<void> persist({
    required ProjectDescriptor project,
    required String relativePath,
    required String title,
    required String content,
    String statePath = '',
  });
}
