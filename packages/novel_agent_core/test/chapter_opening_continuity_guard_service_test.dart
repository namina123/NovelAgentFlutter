import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ChapterOpeningContinuityGuardService', () {
    const service = ChapterOpeningContinuityGuardService();

    test('flags chapter openings that replay the previous tail', () {
      final result = service.evaluate(
        currentChapterContent: '''
# 第03章

王保正家的门是木头的，门环是铁的。陆安在门口站了一会儿，抬手敲了三下。

门里有人应了一声，过了会儿门才开了一条缝。
''',
        previousChapterContent: '''
# 第02章

他走到镇东头那户青砖院子前，犹豫片刻，抬手敲了敲门。

过了一会儿，门开了。开门的是个四十来岁的男人。“你找谁？”
''',
        previousChapterEndExcerpt:
            '他走到镇东头那户青砖院子前，犹豫片刻，抬手敲了敲门。过了一会儿，门开了。开门的是个四十来岁的男人。“你找谁？”',
        nextChapterHandoff: '直接从王保正的回应继续，不要回退重演敲门前。',
      );

      expect(result.blocked, isTrue);
      expect(result.reason, 'chapter_opening_replays_previous_tail');
      expect(result.summary, contains('疑似回退重演'));
      expect(result.openingExcerpt, contains('抬手敲'));
    });

    test('allows chapter openings that directly advance from the handoff', () {
      final result = service.evaluate(
        currentChapterContent: '''
# 第03章

屋里静了一瞬，随后男人把门拉开半扇，目光先落在陆安身上的怪衣裳上。

“你姓什么？从哪里来的？”他没有让开门口，只先把问题抛了出来。
''',
        previousChapterContent: '''
# 第02章

他走到镇东头那户青砖院子前，抬手敲门。门里很快传来一声“谁啊？”。
''',
        previousChapterEndExcerpt: '他走到镇东头那户青砖院子前，抬手敲门。门里很快传来一声“谁啊？”。',
        nextChapterHandoff: '直接从对方开门后的回应继续。',
      );

      expect(result.blocked, isFalse);
      expect(result.hasSignal, isTrue);
    });
  });
}
