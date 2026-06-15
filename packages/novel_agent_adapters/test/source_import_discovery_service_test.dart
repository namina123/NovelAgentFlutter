import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SourceImportDiscoveryService', () {
    late Directory tempDirectory;
    late SourceImportDiscoveryService discoveryService;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'source_import_discovery_service_test_',
      );
      discoveryService = const SourceImportDiscoveryService();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'discovers a single supported file without changing its path hint',
      () async {
        final sourceFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}single_source.md',
        );
        await sourceFile.writeAsString('第一章 港口风暴');

        final result = await discoveryService.discover(
          SourceImportRequest(
            requestId: 'single-file-request',
            selections: <SourceImportSelection>[
              SourceImportSelection(
                selectionId: 'selection-1',
                selectionKind: SourceImportSelectionKinds.singleFile,
                sourceIdentity: const SourceAssetIdentity(
                  sourceAssetId: 'asset-1',
                  sourceKind: 'file',
                  displayName: 'single_source.md',
                  localHintPath: 'single_source.md',
                ),
                sourceLocator: sourceFile.path,
                sortOrder: 1,
                mediaType: '',
                relativePathHint: '',
                recursive: false,
              ),
            ],
          ),
        );

        expect(result.skippedPaths, isEmpty);
        expect(result.selections, hasLength(1));
        final selection = result.selections.single;
        expect(selection.selectionKind, SourceImportSelectionKinds.singleFile);
        expect(selection.sourceLocator, sourceFile.path.replaceAll('\\', '/'));
        expect(selection.mediaType, 'text/markdown');
        expect(selection.relativePathHint, 'single_source.md');
      },
    );

    test(
      'recursively discovers only supported files under a directory and preserves nested relative paths',
      () async {
        final sourceRoot = Directory(
          '${tempDirectory.path}${Platform.pathSeparator}source_root',
        )..createSync(recursive: true);
        final chapterOne = File(
          '${sourceRoot.path}${Platform.pathSeparator}chapter1.txt',
        );
        final nestedDirectory = Directory(
          '${sourceRoot.path}${Platform.pathSeparator}nested',
        )..createSync(recursive: true);
        final chapterTwo = File(
          '${nestedDirectory.path}${Platform.pathSeparator}chapter2.markdown',
        );
        final ignoredImage = File(
          '${nestedDirectory.path}${Platform.pathSeparator}cover.png',
        );
        final notes = File(
          '${sourceRoot.path}${Platform.pathSeparator}notes.md',
        );
        await chapterOne.writeAsString('第一章');
        await chapterTwo.writeAsString('第二章');
        await ignoredImage.writeAsBytes(<int>[0x89, 0x50, 0x4E, 0x47]);
        await notes.writeAsString('附注');

        final result = await discoveryService.discover(
          SourceImportRequest(
            requestId: 'directory-request',
            selections: <SourceImportSelection>[
              SourceImportSelection(
                selectionId: 'directory-selection',
                selectionKind: SourceImportSelectionKinds.directory,
                sourceIdentity: const SourceAssetIdentity(
                  sourceAssetId: 'directory-asset',
                  sourceKind: 'directory',
                  displayName: 'source_root',
                  localHintPath: 'source_root',
                ),
                sourceLocator: sourceRoot.path,
                sortOrder: 1,
                mediaType: 'inode/directory',
                relativePathHint: 'source_root',
                recursive: true,
              ),
            ],
          ),
        );

        expect(result.selections, hasLength(3));
        expect(
          result.selections.map((selection) => selection.relativePathHint),
          containsAllInOrder(<String>[
            'chapter1.txt',
            'nested/chapter2.markdown',
            'notes.md',
          ]),
        );
        expect(
          result.selections.map((selection) => selection.mediaType),
          containsAllInOrder(<String>[
            'text/plain',
            'text/markdown',
            'text/markdown',
          ]),
        );
        expect(
          result.selections.every(
            (selection) =>
                selection.selectionKind ==
                SourceImportSelectionKinds.singleFile,
          ),
          isTrue,
        );
        expect(
          result.skippedPaths.single,
          ignoredImage.path.replaceAll('\\', '/'),
        );
      },
    );
  });
}
