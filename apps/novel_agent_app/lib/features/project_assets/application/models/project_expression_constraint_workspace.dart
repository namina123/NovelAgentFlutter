import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectExpressionConstraintWorkspace {
  const ProjectExpressionConstraintWorkspace({
    this.profiles = const <ExpressionConstraintProfile>[],
    this.bindings = const <ProjectExpressionConstraintBinding>[],
  });

  final List<ExpressionConstraintProfile> profiles;
  final List<ProjectExpressionConstraintBinding> bindings;

  factory ProjectExpressionConstraintWorkspace.empty() {
    return const ProjectExpressionConstraintWorkspace();
  }

  ProjectExpressionConstraintBinding? bindingForProfile(String profileId) {
    // 中文注释: 资产中心只需要按 profile 查当前项目绑定，查找入口集中在这个轻量工作区对象里。
    final cleanProfileId = profileId.trim();
    for (final binding in bindings) {
      if (binding.profileId == cleanProfileId) {
        return binding;
      }
    }
    return null;
  }
}
