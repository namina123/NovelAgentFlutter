import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'agent_group_catalog_overlay_document_codec_service.dart';
import 'catalog_overlay_path_service.dart';

class AgentGroupCatalogOverlayRepository {
  AgentGroupCatalogOverlayRepository({
    required String settingsRootPath,
    CatalogOverlayPathService? pathService,
    AgentGroupCatalogOverlayDocumentCodecService? codecService,
  }) : _settingsRootPath = settingsRootPath,
       _pathService = pathService ?? const CatalogOverlayPathService(),
       _codecService =
           codecService ?? AgentGroupCatalogOverlayDocumentCodecService();

  final String _settingsRootPath;
  final CatalogOverlayPathService _pathService;
  final AgentGroupCatalogOverlayDocumentCodecService _codecService;

  Future<List<JsonMap>> listOverlays() async {
    // 中文注释: 智能体组 overlay 与智能体 overlay 平行存放，避免一个仓储同时承担两类目录规则。
    final root = Directory(
      _pathService.agentGroupOverlayDirectoryPath(_settingsRootPath),
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
        left['group_id'],
      ).compareTo(ValueReaders.stringValue(right['group_id']));
    });
    return result;
  }

  Future<Map<String, JsonMap>> loadOverlayMap() async {
    final result = <String, JsonMap>{};
    for (final overlay in await listOverlays()) {
      final id = ValueReaders.stringValue(overlay['group_id']).trim();
      if (id.isEmpty) {
        continue;
      }
      result[id] = overlay;
    }
    return result;
  }

  Future<JsonMap> saveOverlay(JsonMap rawOverlay) async {
    // 中文注释: 组 overlay 永远按 group_id 单文件落盘，确保未来 UI 编辑不会误改整个 catalog。
    final overlay = _codecService.normalize(rawOverlay);
    final groupId = ValueReaders.stringValue(overlay['group_id']).trim();
    if (groupId.isEmpty) {
      return <String, Object?>{};
    }
    final file = File(
      _pathService.agentGroupOverlayFilePath(_settingsRootPath, groupId),
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
      if (ValueReaders.stringValue(overlay['group_id']).trim().isEmpty) {
        return <String, Object?>{};
      }
      return <String, Object?>{...overlay, 'overlay_relative_path': file.path};
    } catch (_) {
      return <String, Object?>{};
    }
  }
}
