import 'json_types.dart';
import 'open_json_contract_codec_service.dart';
import 'value_readers.dart';

const _sourceAssetIdentityCodecService = OpenJsonContractCodecService();

class SourceAssetIdentity {
  const SourceAssetIdentity({
    required this.sourceAssetId,
    required this.sourceKind,
    this.displayName = '',
    this.resolverUri = '',
    this.localHintPath = '',
    this.metadata = const <String, Object?>{},
  });

  final String sourceAssetId;
  final String sourceKind;
  final String displayName;
  final String resolverUri;
  final String localHintPath;
  final JsonMap metadata;

  SourceAssetIdentity copyWith({
    String? sourceAssetId,
    String? sourceKind,
    String? displayName,
    String? resolverUri,
    String? localHintPath,
    JsonMap? metadata,
  }) {
    return SourceAssetIdentity(
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      sourceKind: sourceKind ?? this.sourceKind,
      displayName: displayName ?? this.displayName,
      resolverUri: resolverUri ?? this.resolverUri,
      localHintPath: localHintPath ?? this.localHintPath,
      metadata: metadata ?? this.metadata,
    );
  }

  factory SourceAssetIdentity.fromJson(JsonMap json) {
    final sourceIdentityJson = ValueReaders.mapValue(json['source_identity']);
    final view = sourceIdentityJson.isNotEmpty ? sourceIdentityJson : json;
    final rawMetadata = _sourceAssetIdentityCodecService
        .readMetadataWithUnknownFields(
          view,
          knownFields: const <String>{
            'source_asset_id',
            'display_name',
            'source_kind',
            'resolver_uri',
            'local_hint_path',
            'source_type',
            'source_id',
            'label',
            'metadata',
          },
        );
    final rawLocalHintPath = ValueReaders.stringValue(
      view['local_hint_path'],
    ).trim();
    final normalizedLocalHintPath = _normalizeLocalHintPath(rawLocalHintPath);
    final explicitSourceAssetId = ValueReaders.stringValue(
      view['source_asset_id'],
    ).trim();
    final legacySourceId = ValueReaders.stringValue(view['source_id']).trim();
    final sourceKind = ValueReaders.stringValue(
      view['source_kind'] ?? view['source_type'],
    ).trim();
    final displayName = ValueReaders.stringValue(
      view['display_name'] ?? view['label'],
    ).trim();
    final resolverUri = ValueReaders.stringValue(view['resolver_uri']).trim();
    final normalizedMetadata = ValueReaders.deepCopyMap(rawMetadata);
    if (_isAbsolutePath(rawLocalHintPath)) {
      normalizedMetadata['debug_local_absolute_path'] = rawLocalHintPath;
    }
    final resolvedSourceAssetId = _resolveSourceAssetId(
      explicitSourceAssetId: explicitSourceAssetId,
      legacySourceId: legacySourceId,
      displayName: displayName,
      sourceKind: sourceKind,
      resolverUri: resolverUri,
      localHintPath: normalizedLocalHintPath,
    );
    return SourceAssetIdentity(
      sourceAssetId: resolvedSourceAssetId,
      sourceKind: sourceKind,
      displayName: displayName,
      resolverUri: resolverUri,
      localHintPath: normalizedLocalHintPath,
      metadata: normalizedMetadata,
    );
  }

  JsonMap toJson() {
    return _sourceAssetIdentityCodecService
        .encodeWithUnknownFields(<String, Object?>{
          'source_asset_id': sourceAssetId,
          'display_name': displayName,
          'source_kind': sourceKind,
          'resolver_uri': resolverUri,
          'local_hint_path': localHintPath,
        }, metadata: metadata);
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (sourceKind.trim().isEmpty) {
      result.add('missing_source_asset_identity_source_kind');
    }
    if (sourceAssetId.trim().isEmpty) {
      result.add('missing_source_asset_identity_source_asset_id');
    }
    if (_isAbsolutePath(localHintPath.trim())) {
      result.add('absolute_local_hint_path_not_allowed_in_source_identity');
    }
    return result;
  }

  static String normalizeLocalHintPath(String raw) {
    return _normalizeLocalHintPath(raw);
  }

  static bool isAbsolutePath(String raw) {
    return _isAbsolutePath(raw);
  }

  static String resolveSourceAssetId({
    required String explicitSourceAssetId,
    required String legacySourceId,
    required String displayName,
    required String sourceKind,
    required String resolverUri,
    required String localHintPath,
  }) {
    return _resolveSourceAssetId(
      explicitSourceAssetId: explicitSourceAssetId,
      legacySourceId: legacySourceId,
      displayName: displayName,
      sourceKind: sourceKind,
      resolverUri: resolverUri,
      localHintPath: localHintPath,
    );
  }

  static String _resolveSourceAssetId({
    required String explicitSourceAssetId,
    required String legacySourceId,
    required String displayName,
    required String sourceKind,
    required String resolverUri,
    required String localHintPath,
  }) {
    final explicit = explicitSourceAssetId.trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    final legacy = legacySourceId.trim();
    if (legacy.isNotEmpty && !_isAbsolutePath(legacy)) {
      return legacy;
    }
    final cleanResolverUri = resolverUri.trim();
    if (cleanResolverUri.isNotEmpty) {
      return cleanResolverUri;
    }
    final cleanLocalHintPath = localHintPath.trim();
    if (cleanLocalHintPath.isNotEmpty) {
      return 'local_hint:${cleanLocalHintPath.replaceAll('\\', '/')}';
    }
    final cleanDisplayName = displayName.trim();
    if (cleanDisplayName.isNotEmpty) {
      return '${sourceKind.trim().isEmpty ? 'source' : sourceKind.trim()}:${_slug(cleanDisplayName)}';
    }
    return '';
  }

  static String _normalizeLocalHintPath(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return '';
    }
    if (_isAbsolutePath(clean)) {
      return _basename(clean);
    }
    return clean.replaceAll('\\', '/');
  }

  static bool _isAbsolutePath(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) {
      return false;
    }
    return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(clean) ||
        clean.startsWith('\\\\') ||
        clean.startsWith('/');
  }

  static String _basename(String raw) {
    final segments = raw.replaceAll('\\', '/').split('/');
    for (final segment in segments.reversed) {
      final clean = segment.trim();
      if (clean.isNotEmpty) {
        return clean;
      }
    }
    return '';
  }

  static String _slug(String raw) {
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9\u4E00-\u9FFF._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? 'source' : normalized.toLowerCase();
  }
}
