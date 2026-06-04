import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import 'narrative_ref.dart';

class NarrativeEvidenceTextSnapshot {
  const NarrativeEvidenceTextSnapshot({
    required this.targetRef,
    required this.text,
    this.snapshotId = '',
    this.label = '',
    this.metadata = const <String, Object?>{},
  });

  final NarrativeRef targetRef;
  final String snapshotId;
  final String label;
  final String text;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: 文本快照只描述内存中的可校验文本，不承担文件读取或检索来源。
    return <String, Object?>{
      'target_ref': targetRef.toJson(),
      'snapshot_id': snapshotId,
      'label': label,
      'text': text,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
