# NovelAgentFlutter 第二阶段 UI / 工作台修补会话顺序文档

最后更新：2026-05-27

## 0.1 Session UI2-01 完成记录

- 已完成 `Session UI2-01：窄屏入口遮挡修复与停靠策略重做`
- 已落地：
  - compact 底部停靠布局基座：
    - `AppShellCompactDockLayout`
  - compact 主视图安全区壳：
    - `AppShellCompactPageFrame`
  - `AppShellCompactScaffold` 已改成：
    - 主视图底部主动预留 launcher 安全区
    - drawer 停靠规则由统一 dock layout 驱动
  - `AppShellCompactDrawer` 已改成：
    - launcher 继续保留快速入口语义
    - panel 与 launcher 的底部停靠高度不再散落硬编码
    - 键盘弹起时不再展开 drawer panel
  - 紧凑模式下的三条规则现在明确为：
    - 收起态：launcher 常驻，但主视图已让出安全区
    - 展开态：panel 从 launcher 上方展开，不再挤压主视图底部
    - 键盘态：launcher 上移避开键盘，panel 直接收口，避免小屏高度炸裂
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/shared/widgets/app_shell_compact_scaffold.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_drawer.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_dock_layout.dart apps/novel_agent_app/lib/shared/widgets/app_shell_compact_page_frame.dart apps/novel_agent_app/test/app_shell_compact_scaffold_test.dart`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/widget_test.dart`
  - 通过
- 新增测试：
  - `compact scaffold reserves bottom space for launcher dock`
  - `compact scaffold hides expanded drawer panel while keyboard is visible`
- 后续扩展点：
  - 当前 launcher 仍是左下停靠，但已经不再遮挡主视图；如果后续想进一步吸收参考图里的窄屏入口形式，优先扩在 compact dock 子组件，不回塞 `AppShellCompactScaffold`
  - 本轮没有改动 drawer 的视觉风格，只修正了停靠与键盘规则；视觉二次吸收继续留给后续会话
  - 下一轮自然接 `Session UX-Storage-01`，单独处理正文目录边界与 `drafts` 旧语义

## 0.2 Session UX-Storage-01 完成记录

- 已完成 `Session UX-Storage-01：正文目录边界清理与 drafts 旧语义拔除`
- 已落地：
  - core 新增统一内容路径策略：
    - `ProjectContentPathPolicyService`
  - core 侧以下入口已改为消费统一路径策略：
    - `DraftFilePathService`
    - `LongTaskChapterOutputPolicyService`
  - adapter 侧工具路径策略已改为复用 core 的内容目录事实源：
    - `ProjectToolPathPolicy`
  - app 侧新增工作区默认目标服务：
    - `WorkspaceCommandDefaultTargetService`
  - `WorkbenchWorkspaceController` 的工作区命令默认目标已改成：
    - 新建文件 -> `chapters`
    - 新建文件夹 -> `assets`
    - 导入默认目标 -> `assets`
  - 相关测试样例与目录基线已同步从旧 `drafts` 示例迁到当前正式目录语义
- 本轮验证结果：
  - `dart analyze packages/novel_agent_core/lib/src/project/project_content_path_policy_service.dart packages/novel_agent_core/lib/src/runtime/draft_file_path_service.dart packages/novel_agent_core/lib/src/workflow/long_task_chapter_output_policy_service.dart packages/novel_agent_adapters/lib/src/tools/project_tool_path_policy.dart apps/novel_agent_app/lib/features/workbench/application/services/workspace_command_default_target_service.dart apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart packages/novel_agent_core/test/project_content_path_policy_service_test.dart apps/novel_agent_app/test/workspace_command_default_target_service_test.dart packages/novel_agent_core/test/draft_generation_use_case_test.dart packages/novel_agent_adapters/test/project_tree_order_service_test.dart apps/novel_agent_app/test/resource_tree_card_test.dart`
  - 通过
  - `dart test test/project_content_path_policy_service_test.dart test/draft_generation_use_case_test.dart`
    in `packages/novel_agent_core`
  - 通过
  - `flutter test test/workspace_command_default_target_service_test.dart test/resource_tree_card_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `dart test test/project_tree_order_service_test.dart`
    in `packages/novel_agent_adapters`
  - 通过
- 新增测试：
  - `packages/novel_agent_core/test/project_content_path_policy_service_test.dart`
  - `apps/novel_agent_app/test/workspace_command_default_target_service_test.dart`
- 本轮结论：
  - 当前生产代码里已没有仍在生效的 `drafts` 默认落盘入口
  - GUI / core / adapters 已共享同一套默认章节与场景目录语义
  - CLI 当前创建文件本来就要求显式 `--path`，因此这轮未改命令行为，但其帮助示例与现行目录口径仍一致
- 后续扩展点：
- 当前仍有部分历史文档保留 `drafts` 兼容期描述，需要在后续文档清理轮继续收束
- 本轮只处理“默认路径语义”，没有做旧项目目录迁移工具
- 下一轮自然进入 `Session UI2-02`，开始会话栏第二轮视觉吸收

## 0.3 Session UI2-02 完成记录

- 已完成 `Session UI2-02：会话栏视觉二次吸收与信息节奏收束`
- 已落地：
  - 会话栏新的局部组装件：
    - `ConversationPanelStyle`
    - `ConversationPanelBand`
    - `ConversationPanelHeader`
    - `ConversationPanelStatusGroup`
    - `ConversationComposerPanel`
  - `ConversationSidebar` 已改成四段式排布：
    - 头部
    - 状态组
    - 主体时间线
    - 组合输入区
  - 顶部头部区已收束为：
    - 标题 + 当前智能体副标题
    - 更紧凑的快捷按钮组
    - 可选的工作台快捷入口行
  - 状态区已统一为同一套窄带样式：
    - `ContextStatusBadge`
    - `ConversationRuntimeStatusStrip`
    - `ToolVisibilityToggle`
  - 底部输入区已收束为同一套组合面板：
    - 文本输入与动作行保持原能力
    - 模型 / 智能体选择条并入同一表面系统
  - 输入动作行已补窄宽度自适应：
    - 宽栏保持单行
    - 窄栏自动切成“工具动作 + 发送按钮”两段式
  - 以下旧组件已切回主题 token / 本地 surface 语言：
    - `ConversationRuntimeStatusStrip`
    - `ContextStatusBadge`
    - `ToolVisibilityToggle`
    - `SelectorField`
  - `ConversationTimeline` 的内边距与表面节奏已同步收束
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_style.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_band.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_header.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_panel_status_group.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_composer_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_toolbar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_dock.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_input_action_row.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_model_strip.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_runtime_status_strip.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/context_status_badge.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/tool_visibility_toggle.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/selector_field.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_timeline.dart apps/novel_agent_app/test/conversation_sidebar_test.dart`
  - 通过
  - `flutter test test/conversation_sidebar_test.dart test/workbench_page_desktop_layout_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test`
    in `apps/novel_agent_app`
  - 通过
- 新增测试：
  - `apps/novel_agent_app/test/conversation_sidebar_test.dart`
    - `conversation sidebar renders grouped header status and composer`
    - `conversation sidebar toggles tool detail summary in place`
- 后续扩展点：
- 当前只做了会话栏内部的第二轮收束，还没有改桌面三栏比例与资源区外观
- `ConversationPanelStyle` 目前只服务会话栏；如果后续资源栏也采用类似窄带状态语言，应先抽象共享 token，再决定是否上移
- 下一轮自然进入 `Session UI2-03`，继续处理桌面三栏比例、表面关系与资源区外观统一

## 0.4 Session UI2-03 完成记录

- 已完成 `Session UI2-03：桌面三栏比例、表面关系与资源区外观统一`
- 已落地：
  - 桌面工作区新增统一局部样式基座：
    - `WorkbenchDesktopStyle`
  - 桌面三栏底板与 pane frame 已收束：
    - `WorkbenchDesktopSurface` 现在提供统一外边距与桌面底板框体
    - `WorkbenchPaneShell` 现在提供更稳定的 pane frame 边界
  - 三栏默认比例已重新校准：
    - `WorkbenchPaneLayoutPolicy`
    - 左栏默认更宽，提升项目树与工具区扫读性
    - 右栏默认略收，给正文区让出更多主阅读宽度
    - 正文区最小宽度门槛同步抬高
  - 资源栏第二轮视觉收束已完成：
    - `ResourceManagerHeader` 改成更明确的项目头部
    - `ResourcePanelSection` 增加强调态
    - `ResourceManagerPanel` 的分区留白、树区高度和节奏统一
    - `ResourceTreeCard` 的树区内框与底色层级统一
  - 正文栏顶部结构已重组：
    - 新增 `DocumentWorkspaceHeaderPanel`
    - `DocumentWorkspacePanel` 改成“头部组合面板 + 正文画布”两段式
    - `DocumentToolbarBar` 改成更接近参考图的信息节奏与工具密度
- 本轮验证结果：
  - `dart analyze apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart apps/novel_agent_app/lib/features/workbench/presentation/layout/workbench_pane_layout_policy.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_desktop_style.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_desktop_surface.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/workbench_pane_shell.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_header.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_panel_section.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_tree_card.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_header_panel.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_toolbar_bar.dart apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_panel.dart apps/novel_agent_app/test/workbench_page_desktop_layout_test.dart`
  - 通过
  - `flutter test test/workbench_page_desktop_layout_test.dart test/resource_manager_panel_test.dart test/document_workspace_panel_test.dart test/widget_test.dart`
    in `apps/novel_agent_app`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test`
    in `apps/novel_agent_app`
  - 通过
- 更新测试：
  - `apps/novel_agent_app/test/workbench_page_desktop_layout_test.dart`
    - 新增 `desktop pane layout policy keeps document pane dominant by default`
- 后续扩展点：
- 本轮只重组了桌面三栏的外层比例与表面层次，没有进入更深的资源渲染器与中栏内容类型扩展
- `WorkbenchDesktopStyle` 当前只服务桌面工作区；如果后续 project assets / review center 也要吃同一套桌面语言，应先判断是否上移到共享 desktop surface token
- 下一轮自然进入后续文档中的下一会话，不需要回头返工这一轮的结构边界

## 0.5 Session UI2-04 完成记录

- 已完成 `Session UI2-04：工作台专项联调、截图比对与 Windows 打包前修整`
- 本轮联调回归覆盖：
  - 窄屏入口遮挡
  - 默认正文路径 / 章节输出路径
  - 桌面三栏默认比例与桌面表面关系
  - 会话栏结构、输入坞、模型条
- 本轮没有新增 UI 主线，只做联调确认与打包前闭环
- 本轮验证结果：
  - `dart test test/project_content_path_policy_service_test.dart test/draft_generation_use_case_test.dart test/long_task_chapter_output_policy_service_test.dart`
    in `packages/novel_agent_core`
  - 通过
  - `dart test test/project_tool_dispatcher_path_test.dart test/project_tree_order_service_test.dart`
    in `packages/novel_agent_adapters`
  - 通过
  - `dart analyze apps/novel_agent_app/lib apps/novel_agent_app/test`
  - 通过
  - `flutter test`
    in `apps/novel_agent_app`
  - 通过
  - `flutter build windows --release`
    in `apps/novel_agent_app`
  - 通过
- Windows 打包产物：
  - 可执行文件：
    - `apps/novel_agent_app/build/windows/x64/runner/Release/novel_agent_app.exe`
  - 归档包：
    - `dist/novel_agent_app-windows-release-2026-05-27-ui2-04.zip`
- 本轮说明：
  - 本轮没有额外新做截图对比脚本；当前以 widget 回归、路径回归和 Windows release 构建通过作为第二阶段闭环依据
  - `ui-second-wave-session-order.md` 中 `UI2-01 ~ UI2-04` 至此全部完成
  - 如果后续继续推进，不应回头重开本文件中的旧 session，而应新开下一阶段 UI / 产品化顺序文档

## 0. 本轮为什么先写文档

当前新增需求不是单点改动，而是三条主线同时存在：

1. 窄屏模式下的工作台入口遮挡主视图
2. 仍有部分“正文 / 章节”内容沿旧语义写入不合适的位置
3. 需要继续吸收 `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
   的设计理念，统一会话栏、比例、配色、特征展示方式

这三件事不能直接混成一轮硬改，原因很明确：

- 第一条属于 `compact shell` 与 `launcher` 的布局问题
- 第二条属于 `core/adapters/app` 跨层的内容归档语义问题
- 第三条属于 `workbench UI information architecture` 的第二轮视觉与组件收束

如果现在直接一把改，很容易把以下问题重新做出来：

- 再次把 `workbench_page.dart` 或 `conversation_sidebar.dart` 塞胖
- 一边改 UI，一边偷偷改章节落盘语义，导致回归难排查
- 桌面三栏变好看了，但窄屏、资源树、输入坞风格又重新分裂

因此这轮最合适的动作不是“立即改全部”，而是：

- 先把下一阶段任务拆成可落地会话
- 先修功能与结构边界，再做统一视觉吸收

---

## 1. 当前确认存在的问题

### 1.1 窄屏模式遮挡

当前 `AppShellCompactDrawer` 采用左下角常驻 launcher，确实会遮挡主视图区一部分内容。

相关文件：

- `apps/novel_agent_app/lib/shared/widgets/app_shell_compact_scaffold.dart`
- `apps/novel_agent_app/lib/shared/widgets/app_shell_compact_drawer.dart`

当前问题本质：

- launcher 是悬浮覆盖，而不是“避让式停靠”
- 主视图底部没有为 launcher 预留安全区
- 抽拉入口和当前页主操作之间没有建立布局协商

### 1.2 正文内容位置边界仍有旧残留

已经能确认的一处明显残留：

- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
  中 `onCreateFileRequested()` 仍默认使用 `relativePath: 'drafts'`

这说明虽然“草稿文件夹应被移除”的方向已经明确，但工程里仍有旧语义残留。

这类问题不能只做字符串替换，因为它实际涉及：

- 用户手动创建内容默认应该去哪里
- 章节正文、样章、分析中间产物、资产文件是否共用同一目录口径
- GUI / CLI / core / adapters 是否使用同一套路径语义

### 1.3 参考图二次吸收已经进入“整体收束”阶段

你这次明确认可的是：

- `references/assets/ai_images_052601/主工作台：桌面三栏模式.png`
  的整体观感
- 尤其是：
  - 会话栏 UI 元素排布
  - 配色层级
  - 三栏比例关系
  - 特征显示形式
  - 右栏整体信息密度与节奏

这已经不是继续修某个单独 widget，而是要做：

- `workbench` 第二轮视觉基准收束
- 会话栏子组件二次排版
- 桌面与窄屏的同风格协同

---

## 2. 第二阶段总原则

### 2.1 先修边界，再做大面积视觉吸收

顺序必须是：

1. 窄屏遮挡与正文目录边界
2. 会话栏结构与视觉二次收束
3. 三栏比例与资源区外观统一
4. 联调和打包

不能先做纯美术化调整，否则后面修存储与窄屏入口时会反复返工。

### 2.2 选择性吸收，不做像素级照抄

参考图只吸收：

- 信息层级
- 元素比例
- 色彩节奏
- 表面关系
- 交互暗示方式

不照搬：

- 具体像素位置
- 具体图标组合
- 任何会让现有信息架构倒退的展示方式

### 2.3 新增改动继续遵守解耦规则

本轮仍必须遵守：

- 单一职责
- 不让单文件继续变重
- 优先拆子组件 / 视图数据 / 小型布局策略
- 纯 UI 问题不把状态强塞回大控制器
- 正文目录边界优先改到 core / adapters 合同，而不是只在 UI 层改文案

### 2.4 参考图吸收必须覆盖深浅主题

虽然你现在更喜欢桌面三栏图里的明亮基调，但本轮设计必须继续兼容：

- 明亮主题
- 偏暗主题

不能做成“只有一套浅色主题看得好，深色就散”。

---

## 3. 任务总量判断

结论：**这是大任务，不适合直接在这一轮一口气实现。**

理由：

- 至少涉及 `shared shell + workbench + conversation sidebar + storage semantics`
- 其中“正文目录边界”不是纯前端问题
- 视觉吸收如果直接开改，改动量会穿过多个已完成 session 的边界

因此这轮只输出下一阶段顺序文档是合理的，而且是更稳的做法。

---

## 4. 第二阶段会话顺序

## 4.1 Session UI2-01：窄屏入口遮挡修复与停靠策略重做

### 本轮目标

把窄屏模式的工作台入口从“遮挡式悬浮”改成“可见但不压主内容”的正式停靠策略。

### 预计改动量

- 约 `700 ~ 1400` 行

### 重点触达层

- `shared/widgets/app_shell_compact_scaffold.dart`
- `shared/widgets/app_shell_compact_drawer.dart`
- 可能新增 compact dock / inset 相关小组件

### 必做项

1. 修掉左下 launcher 挡住正文 / 会话的现状
2. 为 compact 主视图建立底部安全让位
3. 明确入口在：
   - 收起态
   - 展开态
   - 键盘弹起态
   下的停靠规则
4. 不让抽拉栏展开后再把主内容底部裁碎
5. 保持“入口不消失、可快速展开”的原目标

### 本轮不要做

- 不做会话栏整体美术重排
- 不改桌面三栏比例
- 不顺手修改正文落盘逻辑

### 解耦重点

- `compact launcher dock`
- `compact safe inset policy`
- `compact drawer surface`

### 完成判定

- 窄屏底部入口不再挡住主要阅读区域
- 抽拉栏开关与输入法弹出都不会压坏主视图
- 不需要把逻辑回塞 `AppShell`

### 执行提示词

按 `docs/ui-second-wave-session-order.md` 的 `Session UI2-01` 执行。先阅读 `agent.md`、`docs/ui-implementation-session-order.md`、`apps/novel_agent_app/lib/shared/widgets/app_shell_compact_scaffold.dart`、`apps/novel_agent_app/lib/shared/widgets/app_shell_compact_drawer.dart`。只处理窄屏模式下工作台入口遮挡问题：把左下常驻 launcher 改成不压主内容的正式停靠方案，并为 compact 主视图建立底部安全让位。不要顺手改桌面三栏，不要改正文落盘语义。

---

## 4.2 Session UX-Storage-01：正文目录边界清理与 drafts 旧语义拔除

### 本轮目标

把“正文 / 章节 / 样章 / 中间产物 / 资产文件”的默认归档边界重新收束，彻底清掉 UI 层和业务层残留的 `drafts` 旧语义。

### 预计改动量

- 约 `900 ~ 1800` 行

### 重点触达层

- `packages/novel_agent_core`
- `packages/novel_agent_adapters`
- `apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`
- 相关测试

### 必做项

1. 盘点当前仍残留的 `drafts` 默认入口和旧文案
2. 明确以下内容的正式目录策略：
   - 正文章节
   - 样章
   - 长任务阶段产物
   - 分析 / 修订中间产物
   - 导入文件与资产文件
3. GUI 新建文件默认目录不再指向 `drafts`
4. GUI / CLI / core / adapters 使用同一套路径语义
5. 为这一轮补充回归测试

### 本轮不要做

- 不做目录迁移工具
- 不改 SQLite 存储建模
- 不顺手改大面积 UI 配色

### 解耦重点

- `content path policy`
- `chapter output policy`
- `workspace default create target policy`

### 完成判定

- UI 层默认新建文件不再落到 `drafts`
- 章节正文与相关产物目录边界清楚
- 测试能证明不是只改了表面文案

### 执行提示词

按 `docs/ui-second-wave-session-order.md` 的 `Session UX-Storage-01` 执行。先阅读 `agent.md`、`docs/storage-dual-compatibility-design.md`、`packages/novel_agent_core/test/draft_generation_use_case_test.dart`、`packages/novel_agent_core/test/long_task_chapter_output_policy_service_test.dart`、`apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart`。只处理正文目录边界与 drafts 旧语义清理：统一 GUI / CLI / core / adapters 的默认章节与中间产物路径口径，并把 UI 默认新建文件目标从 drafts 迁走。不要做目录迁移工具，不要做大面积前端美化。

---

## 4.3 Session UI2-02：会话栏视觉二次吸收与信息节奏收束

### 本轮目标

针对右侧会话栏，吸收参考图的整体设计理念，把工具条、状态条、消息时间线、输入坞、模型条做成更统一、更好看的正式版本。

### 预计改动量

- 约 `1000 ~ 1900` 行

### 重点触达层

- `features/workbench/presentation/widgets/conversation_sidebar.dart`
- `conversation_toolbar.dart`
- `conversation_runtime_status_strip.dart`
- `conversation_timeline.dart`
- `conversation_input_dock.dart`
- `conversation_model_strip.dart`
- 相关子组件

### 必做项

1. 吸收参考图的右栏信息节奏：
   - 顶部工具区
   - 资源 / 状态提示条
   - 工具细节显示控制
   - 主体内容区
   - 输入坞
   - 模型与智能体条
2. 统一右栏配色层级与留白比例
3. 收束按钮密度与按钮风格
4. 让“工具细节开关 / 状态条 / 输入坞 / 模型条”看起来属于同一套系统
5. 保留已有功能，不降低可用性

### 本轮不要做

- 不修改会话业务状态机
- 不扩新工具链
- 不改桌面三栏整体比例

### 解耦重点

- `conversation panel sections`
- `conversation panel header/status/input shell`
- `conversation local surface tokens`

### 完成判定

- 右栏整体视觉接近参考图的成熟度
- 功能还在，但不再是零散堆叠
- 没有把所有布局塞回 `conversation_sidebar.dart`

### 执行提示词

按 `docs/ui-second-wave-session-order.md` 的 `Session UI2-02` 执行。先阅读 `agent.md`、`docs/ui-absorption-analysis-2026-05-26.md`、`references/assets/ai_images_052601/主工作台：桌面三栏模式.png`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/conversation_sidebar.dart`。只做会话栏的第二轮视觉吸收：收束顶部工具区、状态条、消息时间线、输入坞、模型条的排布、比例和配色，不改业务状态机，不扩新功能链。注意拆子组件，不要把布局继续塞胖到 conversation_sidebar。

---

## 4.4 Session UI2-03：桌面三栏比例、表面关系与资源区外观统一

### 本轮目标

继续吸收桌面三栏参考图，把左栏 / 中栏 / 右栏的比例关系、表面层次、标签条与资源区块做第二轮统一。

### 预计改动量

- 约 `900 ~ 1700` 行

### 重点触达层

- `features/workbench/presentation/pages/workbench_page.dart`
- `workbench_desktop_surface.dart`
- `workbench_pane_shell.dart`
- `resource_manager_panel.dart`
- `document_workspace_panel.dart`
- `document_toolbar_bar.dart`

### 必做项

1. 调整三栏比例与面板内边距，接近参考图的平衡感
2. 统一左栏资源区块、目录树、运行摘要区块的表面风格
3. 统一中栏标签、工具条、显示模式条的层级关系
4. 让三栏在明亮主题下呈现更稳定的背景基调
5. 保证深色主题不被破坏

### 本轮不要做

- 不改 compact 模式
- 不重做资源渲染器合同
- 不处理正文目录边界

### 解耦重点

- `desktop pane proportion policy`
- `resource/document interior surface spec`
- `toolbar/tab strip styling`

### 完成判定

- 桌面三栏整体气质明显更接近参考图
- 左中右三栏不是各自一套表面语言
- 深浅主题都成立

### 执行提示词

按 `docs/ui-second-wave-session-order.md` 的 `Session UI2-03` 执行。先阅读 `agent.md`、`references/assets/ai_images_052601/主工作台：桌面三栏模式.png`、`apps/novel_agent_app/lib/features/workbench/presentation/pages/workbench_page.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/resource_manager_panel.dart`、`apps/novel_agent_app/lib/features/workbench/presentation/widgets/document_workspace_panel.dart`。只处理桌面三栏的比例、表面关系、资源区和中栏外观统一，不改 compact，不碰正文路径语义，不重做资源渲染合同。

---

## 4.5 Session UI2-04：工作台专项联调、截图比对与 Windows 打包前修整

### 本轮目标

对第二阶段改动做一次专项联调，确认窄屏、三栏、会话栏、正文目录边界四条线都闭环，再进入 Windows 打包。

### 预计改动量

- 约 `500 ~ 1200` 行

### 重点触达层

- 回归测试
- widget test
- 可能少量局部修补

### 必做项

1. 回归窄屏入口不遮挡
2. 回归默认新建文件 / 章节输出路径
3. 回归桌面三栏布局
4. 回归会话栏顶部工具区、输入坞、模型条
5. 必要时做截图比对或人工截图核验
6. 回填文档与打包结果

### 本轮不要做

- 不开新视觉主线
- 不扩新功能

### 解耦重点

- 只修联调暴露问题
- 不允许为了收尾再造新中心文件

### 完成判定

- 第二阶段目标闭环
- 可稳定进入 Windows 打包

### 执行提示词

按 `docs/ui-second-wave-session-order.md` 的 `Session UI2-04` 执行。先阅读本文件前面几个 session、`docs/ui-implementation-session-order.md`、`docs/ui-absorption-analysis-2026-05-26.md`。只做第二阶段联调回归：窄屏入口遮挡、默认正文路径、桌面三栏外观、会话栏结构与输入区统一。不要扩新功能，不要再造新的大中心文件。完成后回填文档并打包 Windows 版。

---

## 5. 推荐执行顺序说明

严格按以下顺序推进：

1. `Session UI2-01`
2. `Session UX-Storage-01`
3. `Session UI2-02`
4. `Session UI2-03`
5. `Session UI2-04`

原因：

- `UI2-01` 先清掉最直观的遮挡问题
- `UX-Storage-01` 先把正文边界修正，避免后面一边美化一边发现内容还写错地方
- `UI2-02` 与 `UI2-03` 再去做参考图吸收，才不会返工
- `UI2-04` 负责收尾和打包前验证

---

## 6. 与既有文档的关系

本文件是对以下文档的后续补充，而不是替代：

- `docs/ui-implementation-session-order.md`
- `docs/ui-absorption-analysis-2026-05-26.md`

当前理解是：

- `ui-implementation-session-order` 已经完成第一阶段主链闭环
- 本文件负责第二阶段：
  - 窄屏遮挡修补
  - 正文目录语义清理
  - 桌面三栏与会话栏二次吸收

后续如果第二阶段完成，再视情况决定是否需要第三阶段文档。
