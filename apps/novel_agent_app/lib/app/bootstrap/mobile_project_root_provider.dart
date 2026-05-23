import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MobileProjectRootProvider {
  Future<String> resolveDocumentsRootPath() async {
    // 中文注释: 移动端文档根路径统一在这里读取，让 path_provider 依赖留在平台 provider 内部。
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return Directory(documentsDirectory.path).absolute.path;
  }

  Future<String> resolveDefaultProjectRootPath() async {
    // 中文注释: 移动端默认项目根始终放在应用文档目录内，避免申请额外外部存储权限。
    final documentsRootPath = await resolveDocumentsRootPath();
    return Directory(
      '$documentsRootPath${Platform.pathSeparator}projects${Platform.pathSeparator}default_project',
    ).absolute.path;
  }
}
