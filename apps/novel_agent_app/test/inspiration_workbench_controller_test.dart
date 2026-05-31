import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/inspiration_workbench/application/controllers/inspiration_workbench_controller.dart';
import 'package:novel_agent_app/features/inspiration_workbench/application/models/inspiration_workbench_long_task_launch_result.dart';
import 'package:novel_agent_app/features/inspiration_workbench/application/services/inspiration_workbench_long_task_launcher_service.dart';
import 'package:novel_agent_app/features/inspiration_workbench/application/services/inspiration_workbench_long_task_launch_view_data_service.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('灵感工作台会把阶段答案沉淀为共享预览资产', () async {
    final port = _InMemoryModeGuidanceStatePort();
    final loadUseCase = LoadModeGuidanceStateUseCase(statePort: port);
    final answerUseCase = AnswerModeGuidanceStageUseCase(statePort: port);
    final project = ProjectDescriptor(
      id: 'project-1',
      name: '测试项目',
      rootPath: 'D:/Projects/test_project',
      projectType: 'general_novel',
    );
    var synced = 0;
    final controller = InspirationWorkbenchController(
      loadModeGuidanceStateUseCase: loadUseCase,
      answerModeGuidanceStageUseCase: answerUseCase,
      readCurrentProject: () => project,
      readCurrentProjectTitle: () => project.name,
      syncWorkbenchResources: () async {
        synced += 1;
      },
      onBackRequested: () {},
      showTaskCenterRequested: () async {},
      longTaskLauncherService: _FakeLongTaskLauncherService(),
    );

    await controller.initialize();
    await controller.refresh(preferredModeId: 'full_outline_consensus');

    expect(controller.viewData.selectedModeTitle, '全书共拟式长篇');
    expect(controller.viewData.stages.first.id, 'book_premise');

    await controller.onInspirationWorkbenchTextSubmitted(
      stageId: controller.viewData.stages.first.id,
      fieldKey: controller.viewData.stages.first.fieldKey,
      value: '一个围绕海上巨城权力更替展开的长篇故事前提。',
    );

    final premiseSection = controller.viewData.previewSections.firstWhere(
      (section) => section.id == 'premise',
    );
    expect(synced, 1);
    expect(premiseSection.items, isNotEmpty);
    expect(premiseSection.items.first.summary, contains('海上巨城'));
    expect(controller.viewData.progressText, '1/6');
  });

  test('长任务项目在灵感收束完成后会暴露启动入口', () async {
    final port = _InMemoryModeGuidanceStatePort();
    final transitionService = ModeGuidanceTransitionService();
    final state = _seedReadyState(
      transitionService: transitionService,
      modeId: 'seed_autopilot_novel',
    );
    final project = ProjectDescriptor(
      id: 'project-2',
      name: '长篇项目',
      rootPath: 'D:/Projects/long_project',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await port.save(project, state);

    final controller = InspirationWorkbenchController(
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: port,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: port,
      ),
      readCurrentProject: () => project,
      readCurrentProjectTitle: () => project.name,
      syncWorkbenchResources: () async {},
      onBackRequested: () {},
      showTaskCenterRequested: () async {},
      longTaskLauncherService: _FakeLongTaskLauncherService(),
    );

    await controller.refresh(preferredModeId: 'seed_autopilot_novel');

    expect(controller.viewData.longTaskLaunch.isVisible, isTrue);
    expect(controller.viewData.longTaskLaunch.canLaunch, isTrue);
    expect(
      controller.viewData.longTaskLaunch.guidancePath,
      'tracking/modes/seed_autopilot_novel/guidance.md',
    );
  });

  test('灵感工作台可直接启动长任务并跳到长任务总站', () async {
    final port = _InMemoryModeGuidanceStatePort();
    final transitionService = ModeGuidanceTransitionService();
    final state = _seedReadyState(
      transitionService: transitionService,
      modeId: 'seed_autopilot_novel',
    );
    final project = ProjectDescriptor(
      id: 'project-3',
      name: '长篇项目',
      rootPath: 'D:/Projects/launch_project',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await port.save(project, state);
    final launcher = _FakeLongTaskLauncherService(
      result: const InspirationWorkbenchLongTaskLaunchResult(
        ok: true,
        message: '长任务队列已生成，共创建 7 个任务。',
      ),
    );
    var taskCenterShown = 0;
    var synced = 0;
    final controller = InspirationWorkbenchController(
      loadModeGuidanceStateUseCase: LoadModeGuidanceStateUseCase(
        statePort: port,
      ),
      answerModeGuidanceStageUseCase: AnswerModeGuidanceStageUseCase(
        statePort: port,
      ),
      readCurrentProject: () => project,
      readCurrentProjectTitle: () => project.name,
      syncWorkbenchResources: () async {
        synced += 1;
      },
      onBackRequested: () {},
      showTaskCenterRequested: () async {
        taskCenterShown += 1;
      },
      longTaskLauncherService: launcher,
    );

    await controller.refresh(preferredModeId: 'seed_autopilot_novel');
    await controller.onInspirationWorkbenchLongTaskLaunchRequested();

    expect(launcher.lastProject?.rootPath, project.rootPath);
    expect(launcher.lastModeId, 'seed_autopilot_novel');
    expect(taskCenterShown, 1);
    expect(synced, 1);
    expect(controller.viewData.status, contains('已自动切到长任务总站'));
  });

  test('长任务启动视图只在长任务项目里显示', () {
    final service = InspirationWorkbenchLongTaskLaunchViewDataService();
    final readyState = _seedReadyState(
      transitionService: ModeGuidanceTransitionService(),
      modeId: 'seed_autopilot_novel',
    );

    final longProjectView = service.build(
      projectType: 'long_novel',
      state: readyState,
    );
    final normalProjectView = service.build(
      projectType: 'novel',
      state: readyState,
    );

    expect(longProjectView.isVisible, isTrue);
    expect(longProjectView.canLaunch, isTrue);
    expect(normalProjectView.isVisible, isFalse);
  });
}

class _InMemoryModeGuidanceStatePort implements ModeGuidanceStatePort {
  final Map<String, ModeGuidanceState> _states = <String, ModeGuidanceState>{};

  @override
  Future<ModeGuidanceState?> load(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    return _states['${project.rootPath}::$modeId'];
  }

  @override
  Future<void> save(ProjectDescriptor project, ModeGuidanceState state) async {
    _states['${project.rootPath}::${state.modeId}'] = state;
  }
}

class _FakeLongTaskLauncherService
    extends InspirationWorkbenchLongTaskLauncherService {
  _FakeLongTaskLauncherService({
    this.result = const InspirationWorkbenchLongTaskLaunchResult(
      ok: false,
      message: 'noop',
    ),
  }) : super(
         buildModeGuidancePlanInputUseCase: BuildModeGuidancePlanInputUseCase(
           statePort: _InMemoryModeGuidanceStatePort(),
         ),
         workflowRuntimeService: _UnsupportedWorkflowRuntimeService(),
       );

  final InspirationWorkbenchLongTaskLaunchResult result;
  ProjectDescriptor? lastProject;
  String lastModeId = '';

  @override
  Future<InspirationWorkbenchLongTaskLaunchResult> launch(
    ProjectDescriptor project, {
    required String modeId,
  }) async {
    lastProject = project;
    lastModeId = modeId;
    return result;
  }
}

ModeGuidanceState _seedReadyState({
  required ModeGuidanceTransitionService transitionService,
  required String modeId,
}) {
  var state = transitionService.initialize(modeId);
  switch (modeId) {
    case 'full_outline_consensus':
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'book_premise',
          'field': 'book_premise',
          'value': '围绕海上巨城的权力更替与旧秩序崩塌展开长篇。',
          'label': '故事前提',
        },
        <String, String>{
          'stage': 'main_arc',
          'field': 'main_arc',
          'value': '主角家族与议会联盟围绕继承权和海路控制权展开主线冲突。',
          'label': '主线冲突',
        },
        <String, String>{
          'stage': 'volume_map',
          'field': 'volume_map',
          'value': '三卷结构：夺权、守权、重建新秩序。',
          'label': '分卷结构',
        },
        <String, String>{
          'stage': 'ending_commitment',
          'field': 'ending_commitment',
          'value': '结局落在旧王权瓦解后的新秩序建立。',
          'label': '结局承诺',
        },
        <String, String>{
          'stage': 'style_and_boundaries',
          'field': 'style_and_boundaries',
          'value': '史诗感、政治斗争与人物抉择并重，避免空泛旁白。',
          'label': '风格边界',
        },
        <String, String>{
          'stage': 'review_ready',
          'field': 'review_ready',
          'value': '可以启动长任务。',
          'label': '确认启动',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
          label: item['label']!,
          source: 'free_text',
        );
      }
      return state;
    default:
      for (final item in const <Map<String, String>>[
        <String, String>{
          'stage': 'seed_scope',
          'field': 'seed_scope',
          'value': '都市异闻悬疑长篇。',
          'label': '已有种子',
        },
        <String, String>{
          'stage': 'core_promise',
          'field': 'core_promise',
          'value': '悬疑递进与都市压迫感并行推进。',
          'label': '核心承诺',
        },
        <String, String>{
          'stage': 'world_anchor',
          'field': 'world_anchor',
          'value': '所有异常都必须通过电波残响被感知。',
          'label': '世界锚点',
        },
        <String, String>{
          'stage': 'protagonist_drive',
          'field': 'protagonist_drive',
          'value': '主角要查清姐姐失踪真相。',
          'label': '主角驱动',
        },
        <String, String>{
          'stage': 'style_target',
          'field': 'style_target',
          'value': '商业悬疑风格，利落克制。',
          'label': '风格目标',
        },
        <String, String>{
          'stage': 'autonomy_guardrails',
          'field': 'autonomy_guardrails',
          'value': '允许连续推进，每隔数章回到检查点。',
          'label': '托管边界',
        },
        <String, String>{
          'stage': 'review_ready',
          'field': 'review_ready',
          'value': '可以启动长任务。',
          'label': '确认启动',
        },
      ]) {
        state = transitionService.answer(
          state,
          stageId: item['stage']!,
          fieldKey: item['field']!,
          value: item['value']!,
          label: item['label']!,
          source: 'free_text',
        );
      }
      return state;
  }
}

class _UnsupportedWorkflowRuntimeService extends Fake
    implements ProjectWorkflowRuntimeService {}
