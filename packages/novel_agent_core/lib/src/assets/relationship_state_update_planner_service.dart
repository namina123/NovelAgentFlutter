import 'relationship_record.dart';
import 'relationship_state_update_request.dart';

class RelationshipStateUpdatePlannerService {
  const RelationshipStateUpdatePlannerService();

  RelationshipRecord plan({
    required RelationshipStateUpdateRequest request,
    RelationshipRecord? existingRecord,
  }) {
    // 中文注释: 关系主档必须始终绑定左右实体，防止只更新标题却丢掉真实关系锚点。
    final current = existingRecord;
    final displayName = _pickFirst(
      request.displayName,
      current?.displayName ?? '',
      '未命名关系',
    );
    final leftEntityId = _pickFirst(
      request.leftEntityId,
      current?.leftEntityId ?? '',
    );
    final rightEntityId = _pickFirst(
      request.rightEntityId,
      current?.rightEntityId ?? '',
    );
    return RelationshipRecord(
      id: _pickFirst(
        request.id,
        current?.id ?? '',
        _safeId('$leftEntityId-$rightEntityId-${displayName.trim()}'),
        'relationship',
      ),
      displayName: displayName,
      leftEntityId: leftEntityId,
      rightEntityId: rightEntityId,
      summary: _pickFirst(request.summary, current?.summary ?? ''),
      relationshipType: _pickFirst(
        request.relationshipType,
        current?.relationshipType ?? '',
      ),
      status: _pickFirst(request.status, current?.status ?? '', 'active'),
      relatedEntityIds: _mergeStrings(
        current?.relatedEntityIds ?? const <String>[],
        <String>[leftEntityId, rightEntityId],
      ),
      relatedForeshadowIds: _mergeStrings(
        current?.relatedForeshadowIds ?? const <String>[],
        request.relatedForeshadowIds,
      ),
      relatedTimelineIds: _mergeStrings(
        current?.relatedTimelineIds ?? const <String>[],
        request.relatedTimelineIds,
      ),
      tags: _mergeStrings(current?.tags ?? const <String>[], request.tags),
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
