import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_cli/bootstrap/cli_bootstrap.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 该探针专门验证 CLI 是否能复用同一套模式引导状态，读取状态并直接生成长任务队列。
  final bundle = AdapterBundle.standard(
    workingDirectoryPath: Directory.current.path,
  );
  final createProjectWorkspaceUseCase = CreateProjectWorkspaceUseCase(
    projectRepository: bundle.projectRepository,
    projectWorkspacePort: bundle.projectWorkspacePort,
    projectContentRepository: bundle.projectContentRepository,
    projectReadableProjectionService: bundle.projectReadableProjectionService,
  );
  final modeRepository = ProjectModeGuidanceRepository(
    workspacePort: bundle.projectWorkspacePort,
  );
  final transitionService = ModeGuidanceTransitionService();
  final projectRoot = await Directory.systemTemp.createTemp(
    'novel_agent_cli_mode_probe_',
  );
  try {
    final project = await createProjectWorkspaceUseCase.execute(
      projectsRootPath: projectRoot.path,
      title: 'CLI模式引导探针',
      projectType: 'long_novel',
      runtimeBaselineId: 'continuous_autonomous',
    );
    await _seedReadyState(
      repository: modeRepository,
      transitionService: transitionService,
      project: project,
    );
    final bootstrap = CliBootstrap();
    final guidanceExitCode = await bootstrap.run(<String>[
      'workflow',
      'guidance-status',
      '--mode',
      'seed_autopilot_novel',
      '--project',
      project.rootPath,
    ]);
    final createExitCode = await bootstrap.run(<String>[
      'workflow',
      'create-from-guidance',
      '--mode',
      'seed_autopilot_novel',
      '--project',
      project.rootPath,
    ]);
    final entries = await bundle.projectWorkspacePort.listEntries(
      project.rootPath,
      recursive: true,
    );
    final taskPaths = entries
        .map((entry) => ValueReaders.stringValue(entry['relative_path']))
        .where((path) => path.startsWith('tasks/') && path.endsWith('.json'))
        .toList(growable: false);
    stdout.writeln('guidance_status_exit=$guidanceExitCode');
    stdout.writeln('create_from_guidance_exit=$createExitCode');
    stdout.writeln('task_count=${taskPaths.length}');
    stdout.writeln(
      guidanceExitCode == 0 && createExitCode == 0 && taskPaths.isNotEmpty
          ? 'cli_guidance_probe: PASS'
          : 'cli_guidance_probe: FAIL',
    );
  } finally {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  }
}

Future<void> _seedReadyState({
  required ProjectModeGuidanceRepository repository,
  required ModeGuidanceTransitionService transitionService,
  required ProjectDescriptor project,
}) async {
  var state = transitionService.initialize('seed_autopilot_novel');
  for (final item in const <Map<String, String>>[
    <String, String>{
      'stage': 'seed_scope',
      'field': 'seed_scope',
      'value': '黑暗奇幻权谋长篇。',
    },
    <String, String>{
      'stage': 'core_promise',
      'field': 'core_promise',
      'value': '高压权谋与连续逆转。',
    },
    <String, String>{
      'stage': 'world_anchor',
      'field': 'world_anchor',
      'value': '帝国靠誓约维持秩序，违约会遭受反噬。',
    },
    <String, String>{
      'stage': 'protagonist_drive',
      'field': 'protagonist_drive',
      'value': '复仇翻案，并夺回北境守护权。',
    },
    <String, String>{
      'stage': 'style_target',
      'field': 'style_target',
      'value': '干净利落，偏商业长篇。',
    },
    <String, String>{
      'stage': 'autonomy_guardrails',
      'field': 'autonomy_guardrails',
      'value': '先生成总纲和分卷结构，跨卷大转折再回到用户确认。',
    },
    <String, String>{
      'stage': 'review_ready',
      'field': 'review_ready',
      'value': '已确认以上信息，可以开始生成可恢复长任务链。',
    },
  ]) {
    state = transitionService.answer(
      state,
      stageId: item['stage']!,
      fieldKey: item['field']!,
      value: item['value']!,
      source: 'free_text',
    );
  }
  await repository.save(project, state);
}
