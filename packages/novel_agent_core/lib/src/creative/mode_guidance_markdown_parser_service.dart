import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../modes/mode_guidance_state.dart';
import 'mode_guidance_mapper_service.dart';

class ModeGuidanceMarkdownParserService {
  ModeGuidanceMarkdownParserService({
    ModeGuidanceMapperService? mapperService,
  }) : _mapperService = mapperService ?? ModeGuidanceMapperService();

  final ModeGuidanceMapperService _mapperService;

  JsonMap parseDocument(
    String content, {
    required String modeId,
    String relativePath = '',
  }) {
    // 中文注释: 模式引导 Markdown 主要是用户可读投影，这里只提取足够稳定的事实和边界摘要供共享链路复用。
    final title = _extractHeading(content);
    final facts = <String>[];
    final boundaries = <String>[];
    var inStageAnswers = false;
    for (final rawLine in content.replaceAll('\r', '').split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('## ')) {
        inStageAnswers = line.contains('阶段答案');
        continue;
      }
      if (!line.startsWith('- ')) {
        continue;
      }
      final item = line.substring(2).trim();
      if (item.isEmpty) {
        continue;
      }
      if (inStageAnswers) {
        facts.add(item);
      }
      if (item.contains('边界') || item.contains('禁') || item.contains('风格')) {
        boundaries.add(item);
      }
    }
    final guidance = _mapperService.toDocument(
      _mapperService.fromState(
        _emptyState(modeId),
        sourcePath: relativePath,
      ),
    );
    return <String, Object?>{
      ...guidance,
      'title': title.isEmpty ? ValueReaders.stringValue(guidance['title']) : title,
      'summary': _summaryFromBody(content, title),
      'confirmed_facts': facts,
      'boundaries': boundaries,
      'source_path': relativePath.trim(),
    };
  }

  String _extractHeading(String body) {
    for (final line in body.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('# ')) {
        return trimmed.substring(2).trim();
      }
    }
    return '';
  }

  String _summaryFromBody(String body, String heading) {
    final lines = body.replaceAll('\r', '').split('\n');
    final kept = <String>[];
    var skippedHeading = false;
    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (!skippedHeading && line.trim() == '# $heading'.trim()) {
        skippedHeading = true;
        continue;
      }
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        if (kept.isNotEmpty) {
          break;
        }
        continue;
      }
      if (trimmed.startsWith('- ')) {
        continue;
      }
      kept.add(trimmed);
    }
    return kept.join('\n').trim();
  }

  ModeGuidanceState _emptyState(String modeId) {
    return ModeGuidanceState(
      modeId: modeId,
      projectStrategyId: '',
      workflowStrategyId: '',
      status: ModeGuidanceState.statusCollecting,
      currentStageId: '',
      answers: const [],
      completedStageIds: const [],
      createdAt: '',
      updatedAt: '',
    );
  }
}
