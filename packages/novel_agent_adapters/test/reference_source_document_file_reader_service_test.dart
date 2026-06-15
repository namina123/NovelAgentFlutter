import 'dart:io';

import 'package:archive/archive.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceDocumentFileReaderService', () {
    late Directory tempDirectory;
    late ReferenceSourceDocumentFileReaderService readerService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'reference_source_document_file_reader_test_',
      );
      readerService = const ReferenceSourceDocumentFileReaderService();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('reads utf8 text with stable source metadata', () async {
      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample_utf8.txt',
      );
      await sourceFile.writeAsString('哈利在楼梯间生活。');

      final result = await readerService.read(sourceFilePath: sourceFile.path);

      expect(result.sourceFilePath, sourceFile.path);
      expect(result.sourceTitle, 'sample_utf8.txt');
      expect(result.sourceText, '哈利在楼梯间生活。');
      expect(result.decodeMode, 'utf8');
    });

    test('falls back to latin1 when bytes are not valid utf8', () async {
      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample_latin1.txt',
      );
      await sourceFile.writeAsBytes(<int>[0x63, 0x61, 0x66, 0xe9]);

      final result = await readerService.read(sourceFilePath: sourceFile.path);

      expect(result.sourceText, 'café');
      expect(result.decodeMode, 'latin1');
    });

    test('prefers gbk decode when the fallback text shows mojibake', () async {
      final sourceFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}sample_gbk.txt',
      );
      await sourceFile.writeAsBytes(
        gbk.encode('''
　　Harry Potter and the Sorcerer's Stone
　　CHAPTER ONE
　　THE BOY WHO LIVED
哈利在楼梯间生活。
'''),
      );

      final result = await readerService.read(sourceFilePath: sourceFile.path);

      expect(result.decodeMode, 'gbk');
      expect(result.sourceText, contains('CHAPTER ONE'));
      expect(result.sourceText, contains('THE BOY WHO LIVED'));
      expect(result.sourceText, contains('哈利在楼梯间生活。'));
      expect(result.sourceText, isNot(contains('¡¡¡¡CHAPTER ONE')));
    });

    test(
      'routes epub files through the epub reader and extracts ordered text',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}sample_story.epub',
        );
        await sourceFile.writeAsBytes(_buildSampleEpubBytes());

        final result = await readerService.read(
          sourceFilePath: sourceFile.path,
        );

        expect(result.sourceFilePath, sourceFile.path);
        expect(result.sourceTitle, '哈利波特示例');
        expect(result.decodeMode, 'epub');
        expect(result.sourceText, contains('第一章 港口风暴'));
        expect(result.sourceText, contains('第二章 议会阴影'));
        expect(result.sourceText, isNot(contains('<h1>')));
      },
    );
  });
}

List<int> _buildSampleEpubBytes() {
  // 中文注释: 测试里用最小 EPUB 容器验证 zip 路由、container.xml、opf 与 spine 顺序都能被 reader 正确消费。
  final archive = Archive();
  archive.addFile(
    ArchiveFile.string('mimetype', 'application/epub+zip', ArchiveFile.STORE),
  );
  archive.addFile(
    ArchiveFile.string(
      'META-INF/container.xml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">'
          '<rootfiles>'
          '<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>'
          '</rootfiles>'
          '</container>',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/content.opf',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<package version="3.0" xmlns="http://www.idpf.org/2007/opf" '
          'xmlns:dc="http://purl.org/dc/elements/1.1/">'
          '<metadata>'
          '<dc:title>哈利波特示例</dc:title>'
          '</metadata>'
          '<manifest>'
          '<item id="chap1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>'
          '<item id="chap2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>'
          '</manifest>'
          '<spine>'
          '<itemref idref="chap1"/>'
          '<itemref idref="chap2"/>'
          '</spine>'
          '</package>',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/chapter1.xhtml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<h1>第一章 港口风暴</h1><p>哈利站在海风里。</p>'
          '</body></html>',
    ),
  );
  archive.addFile(
    ArchiveFile.string(
      'OEBPS/chapter2.xhtml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<html xmlns="http://www.w3.org/1999/xhtml"><body>'
          '<h1>第二章 议会阴影</h1><p>城邦议会悄然浮现。</p>'
          '</body></html>',
    ),
  );
  return ZipEncoder().encode(archive)!;
}
