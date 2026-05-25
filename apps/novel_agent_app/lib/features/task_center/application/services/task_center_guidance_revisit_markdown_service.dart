import 'package:novel_agent_core/novel_agent_core.dart';

class TaskCenterGuidanceRevisitMarkdownService {
  const TaskCenterGuidanceRevisitMarkdownService();

  String render(JsonMap package) {
    // 中文注释: 长期约束回看包在这里统一转成详情区可展示文本，避免控制器和 widget 各自拼接文案。
    if (!ValueReaders.boolValue(package['ok'])) {
      return '';
    }
    final lines = <String>[
      '## 长期约束回看',
      '',
      ValueReaders.stringValue(package['summary']).trim(),
    ];
    final focusDomains = ValueReaders.stringList(package['focus_domains']);
    if (focusDomains.isNotEmpty) {
      lines.add('');
      lines.add('- 聚焦域：${_domainLabels(focusDomains).join('、')}');
    }
    for (final item in ValueReaders.mapList(package['items'])) {
      final title = ValueReaders.stringValue(item['title']).trim();
      final path = ValueReaders.stringValue(item['path']).trim();
      final summary = ValueReaders.stringValue(item['summary']).trim();
      final preview = ValueReaders.stringValue(item['content_preview']).trim();
      final highlights = ValueReaders.stringList(item['highlights']);
      lines.add('');
      lines.add('### ${title.isEmpty ? '未命名约束' : title}');
      if (path.isNotEmpty) {
        lines.add('- 路径：$path');
      }
      if (summary.isNotEmpty) {
        lines.add('- 摘要：$summary');
      }
      if (highlights.isNotEmpty) {
        lines.add('- 关键点：${highlights.join('；')}');
      }
      if (preview.isNotEmpty) {
        lines.add('- 预览：$preview');
      }
    }
    return lines.join('\n').trim();
  }

  List<String> _domainLabels(List<String> domains) {
    final result = <String>[];
    for (final domain in domains) {
      switch (domain.trim()) {
        case 'style':
          result.add('风格');
          break;
        case 'world':
          result.add('世界');
          break;
        case 'entity':
          result.add('角色');
          break;
        default:
          result.add(domain.trim());
      }
    }
    return result;
  }
}
