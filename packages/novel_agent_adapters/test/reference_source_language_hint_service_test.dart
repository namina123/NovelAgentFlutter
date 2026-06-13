import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceLanguageHintService', () {
    const service = ReferenceSourceLanguageHintService();

    test('infers english from text preview when path does not help', () {
      final inferred = service.infer(
        sourceFilePath: 'D:/references/reference_source.txt',
        sourceTitle: 'Reference Source.txt',
        sourceText:
            'Chapter One\nHarry walked through the hall and said that the castle felt colder than before. '
            'The students were waiting, and the candles were floating above them.\n'
            'Chapter Two\nThe professor had already prepared the room, and the children were talking quietly.',
      );

      expect(inferred, 'en');
    });

    test('infers chinese from cjk-rich preview', () {
      final inferred = service.infer(
        sourceFilePath: 'D:/references/reference_source.txt',
        sourceTitle: '参考资料.txt',
        sourceText:
            '第一章 这是一个中文样本文档，里面包含了足够多的汉字内容，用来验证语言提示服务可以把源文本识别为中文。'
            '第二章 角色进入场景之后继续对话，世界设定和叙事说明也都使用中文表达。',
      );

      expect(inferred, 'zh-CN');
    });

    test('prefers explicit filename token hints before preview scan', () {
      final inferred = service.infer(
        sourceFilePath: 'D:/references/archive_sample_en.txt',
        sourceTitle: 'archive_sample_en.txt',
        sourceText: '...',
      );

      expect(inferred, 'en');
    });
  });
}
