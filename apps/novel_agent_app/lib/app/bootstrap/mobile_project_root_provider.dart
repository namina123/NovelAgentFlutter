import 'dart:io';

class MobileProjectRootProvider {
  Future<String> resolveDocumentsRootPath() async {
    // 中文注释: 这里避免依赖 Flutter 插件，直接从应用沙箱已知目录推导持久化根路径。
    final sandboxRootPath = _resolveSandboxRootPath();
    if (Platform.isAndroid) {
      return Directory(
        '$sandboxRootPath${Platform.pathSeparator}files',
      ).absolute.path;
    }
    if (Platform.isIOS) {
      return Directory(
        '$sandboxRootPath${Platform.pathSeparator}Documents',
      ).absolute.path;
    }
    return Directory(sandboxRootPath).absolute.path;
  }

  Future<String> resolveDefaultProjectRootPath() async {
    // 中文注释: 移动端默认项目根始终放在应用文档目录内，避免申请额外外部存储权限。
    final documentsRootPath = await resolveDocumentsRootPath();
    return Directory(
      '$documentsRootPath${Platform.pathSeparator}projects${Platform.pathSeparator}default_project',
    ).absolute.path;
  }

  String _resolveSandboxRootPath() {
    // 中文注释: Android 的临时目录通常位于 `<sandbox>/cache`，iOS 通常位于 `<sandbox>/tmp`。
    final tempDirectory = Directory.systemTemp.absolute;
    final parentDirectory = tempDirectory.parent.absolute;
    return parentDirectory.path;
  }
}
