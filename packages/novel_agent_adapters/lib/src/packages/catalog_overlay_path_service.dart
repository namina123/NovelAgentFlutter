import 'dart:io';

class CatalogOverlayPathService {
  const CatalogOverlayPathService();

  String agentOverlayDirectoryPath(String settingsRootPath) {
    return Directory(
      '$settingsRootPath${Platform.pathSeparator}catalog_overlays${Platform.pathSeparator}agents',
    ).absolute.path;
  }

  String agentGroupOverlayDirectoryPath(String settingsRootPath) {
    return Directory(
      '$settingsRootPath${Platform.pathSeparator}catalog_overlays${Platform.pathSeparator}agent_groups',
    ).absolute.path;
  }

  String agentOverlayFilePath(String settingsRootPath, String agentId) {
    return '${agentOverlayDirectoryPath(settingsRootPath)}${Platform.pathSeparator}${agentId.trim()}.json';
  }

  String agentGroupOverlayFilePath(String settingsRootPath, String groupId) {
    return '${agentGroupOverlayDirectoryPath(settingsRootPath)}${Platform.pathSeparator}${groupId.trim()}.json';
  }
}
