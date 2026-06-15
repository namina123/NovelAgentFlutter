import 'project_fact_acquisition_contract.dart';
import 'project_fact_acquisition_lane.dart';
import 'project_fact_acquisition_status.dart';

class ProjectFactAcquisitionContractService {
  const ProjectFactAcquisitionContractService();

  ProjectFactAcquisitionContract build({
    required String workflowId,
    required String projectTypeId,
    String intent = '',
  }) {
    return ProjectFactAcquisitionContract(
      workflowId: workflowId.trim(),
      projectTypeId: projectTypeId.trim(),
      lanes: const <ProjectFactAcquisitionLane>[
        ProjectFactAcquisitionLane(
          statusId: ProjectFactAcquisitionStatus.confirmed,
          title: '已确认',
          description: '只有用户明确确认过，或项目中已有稳定证据可直接指认的长期事实，才能进入这个状态。',
          allowedActions: <String>[
            '写入项目规格、总纲、章纲、任务链、长期资产或知识结构',
            '在后续轮次里当成稳定前提继续使用',
          ],
          forbiddenActions: <String>['拿模型自己脑补出的长期设定冒充 confirmed'],
        ),
        ProjectFactAcquisitionLane(
          statusId: ProjectFactAcquisitionStatus.pendingConfirmation,
          title: '待确认候选',
          description: '当你需要提出方向、归纳用户意图或补一个候选方案时，可以暂时提出，但必须明确它仍待用户确认。',
          allowedActions: <String>[
            '整理为候选方向、可点击选项、待确认摘要',
            '用“我理解你可能想要的是...”之类方式回抛给用户确认',
          ],
          forbiddenActions: <String>[
            '直接写入长期项目资产并当成既定事实',
            '跳过确认就生成依赖该事实的大规模任务链',
          ],
        ),
        ProjectFactAcquisitionLane(
          statusId: ProjectFactAcquisitionStatus.tentativeAssumption,
          title: '暂借假设',
          description: '只允许用于当前轮低风险占位，例如局部场景衔接、示例措辞、不会反向约束项目长期走向的细枝末节。',
          allowedActions: <String>['用于一次性的说明、示例、局部保守推进'],
          forbiddenActions: <String>[
            '写入项目规格、角色稳定设定、世界硬规则、总纲、长期记忆、知识卡或设计卡',
            '在下一轮把它当成已经确认过的事实继续引用',
          ],
        ),
      ],
      longTermFactExamples: const <String>[
        '主角稳定性格与处事风格',
        '主角身份/背景/长期目标',
        '世界硬规则与制度边界',
        '关键人物长期关系',
        '全书主线承诺与结局方向',
        '项目级风格边界与禁区',
      ],
      localFactExamples: const <String>[
        '当前段落的动作衔接',
        '局部场景里的低风险过渡细节',
        '一次性的示例称呼或占位表达',
      ],
      workflowRules: _workflowRules(
        workflowId: workflowId.trim(),
        projectTypeId: projectTypeId.trim(),
        intent: intent.trim(),
      ),
    );
  }

  List<String> _workflowRules({
    required String workflowId,
    required String projectTypeId,
    required String intent,
  }) {
    switch (workflowId) {
      case 'interactive_opening':
        return const <String>[
          '由智能体自己判断这一轮最值得收集哪个信息维度，但不要静默补完长期项目事实。',
          '如果用户只给了模糊背景，你可以提出 2-4 个候选理解；这些候选只能停留在 pending_confirmation，不能直接落成项目规格。',
          '除非用户明确表示“你来定”，否则不要替用户锁死主角稳定设定、世界硬边界、长期关系和项目级风格承诺。',
        ];
      case 'long_task_opening':
        return const <String>[
          '生成长任务队列前，核心承诺、世界边界、主角驱动力、风格边界、托管边界这类长期约束不能停留在 tentative_assumption。',
          '如果当前只能提出候选方向，请先把它们保持在 pending_confirmation，并继续收束，不要直接展开依赖这些候选的庞大任务链。',
          '长任务开局允许逐轴收集，不必硬表单；但一旦要写 specs、总纲、卷纲、章纲或任务链，就只能消费 confirmed 事实，最多附带明确标识的 pending_confirmation 候选。',
        ];
      case 'draft':
      default:
        final baseRules = <String>[
          '正文推进时，如果缺的是长期项目事实，不要为了写得顺而自行写死；能保守推进就保守推进，不能保守推进就停下来确认。',
          '如果只是局部桥接需要少量假设，可以用 tentative_assumption，但不能把它写进长期资产或当成后续事实。',
          '当一章会新引入稳定事实时，只有真正形成证据且应进入长期记忆时，才允许提升为 confirmed 或显式待确认候选。',
        ];
        if (projectTypeId == 'long_novel' || intent == 'chapter') {
          baseRules.add('长任务正文轮尤其不能把未确认的长期设定偷偷塞进章纲、总纲承诺或后续章节前提里。');
        }
        return baseRules;
    }
  }
}
