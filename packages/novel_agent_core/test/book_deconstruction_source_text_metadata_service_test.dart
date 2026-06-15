import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('BookDeconstructionSourceTextMetadataService', () {
    const service = BookDeconstructionSourceTextMetadataService();

    test('优先保留显式标题并正确识别常见媒体类型', () {
      expect(
        service.resolveSourceTitle(
          sourceTitle: '海上城邦',
          sourceAbsolutePath: 'D:/books/harbor_story.txt',
          sourceContent: '第一章 港口风暴',
        ),
        '海上城邦',
      );
      expect(service.mediaTypeOf('D:/books/harbor_story.md'), 'text/markdown');
      expect(
        service.mediaTypeOf('D:/books/harbor_story.markdown'),
        'text/markdown',
      );
      expect(
        service.mediaTypeOf('D:/books/harbor_story.epub'),
        'application/epub+zip',
      );
      expect(service.mediaTypeOf('D:/books/harbor_story.txt'), 'text/plain');
    });

    test('标题缺省时会退回路径文件名和首行内容', () {
      expect(
        service.resolveSourceTitle(
          sourceTitle: '',
          sourceAbsolutePath: 'D:/books/harbor_story.txt',
          sourceContent: '第一章 港口风暴',
        ),
        'harbor_story',
      );
      expect(
        service.resolveSourceTitle(
          sourceTitle: '',
          sourceAbsolutePath: '',
          sourceContent:
              '这是一个非常非常非常非常非常非常非常非常长的首行标题，超过截断长度后应被收束。',
        ),
        '这是一个非常非常非常非常非常非常非常非常长的首行标题，超过截断长度后应被...',
      );
    });
  });
}
