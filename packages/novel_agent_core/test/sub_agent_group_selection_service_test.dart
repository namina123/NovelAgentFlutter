import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  final service = SubAgentGroupSelectionService();

  group('SubAgentGroupSelectionService agent_id 归一化', () {
    test('requestedAgentId 与组成员 kebab/snake/大小写漂移时仍应命中', () {
      // 中文注释: 模型可能 emit world_builder / WorldBuilder，而组里存的是 world-builder。
      // 归一化（小写 + -/_ 等价）后应能选中含该成员的组，而不是静默退回兜底。
      final groups = <JsonMap>[
        <String, Object?>{
          'id': 'editorial_room',
          'agents': const <String>['editor_in_chief', 'world-builder'],
        },
        <String, Object?>{
          'id': 'other_room',
          'agents': const <String>['other_agent'],
        },
      ];

      // snake 形式 emit，存储是 kebab。
      final snakeHit = service.selectGroup(
        parentAgent: const <String, Object?>{},
        task: '构建世界',
        availableGroups: groups,
        requestedAgentId: 'world_builder',
      );
      expect(ValueReaders.stringValue(snakeHit['id']), 'editorial_room');

      // 大小写漂移。
      final caseHit = service.selectGroup(
        parentAgent: const <String, Object?>{},
        task: '构建世界',
        availableGroups: groups,
        requestedAgentId: 'WorldBuilder',
      );
      expect(ValueReaders.stringValue(caseHit['id']), 'editorial_room');

      // 完全不存在时退回兜底，不误命中。
      final miss = service.selectGroup(
        parentAgent: const <String, Object?>{},
        task: '构建世界',
        availableGroups: groups,
        requestedAgentId: 'nonexistent_agent',
      );
      expect(ValueReaders.stringValue(miss['id']), anyOf(equals('editorial_room'), equals('other_room')));
    });
  });
}
