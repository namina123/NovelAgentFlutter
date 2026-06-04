import '../../common/json_types.dart';
import '../../common/value_readers.dart';

class NarrativeRef {
  const NarrativeRef({
    required this.refType,
    required this.refId,
    this.displayName = '',
    this.relativePath = '',
    this.chapterId = '',
    this.segmentId = '',
    this.sourcePath = '',
    this.metadata = const <String, Object?>{},
  });

  final String refType;
  final String refId;
  final String displayName;
  final String relativePath;
  final String chapterId;
  final String segmentId;
  final String sourcePath;
  final JsonMap metadata;

  NarrativeRef copyWith({
    String? refType,
    String? refId,
    String? displayName,
    String? relativePath,
    String? chapterId,
    String? segmentId,
    String? sourcePath,
    JsonMap? metadata,
  }) {
    // 中文注释: 这里统一承接各种引用位点的小范围修补，避免后续 contract 测试散写 map copy。
    return NarrativeRef(
      refType: refType ?? this.refType,
      refId: refId ?? this.refId,
      displayName: displayName ?? this.displayName,
      relativePath: relativePath ?? this.relativePath,
      chapterId: chapterId ?? this.chapterId,
      segmentId: segmentId ?? this.segmentId,
      sourcePath: sourcePath ?? this.sourcePath,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeRef.fromJson(JsonMap json) {
    // 中文注释: refType 同样保持开放字符串，确保未来新增 ref 类型无需先改 core 枚举。
    return NarrativeRef(
      refType: ValueReaders.stringValue(json['ref_type']).trim(),
      refId: ValueReaders.stringValue(json['ref_id']).trim(),
      displayName: ValueReaders.stringValue(json['display_name']).trim(),
      relativePath: ValueReaders.stringValue(json['relative_path']).trim(),
      chapterId: ValueReaders.stringValue(json['chapter_id']).trim(),
      segmentId: ValueReaders.stringValue(json['segment_id']).trim(),
      sourcePath: ValueReaders.stringValue(json['source_path']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 引用合同统一落到固定键名，方便 claims、review、activation 后续共享序列化口径。
    return <String, Object?>{
      'ref_type': refType,
      'ref_id': refId,
      'display_name': displayName,
      'relative_path': relativePath,
      'chapter_id': chapterId,
      'segment_id': segmentId,
      'source_path': sourcePath,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
