import '../common/json_types.dart';
import '../ports/project_repository.dart';
import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';
import '../runtime/project_workspace_snapshot.dart';

class LoadProjectWorkspaceUseCase {
  const LoadProjectWorkspaceUseCase({
    required ProjectRepository projectRepository,
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectRepository = projectRepository,
       _projectWorkspacePort = projectWorkspacePort;

  final ProjectRepository _projectRepository;
  final ProjectWorkspacePort _projectWorkspacePort;

  Future<ProjectWorkspaceSnapshot?> execute(String rootPath) async {
    // 中文注释: 这个用例把“打开项目”和“读取工作空间目录”收成统一入口，避免宿主层手动串联两步。
    final project = await _projectRepository.openByPath(rootPath);
    if (project == null) {
      return null;
    }
    final entries = await _projectWorkspacePort.listEntries(project.rootPath);
    return ProjectWorkspaceSnapshot(
      project: project,
      projectInfo: _projectInfo(project),
      entries: entries,
    );
  }

  JsonMap _projectInfo(ProjectDescriptor project) {
    // 中文注释: 项目信息在这里先落成稳定字典，供上下文组装、提示词和视图层复用。
    return <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
      'stage': 'draft',
    };
  }
}
