import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive.dart';
import 'package:fast_gbk/fast_gbk.dart';

import 'reference_source_document_file_read_result.dart';

class SourceDocumentIsolateReaderService {
  const SourceDocumentIsolateReaderService();

  Future<ReferenceSourceDocumentFileReadResult> readPlainText({
    required String sourceFilePath,
  }) {
    final normalizedPath = sourceFilePath.trim();
    return Isolate.run(
      () => _readPlainTextSourceDocumentInIsolate(normalizedPath),
    );
  }

  Future<ReferenceSourceDocumentFileReadResult> readEpub({
    required String sourceFilePath,
  }) {
    final normalizedPath = sourceFilePath.trim();
    return Isolate.run(() => _readEpubSourceDocumentInIsolate(normalizedPath));
  }
}

ReferenceSourceDocumentFileReadResult _readPlainTextSourceDocumentInIsolate(
  String sourceFilePath,
) {
  final sourceFile = File(sourceFilePath);
  if (!sourceFile.existsSync()) {
    throw StateError('Source file not found: $sourceFilePath');
  }
  final bytes = sourceFile.readAsBytesSync();
  final decoded = _decodeSourceText(bytes);
  final sourceTitle = sourceFile.uri.pathSegments.isEmpty
      ? sourceFile.path
      : sourceFile.uri.pathSegments.last;
  return ReferenceSourceDocumentFileReadResult(
    sourceFilePath: sourceFile.path,
    sourceTitle: sourceTitle,
    sourceText: decoded.text,
    decodeMode: decoded.decodeMode,
  );
}

ReferenceSourceDocumentFileReadResult _readEpubSourceDocumentInIsolate(
  String sourceFilePath,
) {
  final sourceFile = File(sourceFilePath);
  if (!sourceFile.existsSync()) {
    throw StateError('Source file not found: $sourceFilePath');
  }
  final bytes = sourceFile.readAsBytesSync();
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  final sourceTitle = _resolveEpubTitle(archive, sourceFile.path);
  final sourceText = _resolveEpubText(archive);
  return ReferenceSourceDocumentFileReadResult(
    sourceFilePath: sourceFile.path,
    sourceTitle: sourceTitle,
    sourceText: sourceText,
    decodeMode: 'epub',
  );
}

_DecodedSourceText _decodeSourceText(List<int> bytes) {
  try {
    return _DecodedSourceText(text: utf8.decode(bytes), decodeMode: 'utf8');
  } catch (_) {
    final gbkDecoded = _tryDecodeGbk(bytes);
    final latin1Decoded = _DecodedSourceText(
      text: latin1.decode(bytes),
      decodeMode: 'latin1',
    );
    if (gbkDecoded != null &&
        _preferGbkDecodedText(
          gbkText: gbkDecoded.text,
          latin1Text: latin1Decoded.text,
        )) {
      return gbkDecoded;
    }
    return latin1Decoded;
  }
}

_DecodedSourceText? _tryDecodeGbk(List<int> bytes) {
  try {
    return _DecodedSourceText(text: gbk.decode(bytes), decodeMode: 'gbk');
  } catch (_) {
    return null;
  }
}

bool _preferGbkDecodedText({
  required String gbkText,
  required String latin1Text,
}) {
  if (gbkText == latin1Text) {
    return false;
  }
  final gbkSignalScore = _gbkSignalScore(gbkText);
  final latin1MojibakeScore = _mojibakeScore(latin1Text);
  final gbkMojibakeScore = _mojibakeScore(gbkText);
  if (gbkSignalScore > 0 && latin1MojibakeScore > gbkMojibakeScore) {
    return true;
  }
  return latin1MojibakeScore >= 4 && gbkMojibakeScore == 0;
}

int _gbkSignalScore(String text) {
  final cjkMatches = RegExp(r'[\u3400-\u9FFF]').allMatches(text).length;
  final fullWidthSpaceMatches = RegExp(r'\u3000').allMatches(text).length;
  final fullWidthPunctuationMatches = RegExp(
    r'[\u3001-\u303F\uFF00-\uFFEF]',
  ).allMatches(text).length;
  return cjkMatches + fullWidthSpaceMatches + fullWidthPunctuationMatches;
}

int _mojibakeScore(String text) {
  return RegExp(
    r'[¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿Ãâð�]',
  ).allMatches(text).length;
}

String _resolveEpubTitle(Archive archive, String fallbackPath) {
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

String _resolveEpubText(Archive archive) {
  final opfContent = _readOpfContent(archive);
  final orderedPaths = _resolveSpinePaths(archive, opfContent);
  final extractedSections = <String>[];
  for (final path in orderedPaths) {
    final archiveFile = archive.files.whereType<ArchiveFile>().firstWhere(
      (file) => _normalizeArchivePath(file.name) == _normalizeArchivePath(path),
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
      final text = _stripMarkup(_decodeArchiveFileContent(archiveFile)).trim();
      if (text.isNotEmpty) {
        extractedSections.add(text);
      }
    }
  }
  return extractedSections.join('\n\n');
}

String _readOpfContent(Archive archive) {
  final containerContent = _readArchiveText(archive, 'META-INF/container.xml');
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
  final containerContent = _readArchiveText(archive, 'META-INF/container.xml');
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
        RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
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
  return value
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

String _normalizeArchivePath(String value) {
  return value.replaceAll('\\', '/').trim().toLowerCase();
}

class _DecodedSourceText {
  const _DecodedSourceText({required this.text, required this.decodeMode});

  final String text;
  final String decodeMode;
}
