import 'package:novel_agent_adapters/novel_agent_adapters.dart';

class LongTaskStationItemHumanizerService {
  const LongTaskStationItemHumanizerService();

  String title(
    ProjectLongTaskStationItemSummary item, {
    String? titleOverride,
  }) {
    final override = titleOverride?.trim() ?? '';
    if (override.isNotEmpty) {
      return override;
    }
    final relativePath = item.relativePath.replaceAll('\\', '/').trim();
    final rawTitle = item.title.trim();
    if (relativePath.contains('/continuity/clarifications/') ||
        rawTitle == 'Clarification' ||
        rawTitle == 'Clarifications') {
      return '待确认问题';
    }
    if (relativePath.startsWith(
          '.novel_agent/information/research_requests/',
        ) ||
        rawTitle == 'Research Pending') {
      return '待确认调研请求';
    }
    if (relativePath.contains('/information/knowledge_cards/') ||
        rawTitle == 'Knowledge Confirmation') {
      return '待确认知识卡';
    }
    return rawTitle;
  }

  String subtitle(ProjectLongTaskStationItemSummary item) {
    final rawSubtitle = item.subtitle.trim();
    if (rawSubtitle.isEmpty) {
      return '';
    }
    final exact = _humanizedSubtitle(rawSubtitle);
    if (exact != rawSubtitle) {
      return exact;
    }
    if (!rawSubtitle.contains(' · ')) {
      return _humanizedSubtitleSegment(rawSubtitle);
    }
    return rawSubtitle
        .split(' · ')
        .map(_humanizedSubtitleSegment)
        .join(' · ');
  }

  String _humanizedSubtitle(String subtitle) {
    switch (subtitle) {
      case 'Readable projection':
        return '可读投影';
      case 'Information projection':
        return '资料投影';
      case 'quality gate':
        return '质量关口';
      default:
        return subtitle;
    }
  }

  String _humanizedSubtitleSegment(String segment) {
    switch (segment.trim()) {
      case 'delivered':
        return '已交付';
      case 'review':
        return '审稿';
      case 'revision':
        return '返工';
      case 'scope':
        return '审稿范围';
      case 'needs_user_confirmation':
        return '待你确认';
      case 'awaiting_user_confirmation':
        return '等待确认';
      case 'proposed':
        return '待确认';
      case 'setting_fact':
        return '设定事实';
      case 'project.world':
        return '项目世界观';
      case 'adaptive':
        return '自适应';
      case 'suggest_strengthen':
        return '建议加强';
      case 'applied':
        return '已应用';
      case 'force':
        return '强制要求';
      default:
        return segment.trim();
    }
  }
}
