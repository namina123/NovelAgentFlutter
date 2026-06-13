import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../workflow/chapter_delivery_failure.dart';
import '../../workflow/chapter_delivery_state_result.dart';

class SubmitChapterDeliveryResult {
  const SubmitChapterDeliveryResult({
    required this.deliveryId,
    required this.chapterPath,
    required this.deliveryState,
    required this.chapterBodyState,
    required this.sidecarState,
    required this.deliveryEvidenceRefs,
    required this.stateResult,
    this.requestedChapterPath = '',
    this.resolvedChapterPath = '',
    this.title = '',
    this.pathResolution = const <String, Object?>{},
    this.submission = const <String, Object?>{},
    this.constraintCoverage = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String deliveryId;
  final String chapterPath;
  final String requestedChapterPath;
  final String resolvedChapterPath;
  final String title;
  final String deliveryState;
  final String chapterBodyState;
  final String sidecarState;
  final List<NarrativeEvidenceRef> deliveryEvidenceRefs;
  final ChapterDeliveryStateResult stateResult;
  ChapterDeliveryFailure? get deliveryFailure => stateResult.deliveryFailure;
  final JsonMap pathResolution;
  final JsonMap submission;
  final JsonMap constraintCoverage;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'delivery_id': deliveryId,
      'chapter_path': chapterPath,
      'requested_chapter_path': requestedChapterPath,
      'resolved_chapter_path': resolvedChapterPath,
      'title': title,
      'delivery_state': deliveryState,
      'chapter_body_state': chapterBodyState,
      'sidecar_state': sidecarState,
      'delivery_evidence_refs': deliveryEvidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      if (deliveryFailure != null)
        'delivery_failure': deliveryFailure!.toJson(),
      'state_result': stateResult.toJson(),
      'path_resolution': ValueReaders.deepCopyMap(pathResolution),
      'submission': ValueReaders.deepCopyMap(submission),
      'constraint_coverage': ValueReaders.deepCopyMap(constraintCoverage),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
