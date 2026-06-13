import 'dart:io';

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
  });
}
