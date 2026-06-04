import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
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
    this.constraintCoverage = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String deliveryId;
  final String chapterPath;
  final String deliveryState;
  final String chapterBodyState;
  final String sidecarState;
  final List<NarrativeEvidenceRef> deliveryEvidenceRefs;
  final ChapterDeliveryStateResult stateResult;
  final JsonMap constraintCoverage;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'delivery_id': deliveryId,
      'chapter_path': chapterPath,
      'delivery_state': deliveryState,
      'chapter_body_state': chapterBodyState,
      'sidecar_state': sidecarState,
      'delivery_evidence_refs': deliveryEvidenceRefs
          .map((entry) => entry.toJson())
          .toList(growable: false),
      'state_result': stateResult.toJson(),
      'constraint_coverage': ValueReaders.deepCopyMap(constraintCoverage),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
