import 'dart:io';

class LocalLongTaskRuntimePathService {
  const LocalLongTaskRuntimePathService({required this.settingsRootPath});

  final String settingsRootPath;

  String runtimeRootPath() {
    return '${Directory(settingsRootPath).absolute.path}${Platform.pathSeparator}long_task_runtime';
  }

  String registryRootPath() {
    return '${runtimeRootPath()}${Platform.pathSeparator}runs';
  }

  String runDocumentPath(String runId) {
    final safeId = _safeFileName(runId);
    return '${registryRootPath()}${Platform.pathSeparator}$safeId.json';
  }

  String _safeFileName(String raw) {
    // 中文注释: 全局运行实例的落盘文件名只需要稳定和可跨平台，不应依赖项目路径原文或宿主特定字符。
    var result = raw.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'run_instance' : result;
  }
}
