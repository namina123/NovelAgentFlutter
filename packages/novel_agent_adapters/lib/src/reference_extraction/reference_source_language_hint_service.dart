class ReferenceSourceLanguageHintService {
  const ReferenceSourceLanguageHintService();

  String infer({
    required String sourceFilePath,
    required String sourceTitle,
    required String sourceText,
  }) {
    final pathHint = _fromFileName(sourceFilePath);
    if (pathHint.isNotEmpty) {
      return pathHint;
    }
    final titleHint = _fromFileName(sourceTitle);
    if (titleHint.isNotEmpty) {
      return titleHint;
    }
    return _fromTextPreview(sourceText);
  }

  String _fromFileName(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    if (_containsCjk(normalized)) {
      return 'zh-CN';
    }
    final tokenized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    if (RegExp(
      r'(^| )(zh|zh cn|zh tw|cn|chs|cht|chinese)( |$)',
    ).hasMatch(tokenized)) {
      return 'zh-CN';
    }
    if (RegExp(r'(^| )(en|eng|english)( |$)').hasMatch(tokenized)) {
      return 'en';
    }
    return '';
  }

  String _fromTextPreview(String value) {
    final preview = value.trim();
    if (preview.isEmpty) {
      return '';
    }
    final sample = preview.length <= 2400
        ? preview
        : preview.substring(0, 2400);
    final cjkMatches = RegExp(
      r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]',
    ).allMatches(sample).length;
    if (cjkMatches >= 24) {
      return 'zh-CN';
    }
    final lower = sample.toLowerCase();
    final englishSignalCount = <String>[
      ' the ',
      ' and ',
      ' chapter ',
      ' was ',
      ' were ',
      ' said ',
      ' had ',
      ' that ',
    ].where(lower.contains).length;
    final asciiLetterMatches = RegExp(r'[a-z]').allMatches(lower).length;
    if (englishSignalCount >= 2 && asciiLetterMatches >= 120) {
      return 'en';
    }
    return '';
  }

  bool _containsCjk(String value) {
    return RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]').hasMatch(value);
  }
}
