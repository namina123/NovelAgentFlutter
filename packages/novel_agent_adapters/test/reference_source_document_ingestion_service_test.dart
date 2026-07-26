import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReferenceSourceDocumentFileIngestionService', () {
    late Directory tempDirectory;
    late Directory substrateDirectory;
    late SqliteReferenceEvidenceSubstrate substrate;
    late ReferenceSourceDocumentFileIngestionService ingestionService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'reference_source_document_ingestion_test_',
      );
      substrateDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}substrate',
      )..createSync(recursive: true);
      substrate = SqliteReferenceEvidenceSubstrate(
        substrateRootPath: substrateDirectory.path,
      );
      ingestionService = ReferenceSourceDocumentFileIngestionService(
        substrate: substrate,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'builds reference package directly from source txt and exports Chinese projection',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}sample_source.txt',
        );
        await sourceFile.writeAsString('''
CHAPTER ONE
Harry Potter lived with the Dursleys at Privet Drive.

CHAPTER TWO
Letters from Hogwarts kept arriving and Uncle Vernon panicked.

CHAPTER THREE
Hagrid arrived and revealed the truth.
''');
        final bundleDirectory = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}bundle_output',
        );

        final result = await ingestionService.ingestFile(
          sourceFilePath: sourceFile.path,
          packageId: 'pkg_sample',
          packageKind: ReferencePackageKinds.referenceWorkPackage,
          displayName: '哈利波特样本文稿参考包',
          packageVersionId: 'v1',
          versionLabel: '1.0.0',
          createdAt: '2026-06-07T13:10:00Z',
          createdBy: 'test',
          bundleOutputDirectory: bundleDirectory.path,
        );

        expect(result.generatedEntryCount, greaterThanOrEqualTo(5));
        expect(result.targetLanguage, 'zh-CN');
        final summaryFile = File(
          '${bundleDirectory.path}${Platform.pathSeparator}projections${Platform.pathSeparator}summary.md',
        );
        expect(await summaryFile.exists(), isTrue);
        final summaryText = await summaryFile.readAsString();
        expect(summaryText, contains('资料包 ID'));
        expect(summaryText, contains('目标语言'));
        expect(summaryText, isNot(contains('Package ID:')));
        final manifestFile = File(
          '${bundleDirectory.path}${Platform.pathSeparator}manifest.json',
        );
        final manifestText = await manifestFile.readAsString();
        expect(manifestText, contains('"target_language": "zh-CN"'));
      },
    );

    test(
      'ingests a multi-chapter source fixture into multiple entry kinds',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}multi_chapter_source.txt',
        );
        await sourceFile.writeAsString(_multiChapterSourceFixture);

        final result = await ingestionService.ingestFile(
          sourceFilePath: sourceFile.path,
          packageId: 'pkg_multi_chapter_fixture',
          packageKind: ReferencePackageKinds.referenceWorkPackage,
          displayName: '多章节来源夹具参考包',
          packageVersionId: 'v1',
          versionLabel: 'fixture-v1',
          createdAt: '2026-06-07T13:20:00Z',
          createdBy: 'test',
          maxChapterEntries: 5,
          maxEntityEntries: 5,
        );

        expect(result.generatedEntryCount, greaterThanOrEqualTo(7));
        final entries = result.snapshot.entries;
        expect(
          entries
              .where(
                (entry) => entry.entryKind == ReferenceEntryKinds.knowledgeFact,
              )
              .length,
          greaterThanOrEqualTo(4),
        );
        expect(
          entries.any(
            (entry) => entry.entryKind == ReferenceEntryKinds.designElement,
          ),
          isTrue,
        );
        expect(
          entries.any(
            (entry) => entry.entryKind == ReferenceEntryKinds.styleTechnique,
          ),
          isTrue,
        );
      },
    );
  });
}

const String _multiChapterSourceFixture = '''
CHAPTER ONE
Aster Vale crossed the rain-soaked harbor before dawn. Aster Vale noticed a
sealed letter marked with the crest of the North Archive.

CHAPTER TWO
Aster Vale met Rowan Mercer in the old observatory. Rowan Mercer warned that
the North Archive kept a secret map beneath the brass floor.

CHAPTER THREE
Rowan Mercer and Aster Vale followed the map into the underground station.
The locked gate suggested that a hidden danger would return later.

CHAPTER FOUR
Aster Vale heard the council bell and saw the North Archive guards depart.
Rowan Mercer chose to protect the letter instead of revealing its secret.

CHAPTER FIVE
At sunrise, Aster Vale and Rowan Mercer agreed to investigate the missing key.
The final note promised that the truth would surface after the next storm.
''';
