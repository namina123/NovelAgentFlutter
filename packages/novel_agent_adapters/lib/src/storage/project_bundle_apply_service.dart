import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_bundle_write_plan.dart';

class ProjectBundleApplyService {
  ProjectBundleApplyService({required ProjectToolHostPort hostPort})
    : _hostPort = hostPort;

  final ProjectToolHostPort _hostPort;

  Future<JsonMap> applyToProject(
    ProjectDescriptor project,
    ProjectBundleWritePlan plan,
  ) async {
    // 中文注释: apply 阶段只执行已经生成好的写盘计划，不再反向参与预检和冲突判定。
    final changedPaths = <String>[];
    for (final file in plan.files) {
      await _hostPort.writeTextFile(
        project.rootPath,
        file.targetPath,
        file.content,
      );
      changedPaths.add(file.targetPath);
    }
    return <String, Object?>{
      'ok': changedPaths.isNotEmpty,
      'bundle_kind': plan.bundleKind,
      'title': plan.title,
      'source_path': plan.sourcePath,
      'changed_paths': changedPaths,
      'skipped_paths': plan.skippedPaths,
      'summary': changedPaths.isEmpty
          ? '没有需要写入的文件。'
          : '已写入 ${changedPaths.length} 个文件。',
    };
  }
}
