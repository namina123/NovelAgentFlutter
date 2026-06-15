import '../project/project_content_path_policy_service.dart';
import '../project/chapter_output_path_policy_service.dart';

class DraftFilePathService {
  DraftFilePathService({
    ProjectContentPathPolicyService? contentPathPolicyService,
    ChapterOutputPathPolicyService? chapterOutputPathPolicyService,
  }) : _contentPathPolicyService =
           contentPathPolicyService ?? const ProjectContentPathPolicyService(),
       _chapterOutputPathPolicyService =
           chapterOutputPathPolicyService ??
           const ChapterOutputPathPolicyService();

  final ProjectContentPathPolicyService _contentPathPolicyService;
  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;

  String buildPath({
    required String title,
    String content = '',
    String contentType = 'chapter',
    DateTime? now,
  }) {
    // 中文注释: 自动内容保存路径集中在 core，保证桌面 CLI 与 Flutter GUI 始终落到同一正文目录。
    final normalizedContentType = _contentPathPolicyService.normalizeContentType(
      contentType,
    );
    if (normalizedContentType == 'chapter') {
      final preferredTitle = _chapterOutputPathPolicyService
          .effectiveChapterTitle(
            explicitTitle: '',
            chapterContent: content,
          )
          .trim();
      final chapterPath = _chapterOutputPathPolicyService.suggestChapterPath(
        explicitTitle: preferredTitle.isNotEmpty ? preferredTitle : title,
        chapterContent: content,
      );
      final normalizedChapterPath = chapterPath.trim();
      if (normalizedChapterPath.isNotEmpty &&
          normalizedChapterPath != 'chapters/chapter.md') {
        return normalizedChapterPath;
      }
    }
    final resolvedNow = now ?? DateTime.now();
    final timestamp =
        '${resolvedNow.year.toString().padLeft(4, '0')}'
        '${resolvedNow.month.toString().padLeft(2, '0')}'
        '${resolvedNow.day.toString().padLeft(2, '0')}_'
        '${resolvedNow.hour.toString().padLeft(2, '0')}'
        '${resolvedNow.minute.toString().padLeft(2, '0')}'
        '${resolvedNow.second.toString().padLeft(2, '0')}';
    final slug = _slugify(title);
    final contentRoot = _contentPathPolicyService.directoryForContentType(
      normalizedContentType,
    );
    return slug.isEmpty
        ? '$contentRoot/$timestamp.md'
        : '$contentRoot/${timestamp}_$slug.md';
  }

  String _slugify(String value) {
    // 中文注释: 标题转路径片段时统一过滤危险字符，避免不同宿主写出不兼容文件名。
    final buffer = StringBuffer();
    for (final codeUnit in value.trim().codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final isAsciiLetter =
          (codeUnit >= 65 && codeUnit <= 90) ||
          (codeUnit >= 97 && codeUnit <= 122);
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isCjk = codeUnit >= 0x4E00 && codeUnit <= 0x9FFF;
      if (isAsciiLetter || isDigit || isCjk) {
        buffer.write(char.toLowerCase());
        continue;
      }
      if (buffer.length > 0 && !buffer.toString().endsWith('_')) {
        buffer.write('_');
      }
    }
    var result = buffer.toString().replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    if (result.length > 48) {
      return result.substring(0, 48);
    }
    return result;
  }
}
