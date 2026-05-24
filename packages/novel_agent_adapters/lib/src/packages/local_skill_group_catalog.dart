import 'package:novel_agent_core/novel_agent_core.dart';

import 'local_group_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalSkillGroupCatalog {
  LocalSkillGroupCatalog({
    LocalGroupDirectoryLoader? groupDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
  }) : _groupDirectoryLoader =
           groupDirectoryLoader ?? LocalGroupDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver();

  final LocalGroupDirectoryLoader _groupDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;

  Future<List<JsonMap>> loadSkillGroups(ProjectDescriptor project) async {
    // 中文注释: 技能组目录聚合与技能包保持一致，后加载的项目组定义覆盖同名内置组。
    final byId = <String, JsonMap>{};
    final roots = _packageRootPathResolver.resolveSkillGroupRoots(project);
    for (final rootPath in roots) {
      final groups = await _groupDirectoryLoader.loadSkillGroups(rootPath);
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
