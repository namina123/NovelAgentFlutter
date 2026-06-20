import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_smart_import_contract.dart';

class BookDeconstructionSmartImportWorkspaceService {
  const BookDeconstructionSmartImportWorkspaceService({
    SourceDocumentFormatCatalogService? formatCatalogService,
    SourceImportPathScannerService? pathScannerService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService(),
       _pathScannerService =
           pathScannerService ?? const SourceImportPathScannerService();

  final SourceDocumentFormatCatalogService _formatCatalogService;
  final SourceImportPathScannerService _pathScannerService;

  Future<BookDeconstructionSmartImportWorkspace> create({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    required ReferenceSourceDocumentFileReaderService
    sourceDocumentReaderService,
  }) async {
    final runId = DateTime.now().microsecondsSinceEpoch.toString();
    final tempRoot = Directory(
      [
        Directory.systemTemp.path,
        'novel_agent_book_deconstruction_import',
        _safeName(project.name, fallback: project.id),
        runId,
      ].join(Platform.pathSeparator),
    );
    await tempRoot.create(recursive: true);
    final sourcesDirectory = Directory(
      '${tempRoot.path}${Platform.pathSeparator}inputs',
    );
    await sourcesDirectory.create(recursive: true);

    final stagedRelativePaths = <String>[];
    final stagedSourceTexts = <String, String>{};

    for (var index = 0; index < sourcePaths.length; index += 1) {
      final sourcePath = sourcePaths[index].trim();
      if (sourcePath.isEmpty) {
        continue;
      }
      final entityType = await FileSystemEntity.type(
        sourcePath,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.directory) {
        final scannedPaths = await _pathScannerService.scan(
          sourcePath: sourcePath,
          recursive: true,
        );
        for (final scannedPath in scannedPaths) {
          if (!_formatCatalogService.supportsPath(scannedPath)) {
            continue;
          }
          final sourceDocument = await sourceDocumentReaderService.read(
            sourceFilePath: scannedPath,
          );
          final relativePath = _relativePathUnderDirectory(
            rootDirectoryPath: sourcePath,
            filePath: sourceDocument.sourceFilePath,
            fallback: _resolvedSourceFileName(
              sourceDocument.sourceFilePath,
              fallback: 'source_${index + 1}.md',
            ),
          );
          await _writeStagedSource(
            tempRoot: tempRoot,
            relativePath:
                '${BookDeconstructionSmartImportContract.stagedSourcesRoot}/$relativePath',
            sourceText: sourceDocument.sourceText,
          );
          final stagedRelativePath =
              '${BookDeconstructionSmartImportContract.stagedSourcesRoot}/$relativePath';
          stagedRelativePaths.add(stagedRelativePath);
          stagedSourceTexts[stagedRelativePath] = sourceDocument.sourceText;
        }
        continue;
      }
      if (!_formatCatalogService.supportsPath(sourcePath)) {
        continue;
      }
      final sourceDocument = await sourceDocumentReaderService.read(
        sourceFilePath: sourcePath,
      );
      final fileName = _resolvedSourceFileName(
        sourceDocument.sourceFilePath,
        fallback: 'source_${index + 1}.md',
      );
      final relativePath =
          '${BookDeconstructionSmartImportContract.stagedSourcesRoot}/$fileName';
      await _writeStagedSource(
        tempRoot: tempRoot,
        relativePath: relativePath,
        sourceText: sourceDocument.sourceText,
      );
      stagedRelativePaths.add(relativePath);
      stagedSourceTexts[relativePath] = sourceDocument.sourceText;
    }

    final instructionFile = File(
      '${tempRoot.path}${Platform.pathSeparator}${BookDeconstructionSmartImportContract.taskRelativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    await instructionFile.parent.create(recursive: true);
    await instructionFile.writeAsString(_taskMarkdown(stagedRelativePaths));
    final tempProject = ProjectDescriptor(
      id: 'internal_book_deconstruction_import_$runId',
      name: '拆书导入临时工作区',
      rootPath: tempRoot.path,
      projectType: BookDeconstructionConstants.projectTypeId,
      storageStrategy: ProjectStorageStrategy.markdownProjectStore,
    );
    return BookDeconstructionSmartImportWorkspace(
      runId: runId,
      rootPath: tempRoot.path,
      stagedRelativePaths: List<String>.unmodifiable(stagedRelativePaths),
      stagedSourceTexts: Map<String, String>.unmodifiable(stagedSourceTexts),
      tempProject: tempProject,
    );
  }

  Future<void> _writeStagedSource({
    required Directory tempRoot,
    required String relativePath,
    required String sourceText,
  }) async {
    final stagedFile = File(
      '${tempRoot.path}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    await stagedFile.parent.create(recursive: true);
    await stagedFile.writeAsString(sourceText, flush: true);
  }

  String _relativePathUnderDirectory({
    required String rootDirectoryPath,
    required String filePath,
    required String fallback,
  }) {
    final normalizedRoot = Directory(
      rootDirectoryPath,
    ).absolute.path.replaceAll('\\', '/').trim();
    final normalizedFile = File(
      filePath,
    ).absolute.path.replaceAll('\\', '/').trim();
    if (normalizedRoot.isNotEmpty &&
        normalizedFile.startsWith('$normalizedRoot/')) {
      return normalizedFile.substring(normalizedRoot.length + 1);
    }
    return fallback;
  }

  String _resolvedSourceFileName(
    String sourceFilePath, {
    required String fallback,
  }) {
    final normalized = sourceFilePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return fallback;
    }
    final rawName = normalized.split('/').last.trim();
    if (rawName.isEmpty) {
      return fallback;
    }
    if (rawName.contains('.')) {
      return rawName;
    }
    return '$rawName.md';
  }

  String _safeName(String value, {required String fallback}) {
    final clean = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (clean.isEmpty) {
      final backup = fallback
          .trim()
          .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
          .replaceAll(RegExp(r'\s+'), '_');
      return backup.isEmpty ? 'project' : backup;
    }
    return clean;
  }

  String _taskMarkdown(List<String> stagedRelativePaths) {
    final buffer = StringBuffer()
      ..writeln('# 拆书导入任务')
      ..writeln()
      ..writeln('你是内置的拆书导入专用智能体。')
      ..writeln('你只能处理当前临时工作区中的导入文本，不要假设项目正文、设定或其他上下文。')
      ..writeln()
      ..writeln('目标：')
      ..writeln('- 识别章节划分方式。')
      ..writeln('- 找出应清理的广告、采集站尾注、无关推广、明显乱码噪声。')
      ..writeln('- 尽量保留原文有效信息，不主动改写正文。')
      ..writeln('- 只输出“规则”和“说明”，不要手工重写整份归一化正文。')
      ..writeln(
        '- 把结构化规则写入 `${BookDeconstructionSmartImportContract.rulesPath}`。',
      )
      ..writeln(
        '- 把你的拆分/清洗说明写入 `${BookDeconstructionSmartImportContract.reportPath}`。',
      )
      ..writeln()
      ..writeln(
        '程序会在你写出规则后自动执行清洗并生成 `${BookDeconstructionSmartImportContract.normalizedSourcePath}`。',
      )
      ..writeln('只允许依赖项目工具读取和写入当前工作区文件。')
      ..writeln()
      ..writeln('规则 JSON 结构：')
      ..writeln('```json')
      ..writeln('{')
      ..writeln(
        '  "selected_source_paths": ["analysis/deconstruction_import/source_inputs/..."],',
      )
      ..writeln(
        '  "chapter_heading_patterns": ["^第...章.*\$", "^Chapter\\\\s+\\\\d+.*\$"],',
      )
      ..writeln('  "drop_line_contains": ["最新网址", "收藏本站"],')
      ..writeln('  "drop_line_patterns": ["^\\\\s*广告.*\$"],')
      ..writeln('  "collapse_blank_lines": true,')
      ..writeln('  "insert_blank_line_between_sources": true,')
      ..writeln('  "trim_trailing_whitespace": true')
      ..writeln('}')
      ..writeln('```')
      ..writeln()
      ..writeln('导入文件：');
    for (final path in stagedRelativePaths) {
      buffer.writeln('- $path');
    }
    buffer
      ..writeln()
      ..writeln('完成标准：')
      ..writeln(
        '1. `${BookDeconstructionSmartImportContract.rulesPath}` 必须存在且是合法 JSON。',
      )
      ..writeln(
        '2. `${BookDeconstructionSmartImportContract.reportPath}` 应说明识别到的章节规则、清理内容和仍未确定的问题。',
      );
    return buffer.toString().trimRight();
  }
}

class BookDeconstructionSmartImportWorkspace {
  const BookDeconstructionSmartImportWorkspace({
    required this.runId,
    required this.rootPath,
    required this.stagedRelativePaths,
    required this.stagedSourceTexts,
    required this.tempProject,
  });

  final String runId;
  final String rootPath;
  final List<String> stagedRelativePaths;
  final Map<String, String> stagedSourceTexts;
  final ProjectDescriptor tempProject;
}
