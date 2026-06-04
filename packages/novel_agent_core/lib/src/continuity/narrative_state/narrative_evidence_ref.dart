import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_ref.dart';
import 'narrative_source_ref.dart';
import 'narrative_text_span_ref.dart';

class NarrativeEvidenceRef {
  const NarrativeEvidenceRef({
    required this.evidenceType,
    required this.evidenceId,
    this.sourceRef,
    this.targetRef,
    this.textSpan,
    this.summary = '',
    this.metadata = const <String, Object?>{},
  });

  final String evidenceType;
  final String evidenceId;
  final NarrativeSourceRef? sourceRef;
  final NarrativeRef? targetRef;
  final NarrativeTextSpanRef? textSpan;
  final String summary;
  final JsonMap metadata;

  NarrativeEvidenceRef copyWith({
    String? evidenceType,
    String? evidenceId,
    NarrativeSourceRef? sourceRef,
    NarrativeRef? targetRef,
    NarrativeTextSpanRef? textSpan,
    String? summary,
    JsonMap? metadata,
  }) {
    // 中文注释: 证据引用后续会在 review 或 repair 中增补摘要和位点，这里提供稳定浅改入口。
    return NarrativeEvidenceRef(
      evidenceType: evidenceType ?? this.evidenceType,
      evidenceId: evidenceId ?? this.evidenceId,
      sourceRef: sourceRef ?? this.sourceRef,
      targetRef: targetRef ?? this.targetRef,
      textSpan: textSpan ?? this.textSpan,
      summary: summary ?? this.summary,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeEvidenceRef.fromJson(JsonMap json) {
    // 中文注释: evidenceType 保持开放字符串，避免把未来证据来源收窄成固定少量内置类型。
    final rawSourceRef = ValueReaders.mapValue(json['source_ref']);
    final rawTargetRef = ValueReaders.mapValue(json['target_ref']);
    final rawTextSpan = ValueReaders.mapValue(json['text_span']);
    return NarrativeEvidenceRef(
      evidenceType: ValueReaders.stringValue(json['evidence_type']).trim(),
      evidenceId: ValueReaders.stringValue(json['evidence_id']).trim(),
      sourceRef: rawSourceRef.isEmpty
          ? null
          : NarrativeSourceRef.fromJson(rawSourceRef),
      targetRef: rawTargetRef.isEmpty
          ? null
          : NarrativeRef.fromJson(rawTargetRef),
      textSpan: rawTextSpan.isEmpty
          ? null
          : NarrativeTextSpanRef.fromJson(rawTextSpan),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 证据引用输出时保留可选嵌套对象，便于未来 repository 直接写 JSON/JSONL。
    return <String, Object?>{
      'evidence_type': evidenceType,
      'evidence_id': evidenceId,
      'source_ref': sourceRef?.toJson() ?? <String, Object?>{},
      'target_ref': targetRef?.toJson() ?? <String, Object?>{},
      'text_span': textSpan?.toJson() ?? <String, Object?>{},
      'summary': summary,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
