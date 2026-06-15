import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../project/project_fact_acquisition_contract_service.dart';

class LongTaskOpeningPromptBuilderService {
  const LongTaskOpeningPromptBuilderService({
    ProjectFactAcquisitionContractService factAcquisitionContractService =
        const ProjectFactAcquisitionContractService(),
  }) : _factAcquisitionContractService = factAcquisitionContractService;

  final ProjectFactAcquisitionContractService _factAcquisitionContractService;

  String build({
    JsonMap project = const <String, Object?>{},
    String currentGroupDisplayName = '',
    bool canStartLongTask = false,
    List<String> missingRequirementTitles = const <String>[],
    String effectiveModeId = '',
    String suggestedActionTitle = '',
    String suggestedActionDescription = '',
    String activeDocumentPath = '',
    String activeDocumentExcerpt = '',
  }) {
    final lines = <String>[
      '请接管这个长篇项目的开局推进。你现在的职责不是执行固定表单，而是基于项目现状判断下一步最合适的动作。',
      '',
      '先检查当前项目里真实存在的规格、大纲、章纲、tracking、tasks、samples、chapters 和必要设定；不要假装某个阶段已经完成。',
      '如果信息不足，由你判断最关键的缺口并自然地继续收束；不要为了流程整齐而机械地逐项盘问。',
      '只有在确实需要用户做分支选择时，才调用 present_user_options；如果用户直接自由补充，也要接住并继续推进。',
      '如果现有信息已经足够，就直接进入最有价值的下一步：补齐关键规格/大纲、整理长期约束，或在条件满足时调用 start_long_task_run。',
      '不要把本轮停在纯说明、纯导览或按钮解释；需要真实读取、写入、启动或状态更新时，必须调用工具。',
      '',
      '当前项目线索：',
      _projectLine(project),
    ];
    if (currentGroupDisplayName.trim().isNotEmpty) {
      lines.add('- 当前智能体组：${currentGroupDisplayName.trim()}');
    }
    lines.add(
      canStartLongTask
          ? '- 当前判断：开局信息已基本收束，可以视情况直接进入正式长任务。'
          : missingRequirementTitles.isEmpty
          ? '- 当前判断：仍处于长篇开局收束阶段，需要你先判断还缺什么。'
          : '- 当前判断：目前显式缺口包括 ${missingRequirementTitles.join('、')}，但不要求你机械按清单逐项发问。',
    );
    if (effectiveModeId.trim().isNotEmpty) {
      lines.add('- 当前模式线索：$effectiveModeId');
    }
    if (suggestedActionTitle.trim().isNotEmpty) {
      final description = suggestedActionDescription.trim();
      lines.add(
        description.isEmpty
            ? '- orchestration 当前建议动作：${suggestedActionTitle.trim()}'
            : '- orchestration 当前建议动作：${suggestedActionTitle.trim()}（$description）',
      );
    }
    if (activeDocumentPath.trim().isNotEmpty) {
      lines.add('- 当前打开文件：${activeDocumentPath.trim()}');
    }
    final excerpt = _compact(activeDocumentExcerpt, 900);
    if (excerpt.isNotEmpty) {
      lines.add('- 当前文件片段：$excerpt');
    }
    lines
      ..add('')
      ..add(
        _factAcquisitionContractService
            .build(
              workflowId: 'long_task_opening',
              projectTypeId: ValueReaders.stringValue(
                project['project_type'],
                'long_novel',
              ),
              intent: 'opening.launch_long_task',
            )
            .renderMarkdown(),
      )
      ..add('')
      ..add('本次开局要求：')
      ..add('- 由你判断当前应该先补问、先整理长期约束/大纲，还是直接启动长任务。')
      ..add('- 不要预设“必须先选模式页、再答固定问题、再启动”的机械链路；允许你根据现状跳过不必要步骤。')
      ..add('- 如果你判断用户当前给的信息已经足以开跑，就直接推进，不要为了凑流程继续追问。')
      ..add('- 如果你判断还缺关键边界，就用最少的问题把缺口补齐，再继续。')
      ..add('- 用户没有明确授权你代为决定的人设、主线、风格边界等长期信息，不要擅自补全成既定事实。');
    return lines.join('\n');
  }

  String _projectLine(JsonMap project) {
    if (project.isEmpty) {
      return '- 未检测到项目；请先提醒我创建或打开长篇项目。';
    }
    final parts = <String>[
      '名称：${ValueReaders.stringValue(project['title'], '未命名项目')}',
    ];
    final projectType = ValueReaders.stringValue(
      project['project_type'],
      'long_novel',
    ).trim();
    if (projectType.isNotEmpty) {
      parts.add('类型：$projectType');
    }
    final genre = ValueReaders.stringValue(project['genre']).trim();
    if (genre.isNotEmpty) {
      parts.add('题材：$genre');
    }
    final seed = _compact(
      ValueReaders.stringValue(project['seed_prompt']),
      160,
    );
    if (seed.isNotEmpty) {
      parts.add('创作种子：$seed');
    }
    return '- ${parts.join('；')}';
  }

  String _compact(String text, int maxChars) {
    var cleanText = text.trim().replaceAll('\r', ' ').replaceAll('\n', ' ');
    while (cleanText.contains('  ')) {
      cleanText = cleanText.replaceAll('  ', ' ');
    }
    if (cleanText.length <= maxChars) {
      return cleanText;
    }
    return '${cleanText.substring(0, maxChars)}...';
  }
}
