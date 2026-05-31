import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'timeline_state_update_request.dart';

class TimelineStateUpdateRequestMapperService {
  const TimelineStateUpdateRequestMapperService();

  TimelineStateUpdateRequest fromToolArguments(JsonMap arguments) {
    // 中文注释: 时间线工具参数归一化保持在 core，后续 CLI/GUI/MCP 共用同一字段合同。
    return TimelineStateUpdateRequest(
      id: ValueReaders.stringValue(arguments['timeline_id'] ?? arguments['id']).trim(),
      displayName: ValueReaders.stringValue(
        arguments['display_name'] ?? arguments['title'] ?? arguments['name'],
        '未命名时间线事件',
      ).trim(),
      summary: ValueReaders.stringValue(
        arguments['summary'] ?? arguments['content'],
      ).trim(),
      eventType: ValueReaders.stringValue(arguments['event_type']).trim(),
      status: ValueReaders.stringValue(arguments['status']).trim(),
      phaseLabel: ValueReaders.stringValue(arguments['phase_label']).trim(),
      sequence: ValueReaders.intValue(arguments['sequence']),
      relatedEntityIds: ValueReaders.stringList(arguments['related_entity_ids']),
      relatedForeshadowIds: ValueReaders.stringList(
        arguments['related_foreshadow_ids'],
      ),
      relatedRelationshipIds: ValueReaders.stringList(
        arguments['related_relationship_ids'],
      ),
      relatedPaths: ValueReaders.stringList(arguments['related_paths']),
      notes: ValueReaders.stringValue(arguments['notes']).trim(),
      metadata: ValueReaders.deepCopyMap(ValueReaders.mapValue(arguments['metadata'])),
    );
  }
}
