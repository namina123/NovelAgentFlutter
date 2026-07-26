import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ImportProjectFilesUseCase', () {
    test(
      'uses discovery results to preserve nested paths when importing directory selections',
      () async {
        final hostPort = _FakeProjectToolHostPort(
          externalFiles: <String, String>{
            '/imports/source/chapter1.txt': '第一章',
            '/imports/source/nested/chapter2.md': '第二章',
          },
        );
        final discoveryPort = _FakeSourceImportDiscoveryPort(
          result: SourceImportDiscoveryResult(
            selections: <SourceImportSelection>[
              SourceImportSelection(
                selectionId: 'chapter-1',
                selectionKind: SourceImportSelectionKinds.singleFile,
                sourceIdentity: const SourceAssetIdentity(
                  sourceAssetId: 'chapter-1-asset',
                  sourceKind: 'file',
                  displayName: 'chapter1.txt',
                  localHintPath: 'chapter1.txt',
                ),
                sourceLocator: '/imports/source/chapter1.txt',
                sortOrder: 1,
                mediaType: 'text/plain',
                relativePathHint: 'chapter1.txt',
                recursive: false,
              ),
              SourceImportSelection(
                selectionId: 'chapter-2',
                selectionKind: SourceImportSelectionKinds.singleFile,
                sourceIdentity: const SourceAssetIdentity(
                  sourceAssetId: 'chapter-2-asset',
                  sourceKind: 'file',
                  displayName: 'nested/chapter2.md',
                  localHintPath: 'nested/chapter2.md',
                ),
                sourceLocator: '/imports/source/nested/chapter2.md',
                sortOrder: 2,
                mediaType: 'text/markdown',
                relativePathHint: 'nested/chapter2.md',
                recursive: false,
              ),
            ],
            skippedPaths: <String>['/imports/source/cover.png'],
          ),
        );
        final useCase = ImportProjectFilesUseCase(
          projectToolHostPort: hostPort,
          sourceImportDiscoveryPort: discoveryPort,
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'project-1',
            name: '导入项目',
            rootPath: 'D:/Projects/import_project',
            projectType: 'novel',
          ),
          sourcePaths: const <String>['/imports/source'],
          sourceImportRequest: SourceImportRequest(
            requestId: 'directory-request',
            selections: <SourceImportSelection>[
              SourceImportSelection(
                selectionId: 'directory-selection',
                selectionKind: SourceImportSelectionKinds.directory,
                sourceIdentity: const SourceAssetIdentity(
                  sourceAssetId: 'directory-asset',
                  sourceKind: 'directory',
                  displayName: 'source',
                  localHintPath: 'source',
                ),
                sourceLocator: '/imports/source',
                sortOrder: 1,
                mediaType: 'inode/directory',
                relativePathHint: 'source',
                recursive: true,
              ),
            ],
          ),
          targetDirectory: 'assets',
        );

        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.stringList(result['imported_paths']), <String>[
          'assets/chapter1.txt',
          'assets/nested/chapter2.md',
        ]);
        expect(ValueReaders.stringList(result['skipped_paths']), <String>[
          '/imports/source/cover.png',
        ]);
        expect(hostPort.copiedFiles, hasLength(2));
        expect(
          hostPort.copiedFiles,
          contains((
            absolutePath: '/imports/source/chapter1.txt',
            rootPath: 'D:/Projects/import_project',
            targetRelativePath: 'assets/chapter1.txt',
          )),
        );
        expect(
          hostPort.copiedFiles,
          contains((
            absolutePath: '/imports/source/nested/chapter2.md',
            rootPath: 'D:/Projects/import_project',
            targetRelativePath: 'assets/nested/chapter2.md',
          )),
        );
        expect(discoveryPort.requests, hasLength(1));
        expect(
          discoveryPort.requests.single.selections.single.selectionKind,
          SourceImportSelectionKinds.directory,
        );
      },
    );

    test(
      'restores the prepared primary source for the failed item when projection copy fails',
      () async {
        final hostPort = _FakeProjectToolHostPort(failCopy: true);
        final useCase = ImportProjectFilesUseCase(
          projectToolHostPort: hostPort,
        );
        final preparedPaths = <String>[];
        final rolledBackPaths = <String>[];
        const project = ProjectDescriptor(
          id: 'projection-failure-import',
          name: '导入回滚项目',
          rootPath: 'D:/Projects/projection_failure_import',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await expectLater(
          useCase.execute(
            project: project,
            sourcePaths: const <String>['C:/imports/source.md'],
            targetDirectory: 'imports',
            prepareImportedFile: ({
              required project,
              required sourcePath,
              required relativePath,
            }) async {
              preparedPaths.add(relativePath);
            },
            rollbackPreparedImportedFile: ({
              required project,
              required sourcePath,
              required relativePath,
            }) async {
              rolledBackPaths.add(relativePath);
            },
          ),
          throwsA(isA<StateError>()),
        );

        expect(preparedPaths, <String>['imports/source.md']);
        expect(rolledBackPaths, <String>['imports/source.md']);
        expect(hostPort.copiedFiles, isEmpty);
      },
    );

    test(
      'restores the prepared primary source when creating its file projection fails',
      () async {
        final hostPort = _FakeProjectToolHostPort(failWrite: true);
        final useCase = CreateProjectEntryUseCase(projectToolHostPort: hostPort);
        final preparedPaths = <String>[];
        final rolledBackPaths = <String>[];
        const project = ProjectDescriptor(
          id: 'projection-failure-create',
          name: '新建回滚项目',
          rootPath: 'D:/Projects/projection_failure_create',
          storageStrategy: ProjectStorageStrategy.sqliteProjectStore,
        );

        await expectLater(
          useCase.execute(
            project: project,
            relativePath: 'chapters/chapter_01.md',
            content: '第一章',
            prepareFileWrite: ({
              required project,
              required relativePath,
              required content,
            }) async {
              preparedPaths.add(relativePath);
            },
            rollbackPreparedFileWrite: ({
              required project,
              required relativePath,
              required content,
            }) async {
              rolledBackPaths.add(relativePath);
            },
          ),
          throwsA(isA<StateError>()),
        );

        expect(preparedPaths, <String>['chapters/chapter_01.md']);
        expect(rolledBackPaths, <String>['chapters/chapter_01.md']);
      },
    );
  });
}

class _FakeSourceImportDiscoveryPort implements SourceImportDiscoveryPort {
  _FakeSourceImportDiscoveryPort({required this.result});

  final SourceImportDiscoveryResult result;
  final List<SourceImportRequest> requests = <SourceImportRequest>[];

  @override
  Future<SourceImportDiscoveryResult> discover(
    SourceImportRequest request,
  ) async {
    // 中文注释: 测试假实现只记录请求并返回预设 discovery 结果，不在这里伪造业务判断。
    requests.add(request);
    return result;
  }
}

class _FakeProjectToolHostPort implements ProjectToolHostPort {
  _FakeProjectToolHostPort({
    Map<String, String> externalFiles = const <String, String>{},
    this.failCopy = false,
    this.failWrite = false,
  }) : _externalFiles = Map<String, String>.from(externalFiles);

  final Map<String, String> _externalFiles;
  final bool failCopy;
  final bool failWrite;
  final List<
    ({String absolutePath, String rootPath, String targetRelativePath})
  >
  copiedFiles =
      <({String absolutePath, String rootPath, String targetRelativePath})>[];
  final Map<String, String> _projectFiles = <String, String>{};

  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {
    if (failCopy) {
      throw StateError('模拟投影复制失败');
    }
    copiedFiles.add((
      absolutePath: absolutePath,
      rootPath: rootPath,
      targetRelativePath: targetRelativePath,
    ));
    _projectFiles[_projectKey(rootPath, targetRelativePath)] =
        _externalFiles[absolutePath] ?? '';
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {
    _projectFiles.remove(_projectKey(rootPath, relativePath));
  }

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async {
    return _projectFiles.containsKey(_projectKey(rootPath, relativePath));
  }

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    return const <JsonMap>[];
  }

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {
    final value = _projectFiles.remove(
      _projectKey(rootPath, sourceRelativePath),
    );
    if (value != null) {
      _projectFiles[_projectKey(rootPath, targetRelativePath)] = value;
    }
  }

  @override
  Future<String?> readExternalTextFile(String absolutePath) async {
    return _externalFiles[absolutePath];
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    return _projectFiles[_projectKey(rootPath, relativePath)];
  }

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {
    _externalFiles[absolutePath] = content;
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    if (failWrite) {
      throw StateError('模拟投影写入失败');
    }
    _projectFiles[_projectKey(rootPath, relativePath)] = content;
  }

  String _projectKey(String rootPath, String relativePath) {
    // 中文注释: 测试键只做轻量归一化，确保断言不受 Windows 与 POSIX 分隔符差异影响。
    return '${rootPath.replaceAll('\\', '/')}//${relativePath.replaceAll('\\', '/')}';
  }
}
