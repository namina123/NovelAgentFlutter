import '../common/json_types.dart';
import '../ports/project_repository.dart';
import '../ports/project_workspace_port.dart';

class DiscoverProjectsUseCase {
  DiscoverProjectsUseCase({
    required ProjectRepository projectRepository,
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectRepository = projectRepository,
       _projectWorkspacePort = projectWorkspacePort;

  final ProjectRepository _projectRepository;
  final ProjectWorkspacePort _projectWorkspacePort;

  Future<List<JsonMap>> execute(String projectsRootPath) async {
    // 中文注释: 项目发现用例只扫描默认项目根下的一级目录，并尝试解析为可打开项目，不介入 UI 排序和弹层状态。
    final entries = await _projectWorkspacePort.listEntries(
      projectsRootPath,
      recursive: false,
    );
    final projects = <JsonMap>[];
    for (final entry in entries) {
      final isDir = entry['is_dir'] == true;
      final relativePath = entry['relative_path']?.toString().trim() ?? '';
      if (!isDir || relativePath.isEmpty) {
        continue;
      }
      final projectPath = _joinPath(projectsRootPath, relativePath);
      final project = await _projectRepository.openByPath(projectPath);
      if (project == null) {
        continue;
      }
      projects.add(<String, Object?>{
        'id': project.id,
        'title': project.name,
        'path': project.rootPath,
        'project_type': project.projectType,
        'storage_strategy': project.storageStrategy.id,
        'runtime_baseline_id': project.runtimeBaselineId,
      });
    }
    projects.sort((left, right) {
      final leftTitle = left['title']?.toString() ?? '';
      final rightTitle = right['title']?.toString() ?? '';
      return leftTitle.compareTo(rightTitle);
    });
    return projects;
  }

  String _joinPath(String rootPath, String child) {
    // 中文注释: 轻量路径拼接留在用例内部，避免为项目发现额外引入文件系统辅助抽象。
    final normalizedRoot = rootPath
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
    final normalizedChild = child
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'^/+'), '');
    return '$normalizedRoot/$normalizedChild';
  }
}
