import '../../../app/routing/app_destination.dart';
import '../../../app/state/app_shell_controller.dart';
import '../application/command_registry.dart';
import '../domain/command.dart';

/// 根据当前壳层控制器构建命令注册表。
///
/// 命令的 [AppCommand.invoke] 闭包捕获 [controller]，保证执行时无需额外的依赖查找。
/// 导航类命令统一走 [AppShellController.onAppShellDestinationRequested]，与活动栏
/// 同源，确保命令面板跳转与点击导航栏行为完全一致。
///
/// 创作台作用域的命令（保存文档、新建文件、切换面板等）通过 [AppCommand.isEnabled]
/// 绑定到当前目的地：只有身处创作台时才在面板中可见，避免在设置页出现「保存当前文档」。
CommandRegistry buildAppCommandRegistry(AppShellController controller) {
  final registry = CommandRegistry();

  // —— 导航 ——
  registry.register(AppCommand(
    id: 'nav.project_open',
    title: '前往：作品库',
    category: CommandCategory.navigation,
    keywords: const ['作品库', '项目库', '打开项目', 'project', 'library'],
    invoke: () => controller.onAppShellDestinationRequested(
      AppDestination.projectOpen,
    ),
  ));
  registry.register(AppCommand(
    id: 'nav.workbench',
    title: '前往：创作台',
    category: CommandCategory.navigation,
    keywords: const ['创作台', '工作台', '写作', 'workbench'],
    invoke: controller.showWorkbench,
  ));
  registry.register(AppCommand(
    id: 'nav.book_deconstruction',
    title: '前往：拆书分析',
    category: CommandCategory.navigation,
    keywords: const ['拆书', '分析', 'deconstruction'],
    invoke: controller.showBookDeconstructionWorkbench,
  ));
  registry.register(AppCommand(
    id: 'nav.project_assets',
    title: '前往：资料库',
    category: CommandCategory.navigation,
    keywords: const ['资料库', '资产', 'assets', 'rag'],
    invoke: controller.showProjectAssets,
  ));
  registry.register(AppCommand(
    id: 'nav.agent_ecosystem',
    title: '前往：智能体生态',
    category: CommandCategory.navigation,
    keywords: const ['智能体', '生态', 'agent', 'ecosystem', '技能'],
    invoke: controller.showAgentEcosystem,
  ));
  registry.register(AppCommand(
    id: 'nav.long_task_station',
    title: '前往：长任务总站',
    category: CommandCategory.navigation,
    keywords: const ['长任务', '总站', 'long task'],
    invoke: controller.showLongTaskStation,
  ));
  registry.register(AppCommand(
    id: 'nav.task_center',
    title: '前往：任务中心',
    category: CommandCategory.navigation,
    keywords: const ['任务中心', '队列', 'task center', 'queue'],
    invoke: controller.showTaskCenter,
  ));
  registry.register(AppCommand(
    id: 'nav.settings',
    title: '前往：设置',
    category: CommandCategory.navigation,
    keywords: const ['设置', '接口', '模型', '主题', 'settings'],
    invoke: controller.showSettings,
  ));

  // —— 文档 / 文件（仅创作台可用）——
  registry.register(AppCommand(
    id: 'doc.save',
    title: '保存当前文档',
    subtitle: '保存创作台当前打开的文档',
    category: CommandCategory.document,
    keywords: const ['保存', 'save', 'ctrl+s'],
    shortcutLabel: 'Ctrl+S',
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.onSaveCurrentRequested,
  ));
  registry.register(AppCommand(
    id: 'doc.new_file',
    title: '新建文件',
    category: CommandCategory.document,
    keywords: const ['新建', '文件', 'new file'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.onCreateFileRequested,
  ));
  registry.register(AppCommand(
    id: 'doc.new_folder',
    title: '新建文件夹',
    category: CommandCategory.document,
    keywords: const ['新建', '文件夹', '目录', 'new folder'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.onCreateFolderRequested,
  ));

  // —— 视图切换（仅创作台可用）——
  registry.register(AppCommand(
    id: 'view.toggle_session_history',
    title: '切换：会话历史面板',
    category: CommandCategory.view,
    keywords: const ['会话历史', '历史', 'history', '侧栏'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.conversationHandler.onHistoryRequested,
  ));
  registry.register(AppCommand(
    id: 'view.toggle_screen_mode',
    title: '切换：文档 / 对话视图',
    subtitle: '在文档工作区与对话视图之间切换',
    category: CommandCategory.view,
    keywords: const ['文档工作区', '对话', '屏幕模式', 'screen mode'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.conversationHandler.onScreenModeRequested,
  ));

  // —— 运行时操作（仅创作台可用）——
  // 中文注释: 「停止生成」是长任务中最想快速、全局触达的动作，正是命令面板的职责；
  // 即便当前没在生成，保留命令也无副作用（控制器内为空操作）。
  registry.register(AppCommand(
    id: 'ops.stop_generation',
    title: '停止生成',
    subtitle: '中断当前正在进行的写作或工具调用',
    category: CommandCategory.operations,
    keywords: const ['停止', '中断', '取消', '生成', 'stop', 'cancel', 'abort'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.onStopRequested,
  ));
  registry.register(AppCommand(
    id: 'ops.new_session',
    title: '新对话',
    subtitle: '开始一段全新的创作对话',
    category: CommandCategory.operations,
    keywords: const ['新对话', '新会话', '新建对话', '清空对话', 'new session', 'new chat'],
    isEnabled: _onlyOnWorkbench(controller),
    invoke: controller.onNewSessionRequested,
  ));

  // —— 主题 ——
  registry.register(AppCommand(
    id: 'theme.toggle',
    title: '切换主题（亮 / 暗）',
    subtitle: '在云昼与深空之间快速切换',
    category: CommandCategory.theme,
    keywords: const [
      '主题', '深色', '浅色', '亮色', '暗色', 'theme', 'dark', 'light',
    ],
    invoke: controller.onQuickThemeRequested,
  ));

  return registry;
}

/// 仅当当前目的地为创作台时命令可用。
bool Function() _onlyOnWorkbench(AppShellController controller) {
  return () => controller.destinationListenable.value == AppDestination.workbench;
}
