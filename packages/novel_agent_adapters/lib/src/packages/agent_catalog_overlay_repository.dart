import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'catalog_overlay_path_service.dart';
import 'agent_catalog_overlay_document_codec_service.dart';

class AgentCatalogOverlayRepository {
  AgentCatalogOverlayRepository({
    required String settingsRootPath,
    CatalogOverlayPathService? pathService,
    AgentCatalogOverlayDocumentCodecService? codecService,
  }) : _settingsRootPath = settingsRootPath,
       _pathService = pathService ?? const CatalogOverlayPathService(),
       _codecService =
           codecService ?? AgentCatalogOverlayDocumentCodecService(),
       _canUseBackgroundIsolate = pathService == null && codecService == null;

  final String _settingsRootPath;
  final CatalogOverlayPathService _pathService;
  final AgentCatalogOverlayDocumentCodecService _codecService;
  final bool _canUseBackgroundIsolate;

  Future<List<JsonMap>> listOverlays() async {
    // 中文注释: 全局 overlay 列表只扫描设置根目录，不把项目级绑定混进来。
    if (_canUseBackgroundIsolate) {
      return Isolate.run(() => _listAgentOverlaysSync(_settingsRootPath));
    }
    final root = Directory(
      _pathService.agentOverlayDirectoryPath(_settingsRootPath),
    );
    if (!await root.exists()) {
      return const <JsonMap>[];
    }
    final result = <JsonMap>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final overlay = await _readOverlay(entity);
      if (overlay.isEmpty) {
        continue;
      }
      result.add(overlay);
    }
    result.sort((left, right) {
      return ValueReaders.stringValue(
        left['agent_id'],
      ).compareTo(ValueReaders.stringValue(right['agent_id']));
    });
    return result;
  }

  Future<Map<String, JsonMap>> loadOverlayMap() async {
    final result = <String, JsonMap>{};
    for (final overlay in await listOverlays()) {
      final id = ValueReaders.stringValue(overlay['agent_id']).trim();
      if (id.isEmpty) {
        continue;
      }
      result[id] = overlay;
    }
    return result;
  }

  Future<JsonMap> saveOverlay(JsonMap rawOverlay) async {
    // 中文注释: 保存时统一归一化并按 agent_id 落单文件，后续编辑器和 CLI 都可复用同一目录规则。
    final overlay = _codecService.normalize(rawOverlay);
    final agentId = ValueReaders.stringValue(overlay['agent_id']).trim();
    if (agentId.isEmpty) {
      return <String, Object?>{};
    }
    final file = File(
      _pathService.agentOverlayFilePath(_settingsRootPath, agentId),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(overlay),
      flush: true,
    );
    return <String, Object?>{...overlay, 'overlay_relative_path': file.path};
  }

  Future<JsonMap> _readOverlay(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      final overlay = _codecService.normalize(ValueReaders.mapValue(decoded));
      if (ValueReaders.stringValue(overlay['agent_id']).trim().isEmpty) {
        return <String, Object?>{};
      }
      return <String, Object?>{...overlay, 'overlay_relative_path': file.path};
    } catch (_) {
      return <String, Object?>{};
    }
  }
}

List<JsonMap> _listAgentOverlaysSync(String settingsRootPath) {
  final pathService = const CatalogOverlayPathService();
  final codecService = AgentCatalogOverlayDocumentCodecService();
  final root = Directory(
    pathService.agentOverlayDirectoryPath(settingsRootPath),
  );
  if (!root.existsSync()) {
    return const <JsonMap>[];
  }
  final result = <JsonMap>[];
  for (final entity in root.listSync(followLinks: false)) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
      continue;
    }
    try {
      final decoded = jsonDecode(entity.readAsStringSync());
      final overlay = codecService.normalize(ValueReaders.mapValue(decoded));
      if (ValueReaders.stringValue(overlay['agent_id']).trim().isEmpty) {
        continue;
      }
      result.add(<String, Object?>{
        ...overlay,
        'overlay_relative_path': entity.path,
      });
    } catch (_) {
      continue;
    }
  }
  result.sort((left, right) {
    return ValueReaders.stringValue(
      left['agent_id'],
    ).compareTo(ValueReaders.stringValue(right['agent_id']));
  });
  return result;
}
