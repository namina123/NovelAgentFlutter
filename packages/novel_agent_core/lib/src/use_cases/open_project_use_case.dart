import '../ports/project_repository.dart';
import '../project/project_descriptor.dart';

class OpenProjectUseCase {
  const OpenProjectUseCase(this._projectRepository);

  final ProjectRepository _projectRepository;

  Future<ProjectDescriptor?> execute(String rootPath) {
    // 中文注释: 这里未来负责项目打开流程的统一入口，避免 GUI 和 CLI 分别实现一遍。
    return _projectRepository.openByPath(rootPath);
  }
}
