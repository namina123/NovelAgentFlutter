import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SharedNarrativeAssetContextProjectionService', () {
    test('builds shared narrative sections from loaded asset documents', () {
      final service = SharedNarrativeAssetContextProjectionService();

      final sections = service.buildSections(
        projectFileContents: <String, Object?>{
          'assets/foreshadows/tower_key.foreshadow.md': '''
---
id: tower_key
title: 塔楼密钥
status: pending_payoff
target_payoff_path: chapters/ch08.md
---

# 塔楼密钥

夜里得到的金属密钥，关系到王都塔楼暗门。
''',
          'assets/timeline/tower_night.timeline.md': '''
---
id: tower_night
display_name: 塔楼之夜
phase_label: 第三章后
sequence: 12
---

# 塔楼之夜

主角第一次意识到塔楼事件与王都内乱相关。
''',
          'assets/relationships/master_apprentice.relationship.md': '''
---
id: master_apprentice
display_name: 师徒裂痕
left_entity_id: hero
right_entity_id: mentor
relationship_type: mentor
status: active
---

# 师徒裂痕

师父开始隐瞒真相，双方信任出现裂口。
''',
        },
      );

      expect(sections.map((item) => item['title']), contains('待回收伏笔'));
      expect(sections.map((item) => item['title']), contains('最近时间线'));
      expect(sections.map((item) => item['title']), contains('关键关系变化'));
      expect(
        ValueReaders.stringValue(
          sections.firstWhere((item) => item['title'] == '待回收伏笔')['content'],
        ),
        contains('塔楼密钥'),
      );
    });
  });
}
