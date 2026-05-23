import '../project/project_descriptor.dart';

abstract class ProjectRepository {
  Future<ProjectDescriptor?> openByPath(String rootPath);
}
