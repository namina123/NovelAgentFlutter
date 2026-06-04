import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_ref.dart';

class NarrativeEvidenceResolution {
  const NarrativeEvidenceResolution({
    required this.evidenceRef,
    required this.status,
    this.targetRef,
    this.snapshotId = '',
    this.snapshotLabel = '',
    this.matchedSnapshotCount = 0,
    this.textLength = 0,
    this.lineCount = 0,
    this.excerptMatched = false,
    this.message = '',
    this.metadata = const <String, Object?>{},
  });

  final NarrativeEvidenceRef evidenceRef;
  final String status;
  final NarrativeRef? targetRef;
  final String snapshotId;
  final String snapshotLabel;
  final int matchedSnapshotCount;
  final int textLength;
  final int lineCount;
  final bool excerptMatched;
  final String message;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: resolver 结果后续可直接投给 review/submission 报告，因此保留稳定 JSON 结构。
    return <String, Object?>{
      'evidence_ref': evidenceRef.toJson(),
      'status': status,
      'target_ref': targetRef?.toJson() ?? <String, Object?>{},
      'snapshot_id': snapshotId,
      'snapshot_label': snapshotLabel,
      'matched_snapshot_count': matchedSnapshotCount,
      'text_length': textLength,
      'line_count': lineCount,
      'excerpt_matched': excerptMatched,
      'message': message,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
