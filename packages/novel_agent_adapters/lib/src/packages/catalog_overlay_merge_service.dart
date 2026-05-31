import 'package:novel_agent_core/novel_agent_core.dart';

class CatalogOverlayMergeService {
  const CatalogOverlayMergeService();

  JsonMap merge({
    required JsonMap baseDocument,
    required JsonMap overlayDocument,
  }) {
    // 中文注释: overlay 只补充产品层显示与适用范围字段，不改动包目录来源和解析出的主体定义。
    if (baseDocument.isEmpty || overlayDocument.isEmpty) {
      return ValueReaders.deepCopyMap(baseDocument);
    }
    final merged = ValueReaders.deepCopyMap(baseDocument);
    for (final entry in overlayDocument.entries) {
      if (_reservedKeys.contains(entry.key)) {
        continue;
      }
      if (!_hasExplicitValue(entry.value)) {
        continue;
      }
      merged[entry.key] = _deepCopyValue(entry.value);
    }
    final mergedMetadata = <String, Object?>{
      ...ValueReaders.deepCopyMap(
        ValueReaders.mapValue(baseDocument['metadata']),
      ),
      ...ValueReaders.deepCopyMap(
        ValueReaders.mapValue(overlayDocument['metadata']),
      ),
    };
    if (mergedMetadata.isNotEmpty) {
      merged['metadata'] = mergedMetadata;
    }
    if (overlayDocument.containsKey('overlay_relative_path')) {
      merged['overlay_relative_path'] = ValueReaders.stringValue(
        overlayDocument['overlay_relative_path'],
      ).trim();
    }
    return merged;
  }

  bool _hasExplicitValue(Object? value) {
    if (value == null) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List<Object?>) {
      return value.isNotEmpty;
    }
    if (value is Map<Object?, Object?>) {
      return value.isNotEmpty;
    }
    return true;
  }

  Object? _deepCopyValue(Object? value) {
    if (value is Map<Object?, Object?>) {
      return ValueReaders.deepCopyMap(ValueReaders.mapValue(value));
    }
    if (value is List<Object?>) {
      return ValueReaders.deepCopyList(value);
    }
    return value;
  }

  static const Set<String> _reservedKeys = <String>{
    'schema_version',
    'agent_id',
    'group_id',
    'metadata',
  };
}
