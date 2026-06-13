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
      'ingests Harry Potter volume sample into multiple entry kinds',
      () async {
        final sourceFile = File(_harryPotterVolumeSamplePath());
        expect(await sourceFile.exists(), isTrue);

        final result = await ingestionService.ingestFile(
          sourceFilePath: sourceFile.path,
          packageId: 'pkg_hp_volume_1',
          packageKind: ReferencePackageKinds.referenceWorkPackage,
          displayName: '哈利波特第一卷参考包',
          packageVersionId: 'v1',
          versionLabel: 'volume-1-sample',
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

String _harryPotterVolumeSamplePath() {
  final packageRoot = Directory.current.path;
  final repoRoot = Directory(packageRoot).parent.parent.path;
  return '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter - Volume 1 Raw.txt';
}
