import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state.dart';

class ToolRoundEvidence {
  const ToolRoundEvidence({
    required this.toolRoundRef,
    this.toolCallIds = const <String>[],
    this.transcriptMessageIds = const <String>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.metadata = const <String, Object?>{},
  });

  final NarrativeRef toolRoundRef;
  final List<String> toolCallIds;
  final List<String> transcriptMessageIds;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final JsonMap metadata;

  ToolRoundEvidence copyWith({
    NarrativeRef? toolRoundRef,
    List<String>? toolCallIds,
    List<String>? transcriptMessageIds,
    List<NarrativeEvidenceRef>? evidenceRefs,
    JsonMap? metadata,
  }) {
    // 中文注释: 这个桥对象只承接“某一轮工具交互关联了哪些证据”，不混入写作语义判断。
    return ToolRoundEvidence(
      toolRoundRef: toolRoundRef ?? this.toolRoundRef,
      toolCallIds: toolCallIds ?? this.toolCallIds,
      transcriptMessageIds: transcriptMessageIds ?? this.transcriptMessageIds,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ToolRoundEvidence.fromJson(JsonMap json) {
    // 中文注释: 这里补上缺失的 runtime 锚点文件，让后续 narrative evidence 合同有稳定落脚点。
    return ToolRoundEvidence(
      toolRoundRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['tool_round_ref']),
      ),
      toolCallIds: ValueReaders.stringList(json['tool_call_ids']),
      transcriptMessageIds: ValueReaders.stringList(
        json['transcript_message_ids'],
      ),
      evidenceRefs: ValueReaders.mapList(json['evidence_refs'])
          .map(NarrativeEvidenceRef.fromJson)
          .toList(growable: false),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: tool round evidence 只投影结构化证据，不承载正文、claim 或 reviewer 结论本身。
    return <String, Object?>{
      'tool_round_ref': toolRoundRef.toJson(),
      'tool_call_ids': toolCallIds,
      'transcript_message_ids': transcriptMessageIds,
      'evidence_refs': evidenceRefs.map((entry) => entry.toJson()).toList(
        growable: false,
      ),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
