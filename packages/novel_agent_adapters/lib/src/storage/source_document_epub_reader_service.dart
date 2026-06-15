import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import 'reference_source_document_file_read_result.dart';
import 'source_document_format_catalog_service.dart';

class SourceDocumentEpubReaderService {
  const SourceDocumentEpubReaderService({
    SourceDocumentFormatCatalogService? formatCatalogService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService();

  final SourceDocumentFormatCatalogService _formatCatalogService;

  bool supports(String sourceFilePath) {
    // 中文注释: EPUB reader 只承接 epub 格式，避免和普通文本 reader 互相抢路由。
    return _formatCatalogService.readerKindForPath(sourceFilePath) ==
        SourceDocumentFormatCatalogService.epubFormatId;
  }

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    // 中文注释: EPUB 读取只处理本地 zip 容器与正文抽取，不把目录扫描或导入复制职责揉进来。
    final sourceFile = File(sourceFilePath.trim());
    if (!sourceFile.existsSync()) {
      throw StateError('Source file not found: $sourceFilePath');
    }
    final bytes = await sourceFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final sourceTitle = _resolveTitle(archive, sourceFile.path);
    final sourceText = _resolveText(archive);
    return ReferenceSourceDocumentFileReadResult(
      sourceFilePath: sourceFile.path,
      sourceTitle: sourceTitle,
      sourceText: sourceText,
      decodeMode: 'epub',
    );
  }

  String _resolveTitle(Archive archive, String fallbackPath) {
    // 中文注释: 标题优先从 OPF 元数据取，没有时退回文件名，保证 reader 输出始终有稳定标题。
    final opfContent = _readOpfContent(archive);
    if (opfContent.isNotEmpty) {
      final titleMatch = RegExp(
        r'<dc:title[^>]*>(.*?)</dc:title>',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(opfContent);
      if (titleMatch != null) {
        final extracted = _stripMarkup(titleMatch.group(1) ?? '').trim();
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }
    final normalized = fallbackPath.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? normalized : segments.last;
  }

  String _resolveText(Archive archive) {
    // 中文注释: EPUB 正文按 spine 顺序拼接 XHTML/HTML 文件，保留基础段落内容供上层统一消费。
    final opfContent = _readOpfContent(archive);
    final orderedPaths = _resolveSpinePaths(archive, opfContent);
    final extractedSections = <String>[];
    for (final path in orderedPaths) {
      final archiveFile = archive.files.whereType<ArchiveFile>().firstWhere(
        (file) =>
            _normalizeArchivePath(file.name) == _normalizeArchivePath(path),
        orElse: () => ArchiveFile('', 0, <int>[]),
      );
      if (archiveFile.name.isEmpty) {
        continue;
      }
      final content = _decodeArchiveFileContent(archiveFile);
      final text = _stripMarkup(content).trim();
      if (text.isNotEmpty) {
        extractedSections.add(text);
      }
    }
    if (extractedSections.isEmpty) {
      for (final archiveFile in archive.files.whereType<ArchiveFile>()) {
        final normalizedName = _normalizeArchivePath(archiveFile.name);
        if (!normalizedName.endsWith('.xhtml') &&
            !normalizedName.endsWith('.html') &&
            !normalizedName.endsWith('.htm')) {
          continue;
        }
        final text = _stripMarkup(
          _decodeArchiveFileContent(archiveFile),
        ).trim();
        if (text.isNotEmpty) {
          extractedSections.add(text);
        }
      }
    }
    return extractedSections.join('\n\n');
  }

  String _readOpfContent(Archive archive) {
    // 中文注释: OPF 路径由 container.xml 决定，找不到时再退回第一个 opf 文件，保证 reader 能处理常见 EPUB。
    final containerContent = _readArchiveText(
      archive,
      'META-INF/container.xml',
    );
    final rootFileMatch = RegExp(
      r'full-path="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(containerContent);
    final candidates = <String>[
      if (rootFileMatch != null) rootFileMatch.group(1)!.trim(),
    ];
    for (final archiveFile in archive.files.whereType<ArchiveFile>()) {
      final normalizedName = _normalizeArchivePath(archiveFile.name);
      if (normalizedName.endsWith('.opf')) {
        candidates.add(archiveFile.name);
      }
    }
    for (final candidate in candidates) {
      final content = _readArchiveText(archive, candidate);
      if (content.isNotEmpty) {
        return content;
      }
    }
    return '';
  }

  List<String> _resolveSpinePaths(Archive archive, String opfContent) {
    // 中文注释: spine 顺序优先于文件系统顺序，确保 epub 章节按出版顺序拼接。
    final manifest = <String, String>{};
    final manifestMatches = RegExp(
      r'<item\s+[^>]*id="([^"]+)"[^>]*href="([^"]+)"',
      caseSensitive: false,
    ).allMatches(opfContent);
    for (final match in manifestMatches) {
      manifest[match.group(1)!.trim()] = match.group(2)!.trim();
    }
    final spineIds = RegExp(
      r'<itemref\s+[^>]*idref="([^"]+)"',
      caseSensitive: false,
    ).allMatches(opfContent).map((match) => match.group(1)!.trim()).toList();
    final opfPath = _resolveOpfPath(archive);
    final opfDirectory = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/'))
        : '';
    final resolvedPaths = <String>[];
    for (final spineId in spineIds) {
      final href = manifest[spineId];
      if (href == null || href.trim().isEmpty) {
        continue;
      }
      final combined = opfDirectory.isEmpty ? href : '$opfDirectory/$href';
      resolvedPaths.add(combined);
    }
    if (resolvedPaths.isNotEmpty) {
      return resolvedPaths;
    }
    for (final href in manifest.values) {
      resolvedPaths.add(opfDirectory.isEmpty ? href : '$opfDirectory/$href');
    }
    return resolvedPaths;
  }

  String _resolveOpfPath(Archive archive) {
    // 中文注释: OPF 路径优先跟随 container.xml，其次选 archive 里第一个 opf 文件，避免 reader 只依赖单一路径。
    final containerContent = _readArchiveText(
      archive,
      'META-INF/container.xml',
    );
    final rootFileMatch = RegExp(
      r'full-path="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(containerContent);
    if (rootFileMatch != null) {
      return rootFileMatch.group(1)!.trim();
    }
    for (final archiveFile in archive.files.whereType<ArchiveFile>()) {
      final normalizedName = _normalizeArchivePath(archiveFile.name);
      if (normalizedName.endsWith('.opf')) {
        return archiveFile.name;
      }
    }
    return '';
  }

  String _readArchiveText(Archive archive, String path) {
    // 中文注释: 压缩包内文本统一走 UTF-8/latin1 轻量回退，避免 EPUB 内部 XML 因编码差异读坏。
    final archiveFile = archive.files.whereType<ArchiveFile>().firstWhere(
      (file) => _normalizeArchivePath(file.name) == _normalizeArchivePath(path),
      orElse: () => ArchiveFile('', 0, <int>[]),
    );
    if (archiveFile.name.isEmpty) {
      return '';
    }
    return _decodeArchiveFileContent(archiveFile);
  }

  String _decodeArchiveFileContent(ArchiveFile archiveFile) {
    // 中文注释: EPUB XML/XHTML 一般可直接按 UTF-8 解码，失败后回退 latin1，确保 reader 不因单个文件编码差异中断。
    final content = archiveFile.content;
    if (content is String) {
      return content;
    }
    if (content is List<int>) {
      try {
        return utf8.decode(content);
      } catch (_) {
        return latin1.decode(content);
      }
    }
    return content.toString();
  }

  String _stripMarkup(String value) {
    // 中文注释: EPUB 正文只需要稳定的可读文本，不在这里建立完整 HTML 解析器。
    final withoutScripts = value
        .replaceAll(
          RegExp(
            r'<script[^>]*>.*?</script>',
            caseSensitive: false,
            dotAll: true,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'<style[^>]*>.*?</style>',
            caseSensitive: false,
            dotAll: true,
          ),
          ' ',
        );
    final blockNormalized = withoutScripts.replaceAll(
      RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    final stripped = blockNormalized.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return _unescapeEntities(stripped.replaceAll(RegExp(r'\s+'), ' ')).trim();
  }

  String _unescapeEntities(String value) {
    // 中文注释: 只做 EPUB 常见实体的轻量还原，不把 reader 变成完整 HTML 解析器。
    return value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  String _normalizeArchivePath(String value) {
    // 中文注释: 压缩包内部路径统一换成斜杠后再比较，避免平台分隔符影响 reader 路由。
    return value.replaceAll('\\', '/').trim().toLowerCase();
  }
}
