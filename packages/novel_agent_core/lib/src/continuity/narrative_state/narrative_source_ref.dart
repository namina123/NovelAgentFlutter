import '../../common/source_asset_identity.dart';
import '../../common/json_types.dart';
import '../../common/value_readers.dart';

class NarrativeSourceRef {
  const NarrativeSourceRef({
    required this.sourceType,
    this.sourceId = '',
    this.label = '',
    this.description = '',
    this.sourceAssetId = '',
    this.displayName = '',
    this.sourceKind = '',
    this.resolverUri = '',
    this.localHintPath = '',
    this.sourceIdentityMetadata = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String sourceType;
  final String sourceId;
  final String label;
  final String description;
  final String sourceAssetId;
  final String displayName;
  final String sourceKind;
  final String resolverUri;
  final String localHintPath;
  final JsonMap sourceIdentityMetadata;
  final JsonMap metadata;

  SourceAssetIdentity get sourceIdentity => SourceAssetIdentity(
    sourceAssetId: sourceAssetId.isEmpty ? sourceId : sourceAssetId,
    displayName: displayName.isEmpty ? label : displayName,
    sourceKind: sourceKind.isEmpty ? sourceType : sourceKind,
    resolverUri: resolverUri,
    localHintPath: localHintPath,
    metadata: sourceIdentityMetadata,
  );

  NarrativeSourceRef copyWith({
    String? sourceType,
    String? sourceId,
    String? label,
    String? description,
    String? sourceAssetId,
    String? displayName,
    String? sourceKind,
    String? resolverUri,
    String? localHintPath,
    JsonMap? sourceIdentityMetadata,
    JsonMap? metadata,
  }) {
    // 中文注释: 引用合同在后续 claim/profile/review 间会被频繁浅改，这里先提供稳定 copy 入口。
    return NarrativeSourceRef(
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      label: label ?? this.label,
      description: description ?? this.description,
      sourceAssetId: sourceAssetId ?? this.sourceAssetId,
      displayName: displayName ?? this.displayName,
      sourceKind: sourceKind ?? this.sourceKind,
      resolverUri: resolverUri ?? this.resolverUri,
      localHintPath: localHintPath ?? this.localHintPath,
      sourceIdentityMetadata:
          sourceIdentityMetadata ?? this.sourceIdentityMetadata,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeSourceRef.fromJson(JsonMap json) {
    // 中文注释: sourceType 故意保留原始字符串，避免未来未知来源被枚举化后静默丢失。
    final sourceIdentity = SourceAssetIdentity.fromJson(json);
    return NarrativeSourceRef(
      sourceType: ValueReaders.stringValue(
        json['source_type'],
        sourceIdentity.sourceKind,
      ).trim(),
      sourceId: ValueReaders.stringValue(
        json['source_id'],
        sourceIdentity.sourceAssetId,
      ).trim(),
      label: ValueReaders.stringValue(
        json['label'],
        sourceIdentity.displayName,
      ).trim(),
      description: ValueReaders.stringValue(json['description']).trim(),
      sourceAssetId: sourceIdentity.sourceAssetId,
      displayName: sourceIdentity.displayName,
      sourceKind: sourceIdentity.sourceKind,
      resolverUri: sourceIdentity.resolverUri,
      localHintPath: sourceIdentity.localHintPath,
      sourceIdentityMetadata: sourceIdentity.metadata,
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: JSON 输出保持开放字段结构，供后续 runtime、repository 与测试直接复用。
    return <String, Object?>{
      'source_type': sourceType,
      'source_id': sourceId,
      'label': label,
      'description': description,
      'source_asset_id': sourceAssetId,
      'display_name': displayName,
      'source_kind': sourceKind,
      'resolver_uri': resolverUri,
      'local_hint_path': localHintPath,
      'source_identity': sourceIdentity.toJson(),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
