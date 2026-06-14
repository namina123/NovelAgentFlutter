import '../project/project_storage_strategy.dart';
import 'project_storage_aware_tool_capability_matrix.dart';
import 'project_tool_exposure_context.dart';

class SqliteCompatibilityToolPolicy {
  const SqliteCompatibilityToolPolicy({
    ProjectStorageAwareToolCapabilityMatrix? matrix,
  }) : _matrix = matrix ?? const ProjectStorageAwareToolCapabilityMatrix();

  final ProjectStorageAwareToolCapabilityMatrix _matrix;

  bool isCompatibilityOnlyTool(String toolId) {
    // 中文注释: SQLite 兼容层判断固定按 sqlite 上下文解释，方便 prompt 和测试统一口径。
    return _matrix.isCompatibilityTool(
      toolId,
      context: const ProjectToolExposureContext(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
    );
  }

  List<String> compatibilityToolIds(Iterable<String> toolIds) {
    // 中文注释: 这里把 SQLite 兼容工具单独抽出来，避免外层再手写一次低层文件工具名单。
    return _matrix.compatibilityToolIds(
      toolIds,
      context: const ProjectToolExposureContext(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
    );
  }

  String guidanceLine() {
    // 中文注释: 给 prompt 的一句话摘要，帮助模型区分 SQLite 主事实源和文件树兼容层。
    return _matrix.guidanceFor(
      const ProjectToolExposureContext(
        storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
      ),
    );
  }
}
