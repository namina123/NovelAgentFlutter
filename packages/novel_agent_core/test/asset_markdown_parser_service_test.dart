import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Asset markdown parsers', () {
    test('style parser reads frontmatter and markdown body', () {
      final service = StyleProfileMarkdownParserService();
      final parsed = service.parseDocument('''
---
id: serial_style
display_name: 连载风格
genre: 都市奇幻
tags:
  - 克制
  - 悬疑
---

# 连载风格

保持冷静克制的叙事节奏。
强调角色选择带来的后果。
''', relativePath: 'styles/serial_style.style.md');

      expect(parsed['id'], 'serial_style');
      expect(parsed['display_name'], '连载风格');
      expect(parsed['genre'], '都市奇幻');
      expect(ValueReaders.stringList(parsed['tags']), contains('悬疑'));
      expect(
        ValueReaders.stringValue(parsed['summary']),
        contains('保持冷静克制的叙事节奏'),
      );
    });

    test('foreshadow parser splits summary and notes blocks', () {
      final service = ForeshadowRecordMarkdownParserService();
      final parsed = service.parseDocument('''
---
id: tower_secret
title: 高塔秘密
status: planted
---

# 高塔秘密

第一卷里多次提到高塔夜间会发光。

## 备注

第三卷揭示是古代监视装置。
''', relativePath: 'world/foreshadows/tower_secret.foreshadow.md');

      expect(parsed['id'], 'tower_secret');
      expect(parsed['title'], '高塔秘密');
      expect(parsed['status'], 'planted');
      expect(
        ValueReaders.stringValue(parsed['source_path']),
        'world/foreshadows/tower_secret.foreshadow.md',
      );
      expect(ValueReaders.stringValue(parsed['summary']), contains('夜间会发光'));
      expect(ValueReaders.stringValue(parsed['notes']), contains('第三卷揭示'));
    });

    test('timeline parser splits summary and notes blocks', () {
      final service = TimelineRecordMarkdownParserService();
      final parsed = service.parseDocument('''
---
id: tower_glow_night
display_name: 高塔异光之夜
event_type: reveal_hint
sequence: 3
related_entity_ids:
  - character.protagonist
related_foreshadow_ids:
  - tower_secret
---

# 高塔异光之夜

主角第一次在夜里看见高塔异常发光。

## 备注

后续应该指向古代监视装置的伏笔回收。
''', relativePath: 'assets/timeline/tower_glow_night.timeline.md');

      expect(parsed['id'], 'tower_glow_night');
      expect(parsed['display_name'], '高塔异光之夜');
      expect(parsed['event_type'], 'reveal_hint');
      expect(parsed['sequence'], 3);
      expect(
        ValueReaders.stringList(parsed['related_foreshadow_ids']),
        contains('tower_secret'),
      );
      expect(ValueReaders.stringValue(parsed['notes']), contains('监视装置'));
    });

    test('relationship parser splits summary and notes blocks', () {
      final service = RelationshipRecordMarkdownParserService();
      final parsed = service.parseDocument('''
---
id: mentor_conflict
display_name: 师徒裂痕
left_entity_id: character.protagonist
right_entity_id: character.mentor
relationship_type: mentor
related_timeline_ids:
  - tower_glow_night
---

# 师徒裂痕

主角因为高塔事件开始怀疑导师隐瞒真相。

## 备注

后续要逐渐从信任转成对立。
''', relativePath: 'assets/relationships/mentor_conflict.relationship.md');

      expect(parsed['id'], 'mentor_conflict');
      expect(parsed['display_name'], '师徒裂痕');
      expect(parsed['left_entity_id'], 'character.protagonist');
      expect(parsed['right_entity_id'], 'character.mentor');
      expect(
        ValueReaders.stringList(parsed['related_timeline_ids']),
        contains('tower_glow_night'),
      );
      expect(ValueReaders.stringValue(parsed['notes']), contains('信任转成对立'));
    });
  });
}
