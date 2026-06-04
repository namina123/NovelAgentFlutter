import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_ref.dart';

class NarrativeTextSpanRef {
  const NarrativeTextSpanRef({
    required this.targetRef,
    this.startOffset = 0,
    this.endOffset = 0,
    this.startLine = 0,
    this.endLine = 0,
    this.excerpt = '',
    this.metadata = const <String, Object?>{},
  });

  final NarrativeRef targetRef;
  final int startOffset;
  final int endOffset;
  final int startLine;
  final int endLine;
  final String excerpt;
  final JsonMap metadata;

  NarrativeTextSpanRef copyWith({
    NarrativeRef? targetRef,
    int? startOffset,
    int? endOffset,
    int? startLine,
    int? endLine,
    String? excerpt,
    JsonMap? metadata,
  }) {
    // 中文注释: 文本片段定位会在评审和证据细化时局部调整，因此单独保留 copyWith。
    return NarrativeTextSpanRef(
      targetRef: targetRef ?? this.targetRef,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
      startLine: startLine ?? this.startLine,
      endLine: endLine ?? this.endLine,
      excerpt: excerpt ?? this.excerpt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeTextSpanRef.fromJson(JsonMap json) {
    // 中文注释: 片段引用始终依附于 targetRef，避免只留裸 offset 而丢失所指对象。
    return NarrativeTextSpanRef(
      targetRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['target_ref']),
      ),
      startOffset: ValueReaders.intValue(json['start_offset']),
      endOffset: ValueReaders.intValue(json['end_offset']),
      startLine: ValueReaders.intValue(json['start_line']),
      endLine: ValueReaders.intValue(json['end_line']),
      excerpt: ValueReaders.stringValue(json['excerpt']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 统一输出 target_ref，方便后续 evidence、review finding、activation report 直接复用。
    return <String, Object?>{
      'target_ref': targetRef.toJson(),
      'start_offset': startOffset,
      'end_offset': endOffset,
      'start_line': startLine,
      'end_line': endLine,
      'excerpt': excerpt,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
