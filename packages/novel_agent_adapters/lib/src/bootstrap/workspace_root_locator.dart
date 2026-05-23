import 'dart:io';

class WorkspaceRootLocator {
  const WorkspaceRootLocator();

  String locate({String? startPath}) {
    // 中文注释: 仓库根定位集中在这里，避免 CLI、Flutter 和测试环境各自硬编码相对路径。
    var current = Directory(startPath ?? Directory.current.path).absolute;
    while (true) {
      final marker = File('${current.path}${Platform.pathSeparator}agent.md');
      if (marker.existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) {
        return Directory(startPath ?? Directory.current.path).absolute.path;
      }
      current = parent;
    }
  }
}
