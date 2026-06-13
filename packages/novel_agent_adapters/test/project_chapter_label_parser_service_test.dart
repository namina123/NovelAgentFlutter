import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectChapterLabelParserService', () {
    const service = ProjectChapterLabelParserService();

    test(
      'normalizes arabic and full-width chapter labels into canonical form',
      () {
        expect(service.extractCanonicalLabel('继续写第3章。'), '第03章');
        expect(service.extractCanonicalLabel('继续写第03章。'), '第03章');
        expect(service.extractCanonicalLabel('继续写第０９章。'), '第09章');
      },
    );

    test('parses Chinese numeral chapter labels', () {
      expect(service.extractCanonicalLabel('继续写第三章。'), '第03章');
      expect(service.extractCanonicalLabel('请直接进入第十二章正文。'), '第12章');
      expect(service.extractCanonicalLabel('把第一百零二章补完。'), '第102章');
    });

    test('extracts chapter number from file paths and long prompts', () {
      expect(service.extractChapterNumber('chapters/第03章_雨夜入城.md'), 3);
      expect(
        service.extractCanonicalLabel('先承接前文，不要回退铺垫，直接把第三章门后那句回应写出来。'),
        '第03章',
      );
    });

    test(
      'prefers the intended target chapter when prompt also references previous chapter',
      () {
        const prompt = '''
先承接当前项目里第02章章末已经落定的状态，不要回退铺垫。
直接把第三章正式写出来。
''';

        expect(service.extractCanonicalLabel(prompt), '第02章');
        expect(service.extractLikelyTargetCanonicalLabel(prompt), '第03章');
        expect(service.extractLikelyTargetChapterNumber(prompt), 3);
      },
    );
  });
}
