import 'dart:convert';
import 'dart:io';

import 'package:fast_gbk/fast_gbk.dart';

import 'reference_source_document_file_read_result.dart';
import 'source_document_format_catalog_service.dart';

class SourceDocumentTextReaderService {
  const SourceDocumentTextReaderService({
    SourceDocumentFormatCatalogService? formatCatalogService,
  }) : _formatCatalogService =
           formatCatalogService ?? const SourceDocumentFormatCatalogService();

  final SourceDocumentFormatCatalogService _formatCatalogService;

  bool supports(String sourceFilePath) {
    // 中文注释: 文本 reader 只承接 txt 与 markdown，具体格式归属仍由统一格式目录决定。
    final readerKind = _formatCatalogService.readerKindForPath(sourceFilePath);
    return readerKind == SourceDocumentFormatCatalogService.plainTextFormatId;
  }

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
    // 中文注释: 文本 reader 负责 utf8 / gbk / latin1 的轻量回退，不把格式目录外的文件硬吃进来。
    final sourceFile = File(sourceFilePath.trim());
    if (!sourceFile.existsSync()) {
      throw StateError('Source file not found: $sourceFilePath');
    }
    final bytes = await sourceFile.readAsBytes();
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

  _DecodedSourceText _decodeSourceText(List<int> bytes) {
    // 中文注释: 先尝试 utf8，再根据 GBK 信号和 mojibake 情况回退到 gbk 或 latin1，避免把中文源文本读坏。
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
    // 中文注释: GBK 解码是中文历史文本的常见回退路径，失败就让上层继续走 latin1。
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
    // 中文注释: 这里根据 CJK 信号和 mojibake 痕迹选择更可信的回退结果，避免错误字符把正文污染掉。
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
    // 中文注释: 通过 CJK、全角空格和全角标点计算信号分，帮助区分 GBK 与 latin1 的回退结果。
    final cjkMatches = RegExp(r'[\u3400-\u9FFF]').allMatches(text).length;
    final fullWidthSpaceMatches = RegExp(r'\u3000').allMatches(text).length;
    final fullWidthPunctuationMatches = RegExp(
      r'[\u3001-\u303F\uFF00-\uFFEF]',
    ).allMatches(text).length;
    return cjkMatches + fullWidthSpaceMatches + fullWidthPunctuationMatches;
  }

  int _mojibakeScore(String text) {
    // 中文注释: 乱码分通过常见 mojibake 字符粗略判断，用来避免把明显错误解码当成正确文本。
    return RegExp(
      r'[¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿Ãâð�]',
    ).allMatches(text).length;
  }
}

class _DecodedSourceText {
  const _DecodedSourceText({required this.text, required this.decodeMode});

  final String text;
  final String decodeMode;
}
