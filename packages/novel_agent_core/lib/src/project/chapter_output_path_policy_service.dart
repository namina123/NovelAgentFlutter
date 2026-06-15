import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_content_path_policy_service.dart';

class ChapterOutputPathResolution {
  const ChapterOutputPathResolution({
    required this.requestedPath,
    required this.resolvedPath,
    required this.title,
    required this.chapterNumber,
    this.pathChanged = false,
    this.reason = '',
  });

  final String requestedPath;
  final String resolvedPath;
  final String title;
  final int chapterNumber;
  final bool pathChanged;
  final String reason;

  JsonMap toJson() {
    return <String, Object?>{
      'requested_path': requestedPath,
      'resolved_path': resolvedPath,
      'title': title,
      'chapter_number': chapterNumber,
      'path_changed': pathChanged,
      'reason': reason,
    };
  }
}

class ChapterOutputPathPolicyService {
  const ChapterOutputPathPolicyService({
    ProjectContentPathPolicyService? contentPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;

  String defaultChapterPath({
    required int chapterNumber,
    required String title,
    String fallbackTitle = 'chapter',
  }) {
    final stem = chapterFileStem(
      chapterNumber: chapterNumber,
      title: title,
      fallbackTitle: fallbackTitle,
    );
    if (stem.trim().isEmpty) {
      return '';
    }
    final directory = _contentPathPolicyService.directoryForContentType(
      'chapter',
    );
    return '$directory/$stem.md';
  }

  String suggestChapterPath({
    String explicitTitle = '',
    String submissionTitle = '',
    required String chapterContent,
    String fallbackTitle = 'chapter',
  }) {
    final effectiveNumber =
        _chapterNumberFromTitle(explicitTitle) ??
        _chapterNumberFromTitle(submissionTitle) ??
        _chapterNumberFromTitle(_titleFromMarkdownHeading(chapterContent)) ??
        0;
    final effectiveTitle = effectiveChapterTitle(
      explicitTitle: explicitTitle,
      chapterContent: chapterContent,
      submissionTitle: submissionTitle,
      chapterNumber: effectiveNumber,
    );
    final directory = _contentPathPolicyService.directoryForContentType(
      'chapter',
    );
    if (effectiveNumber > 0) {
      final chapterPath = defaultChapterPath(
        chapterNumber: effectiveNumber,
        title: effectiveTitle,
        fallbackTitle: fallbackTitle,
      );
      if (chapterPath.trim().isNotEmpty) {
        return chapterPath;
      }
    }
    final safeTitle = safeFilePart(effectiveTitle, fallbackTitle);
    if (safeTitle.trim().isEmpty) {
      return '';
    }
    return '$directory/$safeTitle.md';
  }

  String chapterFileStem({
    required int chapterNumber,
    required String title,
    String fallbackTitle = 'chapter',
  }) {
    final prefix = chapterPrefix(chapterNumber);
    final loosePrefix = '第$chapterNumber章';
    final cleanTitle = chapterTitleWithoutPrefix(
      title,
      chapterNumber: chapterNumber,
    );
    final safeTitle = safeFilePart(cleanTitle, fallbackTitle);
    if (safeTitle.isEmpty ||
        safeTitle == fallbackTitle ||
        safeTitle == 'seed_to_full' ||
        safeTitle == prefix ||
        safeTitle == loosePrefix) {
      return prefix;
    }
    return '${prefix}_$safeTitle';
  }

  ChapterOutputPathResolution resolveChapterOutput({
    required String requestedPath,
    String explicitTitle = '',
    String submissionTitle = '',
    required String chapterContent,
    int chapterNumber = 0,
  }) {
    final cleanRequested = normalizeRelativePath(requestedPath);
    final effectiveNumber = chapterNumber > 0
        ? chapterNumber
        : _chapterNumberFromPath(cleanRequested) ??
              _chapterNumberFromTitle(explicitTitle) ??
              _chapterNumberFromTitle(submissionTitle) ??
              _chapterNumberFromTitle(
                _titleFromMarkdownHeading(chapterContent),
              ) ??
              0;
    final effectiveTitle = effectiveChapterTitle(
      explicitTitle: explicitTitle,
      chapterContent: chapterContent,
      submissionTitle: submissionTitle,
      chapterNumber: effectiveNumber,
    );
    if (cleanRequested.isEmpty || effectiveNumber <= 0) {
      return ChapterOutputPathResolution(
        requestedPath: cleanRequested,
        resolvedPath: cleanRequested,
        title: effectiveTitle,
        chapterNumber: effectiveNumber,
      );
    }
    final candidatePath = defaultChapterPath(
      chapterNumber: effectiveNumber,
      title: effectiveTitle,
      fallbackTitle: chapterPrefix(effectiveNumber),
    );
    if (candidatePath.isEmpty || candidatePath == cleanRequested) {
      return ChapterOutputPathResolution(
        requestedPath: cleanRequested,
        resolvedPath: cleanRequested,
        title: effectiveTitle,
        chapterNumber: effectiveNumber,
      );
    }
    if (!_isUpgradeablePlaceholderPath(
      cleanRequested,
      chapterNumber: effectiveNumber,
    )) {
      return ChapterOutputPathResolution(
        requestedPath: cleanRequested,
        resolvedPath: cleanRequested,
        title: effectiveTitle,
        chapterNumber: effectiveNumber,
      );
    }
    return ChapterOutputPathResolution(
      requestedPath: cleanRequested,
      resolvedPath: candidatePath,
      title: effectiveTitle,
      chapterNumber: effectiveNumber,
      pathChanged: true,
      reason: 'chapter_placeholder_path_upgraded',
    );
  }

  ChapterOutputPathResolution resolveChapterPath({
    required String requestedPath,
    required String title,
    required String chapterContent,
    int chapterNumber = 0,
  }) {
    return resolveChapterOutput(
      requestedPath: requestedPath,
      explicitTitle: title,
      chapterContent: chapterContent,
      chapterNumber: chapterNumber,
    );
  }

  String effectiveChapterTitle({
    required String explicitTitle,
    required String chapterContent,
    String submissionTitle = '',
    int chapterNumber = 0,
  }) {
    final explicit = explicitTitle.trim();
    if (explicit.isNotEmpty && !_isBareChapterPrefix(explicit)) {
      return explicit;
    }
    final submission = submissionTitle.trim();
    if (submission.isNotEmpty && !_isBareChapterPrefix(submission)) {
      return submission;
    }
    final heading = _titleFromMarkdownHeading(chapterContent);
    if (heading.isNotEmpty) {
      return heading;
    }
    if (explicit.isNotEmpty) {
      return explicit;
    }
    if (submission.isNotEmpty) {
      return submission;
    }
    return chapterNumber > 0 ? chapterPrefix(chapterNumber) : '';
  }

  String chapterPrefix(int chapterNumber) {
    return '第${chapterNumber.toString().padLeft(2, '0')}章';
  }

  String chapterTitleWithoutPrefix(String value, {required int chapterNumber}) {
    var text = value.trim().replaceAll('：', ':');
    final prefix = chapterPrefix(chapterNumber);
    final loosePrefix = '第$chapterNumber章';
    for (var index = 0; index < 2; index += 1) {
      final before = text;
      text = _removeChapterPrefix(text, prefix);
      text = _removeChapterPrefix(text, loosePrefix);
      if (text == before) {
        break;
      }
    }
    return text.trim();
  }

  String safeFilePart(String value, String fallback) {
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
      ' ',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.isEmpty) {
      result = fallback;
    }
    if (result.length > 96) {
      result = result.substring(0, 96);
    }
    return result;
  }

  String normalizeChapterMarkdownHeading({
    required String chapterContent,
    required String title,
  }) {
    final cleanTitle = title.trim();
    final normalizedContent = chapterContent.trimRight();
    if (cleanTitle.isEmpty) {
      return normalizedContent;
    }
    final lines = normalizedContent.replaceAll('\r\n', '\n').split('\n');
    for (var index = 0; index < lines.length; index += 1) {
      final trimmed = lines[index].trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.startsWith('#')) {
        lines[index] = '# $cleanTitle';
        return lines.join('\n').trimRight();
      }
      break;
    }
    if (normalizedContent.isEmpty) {
      return '# $cleanTitle';
    }
    return '# $cleanTitle\n\n$normalizedContent';
  }

  String normalizeRelativePath(String value) {
    final normalized = value.trim().replaceAll('\\', '/');
    final parts = <String>[];
    for (final rawPart in normalized.split('/')) {
      final part = rawPart.trim();
      if (part.isEmpty || part == '.') {
        continue;
      }
      if (part == '..') {
        if (parts.isNotEmpty) {
          parts.removeLast();
        }
        continue;
      }
      parts.add(part);
    }
    return parts.join('/');
  }

  bool _isUpgradeablePlaceholderPath(
    String path, {
    required int chapterNumber,
  }) {
    final normalized = normalizeRelativePath(path);
    final chapterDirectory = _contentPathPolicyService.directoryForContentType(
      'chapter',
    );
    if (!normalized.toLowerCase().startsWith('$chapterDirectory/')) {
      return false;
    }
    final stem = normalized
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.md$', caseSensitive: false), '');
    final prefix = chapterPrefix(chapterNumber);
    final loosePrefix = '第$chapterNumber章';
    if (stem == prefix ||
        stem == loosePrefix ||
        stem == '${prefix}_seed_to_full' ||
        stem == '${loosePrefix}_seed_to_full') {
      return true;
    }
    final remainder = chapterTitleWithoutPrefix(
      stem,
      chapterNumber: chapterNumber,
    );
    return remainder.isEmpty ||
        remainder == prefix ||
        remainder == loosePrefix ||
        remainder == 'seed_to_full';
  }

  String _removeChapterPrefix(String value, String prefix) {
    if (prefix.isEmpty) {
      return value;
    }
    final text = value.trim();
    if (text == prefix) {
      return '';
    }
    if (!text.startsWith(prefix)) {
      return text;
    }
    var rest = text.substring(prefix.length).trim();
    while (rest.startsWith(':') ||
        rest.startsWith('_') ||
        rest.startsWith('-') ||
        rest.startsWith('—')) {
      rest = rest.substring(1).trim();
    }
    return rest;
  }

  String _titleFromMarkdownHeading(String value) {
    for (final rawLine in value.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      if (line.startsWith('#')) {
        return line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      }
      return '';
    }
    return '';
  }

  int? _chapterNumberFromPath(String path) {
    final normalized = normalizeRelativePath(path);
    if (normalized.isEmpty) {
      return null;
    }
    final stem = normalized
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.md$', caseSensitive: false), '');
    return _chapterNumberFromTitle(stem);
  }

  int? _chapterNumberFromTitle(String title) {
    final match = RegExp(r'^第0*(\d+)章').firstMatch(title.trim());
    if (match == null) {
      return null;
    }
    return ValueReaders.intValue(match.group(1));
  }

  bool _isBareChapterPrefix(String value) {
    return RegExp(r'^第0*\d+章$').hasMatch(value.trim());
  }
}
