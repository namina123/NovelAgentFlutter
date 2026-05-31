import 'timeline_record.dart';
import 'timeline_state_update_request.dart';

class TimelineStateUpdatePlannerService {
  const TimelineStateUpdatePlannerService();

  TimelineRecord plan({
    required TimelineStateUpdateRequest request,
    TimelineRecord? existingRecord,
  }) {
    // 中文注释: 时间线合并只处理事件快照本身，不在这里推断任何 UI 展示逻辑。
    final current = existingRecord;
    final displayName = _pickFirst(
      request.displayName,
      current?.displayName ?? '',
      '未命名时间线事件',
    );
    final recordId = _pickFirst(request.id, current?.id ?? '', _safeId(displayName), 'timeline');
    return TimelineRecord(
      id: recordId,
      displayName: displayName,
      summary: _pickFirst(request.summary, current?.summary ?? ''),
      eventType: _pickFirst(request.eventType, current?.eventType ?? ''),
      status: _pickFirst(request.status, current?.status ?? '', 'planned'),
      phaseLabel: _pickFirst(request.phaseLabel, current?.phaseLabel ?? ''),
      sequence: request.sequence > 0
          ? request.sequence
          : (current?.sequence ?? 0),
      relatedEntityIds: _mergeStrings(
        current?.relatedEntityIds ?? const <String>[],
        request.relatedEntityIds,
      ),
      relatedForeshadowIds: _mergeStrings(
        current?.relatedForeshadowIds ?? const <String>[],
        request.relatedForeshadowIds,
      ),
      relatedRelationshipIds: _mergeStrings(
        current?.relatedRelationshipIds ?? const <String>[],
        request.relatedRelationshipIds,
      ),
      relatedPaths: _mergeStrings(
        current?.relatedPaths ?? const <String>[],
        request.relatedPaths,
      ),
      notes: _joinNotes(current?.notes ?? '', request.notes),
      sourcePath: current?.sourcePath ?? '',
      metadata: <String, Object?>{
        ...?current?.metadata,
        ...request.metadata,
      },
    );
  }

  String _pickFirst(String first, [String second = '', String third = '', String fourth = '']) {
    for (final candidate in <String>[first, second, third, fourth]) {
      if (candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return '';
  }

  List<String> _mergeStrings(List<String> left, List<String> right) {
    final result = <String>[];
    for (final value in <String>[...left, ...right]) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty && !result.contains(trimmed)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  String _joinNotes(String left, String right) {
    final leftTrimmed = left.trim();
    final rightTrimmed = right.trim();
    if (leftTrimmed.isEmpty) {
      return rightTrimmed;
    }
    if (rightTrimmed.isEmpty || leftTrimmed.contains(rightTrimmed)) {
      return leftTrimmed;
    }
    return '$leftTrimmed\n\n$rightTrimmed'.trim();
  }

  String _safeId(String value) {
    var result = value.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result;
  }
}
