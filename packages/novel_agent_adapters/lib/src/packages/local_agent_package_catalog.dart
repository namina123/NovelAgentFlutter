import 'package:novel_agent_core/novel_agent_core.dart';

import 'agent_catalog_overlay_repository.dart';
import 'catalog_overlay_merge_service.dart';
import 'local_package_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalAgentPackageCatalog {
  LocalAgentPackageCatalog({
    LocalPackageDirectoryLoader? packageDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
    AgentCatalogOverlayRepository? overlayRepository,
    CatalogOverlayMergeService? overlayMergeService,
  }) : _packageDirectoryLoader =
           packageDirectoryLoader ?? LocalPackageDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver(),
       _overlayRepository = overlayRepository,
       _overlayMergeService =
           overlayMergeService ?? const CatalogOverlayMergeService();

  final LocalPackageDirectoryLoader _packageDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;
  final AgentCatalogOverlayRepository? _overlayRepository;
  final CatalogOverlayMergeService _overlayMergeService;

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
    final overlays =
        await _overlayRepository?.loadOverlayMap() ?? const <String, JsonMap>{};
    overlays.forEach((id, overlay) {
      final baseDocument = byId[id];
      if (baseDocument == null) {
        return;
      }
      byId[id] = _overlayMergeService.merge(
        baseDocument: baseDocument,
        overlayDocument: overlay,
      );
    });
    return byId.values.toList(growable: false);
  }
}
