import 'dart:convert';
import 'dart:io';

import 'package:fast_gbk/fast_gbk.dart';

class ReferenceSourceDocumentFileReaderService {
  const ReferenceSourceDocumentFileReaderService();

  Future<ReferenceSourceDocumentFileReadResult> read({
    required String sourceFilePath,
  }) async {
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
    return RegExp(r'[¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿Ãâð�]').allMatches(text).length;
  }
}

class ReferenceSourceDocumentFileReadResult {
  const ReferenceSourceDocumentFileReadResult({
    required this.sourceFilePath,
    required this.sourceTitle,
    required this.sourceText,
    required this.decodeMode,
  });

  final String sourceFilePath;
  final String sourceTitle;
  final String sourceText;
  final String decodeMode;
}

class _DecodedSourceText {
  const _DecodedSourceText({required this.text, required this.decodeMode});

  final String text;
  final String decodeMode;
}
