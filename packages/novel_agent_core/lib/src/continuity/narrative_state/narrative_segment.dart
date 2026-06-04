import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'chapter_narrative_submission_validation_codes.dart';
import 'narrative_ref.dart';
import 'narrative_text_span_ref.dart';

const _narrativeSegmentValidatorService = OpenJsonStructureValidatorService();

class NarrativeSegment {
  const NarrativeSegment({
    required this.segmentId,
    this.orderIndex = 0,
    this.segmentLabel = '',
    this.textSpan,
    this.scopeRef,
    this.frameRef,
    this.sceneRef,
    this.povRef,
    this.claimIds = const <String>[],
    this.summary = '',
    this.constraintCoverage = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String segmentId;
  final int orderIndex;
  final String segmentLabel;
  final NarrativeTextSpanRef? textSpan;
  final NarrativeRef? scopeRef;
  final NarrativeRef? frameRef;
  final NarrativeRef? sceneRef;
  final NarrativeRef? povRef;
  final List<String> claimIds;
  final String summary;
  final JsonMap constraintCoverage;
  final JsonMap metadata;

  NarrativeSegment copyWith({
    String? segmentId,
    int? orderIndex,
    String? segmentLabel,
    NarrativeTextSpanRef? textSpan,
    NarrativeRef? scopeRef,
    NarrativeRef? frameRef,
    NarrativeRef? sceneRef,
    NarrativeRef? povRef,
    List<String>? claimIds,
    String? summary,
    JsonMap? constraintCoverage,
    JsonMap? metadata,
  }) {
    // 中文注释: segment 合同主要承接章内局部状态，不在这里解释这些状态意味着什么。
    return NarrativeSegment(
      segmentId: segmentId ?? this.segmentId,
      orderIndex: orderIndex ?? this.orderIndex,
      segmentLabel: segmentLabel ?? this.segmentLabel,
      textSpan: textSpan ?? this.textSpan,
      scopeRef: scopeRef ?? this.scopeRef,
      frameRef: frameRef ?? this.frameRef,
      sceneRef: sceneRef ?? this.sceneRef,
      povRef: povRef ?? this.povRef,
      claimIds: claimIds ?? this.claimIds,
      summary: summary ?? this.summary,
      constraintCoverage: constraintCoverage ?? this.constraintCoverage,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeSegment.fromJson(JsonMap json) {
    // 中文注释: segment 只记录章内结构化位点，scope/frame/scene/pov 都继续复用开放 ref 模型。
    final rawTextSpan = ValueReaders.mapValue(json['text_span']);
    final rawScopeRef = ValueReaders.mapValue(json['scope_ref']);
    final rawFrameRef = ValueReaders.mapValue(json['frame_ref']);
    final rawSceneRef = ValueReaders.mapValue(json['scene_ref']);
    final rawPovRef = ValueReaders.mapValue(json['pov_ref']);
    return NarrativeSegment(
      segmentId: ValueReaders.stringValue(json['segment_id']).trim(),
      orderIndex: ValueReaders.intValue(json['order_index']),
      segmentLabel: ValueReaders.stringValue(json['segment_label']).trim(),
      textSpan: rawTextSpan.isEmpty
          ? null
          : NarrativeTextSpanRef.fromJson(rawTextSpan),
      scopeRef: rawScopeRef.isEmpty ? null : NarrativeRef.fromJson(rawScopeRef),
      frameRef: rawFrameRef.isEmpty ? null : NarrativeRef.fromJson(rawFrameRef),
      sceneRef: rawSceneRef.isEmpty ? null : NarrativeRef.fromJson(rawSceneRef),
      povRef: rawPovRef.isEmpty ? null : NarrativeRef.fromJson(rawPovRef),
      claimIds: ValueReaders.stringList(json['claim_ids']),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      constraintCoverage: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['constraint_coverage']),
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: segment 输出时显式保留 constraint_coverage，方便后续约束桥和 reviewer 直接消费。
    return <String, Object?>{
      'segment_id': segmentId,
      'order_index': orderIndex,
      'segment_label': segmentLabel,
      'text_span': textSpan?.toJson() ?? <String, Object?>{},
      'scope_ref': scopeRef?.toJson() ?? <String, Object?>{},
      'frame_ref': frameRef?.toJson() ?? <String, Object?>{},
      'scene_ref': sceneRef?.toJson() ?? <String, Object?>{},
      'pov_ref': povRef?.toJson() ?? <String, Object?>{},
      'claim_ids': claimIds,
      'summary': summary,
      'constraint_coverage': ValueReaders.deepCopyMap(constraintCoverage),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 这里只做 segment 身份校验，不做顺序冲突或文本跨度合法性判断。
    final result = <String>[];
    result.addAll(
      _narrativeSegmentValidatorService.requireNonBlankString(
        segmentId,
        ChapterNarrativeSubmissionValidationCodes.missingSegmentId,
      ),
    );
    return result;
  }
}
