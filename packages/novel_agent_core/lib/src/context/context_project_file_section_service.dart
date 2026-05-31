import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'context_budget_constants.dart';
import 'context_section_catalog.dart';

class ContextProjectFileSectionService {
  List<JsonMap> buildProjectFileSections({
    required List<Object?> projectFiles,
    required JsonMap projectFileContents,
    required JsonMap contextSettings,
  }) {
    // 中文注释: 项目文件片段选择只基于目录类别和已提供的文本内容，不直接触碰文件系统。
    final sections = <JsonMap>[];
    final maxCount = ValueReaders.intValue(
      contextSettings['max_context_files_per_kind'],
      ContextBudgetConstants.defaultMaxContextFilesPerKind,
    );
    final maxChars = ValueReaders.intValue(
      contextSettings['max_context_file_chars'],
      ContextBudgetConstants.defaultMaxContextFileChars,
    );
    for (final rootEntry in ContextSectionCatalog.kindRoots.entries) {
      final root = rootEntry.key;
      final info = ValueReaders.mapValue(rootEntry.value);
      final prefixes = ValueReaders.stringList(info['prefixes']);
      final snippets = _readSnippets(
        projectFiles: projectFiles,
        projectFileContents: projectFileContents,
        root: root,
        prefixes: prefixes,
        maxCount: maxCount,
        maxChars: maxChars,
      );
      if (snippets.isEmpty) {
        continue;
      }
      sections.add(<String, Object?>{
        'id': 'project_$root',
        'title': ValueReaders.stringValue(info['title'], root),
        'source': '$root/',
        'priority': ValueReaders.intValue(info['priority'], 60),
        'content': snippets.join('\n\n'),
      });
    }
    return sections;
  }

  List<String> readPlannedSnippets(
    JsonMap sectionPlan, {
    required JsonMap projectFileContents,
  }) {
    // 中文注释: 计划片段读取保留给后续 candidate plan 接入，这里先用已提供的 path->text 映射完成纯逻辑迁移。
    final snippets = <String>[];
    final maxChars = ValueReaders.intValue(
      sectionPlan['max_chars'],
      ContextBudgetConstants.defaultMaxContextFileChars,
    );
    for (final rawPath in ValueReaders.objectList(sectionPlan['paths'])) {
      final path = ValueReaders.stringValue(rawPath).trim();
      if (path.isEmpty) {
        continue;
      }
      final text = ValueReaders.stringValue(projectFileContents[path]).trim();
      if (text.isEmpty) {
        continue;
      }
      snippets.add('【$path】\n${clipText(text, maxChars)}');
    }
    return snippets;
  }

  String clipText(String value, int maxChars) {
    // 中文注释: 长文本在项目文件片段层只做轻量截断，真正预算裁剪交给 budget service 处理。
    if (value.length <= maxChars) {
      return value;
    }
    return '${value.substring(0, maxChars)}\n……（已截断）';
  }

  List<String> _readSnippets({
    required List<Object?> projectFiles,
    required JsonMap projectFileContents,
    required String root,
    required List<String> prefixes,
    required int maxCount,
    required int maxChars,
  }) {
    // 中文注释: 这里按旧项目目录根类别读取高价值文本片段，避免一次把全项目塞进模型窗口。
    final snippets = <String>[];
    var count = 0;
    for (final rawEntry in projectFiles) {
      final item = ValueReaders.mapValue(rawEntry);
      final path = ValueReaders.stringValue(item['relative_path']).trim();
      final matchesRoot = prefixes.isEmpty
          ? path.startsWith('$root/')
          : prefixes.any((prefix) => path.startsWith(prefix));
      if (ValueReaders.boolValue(item['is_dir']) || !matchesRoot) {
        continue;
      }
      final extension = path.contains('.')
          ? path.split('.').last.toLowerCase()
          : '';
      if (!<String>['md', 'txt', 'json'].contains(extension)) {
        continue;
      }
      final text = ValueReaders.stringValue(projectFileContents[path]).trim();
      if (text.isEmpty) {
        continue;
      }
      snippets.add('【$path】\n${clipText(text, maxChars)}');
      count += 1;
      if (count >= maxCount) {
        break;
      }
    }
    return snippets;
  }
}
