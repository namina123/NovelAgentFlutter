import 'package:novel_agent_core/novel_agent_core.dart';

import 'agent_group_catalog_overlay_repository.dart';
import 'builtin_starter_agent_group_registration_service.dart';
import 'catalog_overlay_merge_service.dart';
import 'local_group_directory_loader.dart';
import 'package_root_path_resolver.dart';

class LocalAgentGroupCatalog {
  LocalAgentGroupCatalog({
    LocalGroupDirectoryLoader? groupDirectoryLoader,
    PackageRootPathResolver? packageRootPathResolver,
    AgentGroupCatalogOverlayRepository? overlayRepository,
    BuiltinStarterAgentGroupRegistrationService?
    starterGroupRegistrationService,
    CatalogOverlayMergeService? overlayMergeService,
  }) : _groupDirectoryLoader =
           groupDirectoryLoader ?? LocalGroupDirectoryLoader(),
       _packageRootPathResolver =
           packageRootPathResolver ?? const PackageRootPathResolver(),
       _overlayRepository = overlayRepository,
       _starterGroupRegistrationService =
           starterGroupRegistrationService ??
           BuiltinStarterAgentGroupRegistrationService(),
       _overlayMergeService =
           overlayMergeService ?? const CatalogOverlayMergeService();

  final LocalGroupDirectoryLoader _groupDirectoryLoader;
  final PackageRootPathResolver _packageRootPathResolver;
  final AgentGroupCatalogOverlayRepository? _overlayRepository;
  final BuiltinStarterAgentGroupRegistrationService
  _starterGroupRegistrationService;
  final CatalogOverlayMergeService _overlayMergeService;

  Future<List<JsonMap>> loadAgentGroups(ProjectDescriptor project) async {
    // 中文注释: 智能体组目录聚合只负责根路径顺序和去重，不把编排语义塞进 adapter。
    final byId = <String, JsonMap>{};
    for (final group in _starterGroupRegistrationService.registeredGroups()) {
      final id = ValueReaders.stringValue(group['id']).trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = ValueReaders.deepCopyMap(group);
    }
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
