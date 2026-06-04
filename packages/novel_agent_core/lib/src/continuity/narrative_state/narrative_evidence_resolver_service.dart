import '../../common/value_readers.dart';
import 'narrative_evidence_ref.dart';
import 'narrative_evidence_resolution.dart';
import 'narrative_evidence_resolution_statuses.dart';
import 'narrative_evidence_text_snapshot.dart';
import 'narrative_ref.dart';
import 'narrative_text_span_ref.dart';

class NarrativeEvidenceResolverService {
  const NarrativeEvidenceResolverService();

  NarrativeEvidenceResolution resolve({
    required NarrativeEvidenceRef evidenceRef,
    List<NarrativeEvidenceTextSnapshot> textSnapshots =
        const <NarrativeEvidenceTextSnapshot>[],
  }) {
    final textSpan = evidenceRef.textSpan;
    if (textSpan == null) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.missing,
        message: 'evidence ref 缺少 text_span，无法做 span 结构校验。',
      );
    }

    final targetRef = _resolveTargetRef(evidenceRef, textSpan);
    if (targetRef == null) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.missing,
        message: 'evidence ref 缺少可解析的 target_ref。',
      );
    }

    if (!_hasSpanCoordinates(textSpan)) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.missing,
        targetRef: targetRef,
        message: 'text_span 缺少 offset/line 范围，无法校验。',
      );
    }

    final matchedSnapshots = textSnapshots
        .where((snapshot) => _matchesRef(snapshot.targetRef, targetRef))
        .toList(growable: false);
    if (matchedSnapshots.isEmpty) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.unresolved,
        targetRef: targetRef,
        message: '当前未提供对应 target_ref 的内存文本，返回 unresolved。',
      );
    }
    if (matchedSnapshots.length > 1) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.ambiguous,
        targetRef: targetRef,
        matchedSnapshotCount: matchedSnapshots.length,
        message: '存在多个内存文本快照同时命中该 target_ref，无法唯一解析。',
      );
    }

    final snapshot = matchedSnapshots.single;
    final textLength = snapshot.text.length;
    final lineCount = _countLines(snapshot.text);
    final offsetIssue = _offsetIssue(textSpan, textLength);
    final lineIssue = _lineIssue(textSpan, lineCount);
    final excerptMatched = _excerptMatched(textSpan, snapshot.text);
    if (offsetIssue.isNotEmpty || lineIssue.isNotEmpty) {
      return _buildResolution(
        evidenceRef: evidenceRef,
        status: NarrativeEvidenceResolutionStatuses.outOfRange,
        targetRef: targetRef,
        snapshotId: snapshot.snapshotId,
        snapshotLabel: snapshot.label,
        matchedSnapshotCount: 1,
        textLength: textLength,
        lineCount: lineCount,
        excerptMatched: excerptMatched,
        message: _joinIssues(<String>[offsetIssue, lineIssue]),
        metadata: <String, Object?>{
          'offset_issue': offsetIssue,
          'line_issue': lineIssue,
        },
      );
    }

    return _buildResolution(
      evidenceRef: evidenceRef,
      status: NarrativeEvidenceResolutionStatuses.resolved,
      targetRef: targetRef,
      snapshotId: snapshot.snapshotId,
      snapshotLabel: snapshot.label,
      matchedSnapshotCount: 1,
      textLength: textLength,
      lineCount: lineCount,
      excerptMatched: excerptMatched,
      message: 'span 范围可解析。',
    );
  }

  List<NarrativeEvidenceResolution> resolveAll({
    required List<NarrativeEvidenceRef> evidenceRefs,
    List<NarrativeEvidenceTextSnapshot> textSnapshots =
        const <NarrativeEvidenceTextSnapshot>[],
  }) {
    return evidenceRefs
        .map(
          (evidenceRef) =>
              resolve(evidenceRef: evidenceRef, textSnapshots: textSnapshots),
        )
        .toList(growable: false);
  }

  NarrativeRef? _resolveTargetRef(
    NarrativeEvidenceRef evidenceRef,
    NarrativeTextSpanRef textSpan,
  ) {
    if (_isPopulatedRef(textSpan.targetRef)) {
      return textSpan.targetRef;
    }
    if (evidenceRef.targetRef != null &&
        _isPopulatedRef(evidenceRef.targetRef!)) {
      return evidenceRef.targetRef;
    }
    return null;
  }

  bool _isPopulatedRef(NarrativeRef ref) {
    return ref.refType.trim().isNotEmpty || ref.refId.trim().isNotEmpty;
  }

  bool _hasSpanCoordinates(NarrativeTextSpanRef textSpan) {
    return textSpan.startOffset > 0 ||
        textSpan.endOffset > 0 ||
        textSpan.startLine > 0 ||
        textSpan.endLine > 0;
  }

  bool _matchesRef(NarrativeRef snapshotRef, NarrativeRef queryRef) {
    if (snapshotRef.refType.trim() != queryRef.refType.trim()) {
      return false;
    }
    if (snapshotRef.refId.trim() != queryRef.refId.trim()) {
      return false;
    }
    if (!_matchesOptionalField(
      queryRef.relativePath,
      snapshotRef.relativePath,
    )) {
      return false;
    }
    if (!_matchesOptionalField(queryRef.chapterId, snapshotRef.chapterId)) {
      return false;
    }
    if (!_matchesOptionalField(queryRef.segmentId, snapshotRef.segmentId)) {
      return false;
    }
    if (!_matchesOptionalField(queryRef.sourcePath, snapshotRef.sourcePath)) {
      return false;
    }
    return true;
  }

  bool _matchesOptionalField(String expected, String actual) {
    final normalizedExpected = expected.trim();
    if (normalizedExpected.isEmpty) {
      return true;
    }
    return normalizedExpected == actual.trim();
  }

  int _countLines(String text) {
    if (text.isEmpty) {
      return 0;
    }
    return '\n'.allMatches(text).length + 1;
  }

  String _offsetIssue(NarrativeTextSpanRef textSpan, int textLength) {
    final hasOffsets = textSpan.startOffset > 0 || textSpan.endOffset > 0;
    if (!hasOffsets) {
      return '';
    }
    if (textSpan.startOffset < 0 || textSpan.endOffset < 0) {
      return 'offset 不能为负数。';
    }
    if (textSpan.endOffset < textSpan.startOffset) {
      return 'end_offset 不能小于 start_offset。';
    }
    if (textSpan.startOffset > textLength || textSpan.endOffset > textLength) {
      return 'offset 超出文本长度。';
    }
    return '';
  }

  String _lineIssue(NarrativeTextSpanRef textSpan, int lineCount) {
    final hasLines = textSpan.startLine > 0 || textSpan.endLine > 0;
    if (!hasLines) {
      return '';
    }
    if (textSpan.startLine <= 0 || textSpan.endLine <= 0) {
      return 'line 范围必须从 1 开始。';
    }
    if (textSpan.endLine < textSpan.startLine) {
      return 'end_line 不能小于 start_line。';
    }
    if (textSpan.startLine > lineCount || textSpan.endLine > lineCount) {
      return 'line 范围超出文本总行数。';
    }
    return '';
  }

  bool _excerptMatched(NarrativeTextSpanRef textSpan, String text) {
    final excerpt = textSpan.excerpt.trim();
    if (excerpt.isEmpty) {
      return false;
    }
    final hasOffsets = textSpan.startOffset > 0 || textSpan.endOffset > 0;
    if (!hasOffsets) {
      return text.contains(excerpt);
    }
    if (textSpan.startOffset < 0 ||
        textSpan.endOffset < textSpan.startOffset ||
        textSpan.endOffset > text.length) {
      return false;
    }
    final spanText = text.substring(textSpan.startOffset, textSpan.endOffset);
    return spanText.contains(excerpt);
  }

  String _joinIssues(List<String> issues) {
    return issues
        .map((issue) => issue.trim())
        .where((issue) => issue.isNotEmpty)
        .join(' ');
  }

  NarrativeEvidenceResolution _buildResolution({
    required NarrativeEvidenceRef evidenceRef,
    required String status,
    NarrativeRef? targetRef,
    String snapshotId = '',
    String snapshotLabel = '',
    int matchedSnapshotCount = 0,
    int textLength = 0,
    int lineCount = 0,
    bool excerptMatched = false,
    String message = '',
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    return NarrativeEvidenceResolution(
      evidenceRef: evidenceRef,
      status: status,
      targetRef: targetRef,
      snapshotId: snapshotId,
      snapshotLabel: snapshotLabel,
      matchedSnapshotCount: matchedSnapshotCount,
      textLength: textLength,
      lineCount: lineCount,
      excerptMatched: excerptMatched,
      message: message,
      metadata: ValueReaders.deepCopyMap(metadata),
    );
  }
}
