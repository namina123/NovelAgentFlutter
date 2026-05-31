import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectBundleDirectoryLayoutService {
  const ProjectBundleDirectoryLayoutService();

  String bundleFileName() => 'bundle.json';

  String exportDirectoryName({
    required String bundleKind,
    required String title,
  }) {
    // 中文注释: 目录导出统一给出稳定目录名，后续 zip 直接压这一层目录即可，不影响 core 合同。
    final prefix = _prefixForKind(bundleKind);
    final safeTitle = _safeFileStem(title);
    if (safeTitle.isEmpty) {
      return prefix;
    }
    return '${prefix}_$safeTitle';
  }

  String _prefixForKind(String bundleKind) {
    switch (bundleKind) {
      case BundleKind.projectPackage:
        return 'project_package';
      case BundleKind.characterCardBundle:
        return 'character_bundle';
      case BundleKind.styleBundle:
        return 'style_bundle';
      default:
        return 'asset_bundle';
    }
  }

  String _safeFileStem(String value) {
    var result = value.trim();
    result = result.replaceAll(RegExp(r'[\\/:*?"<>|\n\r\t ]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.toLowerCase();
  }
}
