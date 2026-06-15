import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'project_fact_acquisition_lane.dart';

class ProjectFactAcquisitionContract {
  const ProjectFactAcquisitionContract({
    required this.workflowId,
    required this.projectTypeId,
    required this.lanes,
    this.longTermFactExamples = const <String>[],
    this.localFactExamples = const <String>[],
    this.workflowRules = const <String>[],
  });

  final String workflowId;
  final String projectTypeId;
  final List<ProjectFactAcquisitionLane> lanes;
  final List<String> longTermFactExamples;
  final List<String> localFactExamples;
  final List<String> workflowRules;

  JsonMap toJsonMap() {
    return <String, Object?>{
      'workflow_id': workflowId,
      'project_type_id': projectTypeId,
      'lanes': lanes
          .map((lane) => lane.toJsonMap())
          .cast<Object?>()
          .toList(growable: false),
      'long_term_fact_examples': ValueReaders.deepCopyList(
        longTermFactExamples.cast<Object?>(),
      ),
      'local_fact_examples': ValueReaders.deepCopyList(
        localFactExamples.cast<Object?>(),
      ),
      'workflow_rules': ValueReaders.deepCopyList(
        workflowRules.cast<Object?>(),
      ),
    };
  }

  String renderMarkdown() {
    final lines = <String>[
      '## 项目事实获取合同',
      '遇到尚未完全明确的信息时，只允许使用 confirmed、pending_confirmation、tentative_assumption 三种状态，不要把猜测伪装成既定项目事实。',
      '',
      '长期项目事实示例：${longTermFactExamples.join('、')}。',
      '局部可暂借事实示例：${localFactExamples.join('、')}。',
      '',
      '三态语义：',
    ];
    for (final lane in lanes) {
      lines.add('- `${lane.statusId}` / ${lane.title}：${lane.description}');
      if (lane.allowedActions.isNotEmpty) {
        lines.add('  可做：${lane.allowedActions.join('；')}。');
      }
      if (lane.forbiddenActions.isNotEmpty) {
        lines.add('  不可做：${lane.forbiddenActions.join('；')}。');
      }
    }
    if (workflowRules.isNotEmpty) {
      lines.add('');
      lines.add('流程补充：');
      for (final rule in workflowRules) {
        lines.add('- $rule');
      }
    }
    return lines.join('\n');
  }
}
