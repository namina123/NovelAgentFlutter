import '../../common/json_types.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'chapter_narrative_submission_validation_codes.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';
import 'narrative_text_span_ref.dart';

const _narrativeTransitionValidatorService =
    OpenJsonStructureValidatorService();

class NarrativeTransition {
  const NarrativeTransition({
    required this.transitionId,
    required this.transitionKind,
    this.fromSegmentId = '',
    this.toSegmentId = '',
    this.textSpan,
    this.scopeRef,
    this.frameRef,
    this.claimIds = const <String>[],
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.summary = '',
    this.metadata = const <String, Object?>{},
  });

  final String transitionId;
  final String transitionKind;
  final String fromSegmentId;
  final String toSegmentId;
  final NarrativeTextSpanRef? textSpan;
  final NarrativeRef? scopeRef;
  final NarrativeRef? frameRef;
  final List<String> claimIds;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final String summary;
  final JsonMap metadata;

  NarrativeTransition copyWith({
    String? transitionId,
    String? transitionKind,
    String? fromSegmentId,
    String? toSegmentId,
    NarrativeTextSpanRef? textSpan,
    NarrativeRef? scopeRef,
    NarrativeRef? frameRef,
    List<String>? claimIds,
    List<NarrativeEvidenceRef>? evidenceRefs,
    String? summary,
    JsonMap? metadata,
  }) {
    // 中文注释: transition 只表达章内变化点本身，不在这里解释变化类型的文学语义。
    return NarrativeTransition(
      transitionId: transitionId ?? this.transitionId,
      transitionKind: transitionKind ?? this.transitionKind,
      fromSegmentId: fromSegmentId ?? this.fromSegmentId,
      toSegmentId: toSegmentId ?? this.toSegmentId,
      textSpan: textSpan ?? this.textSpan,
      scopeRef: scopeRef ?? this.scopeRef,
      frameRef: frameRef ?? this.frameRef,
      claimIds: claimIds ?? this.claimIds,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      summary: summary ?? this.summary,
      metadata: metadata ?? this.metadata,
    );
  }

  factory NarrativeTransition.fromJson(JsonMap json) {
    // 中文注释: transitionKind 故意保留开放字符串，避免 core 写死题材分支。
    final rawTextSpan = ValueReaders.mapValue(json['text_span']);
    final rawScopeRef = ValueReaders.mapValue(json['scope_ref']);
    final rawFrameRef = ValueReaders.mapValue(json['frame_ref']);
    return NarrativeTransition(
      transitionId: ValueReaders.stringValue(json['transition_id']).trim(),
      transitionKind: ValueReaders.stringValue(json['transition_kind']).trim(),
      fromSegmentId: ValueReaders.stringValue(json['from_segment_id']).trim(),
      toSegmentId: ValueReaders.stringValue(json['to_segment_id']).trim(),
      textSpan: rawTextSpan.isEmpty
          ? null
          : NarrativeTextSpanRef.fromJson(rawTextSpan),
      scopeRef: rawScopeRef.isEmpty ? null : NarrativeRef.fromJson(rawScopeRef),
      frameRef: rawFrameRef.isEmpty ? null : NarrativeRef.fromJson(rawFrameRef),
      claimIds: ValueReaders.stringList(json['claim_ids']),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: transition 输出时保留 evidence 和 segment 连接信息，方便后续 tool/review 共享。
    return <String, Object?>{
      'transition_id': transitionId,
      'transition_kind': transitionKind,
      'from_segment_id': fromSegmentId,
      'to_segment_id': toSegmentId,
      'text_span': textSpan?.toJson() ?? <String, Object?>{},
      'scope_ref': scopeRef?.toJson() ?? <String, Object?>{},
      'frame_ref': frameRef?.toJson() ?? <String, Object?>{},
      'claim_ids': claimIds,
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'summary': summary,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 本轮只校验 transition 的最小身份与 kind，不在这里验证 segment 连接是否真实存在。
    final result = <String>[];
    result.addAll(
      _narrativeTransitionValidatorService.requireNonBlankString(
        transitionId,
        ChapterNarrativeSubmissionValidationCodes.missingTransitionId,
      ),
    );
    result.addAll(
      _narrativeTransitionValidatorService.requireNonBlankString(
        transitionKind,
        ChapterNarrativeSubmissionValidationCodes.missingTransitionKind,
      ),
    );
    return result;
  }
}
