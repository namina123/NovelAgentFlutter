# NovelAgentFlutter 界面精简与 CLI 对齐实施顺序文档

最后更新：2026-05-28

关联文档：

- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

---

## 0.1 Session US-01 完成记录

- 已完成 `Session US-01：全局导航收束与 AppDestination 减负`
- 当前全局目的地已正式收束为：
  - `projectOpen`
  - `workbench`
  - `longTaskStation`
  - `settings`
- 当前全局导航已正式只保留 4 项：
  - `打开项目`
  - `工作台`
  - `长任务`
  - `设置`
- 本轮已完成的关键实现：
  - `AppDestination` 已移除这些顶层目的地：
    - `bookDeconstruction`
    - `inspirationWorkbench`
    - `agentEcosystem`
    - `projectCollection`
    - `taskCenter`
    - `reviewCenter`
    - `promptTemplates`
    - `projectAssets`
  - `AppShellNavigationCatalog` 已不再暴露上述入口
  - `AppRouter` 已只对 4 个正式目的地建页
  - `projectOpen` 当前先复用旧的 `ProjectCollectionPage` 承载
    - 这是过渡实现
    - 真正的“打开项目入口页”内容升级留到 `US-02`
  - `AppShellDestinationController` 已收束成：
    - 4 个正式目的地
    - 若旧入口仍被局部按钮触发，则临时重定向到最近的正式空间
  - 与旧顶层目的地强绑定的壳层切页分支已清理
- 本轮刻意未做：
  - 未重做 `打开项目` 页内容
  - 未删除旧 feature 文件
  - 未合并任务 / 审稿 / 生态 / 模板 / 资产等实际内容
- 本轮顺手修复的验证装配问题：
  - `apps/novel_agent_app/test/widget_test.dart`
  - 该测试的 `AppShellController` 构造参数长期落后于当前装配
  - 本轮已补齐：
    - skill loadout 相关仓储接线
    - expression constraint workspace service 接线
    - 缺失 import
  - 这是测试装配漂移修复，不改变 `US-01` 的产品边界
- 当前过渡策略已经固定：
  - 这轮先取消旧页面的“可达主语义”
  - 后续 session 再分别吸收内容与清理遗留实现
  - 不在这一轮混入大规模物理删除
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart test/widget_test.dart`
    - in `apps/novel_agent_app`
    - 通过
  - `dart analyze`
    - 目标：
      - `apps/novel_agent_app/lib/app/routing/app_destination.dart`
      - `apps/novel_agent_app/lib/app/navigation/app_shell_navigation_catalog.dart`
      - `apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart`
      - `apps/novel_agent_app/lib/app/routing/app_router.dart`
      - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`
      - `apps/novel_agent_app/test/app_shell_compact_scaffold_test.dart`
    - 通过
  - `flutter test test/app_shell_compact_scaffold_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - `Session US-02` 继续把 `projectOpen` 从“旧集合页换名”升级成真正的项目入口页
  - `Session US-03` 再处理灵感开局入口收束，不要回头把 opening 逻辑混进这轮导航改造
  - `Session US-06` 之前，旧的任务 / 审稿按钮虽然已不再对应独立顶层目的地，但局部重定向仍会保留，避免中途把链路做断

---

## 0.2 Session US-02 完成记录

- 已完成 `Session US-02：打开项目 成为唯一项目入口页`
- 当前 `projectOpen` 已不再复用旧 `ProjectCollectionPage`
- 当前“打开项目”页已成为独立 feature：
  - `project_open/presentation/models/project_open_view_data.dart`
  - `project_open/presentation/contracts/project_open_action_handler.dart`
  - `project_open/application/services/project_open_view_data_service.dart`
  - `project_open/presentation/pages/project_open_page.dart`
- 本轮已完成的关键实现：
  - `AppRouter` 已将 `AppDestination.projectOpen` 正式切到 `ProjectOpenPage`
  - `AppShellViewModel` / `AppShellListenableState` 已补齐 `projectOpen` 读态
  - `AppShellController` 已正式实现 `ProjectOpenActionHandler`
  - `AppShellDestinationController` 的 `refreshProjectOpen` 已改为刷新新的项目入口页
  - `ProjectOpenViewDataService` 已承担：
    - 默认项目目录扫描
    - 最近项目吸收
    - 当前项目优先
    - 去重与来源徽标合并
    - 选中项决议
  - `打开项目` 页现在已具备：
    - 默认目录下可打开项目列表
    - 最近项目来源标记
    - 当前项目标记
    - `刷新`
    - `导入本地项目`
    - `新建项目`
    - 右侧项目详情面板
  - `导入本地项目` 已改为文件夹选择器流
  - 导入前已增加最小有效性预检：
    - 所选目录不是有效项目根目录时会在入口页直接反馈
  - 从入口页直接打开项目后，会正式切回 `工作台`
- 本轮刻意未做：
  - 未删除旧 `project_collection` feature 文件
  - 未开始处理灵感、拆书、长任务总站收口
  - 未把旧集合类页面的底层实现一并物理清理
- 本轮新增验证：
  - `apps/novel_agent_app/test/project_open_view_data_service_test.dart`
    - 覆盖项目发现去重、当前项目优先、最近项目徽标合并
    - 覆盖入口页选中态切换
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/project_open_view_data_service_test.dart test/app_shell_compact_scaffold_test.dart test/widget_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - `Session US-03` 继续处理灵感入口退役与 opening 流程收束
  - 后续轮次再决定何时物理清理旧 `project_collection` feature

---

## 0.3 Session US-03 完成记录

- 已完成 `Session US-03：移除灵感全局页语义并收束开局入口`
- 本轮没有物理删除 `inspiration_workbench` feature 文件
  - 但它已经不再作为工作台内可见正式入口继续存在
  - 当前工作台资源栏里的 `灵感工作台` 快捷入口已移除
- 本轮新增了稳定的项目成熟度判定口：
  - `project_opening_maturity_stage.dart`
  - `project_opening_maturity_assessment.dart`
  - `project_opening_maturity_assessment_service.dart`
- 当前开局判定已正式分成三类：
  - `fresh`
  - `openingInProgress`
  - `continueReady`
- 判定策略已收口为：
  - 若项目还没有真实创作基础，则继续视为开局阶段
  - 若已经存在正文 / 场景 / 大纲等基础文件，或已有明显项目基础，则视为可直接继续创作
  - 不再把“已有基础项目”错误拉回开局按钮树
- 本轮新增了开局动作裁剪策略：
  - `opening_starter_action_policy_service.dart`
- 当前会话空态和引导动作已按成熟度分流：
  - 未开局或开局中项目：
    - 只保留轻量开局入口
    - 不再展示过重的固定按钮树
  - 已有基础项目：
    - 普通小说项目不再优先显示 `智能开局`
    - 长篇项目不再默认显示 `长任务开局 / 直接生成队列`
    - 改为优先显示继续推进当前项目的动作
- `ConversationGuideViewDataService` 已不再直接把 opening 文案硬塞给所有项目
  - 现在先消费成熟度评估
  - 再通过 `ConversationOpeningGuideViewDataService` 做：
    - 开局中项目的引导
    - 已有基础项目的 grounded guide 装饰
- `ConversationOpeningPanelViewDataService` 已调整为：
  - 只有在项目仍应显示开局入口时才渲染 opening panel
  - 对已有基础项目直接隐藏 opening panel
- 本轮顺手完成的界面收口：
  - `ResourceUtilityStrip` 已移除 `灵感工作台` 按钮
  - `ResourceManagerActionHandler` 已不再要求该快捷入口合同
- 本轮刻意未做：
  - 未重构 `task_center` 里的长任务开局表单
  - 未开始 `US-04` 的导入 / 自动拆书动作统一
  - 未物理删除 `inspiration_workbench` 页面与控制器实现
- 本轮新增验证：
  - `test/project_opening_maturity_assessment_service_test.dart`
  - `test/conversation_guide_view_data_service_test.dart`
  - `test/conversation_opening_panel_view_data_service_test.dart`
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/conversation_guide_view_data_service_test.dart test/conversation_opening_panel_view_data_service_test.dart test/project_opening_maturity_assessment_service_test.dart test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
- `Session US-04` 再统一导入文件 / 自动拆书 / 拆书项目动作语义
  - 后续轮次再决定何时物理清理旧 `inspiration_workbench` feature

---

## 0.4 Session US-04 完成记录

- 已完成 `Session US-04：统一 导入文件 / 自动拆书 / 拆书项目 动作语义`
- 当前导入文件已经成为唯一正式宿主入口：
  - 工作台文件区继续保留明确 `导入文件` 按钮
  - 不再要求用户手填绝对路径
  - 改为文件选择器 + 导入目标目录 + 自动拆书选项
- 本轮已完成的关键实现：
  - 新增导入动作 contract / policy / execution 分层：
    - `project_import_request.dart`
    - `project_import_action_policy.dart`
    - `project_import_execution_result.dart`
    - `project_import_action_policy_service.dart`
    - `project_import_execution_service.dart`
    - `project_import_workspace_command_view_data_service.dart`
  - 工作台导入弹层已正式改为：
    - `选择文件`
    - 已选文件只读列表
    - 导入目标目录
    - `自动拆书` 勾选项
    - 输出位置与格式支持提示
  - `WorkbenchWorkspaceController` 已不再直接解析“手填绝对路径”表单
    - 文件选择交给 `DesktopProjectImportFilePickerService`
    - 策略判断交给 `ProjectImportActionPolicyService`
    - 导入与自动拆书预演执行交给 `ProjectImportExecutionService`
  - 自动拆书当前正式收束为：
    - 仅支持单个 `.txt / .md / .markdown` 文件
    - `book_deconstruction` 项目默认落到 `chapters/`
    - 普通项目导入默认仍落到正式导入目录
    - 自动拆书预演纪要写回：
      - 拆书项目：`chapters/book_deconstruction_<slug>.md`
      - 普通项目：`analysis/deconstruction/book_deconstruction_<slug>.md`
  - 拆书引导语义已收束：
    - `SessionGuideProfileService` 不再主推“打开拆书向导”
    - 改为 `导入文件`
    - `WorkbenchConversationController` 对旧 command id 保持兼容，但已映射到工作台导入动作
- 本轮刻意未做：
  - 未物理删除旧 `book_deconstruction` feature 页面与控制器
  - 未开始 `US-05` 的左栏对象收束
  - 未扩展真实“拆书应用链”，当前仍先落预演纪要
- 本轮新增验证：
  - `test/project_import_action_policy_service_test.dart`
    - 覆盖拆书项目默认目标目录与自动拆书启用规则
    - 覆盖普通项目默认导入策略
    - 覆盖多文件场景下自动拆书禁用
  - `test/project_import_execution_service_test.dart`
    - 覆盖普通导入
    - 覆盖导入后自动拆书预演纪要写回
  - `test/workspace_command_overlay_test.dart`
    - 覆盖导入弹层的文件选择请求回传
    - 覆盖导入弹层对控制器回写数据的同步
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/project_import_action_policy_service_test.dart test/project_import_execution_service_test.dart test/workspace_command_overlay_test.dart test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
    - in `apps/novel_agent_app`
    - 通过
  - `dart analyze lib test`
    - in `packages/novel_agent_core`
    - 通过
- 后续扩展点：
  - `Session US-05` 再处理工作台左栏收束为 `文件 / 项目 / 长任务`
- 若后续要物理退役旧拆书页，应在确认没有残余导航和兼容调用后单独做一轮清理

---

## 0.5 Session US-05 完成记录

- 已完成 `Session US-05：工作台左栏收束为 文件 / 项目 / 长任务`
- 当前工作台左栏已经正式收束为三类对象：
  - `文件`
  - `项目`
  - `长任务`
- 本轮已完成的关键实现：
  - `WorkbenchNavigationPanelId` 已从：
    - `files`
    - `workspace`
    - `prompts`
    - `context`
    收束为：
    - `files`
    - `project`
    - `longTask`
  - `WorkbenchActivityRail` 已正式只保留三个局部 panel：
    - `文件`
    - `项目`
    - `长任务`
  - `WorkbenchSidePanelHost` 已不再挂旧的：
    - `工作区概览`
    - `策略与协作`
    - `上下文选择`
  - 新增：
    - `workbench_project_panel.dart`
    - `workbench_long_task_panel.dart`
    - `project_panel_action_tile.dart`
  - `文件` panel 已正式减负：
    - `ResourceManagerPanel` 不再显示 `项目与文件`
    - 改为只保留：
      - 文件动作
      - 资源树
    - 已移除：
      - 当前项目长任务摘要
      - `工作区入口`
      - `打开某中心` 式快捷跳板
  - `项目` panel 已正式吸收项目级入口：
    - 项目动作：
      - 新建项目
      - 打开项目
      - 项目信息
      - 刷新项目
    - 当前协作基线：
      - 工作流
      - 模型
      - 智能体
    - 项目资料与规则：
      - `项目资产与表达限制`
      - `提示模板`
      - `智能体生态`
  - `长任务` panel 已正式收束为：
    - 当前项目长任务摘要
    - `打开总站`
    - 不再在左栏复制第二套任务中心语义
  - 旧的局部导航实现文件已退役：
    - `workbench_navigation_panels.dart`
    - `resource_utility_strip.dart`
- 本轮刻意未做：
  - 未把 `项目资产 / 提示模板 / 智能体生态` 物理嵌入工作台左栏正文
    - 当前仍通过 `项目` panel 作为唯一局部入口打开各自既有页面
  - 未开始 `US-06` 的 `任务中心 / 审稿中心` 并入 `长任务总站`
  - 未重做中栏主画布 renderer
- 本轮新增验证：
  - `test/workbench_project_panel_test.dart`
    - 覆盖 `项目` panel 对项目级入口的收束与动作回传
  - `test/workbench_navigation_sidebar_test.dart`
    - 覆盖左栏 panel 已切换为 `文件 / 项目 / 长任务`
  - `test/resource_manager_panel_test.dart`
    - 覆盖 `文件` panel 已移除 `工作区入口` 与长任务摘要
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_project_panel_test.dart test/workbench_canvas_workspace_shell_test.dart test/workbench_compact_workspace_shell_test.dart test/workbench_page_desktop_layout_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - `Session US-06` 再处理 `任务中心 / 审稿中心` 并入 `长任务总站`
  - 后续若确认 `项目资产 / 提示模板 / 智能体生态` 需要进一步嵌入工作台，应在不引入新二次导航的前提下单独收口

---

## 0.6 Session US-06 完成记录

- 已完成 `Session US-06：任务中心 / 审稿中心 并入 长任务总站`
- 当前用户继续长任务时，正式只需要认：
  - `长任务总站`
  - 工作台内“当前项目长任务摘要 + 打开总站”
- 本轮已完成的关键实现：
  - `long_task_station` 已正式补齐 `station-native projection`
    - 总站详情区继续承接：
      - 任务节点
      - 检查点
      - 审稿结果
      - 返工任务
    - 这些对象不再以“去任务中心 / 去审稿中心”的形式跳去旧中心页
    - 统一改为：
      - 在总站里查看运行关联项
      - 必要时直接回到工作台打开对应文件
  - 总站新增了轻量 `当前项目过滤视图`
    - 当存在当前打开项目时，可切换为：
      - `仅看当前项目`
    - 过滤后的：
      - 运行列表
      - 汇总计数
      - 详情选中态
      都由总站自身控制器与 view-data 投影统一维护
  - 总站内遗留文案与动作已清理：
    - `任务中心`
    - `审稿中心`
    - `去任务中心`
    - `去审稿中心`
    已从总站正式 UI 文案中移除
  - `LongTaskStationController` 导航接线已收口为：
    - `打开项目`
    - `打开关联资源`
    - `读取当前项目作用域`
    - 不再把旧任务页 / 审稿页导航硬塞进总站控制器
  - 工作台内相关入口已进一步降级：
    - `审稿分析` 面板里的按钮已从 `打开审稿中心` 改为 `打开总站`
    - `onTasksRequested` / `onReviewsRequested` 都统一折返到 `长任务总站`
  - 灵感工作台启动长任务后的状态提示已同步改为：
    - `已自动切到长任务总站`
- 本轮刻意未做：
  - 未物理删除 `task_center` / `review_center` feature 文件
  - 未重做旧任务 / 审稿控制链内部状态
  - 未开始 `US-07` 的会话区伪动作清理
- 本轮新增验证：
  - `test/long_task_station_view_data_service_test.dart`
    - 覆盖总站对当前项目过滤视图的投影
    - 覆盖总站范围标签与运行计数收口
  - `test/inspiration_workbench_controller_test.dart`
    - 同步覆盖长任务启动后切到总站的新状态文案
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/long_task_station_view_data_service_test.dart test/inspiration_workbench_controller_test.dart test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart test/workbench_canvas_workspace_shell_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - `Session US-07` 再处理会话区空态入口、输入区伪动作和设置泛滥
  - 若后续确认旧 `task_center / review_center` 已无残余读态价值，再单独安排物理清理轮次

---

## 0.7 Session US-07 完成记录

- 已完成 `Session US-07：清理会话区伪动作、设置泛滥和二次导航`
- 当前会话区已进一步收束为“当前协作空间”：
  - 不再把系统设置、快速主题、屏幕模式这类动作继续塞在会话头部
  - 不再让空态像一个功能入口菜单页
  - 不再让输入区显示看起来能用、实际上只是预留的动作按钮
- 本轮已完成的关键实现：
  - 会话顶部动作已精简：
    - `ConversationToolbar` 已移除：
      - `快速主题`
      - `屏幕模式`
    - 当前优先保留：
      - `会话历史`
      - `新会话`
    - 窄屏补充入口 `ConversationSecondaryActionsRow` 已只保留：
      - `文档`
  - 会话空态已移除局部设置入口：
    - `ConversationEmptyStatePanel`
    - `WorkflowGuideCard`
    不再显示 `工作台设置`
  - 新增 `conversation_empty_state_action_projection_service.dart`
    - 会话空态动作不再直接照搬完整 `primaryActions`
    - 当前投影规则已收口为：
      - 未打开项目时，不显示菜单化入口
      - 普通协作流里，只保留“最自然的下一步”
      - 明确处于开局/模式引导流时，才保留完整引导动作
  - 输入区伪动作已收口：
    - `优化`
    - `工具`
    - `附件`
    - `停止`
    当前都不再作为伪可用动作显示
  - `ConversationInputCapabilityService` 已改为只暴露真实能力：
    - 生成中时不再显示伪 `停止`
    - 发送按钮会进入 `生成中` 等待态
    - 未接通的附件/工具设置入口不再冒充当前协作动作
  - 会话区底部主动作列表已支持空投影：
    - 没有当前协作动作时不再硬渲染一组空壳按钮
- 本轮刻意未做：
  - 未接通真实中断生成链路
  - 未接通真实桌面附件传输链路
  - 未重做主题系统或会话视觉结构
  - 未开始 `US-08` 的最终占位文案清理与辅助工作层降级
- 本轮新增验证：
  - `test/conversation_empty_state_action_projection_service_test.dart`
    - 覆盖未打开项目时隐藏菜单化入口
    - 覆盖普通协作流只保留单一自然下一步
    - 覆盖开局/引导流保留完整动作
  - `test/conversation_sidebar_test.dart`
    - 覆盖空态不再显示 `工作台设置 / 快速主题 / 屏幕模式`
    - 覆盖生成中输入区不再显示 `优化 / 工具 / 附件 / 停止`
  - `test/conversation_input_capability_service_test.dart`
    - 覆盖输入区只暴露真实已接通动作
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/conversation_sidebar_test.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_input_capability_service_test.dart test/conversation_input_dock_test.dart test/workbench_canvas_workspace_shell_test.dart test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - `Session US-08` 再处理占位文案清理、辅助工作层降级与最终易用性回归
  - 若后续真实接通“停止生成”或“桌面附件”，应回到 `ConversationInputCapabilityService` 重新显式开启，而不是先把按钮摆出来

---

## 0.8 Session US-08 完成记录

- 已完成 `Session US-08：清理占位文案、降级辅助工作层并做最终易用性回归`
- 当前这条 `ui-simplification` 主线已经完成最后一轮收口：
  - 会话区不再承担系统设置和伪动作
  - 辅助工作层已降级为按需结果面板
  - 开发期解释腔和“后续会...”式占位文案进一步减少
- 本轮已完成的关键实现：
  - `WorkbenchCanvasWorkspaceShell` 已把底部常驻 `辅助工作层` 改为按需 `结果面板`
    - 默认不再长期占用固定大块空间
    - 文档工具栏触发：
      - `审稿`
      - `大纲`
      时会自动展开对应结果面板
    - 用户也可以通过折叠态按钮手动展开
    - 面板支持显式收起
  - `WorkbenchAuxiliaryPanelHost` 已从“结构层”降级成“结果层”
    - 标题从 `辅助工作层` 收口为 `结果面板`
    - 删除了面板内部的重复跳板入口：
      - `模板中心`
      - `会话设置`
      - `打开总站`
      - `打开资产中心`
    - 各子面板文案已改成当前可理解的结果说明，不再使用：
      - `后续会接入`
      - `会逐步承接`
      - `归属位置`
      这类开发期语气
  - 资源渲染中的占位文案进一步清理：
    - `DocumentStructuredResourceRenderer`
      - `结构视图占位` 改为 `结构摘要`
    - `DocumentPreviewResourceRenderer`
      - 预览说明改为当前行为描述，不再写“后续可以继续在这里接...”
- 本轮刻意未做：
  - 未重做辅助面板的数据来源或开新业务块
  - 未物理删除所有旧注释或历史 feature 文件
  - 未借回归之名继续扩新页面
- 本轮易用性回归覆盖：
  - `打开已有项目`
    - `test/project_open_view_data_service_test.dart`
  - `新建项目`
    - `test/project_creation_controller_test.dart`
  - `已有项目继续创作 / 会话空态收口`
    - `test/conversation_guide_view_data_service_test.dart`
    - `test/conversation_sidebar_test.dart`
  - `已有项目导入文件`
    - `test/workspace_command_overlay_test.dart`
  - `长任务项目进入总站相关路径`
    - `test/long_task_station_view_data_service_test.dart`
  - `工作台结果面板按需展开`
    - `test/workbench_canvas_workspace_shell_test.dart`
- 本轮验证结果：
  - `dart analyze lib test`
    - in `apps/novel_agent_app`
    - 通过
  - `flutter test test/workbench_canvas_workspace_shell_test.dart test/project_open_view_data_service_test.dart test/project_creation_controller_test.dart test/workspace_command_overlay_test.dart test/conversation_empty_state_action_projection_service_test.dart test/conversation_guide_view_data_service_test.dart test/long_task_station_view_data_service_test.dart test/conversation_sidebar_test.dart test/resource_manager_panel_test.dart test/workbench_navigation_sidebar_test.dart`
    - in `apps/novel_agent_app`
    - 通过
- 后续扩展点：
  - 这份 `ui-simplification` 顺序文档中的主线 session 已全部完成
  - 下一次如果再收到同一类“继续下一步”的自动提示，应切换到你要求的阻塞式控制台任务分支，而不是再开启新 UI 主线

---

## 0. 这份文档的定位

这不是继续“把现有很多页面再做得更漂亮”的顺序文档。

这是一次明确的收口顺序文档，目标是：

1. 把入口数量压到人类真正能理解的程度
2. 把重复语义和重复跳转真正合并掉
3. 把 AI 可自然引导完成的流程，从硬写 GUI 树里释放出来
4. 让顶层信息架构能够映射到未来 CLI

如果本文件与更早的前端演化类文档存在冲突，那么在以下问题上，以本文件为新基线：

- 是否保留某个一级页面
- 顶层导航数量
- 同一逻辑允许多少入口
- 哪些流程应交还给 AI 引导
- 哪些配置应归到 `设置`，哪些应归到 `项目`

---

## 1. 已经明确的最终基线

### 1.1 全局一级入口只保留四个

只保留：

1. `打开项目`
2. `工作台`
3. `长任务总站`
4. `设置`

### 1.2 这些页面不再保留独立全局语义

要移除或降级：

- `项目库`
- `灵感工作台`
- `拆书向导`
- `任务中心`
- `审稿中心`
- `项目资产`
- `提示模板`
- `智能体生态`

### 1.3 工作台的稳定结构

工作台内只保留一个主空间，桌面端以三栏为语义基座：

1. 左栏：`文件 / 项目 / 长任务`
2. 中栏：主画布
3. 右栏：会话

`辅助工作层` 不再作为长期常驻大层级，而改成：

- 按需出现
- 上下文相关结果
- 关闭后不占空间

### 1.4 单入口原则

从这轮开始，默认规则是：

**一套逻辑，只允许一个主入口。**

可接受的例外只有：

1. 主入口 + 只读快捷跳转
2. 主入口 + 当前上下文下的单次行动按钮

不允许再长期存在：

- 主入口 + 独立页面 + AI 引导并存
- 同一逻辑在已有项目和空项目中显示同样的开局按钮树
- 会话里一个入口、左栏一个入口、全局导航再一个入口

### 1.5 AI 引导优先级

默认优先级固定为：

1. 当前上下文下的自然 AI 引导
2. 必要的唯一主入口
3. 少量只读快捷跳转

而不是：

1. 先造很多按钮
2. 再做页面
3. 最后让 AI 接管残余流程

### 1.5.1 宿主动作白名单

“更多交给 AI 引导”不等于把所有显式动作都删掉。

以下动作默认应保留为明确宿主动作，而不是强行藏进对话：

- 打开项目
- 新建项目
- 导入本地项目
- 导入文件
- 打开文件 / 资源
- 停止当前生成或运行
- 启动长任务
- 桌面端附件选择

判断原则是：

- 需要系统权限或宿主 API
- 比 AI 引导快得多
- 一旦藏进对话会明显降低可发现性
- 出错后需要明确反馈

### 1.6 已有项目的硬规则

对于已经具备明确基础的项目，例如已有：

- 正文
- 角色
- 设定
- 文件结构

则不再显示：

- `灵感种子`
- `从零开局`
- `开局模式按钮树`

这类入口只允许出现在：

- 新建项目
- 仍处于真正未开局状态的项目

### 1.7 文件导入硬规则

不允许再让用户手填绝对路径作为主入口。

导入必须走：

- 文件选择器
- 文件夹选择器
- 或拖拽

### 1.8 设置边界

以后只保留两类稳定设置语义：

1. `设置`
   - 应用级
2. `项目`
   - 当前项目级

不再继续扩：

- 工作台设置
- 会话设置
- 工具设置

这类面向内部结构的入口名。

---

## 2. 执行总原则

### 2.1 继续遵守解耦要求

即便本轮主要做 UI 精简，也必须继续遵守：

- 单一职责
- 不让单文件过重
- presenter / controller / view data / widget / policy 分层
- 不把很多分流规则重新堆回大 controller

### 2.2 推荐的实现顺序

本轮必须按这个方向推进：

1. 先砍错的入口层级
2. 再合并重复语义
3. 再把 AI 可替代流程从 GUI 中撤掉
4. 最后才做局部 UI 收尾和文案清理

不要反过来：

- 先美化
- 再补跳转
- 最后保留一堆历史入口

### 2.2.1 退役策略

被降级或移除的页面，不建议在同一轮里做“一刀切物理删除”。

更优雅的做法是分两步：

1. 先取消它的产品主语义与可见入口
2. 再在后续轮次里清理兼容路由、死跳转和无人使用的实现文件

这样做的原因是：

- 可以先验证新路径是否真的顺手
- 可以避免一轮里同时混入信息架构重写和大规模删文件
- 可以减少回滚成本

### 2.3 探针时机

真实使用探针或强回归，不应在最前面跑。

建议节奏：

1. 前几轮先做结构清理
2. 入口和语义收束后再做整体验证
3. 最后一轮再做“真实路径是否顺手”的使用探针

---

## 3. 任务总览

建议按以下顺序推进：

1. `Session US-01`：全局导航收束与 `AppDestination` 减负
2. `Session US-02`：`打开项目` 成为唯一项目入口页
3. `Session US-03`：移除 `灵感` 全局页并收束开局入口
4. `Session US-04`：统一 `导入文件 / 自动拆书 / 拆书项目` 动作语义
5. `Session US-05`：工作台左栏收束为 `文件 / 项目 / 长任务`
6. `Session US-06`：`任务中心 / 审稿中心` 并入 `长任务总站`
7. `Session US-07`：清理会话区伪动作、设置泛滥和二次导航
8. `Session US-08`：清理占位文案、降级辅助工作层并做最终易用性回归

---

## 4. Session US-01：全局导航收束与 `AppDestination` 减负

### 本轮目标

先把顶层信息架构从“很多内部模块并列暴露”收束成四项全局入口。

### 预计改动量

- 约 `700 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 收缩 `AppDestination`
2. 收缩 `AppShellNavigationCatalog`
3. 让全局导航只保留：
   - `打开项目`
   - `工作台`
   - `长任务总站`
   - `设置`
4. 清理与旧目标强耦合的基础路由分派与标题映射
5. 不让“已被降级的页面”继续以一级入口身份残留

### 本轮不要做

- 不重做 `打开项目` 内容本身
- 不直接删全部旧 feature 文件
- 不顺手改工作台内部布局

### 本轮重点拆耦

- `destination contract`
- `navigation metadata`
- `page routing bridge`

### 完成判定

- 顶层导航已只剩 4 项
- 已被降级的页面不再作为全局主语义暴露
- 基础路由代码没有因此更集中地耦到一个大文件里

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-01 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理全局导航收束与 AppDestination 减负：把顶层入口正式压到 打开项目 / 工作台 / 长任务总站 / 设置 四项，清理相关导航元数据与基础路由接线。不要重做打开项目页内容，不要顺手改工作台内部布局，不要把分流逻辑堆回大 controller。
```

---

## 5. Session US-02：`打开项目` 成为唯一项目入口页

### 本轮目标

把“项目库”真正吸收进 `打开项目`，让它成为唯一自然的项目进入页。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 升级 `打开项目` 页，使其至少具备：
   - 最近项目列表
   - 可打开项目列表
   - `新建项目`
   - `导入本地项目`
2. 吸收 `项目库` 语义
3. `导入本地项目` 改成选择器流，而不是手填路径
4. 对导入结果提供最小预检反馈
5. 清理“项目库”相关遗留跳转

### 本轮不要做

- 不做灵感或拆书流程
- 不改长任务总站
- 不做项目详情大百科页

### 本轮重点拆耦

- `open-project view data`
- `project import action flow`
- `project list presenter`

### 完成判定

- 用户不需要再理解“项目库”这个额外概念
- `打开项目` 已具备真实入口页能力
- 项目导入主路径不再依赖路径手填

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-02 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。把 打开项目 升级成唯一项目入口页：吸收项目库语义，补齐最近项目、可打开项目、新建项目、导入本地项目，并让导入流程走选择器与最小预检，不要再让用户手填绝对路径。不要顺手做灵感、拆书或长任务改版。注意 view data、导入动作流、列表 presenter 分层。
```

---

## 6. Session US-03：移除 `灵感` 全局页并收束开局入口

### 本轮目标

把 `灵感` 从一级页面改回它真实的产品语义：

- 灵感是开局状态

### 预计改动量

- 约 `900 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`
- 与 opening 相关的现有 workbench 服务

### 必须完成

1. 去掉 `灵感工作台` 独立页面语义
2. 把开局入口收束成：
   - 新项目或未开局项目中的轻量入口
   - 后续由 AI 在会话中继续引导
3. 对已有基础项目，禁止继续显示：
   - 灵感种子
   - 从零开始
   - 固定开局按钮树
4. 为“未开局 / 已有基础 / 可直接继续创作”建立稳定判定口
5. 清理与旧开局页面强耦合的 guide / starter actions

### 本轮不要做

- 不大改智能体组体系
- 不做导入与拆书动作重构
- 不做长任务总站合并

### 本轮重点拆耦

- `opening-state projection`
- `project maturity / readiness rule`
- `opening starter action policy`

### 完成判定

- 灵感不再作为独立一级空间
- 已有基础项目不会再被错误拉回开局逻辑
- 开局入口与项目成熟度判定已不再散落在多个面板里

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-03 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md，以及当前 opening 相关服务。只处理 灵感页降级与开局入口收束：移除灵感工作台的全局页语义，把开局收束成新项目或未开局项目中的轻入口并交给 AI 继续引导，同时确保已有基础项目不再显示灵感种子和从零开局按钮，并为项目成熟度建立稳定判定口。不要顺手做导入/拆书动作重构，不要大改智能体组体系或长任务总站。注意 opening-state projection、项目成熟度判定、starter action policy 分层。
```

---

## 7. Session US-04：统一 `导入文件 / 自动拆书 / 拆书项目` 动作语义

### 本轮目标

把 `拆书` 从独立页面彻底改回“项目类型或导入后动作”，并把导入动作收束成一套正式宿主流程。

### 预计改动量

- 约 `1000 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 去掉 `拆书向导` 独立页面语义
2. 把 `导入文件` 定义为唯一主入口
3. 在导入动作中支持：
   - 普通导入
   - 可选自动拆书
4. 让 `拆书项目` 与 `普通项目导入拆书` 共享同一动作模型
5. 明确输出位置、格式支持和失败反馈
6. 保持文件选择器 / 拖拽这类宿主动作是显式入口，不藏进对话

### 本轮不要做

- 不大改工作台左栏布局
- 不做最终会话区动作清理
- 不做总站整合

### 本轮重点拆耦

- `import action contract`
- `deconstruction option policy`
- `import result feedback model`

### 完成判定

- 拆书不再是独立一级空间
- 导入文件已成为唯一正式入口
- 自动拆书成为导入动作的一个清晰选项，而不是另一条产品路径

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-04 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md，以及当前 import/deconstruction 相关实现。只处理 导入文件/自动拆书/拆书项目 的统一动作语义：移除拆书向导的独立全局页语义，把导入文件收束成唯一主入口，在其中支持可选自动拆书，并统一普通项目与拆书项目的动作模型。不要顺手大改工作台左栏布局，不要改最终会话动作条。注意 import action contract、deconstruction option policy、结果反馈模型分层。
```

---

## 8. Session US-05：工作台左栏收束为 `文件 / 项目 / 长任务`

### 本轮目标

清理工作台内部的二次导航和重复入口，让左栏只表达当前项目真正稳定的三类对象。

### 预计改动量

- 约 `1000 ~ 1900` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 左栏正式收束为：
   - `文件`
   - `项目`
   - `长任务`
2. 合并以下分散能力到 `项目`：
   - 资产
   - 模板
   - 智能体生态
   - 表达限制
3. 移除或重做这些二次导航语义：
   - 工作区入口
   - 工作区概览
   - 策略与协作
   - 上下文选择
4. 保留当前项目长任务摘要，但不再把它做成第二个任务中心
5. 尽量减少“打开某中心”的跳板式面板

### 本轮不要做

- 不大改中栏主画布 renderer
- 不做最终会话区动作清理
- 不做总站整合

### 本轮重点拆耦

- `left-panel section contract`
- `project-panel subview data`
- `current-project long-task summary`

### 完成判定

- 用户不会在工作台里再看见一套伪全局导航
- 项目级配置能力已收进 `项目`
- 左栏表达的是对象，不再是内部模块入口集合

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-05 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理工作台左栏收束：把左栏正式压到 文件 / 项目 / 长任务 三类对象，并把资产、模板、智能体生态、表达限制并入 项目；同时移除工作区入口、工作区概览、策略与协作、上下文选择 这类二次导航语义。不要顺手重做主画布 renderer，不要改最终会话动作条。注意左栏 section 合同、项目面板子视图、当前项目长任务摘要分层。
```

---

## 9. Session US-06：`任务中心 / 审稿中心` 并入 `长任务总站`

### 本轮目标

把运行态与返工态统一并回总站，终止“总站 / 任务 / 审稿”三套并行入口。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 移除 `任务中心` 独立全局语义
2. 移除 `审稿中心` 独立全局语义
3. 把以下能力并回 `长任务总站`：
   - 任务节点
   - 检查点
   - 审稿 / 返工关联项
   - 当前项目过滤视图
4. 把工作台中的相关入口降级为：
   - 当前项目摘要
   - 打开总站
5. 清理总站里仍然指向“任务中心 / 审稿中心”的文案和按钮

### 本轮不要做

- 不重做整个长任务业务域
- 不顺手扩新任务类型
- 不回头改打开项目页

### 本轮重点拆耦

- `station-native task projection`
- `station-native review projection`
- `project-scoped station summary`

### 完成判定

- 用户继续某个长任务时只需要认 `长任务总站`
- 任务与审稿不再是平级全局空间
- 工作台中的长任务入口只起当前项目投影作用

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-05 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理 任务中心/审稿中心 并入 长任务总站：把任务节点、检查点、审稿与返工关联项并回总站，清理所有仍指向任务中心或审稿中心的按钮和文案，并把工作台侧只保留当前项目摘要与打开总站。不要顺手重做长任务业务域或扩新任务类型。注意 station 内投影、当前项目摘要和跳转接线分层。
```

---

## 10. Session US-07：清理会话区伪动作、设置泛滥和二次导航

### 本轮目标

把会话区重新变回“当前协作空间”，而不是混合了入口菜单、局部设置页和占位按钮的区域。

### 预计改动量

- 约 `900 ~ 1700` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`

### 必须完成

1. 清理会话空态中的菜单化入口堆
2. 清理输入区中的伪动作或占位动作，重点检查：
   - `优化`
   - `工具`
   - `附件`
   - `停止`
3. 让“工具/附件/停止”只在它们是正式可用动作时出现
4. 把不属于当前会话协作的设置入口移出会话区
5. 精简会话顶部，使其优先只保留：
   - 当前会话相关动作
   - 少量必要历史动作

### 本轮不要做

- 不重做主题系统
- 不扩新会话块类型
- 不顺手重构全部视觉细节

### 本轮重点拆耦

- `conversation action availability`
- `empty-state projection`
- `session-vs-project setting boundary`

### 完成判定

- 会话区不再像一页系统功能目录
- 用户不会再点到“看起来能用、实际上只是预留”的动作
- 会话区职责重新收束到协作本身

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-06 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md。只处理会话区收束：清理空态中的菜单化入口、输入区中的伪动作和占位动作，重新划清会话动作与项目/应用设置的边界，让会话区只保留真正属于当前协作的最小动作。不要顺手重做主题系统或大面积视觉细节。注意 action availability、empty-state projection、setting boundary 分层。
```

---

## 11. Session US-08：清理占位文案、降级辅助工作层并做最终易用性回归

### 本轮目标

做最后一轮产品化收口，只修真实问题，不再开新主线。

### 预计改动量

- 约 `700 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-full-audit-2026-05-28.md`
- 本文档前面各 session

### 必须完成

1. 清理开发期占位文案，例如：
   - `后续这里会...`
   - `入口已预留...`
   - `打开某中心`
2. 把辅助工作层彻底降级成按需结果面板，而不是常驻结构层
3. 检查仍然残留的重复入口和伪整合跳板
4. 做一次真实使用路径回归，至少覆盖：
   - 打开已有项目
   - 新建项目
   - 在已有项目中继续创作
   - 在已有项目中导入文件
   - 在长任务项目中进入总站相关路径
5. 回填文档与回归结果

### 本轮不要做

- 不扩新业务能力
- 不再开新中心页
- 不借回归之名重写工作台架构

### 本轮重点拆耦

- `auxiliary result panel host`
- `copy cleanup`
- `usability regression probe`

### 完成判定

- 界面里的解释腔和占位腔明显下降
- 辅助工作层不再抢结构主语义
- 主要用户路径已经能用更少入口走通

### 建议提示词

```text
按 docs/ui-simplification-session-order-2026-05-28.md 的 Session US-07 执行。先阅读 agent.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md、docs/ui-simplification-full-audit-2026-05-28.md，以及本文件前面各 session。只做最终收口：清理 后续会... / 已预留 / 打开某中心 这类占位文案，把辅助工作层彻底降级成按需结果面板，并对打开已有项目、新建项目、已有项目继续创作、导入文件、长任务总站路径做真实易用性回归。不要开新主线，不要借回归之名重写架构，完成后回填文档。
```

---

## 12. 推荐起点

从当前状态看，最自然的起点是：

1. `Session US-01`
2. `Session US-02`
3. `Session US-03`

原因很明确：

- 现在最伤可用性的，不是视觉微调，而是错误的信息架构
- 只要全局入口层级还是错的，后面的工作台和会话区就会持续长出重复入口
- 先砍掉不该存在的页面语义，再继续做局部简化，收益最高

---

## 13. 执行规则

后续按本文件推进时，默认遵循：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或者暴露强关联回归，先补完，不开启下一轮。
3. 每轮开始前至少复读：
   - `agent.md`
   - 本文件对应 session
   - 本文件关联的两份分析文档
4. 每轮结束时都要说明：
   - 本轮完成了什么
   - 哪些文件是后续扩展点
   - 哪些点被明确延期
5. 即便做的是 UI 精简，也继续遵守：
   - 单一职责
   - 不让单文件过重
   - 不把很多入口判断继续堆回大 controller
   - 先收语义，再收视觉
