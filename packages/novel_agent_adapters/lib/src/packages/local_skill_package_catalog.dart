import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_package_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalSkillPackageCatalog {
  LocalSkillPackageCatalog({
    LocalPackageDirectoryLoader? packageDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
  }) : _packageDirectoryLoader =
           packageDirectoryLoader ?? LocalPackageDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver();

  final LocalPackageDirectoryLoader _packageDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;

  Future<List<JsonMap>> loadSkillPackages(ProjectDescriptor project) async {
    // 中文注释: 技能目录聚合只负责多根路径扫描与覆盖顺序，不承担包解析与智能体作用域规则。
    final byId = <String, JsonMap>{};
    final roots = _packageRootPathResolver.resolveSkillRoots(project);
    for (final rootPath in roots) {
      final packages = await _packageDirectoryLoader.loadSkillPackages(
        rootPath,
      );
      for (final rawPackage in packages) {
        final package = ValueReaders.mapValue(rawPackage);
        final id = ValueReaders.stringValue(package['id']).trim();
        if (id.isEmpty) {
          continue;
        }
        byId[id] = package;
      }
    }
    return byId.values.toList(growable: false);
  }
}
