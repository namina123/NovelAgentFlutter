import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/src/reference_extraction/reference_source_boundary_locator_service.dart';
import 'package:novel_agent_adapters/src/reference_extraction/reference_source_language_hint_service.dart';
import 'package:novel_agent_adapters/src/storage/reference_source_document_file_reader_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

const String _runId = '2026-06-10T01-35-42';
const String _targetSession = 'HFVV-03';
const int _boundaryTargetChars = 1000000;

Future<void> main() async {
  final packageRoot = Directory.current;
  final repoRoot = packageRoot.parent.parent;
  final artifactsRoot = Directory(
    '${repoRoot.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}high_fidelity_viewmodel_validation${Platform.pathSeparator}$_runId${Platform.pathSeparator}hfvv_03',
  );
  final localRoot = Directory(
    '${repoRoot.path}${Platform.pathSeparator}local${Platform.pathSeparator}hfvv_source_assets${Platform.pathSeparator}$_runId',
  );
  final originalOutputRoot = Directory(
    '${artifactsRoot.path}${Platform.pathSeparator}source_assets${Platform.pathSeparator}original',
  );
  final artifactUtf8Root = Directory(
    '${artifactsRoot.path}${Platform.pathSeparator}source_assets${Platform.pathSeparator}utf8',
  );
  final artifactExcerptRoot = Directory(
    '${artifactsRoot.path}${Platform.pathSeparator}source_assets${Platform.pathSeparator}excerpts',
  );
  final localUtf8Root = Directory(
    '${localRoot.path}${Platform.pathSeparator}utf8',
  );

  for (final directory in <Directory>[
    artifactsRoot,
    localRoot,
    originalOutputRoot,
    artifactUtf8Root,
    artifactExcerptRoot,
    localUtf8Root,
  ]) {
    await directory.create(recursive: true);
  }

  final readerService = const ReferenceSourceDocumentFileReaderService();
  final languageHintService = const ReferenceSourceLanguageHintService();
  final boundaryLocatorService = const ReferenceSourceBoundaryLocatorService();
  final checksumService = const BundleChecksumService();

  final assets = <_SourceAssetPlan>[
    _SourceAssetPlan(
      key: 'harry_potter_full',
      sourceRelativePath: 'references/files/Harry Potter.txt',
      artifactOriginalFileName: 'harry_potter_full.txt',
      artifactUtf8FileName: 'harry_potter_full_utf8.txt',
      localUtf8FileName: 'harry_potter_full_utf8.txt',
    ),
    _SourceAssetPlan(
      key: 'harry_potter_volume1_raw',
      sourceRelativePath: 'references/files/Harry Potter - Volume 1 Raw.txt',
      artifactOriginalFileName: 'harry_potter_volume1_raw.txt',
      artifactUtf8FileName: 'harry_potter_volume1_raw_utf8.txt',
      localUtf8FileName: 'harry_potter_volume1_raw_utf8.txt',
    ),
    _SourceAssetPlan(
      key: 'rezero_full',
      sourceRelativePath: 'references/files/re从零开始的异世界生活.txt',
      artifactOriginalFileName: 'rezero_original.txt',
      artifactUtf8FileName: 'rezero_utf8.txt',
      localUtf8FileName: 'rezero_utf8.txt',
    ),
  ];

  final preparedAssets = <Map<String, Object?>>[];
  for (final asset in assets) {
    final absoluteSourcePath =
        '${repoRoot.path}${Platform.pathSeparator}${asset.sourceRelativePath.replaceAll('/', Platform.pathSeparator)}';
    final sourceFile = File(absoluteSourcePath);
    if (!sourceFile.existsSync()) {
      throw StateError(
        'HFVV-03 source file missing: ${asset.sourceRelativePath}',
      );
    }
    final originalBytes = await sourceFile.readAsBytes();
    final originalCopyFile = File(
      '${originalOutputRoot.path}${Platform.pathSeparator}${asset.artifactOriginalFileName}',
    );
    await originalCopyFile.writeAsBytes(originalBytes, flush: true);

    final readResult = await readerService.read(
      sourceFilePath: absoluteSourcePath,
    );
    final normalizedUtf8Text = _normalizeLineEndings(readResult.sourceText);
    final sourceLanguage = languageHintService.infer(
      sourceFilePath: readResult.sourceFilePath,
      sourceTitle: readResult.sourceTitle,
      sourceText: normalizedUtf8Text,
    );
    final utf8Bytes = utf8.encode(normalizedUtf8Text);

    final artifactUtf8File = File(
      '${artifactUtf8Root.path}${Platform.pathSeparator}${asset.artifactUtf8FileName}',
    );
    final localUtf8File = File(
      '${localUtf8Root.path}${Platform.pathSeparator}${asset.localUtf8FileName}',
    );
    await artifactUtf8File.writeAsBytes(utf8Bytes, flush: true);
    await localUtf8File.writeAsBytes(utf8Bytes, flush: true);

    final boundary = boundaryLocatorService.locateNearTarget(
      sourceText: normalizedUtf8Text,
      targetChars: _boundaryTargetChars,
    );
    String excerptRelativePath = '';
    if (boundary.boundaryKind != ReferenceSourceBoundaryKinds.belowTarget &&
        boundary.boundaryKind != ReferenceSourceBoundaryKinds.emptySource) {
      final excerptFile = File(
        '${artifactExcerptRoot.path}${Platform.pathSeparator}${asset.key}_around_1m_excerpt.txt',
      );
      final excerptText = _buildBoundaryExcerpt(
        text: normalizedUtf8Text,
        boundaryOffset: boundary.boundaryOffset,
      );
      await excerptFile.writeAsString(excerptText, flush: true);
      excerptRelativePath = _repoRelativePath(repoRoot, excerptFile.path);
    }

    final fingerprint = checksumService.checksumOf(<String, Object?>{
      'key': asset.key,
      'source_relative_path': asset.sourceRelativePath,
      'decode_mode': readResult.decodeMode,
      'source_language': sourceLanguage,
      'original_byte_length': originalBytes.length,
      'utf8_byte_length': utf8Bytes.length,
      'decoded_char_length': normalizedUtf8Text.length,
      'preview_head': normalizedUtf8Text.substring(
        0,
        normalizedUtf8Text.length.clamp(0, 120),
      ),
      'preview_tail': normalizedUtf8Text.substring(
        (normalizedUtf8Text.length - 120).clamp(0, normalizedUtf8Text.length),
      ),
    });
    final assetId = '${asset.key}_${fingerprint.substring(0, 12)}';

    preparedAssets.add(<String, Object?>{
      'asset_id': assetId,
      'asset_key': asset.key,
      'source_display_name': readResult.sourceTitle,
      'source_reference_relative_path': asset.sourceRelativePath,
      'artifact_original_relative_path': _repoRelativePath(
        repoRoot,
        originalCopyFile.path,
      ),
      'artifact_utf8_relative_path': _repoRelativePath(
        repoRoot,
        artifactUtf8File.path,
      ),
      'local_utf8_relative_path': _repoRelativePath(
        repoRoot,
        localUtf8File.path,
      ),
      'decode_mode': readResult.decodeMode,
      'source_language_hint': sourceLanguage,
      'original_byte_length': originalBytes.length,
      'utf8_byte_length': utf8Bytes.length,
      'decoded_char_length': normalizedUtf8Text.length,
      'content_fingerprint': fingerprint,
      'boundary': boundary.toJson(),
      'boundary_excerpt_relative_path': excerptRelativePath,
      'conversion_notes': _conversionNotes(
        sourceTitle: readResult.sourceTitle,
        decodeMode: readResult.decodeMode,
      ),
    });
  }

  final manifest = <String, Object?>{
    'session': _targetSession,
    'run_id': _runId,
    'generated_at': DateTime.now().toIso8601String(),
    'target_boundary_chars': _boundaryTargetChars,
    'source_asset_count': preparedAssets.length,
    'artifact_root_relative_path': _repoRelativePath(
      repoRoot,
      artifactsRoot.path,
    ),
    'local_root_relative_path': _repoRelativePath(repoRoot, localRoot.path),
    'assets': preparedAssets,
  };
  final manifestFile = File(
    '${artifactsRoot.path}${Platform.pathSeparator}source_asset_manifest.json',
  );
  await manifestFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );

  final reportFile = File(
    '${artifactsRoot.path}${Platform.pathSeparator}hfvv_03_report.md',
  );
  await reportFile.writeAsString(
    _buildMarkdownReport(
      assets: preparedAssets,
      manifestRelativePath: _repoRelativePath(repoRoot, manifestFile.path),
      localRootRelativePath: _repoRelativePath(repoRoot, localRoot.path),
    ),
    flush: true,
  );
}

class _SourceAssetPlan {
  const _SourceAssetPlan({
    required this.key,
    required this.sourceRelativePath,
    required this.artifactOriginalFileName,
    required this.artifactUtf8FileName,
    required this.localUtf8FileName,
  });

  final String key;
  final String sourceRelativePath;
  final String artifactOriginalFileName;
  final String artifactUtf8FileName;
  final String localUtf8FileName;
}

String _normalizeLineEndings(String value) {
  return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String _conversionNotes({
  required String sourceTitle,
  required String decodeMode,
}) {
  if (sourceTitle.contains('Re:Zero') || sourceTitle.contains('从零开始')) {
    return decodeMode == 'utf8'
        ? 'Re:Zero 源文件已直接按 UTF-8 读出，并复制到 UTF-8 产物目录。'
        : 'Re:Zero 源文件已按 $decodeMode 解码并重新写出为 UTF-8。';
  }
  if (decodeMode == 'utf8') {
    return '源文件已复制并写出稳定 UTF-8 副本。';
  }
  return '源文件按 $decodeMode 解码后写出 UTF-8 副本。';
}

String _repoRelativePath(Directory repoRoot, String absolutePath) {
  final normalizedRoot = repoRoot.path.replaceAll('\\', '/');
  final normalizedPath = absolutePath.replaceAll('\\', '/');
  if (normalizedPath.startsWith(normalizedRoot)) {
    var relative = normalizedPath.substring(normalizedRoot.length);
    if (relative.startsWith('/')) {
      relative = relative.substring(1);
    }
    return relative;
  }
  return normalizedPath.split('/').last;
}

String _buildBoundaryExcerpt({
  required String text,
  required int boundaryOffset,
}) {
  const radius = 3000;
  final safeOffset = boundaryOffset.clamp(0, text.length);
  final start = (safeOffset - radius).clamp(0, text.length);
  final end = (safeOffset + radius).clamp(0, text.length);
  final before = text.substring(start, safeOffset).trim();
  final after = text.substring(safeOffset, end).trim();
  return '''
=== BEFORE BOUNDARY ===
$before

=== BOUNDARY OFFSET ===
$safeOffset

=== AFTER BOUNDARY ===
$after
''';
}

String _buildMarkdownReport({
  required List<Map<String, Object?>> assets,
  required String manifestRelativePath,
  required String localRootRelativePath,
}) {
  final buffer = StringBuffer()
    ..writeln('# HFVV-03 Report')
    ..writeln()
    ..writeln('状态：`passed`')
    ..writeln()
    ..writeln('本轮只完成 `HFVV-03`，未开启 `HFVV-04`。')
    ..writeln()
    ..writeln('## 产物')
    ..writeln()
    ..writeln('1. source asset manifest：`$manifestRelativePath`')
    ..writeln('2. local UTF-8 temp root：`$localRootRelativePath`')
    ..writeln()
    ..writeln('## 结果摘要')
    ..writeln();
  for (final asset in assets) {
    final boundary = ValueReaders.mapValue(asset['boundary']);
    buffer
      ..writeln('### ${asset['source_display_name']}')
      ..writeln()
      ..writeln('- asset_id: `${asset['asset_id']}`')
      ..writeln('- source_ref: `${asset['source_reference_relative_path']}`')
      ..writeln('- decode_mode: `${asset['decode_mode']}`')
      ..writeln('- source_language_hint: `${asset['source_language_hint']}`')
      ..writeln('- utf8_copy: `${asset['artifact_utf8_relative_path']}`')
      ..writeln('- local_utf8_copy: `${asset['local_utf8_relative_path']}`')
      ..writeln(
        '- boundary: `${boundary['boundary_kind']}` @ ${boundary['boundary_offset']} (distance ${boundary['distance_from_target']})',
      )
      ..writeln('- notes: ${asset['conversion_notes']}')
      ..writeln();
  }
  return buffer.toString();
}
