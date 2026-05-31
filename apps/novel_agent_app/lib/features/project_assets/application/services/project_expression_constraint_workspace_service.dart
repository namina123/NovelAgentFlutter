import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_expression_constraint_workspace.dart';

typedef LoadProjectExpressionConstraintProfiles =
    Future<List<ExpressionConstraintProfile>> Function(
      ProjectDescriptor project,
    );
typedef LoadProjectExpressionConstraintBindings =
    Future<List<ProjectExpressionConstraintBinding>> Function(
      ProjectDescriptor project,
    );
typedef SaveProjectExpressionConstraintBindings =
    Future<void> Function(
      ProjectDescriptor project,
      List<ProjectExpressionConstraintBinding> bindings,
    );

class ProjectExpressionConstraintWorkspaceService {
  ProjectExpressionConstraintWorkspaceService({
    required LoadProjectExpressionConstraintProfiles loadProfiles,
    required LoadProjectExpressionConstraintBindings loadBindings,
    required SaveProjectExpressionConstraintBindings saveBindings,
  }) : _loadProfiles = loadProfiles,
       _loadBindings = loadBindings,
       _saveBindings = saveBindings;

  final LoadProjectExpressionConstraintProfiles _loadProfiles;
  final LoadProjectExpressionConstraintBindings _loadBindings;
  final SaveProjectExpressionConstraintBindings _saveBindings;

  Future<ProjectExpressionConstraintWorkspace> load(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 表达限制工作区一次性装载 preset 与项目绑定，避免控制器分散管理两个仓储时序。
    final results = await Future.wait<Object>(<Future<Object>>[
      _loadProfiles(project),
      _loadBindings(project),
    ]);
    return ProjectExpressionConstraintWorkspace(
      profiles: List<ExpressionConstraintProfile>.from(
        results[0] as List<ExpressionConstraintProfile>,
      ),
      bindings: List<ProjectExpressionConstraintBinding>.from(
        results[1] as List<ProjectExpressionConstraintBinding>,
      ),
    );
  }

  Future<void> saveBindings(
    ProjectDescriptor project,
    List<ProjectExpressionConstraintBinding> bindings,
  ) {
    // 中文注释: 当前 app 入口只允许改项目级 binding，不在这里混入 profile 编辑与 builtin 注册逻辑。
    return _saveBindings(project, _stableBindings(bindings));
  }

  List<ProjectExpressionConstraintBinding> _stableBindings(
    List<ProjectExpressionConstraintBinding> bindings,
  ) {
    // 中文注释: 绑定写盘前做一次稳定排序，减少项目文档因为点击顺序不同而产生无意义 diff。
    final items = List<ProjectExpressionConstraintBinding>.from(bindings);
    items.sort((left, right) {
      final profileOrder = left.profileId.compareTo(right.profileId);
      if (profileOrder != 0) {
        return profileOrder;
      }
      return left.id.compareTo(right.id);
    });
    return items;
  }
}
