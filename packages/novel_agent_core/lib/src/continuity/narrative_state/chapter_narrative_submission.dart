import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/open_json_structure_validator_service.dart';
import '../../common/value_readers.dart';
import 'chapter_narrative_submission_validation_codes.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';
import 'narrative_segment.dart';
import 'narrative_state_claim.dart';
import 'narrative_transition.dart';

const _chapterNarrativeSubmissionCodecService = OpenJsonContractCodecService();
const _chapterNarrativeSubmissionValidatorService =
    OpenJsonStructureValidatorService();

class ChapterNarrativeSubmission {
  const ChapterNarrativeSubmission({
    required this.submissionId,
    required this.chapterRef,
    this.title = '',
    this.summary = '',
    this.claims = const <NarrativeStateClaim>[],
    this.segments = const <NarrativeSegment>[],
    this.transitions = const <NarrativeTransition>[],
    this.finalStateSummary = const <String, Object?>{},
    this.constraintCoverage = const <String, Object?>{},
    this.evidenceRefs = const <NarrativeEvidenceRef>[],
    this.uncertainty = '',
    this.confidence = 0,
    this.schemaVersion = '',
    this.metadata = const <String, Object?>{},
  });

  final String submissionId;
  final NarrativeRef chapterRef;
  final String title;
  final String summary;
  final List<NarrativeStateClaim> claims;
  final List<NarrativeSegment> segments;
  final List<NarrativeTransition> transitions;
  final JsonMap finalStateSummary;
  final JsonMap constraintCoverage;
  final List<NarrativeEvidenceRef> evidenceRefs;
  final String uncertainty;
  final double confidence;
  final String schemaVersion;
  final JsonMap metadata;

  ChapterNarrativeSubmission copyWith({
    String? submissionId,
    NarrativeRef? chapterRef,
    String? title,
    String? summary,
    List<NarrativeStateClaim>? claims,
    List<NarrativeSegment>? segments,
    List<NarrativeTransition>? transitions,
    JsonMap? finalStateSummary,
    JsonMap? constraintCoverage,
    List<NarrativeEvidenceRef>? evidenceRefs,
    String? uncertainty,
    double? confidence,
    String? schemaVersion,
    JsonMap? metadata,
  }) {
    // 中文注释: submission 会在 writer/recovery/review 链上被局部修补，这里统一提供稳定 copy 入口。
    return ChapterNarrativeSubmission(
      submissionId: submissionId ?? this.submissionId,
      chapterRef: chapterRef ?? this.chapterRef,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      claims: claims ?? this.claims,
      segments: segments ?? this.segments,
      transitions: transitions ?? this.transitions,
      finalStateSummary: finalStateSummary ?? this.finalStateSummary,
      constraintCoverage: constraintCoverage ?? this.constraintCoverage,
      evidenceRefs: evidenceRefs ?? this.evidenceRefs,
      uncertainty: uncertainty ?? this.uncertainty,
      confidence: confidence ?? this.confidence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      metadata: metadata ?? this.metadata,
    );
  }

  factory ChapterNarrativeSubmission.fromJson(JsonMap json) {
    // 中文注释: submission 作为章节 sidecar 的升级形态，只承接结构化提交，不扫描正文猜语义。
    return ChapterNarrativeSubmission(
      submissionId: ValueReaders.stringValue(json['submission_id']).trim(),
      chapterRef: NarrativeRef.fromJson(
        ValueReaders.mapValue(json['chapter_ref']),
      ),
      title: ValueReaders.stringValue(json['title']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      claims: ValueReaders.mapList(
        json['claims'],
      ).map(NarrativeStateClaim.fromJson).toList(growable: false),
      segments: ValueReaders.mapList(
        json['segments'],
      ).map(NarrativeSegment.fromJson).toList(growable: false),
      transitions: ValueReaders.mapList(
        json['transitions'],
      ).map(NarrativeTransition.fromJson).toList(growable: false),
      finalStateSummary: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['final_state_summary']),
      ),
      constraintCoverage: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['constraint_coverage']),
      ),
      evidenceRefs: ValueReaders.mapList(
        json['evidence_refs'],
      ).map(NarrativeEvidenceRef.fromJson).toList(growable: false),
      uncertainty: ValueReaders.stringValue(json['uncertainty']).trim(),
      confidence: ValueReaders.doubleValue(json['confidence']),
      schemaVersion: _chapterNarrativeSubmissionCodecService.readSchemaVersion(
        json,
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: submission 输出时显式保留章内 segment/transition/final state/constraint coverage，供后续工具和存储层接管。
    return <String, Object?>{
      'submission_id': submissionId,
      'chapter_ref': chapterRef.toJson(),
      'title': title,
      'summary': summary,
      'claims': claims.map((entry) => entry.toJson()).toList(growable: false),
      'segments': segments
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'transitions': transitions
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'final_state_summary': ValueReaders.deepCopyMap(finalStateSummary),
      'constraint_coverage': ValueReaders.deepCopyMap(constraintCoverage),
      'evidence_refs': evidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'uncertainty': uncertainty,
      'confidence': confidence,
      'schema_version': schemaVersion,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 本轮只做最小 submission 结构校验，不在这里判断 transition 是否写得“像某种题材”。
    final result = <String>[];
    result.addAll(
      _chapterNarrativeSubmissionValidatorService.requireNonBlankString(
        submissionId,
        ChapterNarrativeSubmissionValidationCodes.missingSubmissionId,
      ),
    );
    result.addAll(
      _chapterNarrativeSubmissionValidatorService.requireNonBlankString(
        chapterRef.refId,
        ChapterNarrativeSubmissionValidationCodes.missingChapterRef,
      ),
    );
    result.addAll(segments.expand((segment) => segment.validateBasics()));
    result.addAll(
      transitions.expand((transition) => transition.validateBasics()),
    );
    return result;
  }
}
