import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_project_file_mutation_adapter.dart';

class ProjectWorkspaceToolHostAdapter implements ProjectToolHostPort {
  ProjectWorkspaceToolHostAdapter({
    required ProjectWorkspacePort workspacePort,
    required LocalProjectFileMutationAdapter fileMutationAdapter,
  }) : _workspacePort = workspacePort,
       _fileMutationAdapter = fileMutationAdapter;

  final ProjectWorkspacePort _workspacePort;
  final LocalProjectFileMutationAdapter _fileMutationAdapter;

  @override
  Future<List<JsonMap>> listEntries(String rootPath, {bool recursive = true}) {
    // 中文注释: 工具宿主适配器复用工作区读取接口，确保 list/read/write 与主工作区口径一致。
    return _workspacePort.listEntries(rootPath, recursive: recursive);
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) {
    // 中文注释: 工具读取直接委托给工作区端口，避免工具链和项目浏览链各用一套读文件规则。
    return _workspacePort.readTextFile(rootPath, relativePath);
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) {
    // 中文注释: 工具写入沿用工作区文本写入能力，保证项目文件最终都走同一出口。
    return _workspacePort.writeTextFile(rootPath, relativePath, content);
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) {
    // 中文注释: 会改变文件系统状态的辅助判断交给更细的变更适配器，防止工作区端口继续变重。
    return _fileMutationAdapter.entryExists(rootPath, relativePath);
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) {
    // 中文注释: 创建目录属于变更职责，因此由文件变更适配器承接。
    return _fileMutationAdapter.createDirectory(rootPath, relativePath);
  }

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) {
    // 中文注释: 删除入口统一经由变更适配器，未来替换为更严格策略时不会影响工作区读取层。
    return _fileMutationAdapter.deleteEntry(rootPath, relativePath);
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) {
    // 中文注释: 移动入口统一经由变更适配器，便于后续加入覆盖保护和事务式策略。
    return _fileMutationAdapter.moveEntry(
      rootPath,
      sourceRelativePath,
      targetRelativePath,
    );
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) {
    // 中文注释: 外部文本读取仍由更细的宿主变更适配器承接，避免工作区端口引入宿主绝对路径概念。
    return _fileMutationAdapter.readExternalTextFile(absolutePath);
  }

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) {
    // 中文注释: 外部文件复制属于宿主导入行为，因此保持在变更适配器边界内。
    return _fileMutationAdapter.copyExternalFile(
      absolutePath,
      rootPath,
      targetRelativePath,
    );
  }
}
