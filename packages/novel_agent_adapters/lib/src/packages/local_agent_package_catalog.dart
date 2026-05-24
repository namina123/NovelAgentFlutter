import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_package_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalAgentPackageCatalog {
  LocalAgentPackageCatalog({
    LocalPackageDirectoryLoader? packageDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
  }) : _packageDirectoryLoader =
           packageDirectoryLoader ?? LocalPackageDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver();

  final LocalPackageDirectoryLoader _packageDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;

  Future<List<JsonMap>> loadAgentPackages(ProjectDescriptor project) async {
    // 中文注释: 智能体目录聚合和技能目录保持同一覆盖策略，后加载的项目包可以覆盖内置同名条目。
    final byId = <String, JsonMap>{};
    final roots = _packageRootPathResolver.resolveAgentRoots(project);
    for (final rootPath in roots) {
      final packages = await _packageDirectoryLoader.loadAgentPackages(
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
