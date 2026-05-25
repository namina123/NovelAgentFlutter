import '../common/value_readers.dart';
import '../strategy/strategy_catalog_service.dart';
import 'mode_guidance_state.dart';

class ModeGuidanceSummaryMarkdownRenderer {
  ModeGuidanceSummaryMarkdownRenderer({
    StrategyCatalogService? strategyCatalogService,
  }) : _strategyCatalogService =
           strategyCatalogService ?? const StrategyCatalogService();

  final StrategyCatalogService _strategyCatalogService;

  String render(ModeGuidanceState state) {
    // 中文注释: 模式摘要 Markdown 作为用户可读面和模型可读面，必须稳定且避免泄露内部控制字段。
    final mode = _strategyCatalogService.modeDefinitionById(state.modeId);
    final lines = <String>[
      '# ${mode.title} 引导摘要',
      '',
      '- 模式 ID：${state.modeId}',
      '- 状态：${state.status == ModeGuidanceState.statusReady ? '可启动长任务' : '收集中'}',
      '- 当前阶段：${_stageTitle(mode.id, state.currentStageId)}',
      '- 已完成阶段数：${state.completedStageIds.length}/${mode.stages.length}',
      '',
      '## 阶段答案',
      '',
    ];
    for (final stage in mode.stages) {
      final answer = state.answers
          .where((item) => item.stageId == stage.id)
          .toList(growable: false);
      lines.add('### ${stage.title}');
      if (answer.isEmpty) {
        lines.add('- 暂未确认');
      } else {
        for (final item in answer) {
          final label = item.label.trim().isEmpty ? item.value : item.label;
          lines.add('- $label');
          if (item.label.trim().isNotEmpty &&
              item.value.trim() != item.label.trim()) {
            lines.add('  - 展开：${ValueReaders.stringValue(item.value)}');
          }
        }
      }
      lines.add('');
    }
    return lines.join('\n').trimRight() + '\n';
  }

  String _stageTitle(String modeId, String stageId) {
    for (final stage in _strategyCatalogService
        .modeDefinitionById(modeId)
        .stages) {
      if (stage.id == stageId) {
        return stage.title;
      }
    }
    return stageId;
  }
}
