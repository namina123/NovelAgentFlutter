import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_group_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalAgentGroupCatalog {
  LocalAgentGroupCatalog({
    LocalGroupDirectoryLoader? groupDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
  }) : _groupDirectoryLoader =
           groupDirectoryLoader ?? LocalGroupDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver();

  final LocalGroupDirectoryLoader _groupDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;

  Future<List<JsonMap>> loadAgentGroups(ProjectDescriptor project) async {
    // 中文注释: 智能体组目录聚合只负责根路径顺序和去重，不把编排语义塞进 adapter。
    final byId = <String, JsonMap>{};
    final roots = _packageRootPathResolver.resolveAgentGroupRoots(project);
    for (final rootPath in roots) {
      final groups = await _groupDirectoryLoader.loadAgentGroups(rootPath);
      for (final rawGroup in groups) {
        final group = ValueReaders.mapValue(rawGroup);
        final id = ValueReaders.stringValue(group['id']).trim();
        if (id.isEmpty) {
          continue;
        }
        byId[id] = group;
      }
    }
    return byId.values.toList(growable: false);
  }
}
