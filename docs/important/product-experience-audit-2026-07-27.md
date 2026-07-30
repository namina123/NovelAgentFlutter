# 产品体验全景审计（2026-07-27）

承接 2026-07-24 的全流程审计与之后的诚实化、接口/模型职责归位重设计。本轮以「真实用户视角」再次全量走查：**接口/模型/设置 → 创建 → 创作台/对话 → 拆书 → 长任务/任务中心 → 资料库 → 智能体生态**。三组并行审计共产出 ~45 条可指认缺陷。本文件记录**已直接修复**与**暂缓（过大/需设计）**两部分。

> 验证：本轮所有改动 `dart analyze lib` 0 error；`provider/model_settings/context/conversation_input_dock` 测试 21/21 通过；0.1.20 Windows+Android 构建通过。

---

## 第二轮逐项修复（2026-07-27 续）：暂缓项 B1–B13 收口

第一轮 A 段 23 条已修后，逐项处理 B 段暂缓项，结果如下：

- **B1 设置保存可见反馈** ✅ 新增 `SettingsViewData.settingsAnnouncement` 瞬态字段 + `_announceSettings`；`_persistSettings` 与模型页校验分支改走它；`SettingsHeader` 渲染 3.5s 自动消失的成功/失败横幅（成功/失败配色区分）。所有设置 tab 保存反馈现在可见。
- **B2 首次运行模型未配置引导** ✅ 会话输入区上方条件渲染 `_ModelConfigBanner`（`hasActiveProject && modelOptions.isEmpty`），附「去设置」按钮。
- **B3 创建按钮创建期置灰** ✅ `project_create_panel` 在 `status` 以「正在创建项目」开头时禁用提交，防止重复触发 `executePrepared`。
- **B4 无项目发送置灰 + 设置入口** ✅ `canSendAction` 接进 `hasActiveProject`；设置入口由 B2 的 banner「去设置」承担（接已实现但此前无 UI 的 `onConversationSettingsRequested`）。
- **B5 无项目空态不再误导到小说** ✅ `applyConversationState` 在 `currentProject==null` 时产出「尚未打开项目」引导并清空 primaryActions/openingPanel。
- **B6 拆书失败重确认诚实** ✅ 恢复文案补充「重新确认会重写各步文件（章节按序号覆盖，可安全重试）」。
- **B7 拆书取消就近 + 粘贴模型降级警示** ✅ 步骤卡片标题行在 `isLoading` 时露「取消」；`_SplitStep` 在粘贴内容+勾模型时显式警示「模型去噪会跳过」。
- **B8 总站重入刷新 + 空队列诚实** ✅ `LongTaskStationVisibilityRefreshService` 重入即刷一次（新增测试）；`_resultMessage` 在 `stop_reason=no_runnable_task/record_missing` 时用 stop 文案代替假「已推进」。
- **B9 任务中心数字/Markdown/置灰** ✅ 数字字段 `int.tryParse` 失败现在报错并阻止提交（不再静默回落默认）；链路树/日志/detail 改用 `flutter_markdown` 真渲染（不再字面 `## - **`）；执行类按钮（准备执行/执行一次/下一任务/连续运行）在 `commandInFlight || tasks.isEmpty` 时禁用（commandInFlight 已接进 view data）。
- **B10 RAG 降级显式化** ✅ `project_rag_extraction_panel` 的 status 在含降级标记（关键词匹配/仅写入元数据/未配置 embedding）时用警示色卡片突出。
- **B11 装载假禁用 + 未应用高亮** ✅ `project_skill_loadout_detail_panel` 去掉 `IgnorePointer+Opacity`，改透传 `ActionButton.disabled`；「应用装载」在 `hasPendingChanges` 时 accent + emphasized。
- **B12 恢复路径 + detail 失败/空态** ◐ E1 恢复报错文案补「运行号 + 去任务中心哪个 tab」（auto-select run 需更多接线，暂缓）；E2 detail 加载失败用 error 色放大区分「干净空」；**E3 resume「重试当前步骤」语义** 暂缓——底层是否真单步重试需先实证，未改以免反向误导。
- **B13 死代码清理** ◐ `ProviderDraftViewData` 已删；`_providerConnectionValidationResults` 缓存 / `SettingsViewData.providerConnectionValidationResult` / `ProviderEndpointViewData.connectionValidationResult` / `tabSections` / `SettingsOverviewPanel` 暂缓——这些是 required 视图字段，被 ~10 个测试夹具构造，移除属单独的高 churn 重构、零用户收益。

**遗留（非本轮引入）**：`app_shell_task_center_workflow_create_request_test.dart` 因诚实化 pass 把创建向导默认改为跳过「存储策略」步而超时（等 storage phase）——测试夹具需同步更新，与本轮改动无关。

---

## 第三轮：复审（2026-07-27 续）— 验证修复端到端生效 + 抓回归

三组复审 agent 重新从用户视角走查，**确认 B1–B12 主体全部端到端生效**，同时发现 2 个由前轮修复引入的 P1 回归与若干漏网/边界缺陷，已逐项处理：

### 已修（本轮）
- **[P1 回归] 删当前作品失败时被锁在 guard launcher**：前轮把 `resetToProjectlessWorkbench + showLauncher(guard)` 放在 `target.delete()` 之前，删除抛错会困住用户。改为先删成功再锁 launcher。`app_shell_controller._deleteProjectFromProjectOpen`。
- **[P1 回归/漏网] 删默认接口未清 defaultModelId**：`_modelSelectorOptions` 仍列出孤立模型 → B2 banner 不亮、用户盲发。删除时同步清 `defaultModelId` 与 `model_settings.model_id`。`onProviderDeleted`。
- **[P1] 切换接口/模型后旧"连接成功"绿卡残留**：A+X 的成功结果在切到 B+Y 后仍显示，误导用户以为已通过。`onProviderSelected/onModelSelected` 现重置 `_connectionResult`。`model_settings_panel`。
- **[P1] 发送被拒时草稿被清空（文本丢失）**：B7 去掉空文本守卫后，控制器拒绝分支（无项目/无模型）仍导致 sidebar 无条件清空输入。改为只在"有项目且有可用模型"时清空。`conversation_sidebar._handleSendRequested`。
- **[HIGH] B10 RAG 降级匹配错字（实际未生效）**：上游文案是"关键词检索/退回关键词检索/向量化失败"，原匹配"关键词匹配/未配置向量"是死关键字——embedding 失败这类紧急场景被当普通成功。改为匹配"关键词/向量化失败/退回/仅写入元数据/未配置 embedding"。`project_rag_extraction_panel`。
- **[M] 相同成功消息二次保存不弹横幅**：`SettingsHeader` 收起时清掉去重 key，重复保存能再次弹出。
- **[M] 重进设置页时陈旧横幅再弹**：`_settingsAnnouncement` 不复位 + State 重建后 `_lastShown` 归空导致旧消息复现。`initState` 把进入时的非空 announcement 记为已展示。
- **[M] ActionButton disabled 仍按 enabled 配色**：disabled 只 null 了 onPressed，背景/边框仍 accent 色，看着可点。改为 disabled 时统一中性弱化色（惠及 B3/B4/B9/B11 所有禁用按钮）。`action_button.dart`。
- **[small] 接口预校验走错通道**：`onProviderSaved` 两个 `_announce` 改 `_announceSettings`（设置页可见）。
- **[small] 回退文案暴露技术 actionId**：去掉裸 `actionId`，改中性文案。`conversation_opening_flow_controller`。
- **[small] `ConversationInputCapabilityState.initial` canSendAction 过宽**：默认改 `false`，与无项目不可发语义一致。

### 暂缓（low / 已服务端兜底，按需再做）→ 已随后续补丁修掉

后续又把复审里的 low 项逐个收口：
- 任务中心**所有变更类按钮**（生成计划/链路快照/后处理×2/标记完成/完成并下一条/接受修复/回滚修复/重试）现都跟随 `commandInFlight || tasks.isEmpty` 置灰（暂停/恢复/取消保留为运行控制）。
- **创建失败 status 用 error 色区分**进行中态（扫视即可辨识失败）。
- **`_ModelConfigBanner` 改用 Novel 主题 token（warm）+ 加「暂时关闭」**，切换对话上下文后恢复提示。
- **草稿清空改用 `sessionId + hasActiveProject` 组合指纹**，覆盖空 sessionId 的新项目加载，不再误带/误清。
- **任务中心 Markdown 超长内容截断**（diagnostics 8000 字 / detail 12000 字），避免 flutter_markdown 卡顿。
- **模型保存按钮置灰时给出就近原因**（缺接口/未选接口/未填模型）。
- **`_AnnouncementBanner` isError 判定统一**用 `message.contains`（去掉无意义的 toLowerCase）。
- **有项目但无可用模型时发送按钮也置灰**（`canSendAction` 复合 `modelOptions.isNotEmpty`，新增 state copyWith）。
- **修复 `app_shell_task_center_workflow_create_request_test`**：harness 不再等待已被默认跳过的 storage 相位（此前一直超时）。

剩余真正可延后的：`_ModelConfigBanner` 加载中瞬时 `modelOptions` 为空可能闪一下（需下沉为控制器层稳定信号 `requiresModelConfigHint`）；其余均已闭环。

---

## 第四轮：全功能用户旅程走查（2026-07-28）

重建 Windows release 并做启动冒烟（当前代码：构建通过、启动 9s 无崩溃、boot log 干净），再以一条完整用户旅程走完全部功能。**确认主旅程端到端走得通**（设置反馈/接口模型分离/首个接口自动默认/删默认接口同步清模型/切接口模型清旧探测/未配置模型 banner+发送禁用/无项目空态/创建期禁用/创建后自动打开/拆书粘贴降级提示+取消就近+派生入口/任务中心空队列诚实+回滚取消确认+数字校验/总站重入刷新+恢复失败带运行号/Markdown 渲染/RAG 降级显眼/装载真禁用+未应用高亮/接口删除确认/错误人话化/发送被拒保留草稿——均验证到位）。

新发现并已修：
- **[LARGE] 长任务总站「停止」无二次确认**（与任务中心「取消」不对称，误点丢整条运行）→ 加 `showConfirmationDialog`。
- **[LARGE] 创建进行中「上一步」「打开已有项目」未禁用**（可中断 executePrepared → 状态错位/目录残留）→ 创建期整行动作均禁用。
- **[SMALL] 任务中心「生成队列」置灰无就近原因** → 补「仅长篇项目支持…」提示。
- **[SMALL] `_applyQueueControl` catch 把原始 error 拼进文案** → 改用 `UserFacingErrorHumanizer`。
- **[SMALL] 网络设置 custom 代理保存前无校验**（host 空/port 越界被静默归一）→ 保存前校验并报错。
- **[SMALL] 上下文阈值字段失败静默回退 0.8/80%** → 非法百分比报错并阻止保存。
- **[SMALL] `_ModelConfigBanner` 加载中可能闪一下** → 加「不在加载中」门控（generationStatus 不含「正在加载」）。

判定为非问题（核实）：旅程报告提到的「优化」按钮——`showOptimizeAction` 在 resolver 恒为 false，按钮实际从不渲染，无需处理。

仍可延后（LOW）：发送按钮置灰时若用户已关掉 banner 则缺就近 hint（banner 已解释，关掉是用户选择）；`onRetryLastFailedRequested` 仍走旧通道未接 runtime controller 统一取消句柄（功能正常，仅取消语义不完美，留有 TODO）。

---

## 第五轮：三组并行新鲜视角审计 + 逐项收口（2026-07-28）

收掉第四轮遗留的两个 LOW 后，启动三组**新鲜视角**审计 agent（设置/接口/模型、拆书/资料库/智能体、壳层/导航/无障碍/极端尺寸），各自先读本报告去重，再从真实用户视角逐路径走查。共产出 **22 条新发现（7 LARGE / 11 MEDIUM / 4 SMALL）**，全部经代码路径复核确认为真（无一条像此前的 retry 那样是误报）。**22 条已全部修复**（初轮修 21 条，原列暂缓的 5 条随后全部收口），外加同步了诚实化 pass 留下的陈旧测试夹具。

### 已修（本轮 22 条全部 + 陈旧测试夹具）

**数据完整性 / LARGE**
- **切项目时旧项目在飞响应泄漏进新项目**：`resetRuntimeState()`（取消 `_activeRequestHandle` + 清空会话运行时）此前**零调用者**；壳层 `resetConversationRuntimeState` lambda 只清自己的字段、不取消句柄 → 切项目时旧流式的 `onProgress`/结果仍写进新项目会话。lambda 现追加 `_workbenchConversationController.resetRuntimeState()`。`app_shell_controller`。
- **连接测试绕过用户自定义代理**：`ProviderConnectionProbeService.probe` 恒传空 `networkSettings`，与真实生成走的代理路径不一致（代理用户得到与实战相反的通过/失败）。probe 增 `networkSettings` 参，控制器传 `settings.networkSettings`。`provider_connection_probe_service` + `app_shell_controller`。
- **自定义代理空端口静默降级为 system**：core 在 custom+空端口时静默把 `proxy_mode` 改回 system 并清空字段，用户看到"保存成功"后下拉跳回系统网络、零解释。网络面板 `_save` 现把空端口当错误拦截。`network_settings_panel`。
- **设置横幅切 tab 重弹陈旧消息**：`_settingsAnnouncement` 写入后永不清理，任何 tab/provider 切换触发的重建都把它当新消息再弹。`_refreshSettingsViewData` 投影后立即清空（一次性瞬态；重复保存会重新写入，仍能再弹）。`app_shell_controller` + `settings_header`。
- **生态「新建/打开源文」反馈走错通道**：`_createEcosystemEntry`/`_openEcosystemEntrySource` 用 `_announce`（只写工作台状态条，生态页看不到），改用 `_setAgentEcosystemStatus`。`app_shell_controller`。
- **长任务详情 primaryMetadata 重复渲染**：`overviewBlocks` 为空时第 63-66 行已兜底渲染 primaryMetadata，第 264-268 行「高级信息」下又渲染一次。「高级信息」下的 primaryMetadata 现仅在 overviewBlocks 非空时列出。`long_task_run_detail_panel`。
- **知识库 RAG 工作区降级提示回归（B10 漏网）**：B10/HIGH 修复只改了嵌入式面板，KB 项目用的 `KnowledgeBaseRagWorkspace._ProgressStrip` 仍把降级状态当普通正文——最该警告的项目类型反而最不显眼。抽共享组件 `RagStatusText`，两处复用。`rag_status_text.dart`（新）+ `project_rag_extraction_panel` + `project_assets_knowledge_base_rag_workspace`。

**MEDIUM**
- **AI 超时无校验/无 formatter，静默回落 90s**：加 `inputFormatters` + `_save` 校验（>0、≤3600）。`network_settings_panel`。
- **自动重试次数静默 clamp 6-9→5**：formatter 改 `allow([0-5])` + `_save` 校验。`network_settings_panel`。
- **工具策略 proactive 与 balanced 开关完全相同（下拉像死的）**：proactive 现设 `_forceToolChoice=true`。`tool_strategy_settings_panel`。
- **工具策略手动改开关后重进丢失**：`_sync` 末尾的 `_applyMode(_mode)` 把按预设覆盖回刚回填的持久化开关 → "改开关→保存→重进"改动消失。移除该调用（`_applyMode` 只服务于下拉选预设）。`tool_strategy_settings_panel`。
- **生态编辑器删除无二次确认**（与 foreshadow/style 不对称）→ 包 `showConfirmationDialog`。`ecosystem_editor_overlay`。
- **生态导入提交无 in-flight 守卫**（慢盘连点触发并行导入写同一批文件）→ 视图数据增 `isImporting`，控制器在导入开始/各终止分支置位，弹层据此禁用按钮+改文案。`ecosystem_import_command_view_data` + `app_shell_controller` + `ecosystem_import_overlay`。
- **派生新写作项目无确认即自动切换**→ 按钮包 `showConfirmationDialog`。`book_deconstruction_page`。
- **生态/资料库错误把原始 `$error` 抛给用户**（8 处）→ 全部走 `UserFacingErrorHumanizer.humanize`。`app_shell_controller` + `project_assets_controller`。
- **长任务动作条用裸 `OutlinedButton`** 非 `ActionButton`（禁用态与全应用不一致）→ 改 ActionButton，禁用态统一中性弱化；测试 finder 同步 OutlinedButton→TextButton。`long_task_run_action_bar` + `long_task_run_detail_panel_test`。

**SMALL / 收尾**
- **连接状态卡术语泄漏**（`需要隐藏的选项：chat、responses` / `当前组合不允许 fallback。`）→ 合并成人话提示。`connection_status_card`。
- **拆书 Step2/Step3 取消键在任一加载时都出现**（误导）→ 各自按 operationKind 门控。`book_deconstruction_page`。
- **6 处关闭/返回 IconButton 缺 tooltip**（生态导入/编辑、工作区命令、智能体组、作品库返回、任务列表进入）→ 补 tooltip。
- **任务中心集群 AppPalette 硬编码深色（亮色主题不可读）**：diagnostics/detail/shared_actions/page 全部迁移到 `novelThemeColors`，亮色主题下链路树/日志/详情 Markdown 不再白字白底。`task_center_*`。
- **发送按钮置灰且 banner 已关时缺就近 hint**（第四轮 LOW）→ 关闭大 banner 后保留一行紧凑 `_ModelConfigHint`。`conversation_sidebar`。
- **`onRetryLastFailedRequested` 陈旧 TODO**（第四轮 LOW，核实为非 bug）：retry 实际已走统一 `_sendPrompt`→`_activeRequestHandle`，可被 `onStopRequested` 取消；清掉误导性 TODO 注释。`workbench_conversation_controller`。
- **陈旧测试 `project_create_panel_continuity`**（普通小说单相向导，按钮文案是"创建并打开"非"下一步"）→ 更新断言。

### 原暂缓项已全部收口（追加修复）

此前列出的 5 条暂缓项已全部修复，无遗留：

- **[LARGE 残余] AppPalette 深色专用硬编码** ✅ 余 ~36 站点全部迁移到 `novelThemeColors`：生态编辑/导入 overlay、工作区命令 overlay、作品库页、提示模板页、权限设置页。亮色主题下不再白字白底。
- **[MEDIUM] `WorkspacePaneLayout` 短高度溢出** ✅ stacked 模式按 maxHeight 给边栏分预算、超出同比缩放，保证主区 Expanded 永远非负（≥120px 保底）。Android 横屏/分屏不再黄黑溢出。
- **[MEDIUM] 生态浏览页顶部按钮永不禁用** ✅ `AgentEcosystemViewData` 增 `isBusy`，控制器围绕刷新/生成索引置位（`_setAgentEcosystemBusy` + try/finally），按钮据此禁用防连点。
- **[MEDIUM] RAG 提取并发：切项目时在飞结果可能写进新项目** ✅ `project_assets_controller` 在 `pickAndExecute` 之后校验 `_readCurrentProject()?.rootPath == project.rootPath`，不匹配则丢弃结果（reference/rag 两条链均加）。
- **[pre-existing 测试夹具]** ✅ 诚实化 pass 默认跳过存储策略步后留下的陈旧夹具已全部同步：`project_creation_controller_test`（移除 storage 相位/双提交）、`app_shell_reference_extraction_refresh_regression_test`（移除 storage 相位等待）、`task_center_detail_panel_test`（Markdown 渲染后断言找标题文本非字面 `##`）、`project_launcher_view_data_service_test`（服务步号计算：当前相位为 storage 时计入相位列表，步号正确）。

### 验证
- `dart analyze lib`：0 error / 0 新告警（仅 2 条与本次无关的既有 info）。
- **全量 `flutter test`：646 通过 / 12 跳过 / 2 失败**。仅剩的 2 个失败是 `hfvv_wave1/2_viewmodel_real_run`，需 `local/probe_api.txt` 真实 API 凭据（环境依赖，非代码缺陷）；`hfvv_wave1_createproject_phase_fix` 单跑通过，全量跑里的偶发是 hfvv harness 全局状态串扰（kb deferHydration 已知缺陷，已 Skip）。
- 所有触及区域测试通过；本轮修复均经 revert/单跑对照核实非回归。

---

## 第六轮：未深查面的新鲜用户视角审计（2026-07-28）

第五轮后，针对**此前 5 轮未深查**的面（审稿中心/会话/灵感工作台/workflow、打开项目/作品库/主题切换/移动端、首运引导跨 destination）再开三组新鲜视角审计。产出 ~24 条新发现，已修其中 16 条用户体验缺陷，余下为死代码/需 plumbing 项，记录如下。

### 已修（16 条）

**作品库 / 打开项目（高价值）**
- **[HIGH] 腐损项目打开丢失失败原因 + 无 launcher 兜底**：协调器产出的具体原因（如"项目清单损坏…请从备份恢复"）与 `shouldShowLauncher` 被控制器丢弃，只写死"path"。现回传 `result.statusMessage`，并在 `shouldShowLauncher` 时弹启动器带原因。`_openProjectFromProjectOpen`。
- **[HIGH] 打开无可见反馈 + 无防重**：`_announce('正在打开项目...')` 只写工作台状态条（作品库页看不到），且连点触发并发 open。现走 projectOpen 视图状态（页内可见）+ `_isOpeningProject` 防重入。
- **[MEDIUM] 移动端无法在作品库删除作品**：窄屏隐藏详情面板（含删除键），手机用户只能用系统文件管理器。每个条目加 `onLongPress` → 删除确认（含当前作品副作用警示）。
- **[SMALL] 作品库空态对移动端谎称可导入**：移动端 `allowImportLocal=false`（导入按钮隐藏），空态却写"或导入已有项目"。现按 `allowImportLocal` 条件化。
- **[SMALL] 作品库空态冗余双文案**：service 兜底"还没有可继续的作品"与页面空态"还没有作品…"同时显示。移除 service 兜底，真实状态仍透出。
- **[SMALL] 删除确认未提示当前作品副作用**：删当前作品会锁启动器、强制回项目入口，文案没说。删除消息在 `isCurrentProject` 时追加警示。
- **[MEDIUM] 作品库页返回键陷阱**：无当前项目时硬件返回弹"退出应用"，而非回工作台。改 `showWorkbench()` + return false，与其他 destination 一致。

**长任务 / 生成链**
- **[HIGH] 长任务启动无接口/模型预检 + 原始 `$error` 泄漏**：未配置时让 workflow runtime 内部抛错，用户看到 `DioException(...)`。启动前显式校验 provider/model 并给设置指引；catch 改走 `UserFacingErrorHumanizer`。`_startLongTaskRunFromOpening`。
- **[MEDIUM] 多处原始 `$error` 泄漏**（第五轮漏网的同模式）：长任务总站 4 处（加载运行实例/资料请求/读取详情）、会话历史保存、语料挂载——全部 humanize。

**设置 / 创作**
- **[MEDIUM] 接口保存未校验空 API Key**：空 key 静默保存并提示"已保存"，用户直到首次发送才撞"鉴权失败"。成功消息现按需追加"API Key 未填写，发送前需补上"提醒（不硬拦，本地/自建服务可忽略）。
- **[MEDIUM] 任务中心无导航栏入口但空态指引用户去**：空态写"在「任务中心」点生成队列"，但任务中心只能从长任务总站右上工具栏进。文案改点明"本页右上「任务中心」图标"。
- **[SMALL] 工作台空态指引指向错误子面板**："新建项目/打开已有项目"在左侧「项目」标签页（非默认 Files），文案没说。改为点明「项目」标签。

**会话 / 工具栏**
- **[MEDIUM] 会话历史开关无会话时像坏了**：开关高亮但无面板渲染（条件要求 entries 非空）。加 `_SessionHistoryEmptyHint` 占位"还没有历史会话…"。
- **[SMALL] 文档工具栏保存/审稿无文档时仍可点**：状态条已显示"空白"，按钮却邀请点击。按 `hasDocument` 禁用。
- **[HIGH] 审稿失败零反馈**：失败分支写到已废弃的 `_refreshReviewCenter`（无 widget 渲染），用户点审稿失败什么也看不到。改走 `_announce`（工作台状态条可见）。

**清理**
- **[SMALL] 删除空占位目录** `features/session/`、`features/workflow/`（仅含空 presentation/，零引用）。
- **[SMALL] 删除死类 `AppPalette`**（第五轮 AppPalette 全量迁移后零引用，仅余注释）。

### 暂缓（需 plumbing 或为刻意停用的功能，记录不动）

- **[LARGE] 首运创建向导未提示先配接口/模型（L1）**：需把"模型是否已配置"信号经 view-data 透到创建面板/overlay。但 B2 的 `_ModelConfigBanner` 已在项目创建后立刻提示"去设置"，覆盖了主路径；L1 是"更早提示"的改进，单独 plumbing pass。
- **[MEDIUM] 资料库工具栏按钮无项目时不置灰（M3）**：核实资料库页本就是项目作用域（仅开项目时进 nav），"无项目"前提弱；handler 的 no-project 守卫是防御性死代码。
- **[MEDIUM] 拆书"未配置模型"提示无"去设置"按钮（M4）**：需给拆书 action handler 加设置回调 plumbing；当前文案已点明"需在设置里配模型"，价值有限。
- **[死代码·刻意停用]** `features/review_center/`（~600 LOC，无 widget 消费 ReviewCenterViewData，`showReviewCenter()` 桩重定向到长任务总站）、`features/inspiration_workbench/`（页面零构造点，`showInspirationWorkbench()` 桩注释"暂时收束回工作台"——暗示待重启用）、`features/project_collection/`（`showProjectCollection()` 桩重定向到 `showProjectOpen()`）。三者均为停用桩，非废弃——保留用例被工作台复用；删除属单独重构。

### 验证
- `dart analyze lib`：0 error / 0 新告警（仅 2 条既有 info）。
- **全量 `flutter test`：646 通过 / 12 跳过 / 2 失败**（仅 hfvv real_run 需 `local/probe_api.txt` 真实 API）。
- 主题切换端到端已核实健康（MaterialApp 重建 + NovelThemeExtension，无生产代码再引用 AppPalette）；移动端窄屏/返回键经代码路径核实。

---

## 第七轮：核心写作/生成面 + 全局文案一致性（2026-07-28）

第六轮后，针对**核心写作与生成体验**（前 6 轮未深查，却是用户花最多时间的地方）再开审计：文档工作区/资源树/编辑、对话→生成→正文→审稿闭环/子智能体/上下文压力、全局文案术语一致性。产出 ~30 条，已修高价值项，feature gap 与 delicate 项记录如下。

### 已修（高价值）

**写作面（数据完整性）**
- **[LARGE] 关闭有未保存修改的文档标签静默丢失**：编辑半小时点 X 全丢，仅一个 5px 小点提示。关闭前按 `isDirty` 弹确认（保存需先手动保存——因保存只作用于活动文档）。`document_tab_strip`。
- **[HIGH] 设置文件空/损坏导致启动崩溃**：`LocalSettingsRepository._loadDocument` 直接 `jsonDecode(raw)`，空文件或半截 JSON 抛 FormatException 让应用起不来（由一个遗留空 `temp/novel_agent_settings.json` 测试工件暴露）。改为空/解析失败时跳过该候选、回退默认空设置。`local_settings_repository`。

**生成/会话**
- **[MEDIUM] 自动压缩历史零提示**：preflight 静默压缩 N 条历史再发送，用户不知道模型本轮只看摘要、会以为"失忆"。压缩事实拼进本轮生成状态条（`_announce` 会被生成状态覆盖，故合并进 generationStatus）。`workbench_conversation_controller._sendPrompt`。

**确认对称性（3 处与已确认同级动作不对称）**
- prompt 模板「删除覆盖」（删项目文件）、「恢复内置」（覆盖用户编辑）—— 加 `showConfirmationDialog`。`prompt_templates_page`。
- 表达限制「移除绑定」（即时改写绑定文件、无撤销）—— 加确认。`expression_constraint_binding_editor_panel`。

**文案/术语一致性**
- **任务中心三名统一**：入口 tooltip「任务中心」/ 初始标题「长任务中心」/ 加载后标题「长篇自动化队列」—— 同一目的地三个名，用户迷惑。统一为「任务中心」。
- **英文泄漏清理**：`provider`×6（拆书/导入/资料库/设置描述）→「接口」；RAG 降级文案 `embedding`/`Key`/`chunk` →「向量化模型」/「密钥」/「分片」（同步更新 `rag_status_text` 匹配）；工具策略 `fallback` →「兜底」；任务中心 `runtime` →「运行时」；设置里裸 `openai_compatible` 协议 id →「OpenAI 兼容」（2 处）。
- **「新章节」按钮误导**：warm 色像主动作，点了却只给一句指引。改为中性色 + help 图标 + tooltip「如何创建章节」，读起来像求助而非坏掉的创建按钮。`file_tool_group`。

### 暂缓（feature gap 或 delicate，记录）

- **[LARGE feature gap] 资源树无重命名/删除/移动**：写小说的产品不能在应用内重命名章节/删草稿/移文件，得用系统文件管理器。需加 context menu + handler，单独功能。
- **[MEDIUM feature gap] 无查找/替换、无 Ctrl+S/Ctrl+F、无 undo/redo 修饰**：长篇写作的基本功。最小可用（Ctrl+S→保存、Ctrl+F→查找栏）可做，完整 find/replace + 跨会话 undo 属二期。
- **[MEDIUM perf] 编辑器每键触发 O(N) 行号 layout + 全工作台重投影**：长章节会卡。需把行号改 lazy ListView + 投影 debounce，单独优化。
- **[HIGH mobile] 子智能体全屏陷阱 Android 返回键 → 弹「退出应用」**：根 `PopScope(canPop:false)` 收走所有返回事件，子智能体路由是侧栏本地状态、未上抛壳层。需把 active sub-agent id 经 view-data 透到 `handleSystemBackRequested`，plumbing 较重。
- **[MEDIUM] 归档压缩 chip 画展开/收起箭头但点击空操作**：需在侧栏加 expandedItemIds 本地状态做真切换，plumbing。
- **[MEDIUM] stop/error 的 catch 丢部分流式正文（数据丢失）**：catch 用 preflight.sessionState（流式前）而非含部分正文的流式态。涉及核心发送/流式管线，需谨慎实证（哪条取消路径）再改，勿反向引入回归。
- **[MEDIUM] 上下文压力徽章 warning/critical/越界 同色**、**[SMALL] 模式引导 !allowFreeText 时发送仍可点**、**[SMALL] 子智能体运行诊断泄漏 snake_case(run_id/agent_id)**、**[SMALL] 「结构」模式实为元数据信息表而非内容结构 + 偏好切 tab 重置**——均需 moderate plumbing/projection，单独处理。
- **文案低优先**：省略号 `...`/`…`、冒号 `：`/`:`、引号 `「」`/`""`、`重试`/`再试`、`作品`/`项目` 混用——机械统一，价值有限，单独 pass。

### 验证
- `dart analyze lib`：0 error / 0 新告警。
- **全量 `flutter test`：646 通过 / 12 跳过 / 2 失败**（仅 hfvv real_run 需真实 API）。
- Windows release 39.7s 构建通过 + 启动 9s 无崩溃（含设置加载路径改动）。

---

## 第八轮：第七轮暂缓项收口（2026-07-29）

第七轮记录的暂缓项里，把可安全修复的逐项收口：

### 已修
- **[MEDIUM 数据丢失] stop/error 的 catch 丢部分流式正文**：catch 用 `preflight.sessionState`（流式前），把用户刚看到的部分正文擦掉、只剩重试横幅。改用 `streamingBaseState`（含已流式输出，且在 catch 作用域内），无进度时两者相同故安全。`_applyRequestFailure`。同步更新 agent_selection 测试。
- **[MEDIUM] 归档压缩 chip 画展开/收起箭头但点击空操作**：侧栏加 `_collapsedStatusItemIds` 本地状态，`_ConversationStatusDeck` 据此重算各 chip 的 isExpanded，`onItemPressed` 接真切换——带箭头的 chip 现在真能收起/展开。
- **[SMALL] 子智能体「运行诊断」泄漏 snake_case**：`run_id/sub_session_id/agent_id/selected_conflict_id/accepted_conflict_ids` → 运行号/子会话号/智能体 ID/选中的冲突/已采纳的冲突（同步更新投影服务测试）。
- **文案**：长任务空态文案 `「任务中心」→"生成队列"` 混用引号 → 统一 `「」`；用户提示里的 `稍后再试/重新拆书后再试/切换…再试` 统一为 `重试`（与 humanizer 一致），同步更新 snapshot 测试。

### 仍暂缓（记录）
- **[HIGH mobile] 子智能体全屏 Android 返回键陷阱**：根 `PopScope(canPop:false)` 收走所有返回事件，子智能体路由是侧栏本地状态；需把 active sub-agent id 经 view-data 透到 `handleSystemBackRequested`，plumbing 较重，单独做。
- **[MEDIUM] 上下文压力徽章 warning/critical/越界 同色**：需按 pressureLevel 驱动徽章前景色 + tooltip，theming 改动。
- **[SMALL] 模式引导 !allowFreeText 时发送仍可点**：需 view-data 透 `modeGuidanceFreeTextBlocked` 标志进 inputCapability；文案已提示，价值有限。
- **[SMALL] 「结构」模式实为元数据信息表、偏好切 tab 重置**。
- **省略号 `…`/`...` 跨特性不一致**：各特性内部一致（拆书用 `…`、其余用 `...`），跨特性统一属机械 churn，价值有限。
- **feature gap（单独功能）**：资源树重命名/删除/移动、查找/Ctrl+S/undo、编辑器每键 O(N) 行号+全投影性能优化。

### 验证
- `dart analyze lib`：0 error / 0 新告警。
- **全量 `flutter test`：646 通过 / 12 跳过 / 2 失败**（仅 hfvv real_run 需真实 API）。
- Windows release 40.4s 构建通过 + 启动 9s 无崩溃（含发送/流式管线改动）。

---

## 第九轮：搁置项继续收口（2026-07-29）

继续攻第七/八轮记录的暂缓项。本轮收口 6 条（plumbing + perf），余 3 条 feature-sized 单独记录。

### 已修（6 条）
- **[MEDIUM] 上下文徽章 warning/critical/越界 同色**：`ContextStatusBadge` 现按 `pressureLevel` 分色（warning→暖、critical/overLimit→警示），并加 `Tooltip` 展示压力摘要。`ConversationPanelBand` 增可选前景/背景色覆盖。`context_status_badge` + `conversation_panel_band`。
- **[SMALL] 模式引导 !allowFreeText 时发送仍可点**：侧栏 `_inputCapabilities` 据 composerHint（guide 服务固定产出"先从下面的选项"）置灰发送，避免无效点击。
- **[SMALL] 「结构」模式实为元数据 + 偏好切 tab 重置**：chip 改名「信息」（不再伪装成内容结构）；结构偏好改 per-doc `Map<String,bool>` 记忆，切文档再切回保留（与 isRendered 一致）。
- **省略号 `…`→`...` 跨特性统一**：拆书/作品库/模型设置/任务中心截断标记等全部统一为 ASCII `...`（各特性内部此前混用）。
- **[feature] Ctrl+S 保存当前文档**：`WorkbenchPrimaryCanvasHost` 包 `CallbackShortcuts`，Ctrl+S 触发保存（无文档时保存动作自行提示）。
- **[perf] 编辑器行号每键 O(N) 重排**：`DocumentTextEditorSurface._handleControllerChanged` 改 150ms debounce（正文经 onChanged 即时保存，行号晚 150ms 无妨）；dispose 取消定时器。

### 仍暂缓（3 条 feature-sized，附实现路径）
- **[LARGE feature] 资源树删除/重命名/移动**：`ProjectToolHostPort` 已支持 `deleteEntry`/`moveEntry`，但 workbench 未接线。需：①`WorkbenchWorkspaceController` 存 `_projectToolHostPort` 字段；②facade 增 `onDeleteResourceEntryRequested`/`onRenameResourceEntryRequested`（删→关闭路径匹配的已开文档→`_refreshFiles`；重命名→`moveEntry`→更新已开文档路径）；③`WorkbenchFilePanelActionHandler` 增接口；④`resource_tree_card` 给 `ResourceTreeEntryTile` 加长按/右键 context menu（删除含确认、重命名弹输入框）；⑤测试。属正经功能，单独实现。
- **[MEDIUM feature] Ctrl+F 查找**：需跨组件协调（`WorkbenchPrimaryCanvasHost` 的 Ctrl+F 开关 + `DocumentTextEditorSurface` 的查找栏 + 在 `_controller.text` 里定位/选中匹配）。基础版可用"跳转到下一个匹配(设 selection)"，高亮覆盖属二期。
- **[HIGH mobile] 子智能体全屏 Android 返回键陷阱**：根 `PopScope(canPop:false)` 收走所有返回事件；需把 active sub-agent run id 经 view-data 透到 `handleSystemBackRequested`（侧栏 `_detailRoute` 变化时上抛）——接口/控制器/视图模型/侧栏/返回处理 5 处 plumbing。

### 验证
- `dart analyze lib`：0 error / 0 新告警（仅 2 条既有 info）。
- **全量 `flutter test`：646 通过 / 12 跳过 / 2 失败**（仅 hfvv real_run 需真实 API）。
- Windows release 40.0s 构建通过 + 启动 9s 无崩溃。

---

## A. 已直接修复（本轮）

### 设置 / 接口 / 模型
1. **模型页连接测试发错 api_mode** —— `model_settings_panel.dart` 的 `_testConnection` 原本发 `editor.capabilityExposure.apiMode`（已保存值），用户在高级区改的 `_apiMode` 没回读。改为 `_apiMode`。
2. **ConnectionStatusCard 文档与配色** —— 文档串自相矛盾已改；硬编码绿/黄配色改为 `colorScheme.primary/tertiary`，深色主题不再冲突。
3. **接口列表「未配置密钥」无视觉区分** —— 改用 `colorScheme.error`，扫一眼即可定位待补 Key 的接口。`provider_list_pane.dart`。
4. **移动端项目路径禁用无说明** —— 禁用框下补「移动端项目目录固定在应用文档目录内，不能更改。」`context_settings_panel.dart`。
5. **Base URL 空校验文案无指引** —— 改为「可在上方下拉点选厂商模板自动填入，或展开高级设置手动填写」。`provider_detail_pane.dart`。
6. **窄屏首次进接口页要多点一次** —— `providers` 为空时窄屏直接渲染添加表单，不再先弹空列表。`provider_settings_panel.dart`。
7. **项目创建默认表达限制面板文案拗口** —— 重写为通顺中文。`project_creation_expression_constraint_defaults_panel.dart`。
8. **RAG 向量化模型 hint 过长截断** —— hint 缩短为例示，长说明移到框下 helper 行。`model_settings_panel.dart`。
9. **死类 `ProviderDraftViewData` 移除** —— 全仓零引用。

### 创作台 / 对话
10. **切项目/会话时输入框残留上一处草稿** —— `conversation_sidebar` 的 `didUpdateWidget` 现按 `activeSessionId` 变化清空输入控制器。
11. **空文本发送被静默吞掉（按钮像死的）** —— 去掉侧栏的空判，交给控制器 `_sendPrompt` 统一给出「请输入创作需求后再发送。」。
12. **错误文案对 GUI 用户不友好** —— `workbench_conversation_controller`：「provider」→「模型接口配置」；「请先在 novel_agent_settings.json…」→「请先到设置→接口/模型…」。
13. **启动器副标题中文别扭** —— 「接回已有工作区」→「打开已有项目继续」。`project_launcher_overlay.dart`。
14. **主动作找不到时回退文案写死「续写/拆书」** —— 改为通用回退。`conversation_opening_flow_controller.dart`。
15. **移动端「打开已有项目」禁用文案写成「创建」** —— 改正。`project_creation_controller.dart`。
16. **删当前作品后工作台变死寂** —— `_deleteProjectFromProjectOpen` 在重置工作台后追加 `showLauncher(guard, canDismiss:false)`，回到工作台即被引导重新选择/新建。`app_shell_controller.dart`。

### 拆书 / 长任务 / 资料库 / 智能体
17. **RAG 语料模式 ChoiceChip 调错方法（模式实际切不动）** —— 原调 `onProjectAssetsTabSelected('rag_extraction')`（切到自己），改为 `onProjectAssetsEntrySelected(mode.id)`。`project_rag_extraction_panel.dart`。【真 bug】
18. **RAG 工作区按钮加载中「假可点」** —— `() {}` 改为 `disabled:` 真灰化。`project_assets_knowledge_base_rag_workspace.dart`。
19. **长任务总站空态孤零零四字** —— 改为「暂无运行实例。打开小说项目后，在任务中心点"生成队列"即可启动长任务。」`long_task_run_list_panel.dart`。
20. **资料库分类空列表全空白** —— 补空态引导。`project_assets_entry_list_panel.dart`。
21. **智能体生态浏览列表空态空白** —— 补「还没有智能体或技能。点右上"导入生态包"或"生成索引"以开始。」`ecosystem_browser_panel.dart`。
22. **任务中心危险动作无二次确认** —— 「回滚修复」「取消」两个不可逆动作包 `showConfirmationDialog`。`task_center_page.dart`。
23. **拆书「派生项目」入口缺失（功能已实现却不可达）** —— `_ConfirmStep` 补「派生新写作项目」按钮，接 `onBookDeconstructionCreateDerivedProjectRequested`（controller 早已实现）。`book_deconstruction_page.dart`。【隐形功能补回】

---

## B. 暂缓（记录待办，过大或需设计）

### B1 设置反馈通道（最高优先）
- **现象**：全应用无 `SnackBar/ScaffoldMessenger`。`_announce(msg)` 只写 `_viewModel.workbench.generationStatus`，仅工作台 destination 渲染。**所有设置 tab 的「保存」成功提示与校验失败原因都看不到**（要切回工作台才见状态条）。`_persistSettings` 抛异常也沉默。
- **位置**：`app_shell_controller.dart` `_announce`（~5603）与各 settings `onXxxSaved` 校验点。
- **修法**：新增设置可见的瞬态消息通道（控制器 → `SettingsHeader` 临时 banner，或 `ScaffoldMessenger`），保存校验失败同样走它。涉及 7 个 settings 保存回调 + announce 漏斗，touch 面大但机械。

### B2 首次运行工作台无配置引导
- **现象**：provider/model 未配置时，工作台只在模型胶囊显示「未配置模型」，无 banner、无「前往设置」CTA。用户不知要先去接口页加 Key、再绑模型。
- **修法**：`workbench_ide_shell` 顶部条件渲染 banner（`providers.isEmpty || defaultProviderId/defaultModelId 空`）+ 按钮调 `showSettings()`。

### B3 创建向导提交按钮创建期间不置灰
- **现象**：「创建并打开」在 `executePrepared` 等待期间仍可点，重复触发可能产出两个同名目录。
- **修法**：`ProjectLauncherViewData` 加 `isCreating`，创建期置 true，面板据此 `disabled`/`onPressed:null`。

### B4 无活动项目时发送仍可点 + 无「打开设置」入口
- **现象**：发送按钮 `canSendAction` 只看 `isGenerating`，不看 `hasActiveProject`；点了得到误导的「默认项目尚未加载完成」。对话区也无任何「打开设置」入口（`onConversationSettingsRequested` 是死 handler）。
- **修法**：`hasActiveProject` 接进 `ConversationInputCapabilityState` 的 disabled 条件 + disabledReason；对话工具栏加齿轮按钮接 `onConversationSettingsRequested`（或删该死接口）。

### B5 无项目时创作台空态误导到「小说」
- **现象**：`applyConversationState` 在 `currentProject==null` 时仍按 `'novel'` 解析 session guide，显示小说工作台空态而非「请先打开/新建项目」。
- **修法**：`currentProject==null` 时直接产出 no-project 引导。`conversation_guide_view_data_service` + 控制器调用点。（删当前作品后已由 B16 launcher 缓解，但首次无项目路径仍需处理。）

### B6 拆书失败重确认无差异提示
- **现象**：`markPending` 失败后再点「保存拆书结果」会从头重跑全部写入；恢复文案没告诉用户「上次哪步成功、本次会重写哪些」。
- **位置**：`book_deconstruction_confirm_workflow_service.dart`。
- **修法**：按 `failed` journal 的 `currentStep` 给具象提示，或跳过已幂等的 `completedSteps`。

### B7 拆书取消按钮藏顶栏 + 粘贴模型降级静默
- **现象**：8 分钟级长操作的取消按钮只在工具栏右上角，步骤卡片内无；粘贴内容 + 勾「使用模型」会被静默降级为规则分章，仅状态条一句尾注。
- **修法**：步骤卡片标题行加「取消」（仅 `isLoading` 时露）；`_SplitStep` 在 sourcePath 空且勾了模型时显示警示或禁用勾选。

### B8 长任务总站重新进入不刷新 + 任务中心空队列报成功
- **现象**：`decide()` 在「已初始化且未开自动刷新」时不刷新，重进总站看到的是离开时快照。任务中心「连续运行」在 `no_runnable_task`（0 任务）时仍 `ok=true` 显示「队列运行已推进」。
- **修法**：`LongTaskStationVisibilityRefreshService.decide`/控制器增加「重入刷新一次」信号；`task_center_command_orchestration_service._resultMessage` 读 `stop_reason/stop_note` 区分真假推进。

### B9 任务中心数字输入静默回落 + 链路 Markdown 当纯文本 + 按钮永不置灰
- **现象**：章节字数等 `int.tryParse ?? 默认值`，输入「2.000/两百」静默用默认；链路树/日志 Markdown 字面展示 `## - **`；16 个运行动作按钮无 disabled，永远可点。
- **修法**：解析失败给 errorText/状态条报错并阻提交；换 `flutter_markdown` 的 `MarkdownBody`；动作按钮按 `commandInFlight/selected==null/settings==null` 透传 `disabled`。

### B10 资料库入库降级提示埋尾 + 索引后端字段条件显示
- **现象**：embedding 降级（仅关键词检索）说明被括号包在成功消息尾部，用户易忽略；「索引后端」仅 label 非空才显示，不足以传达「以后检索将不用向量」。
- **修法**：降级说明抽到 view data 独立 `degradationWarning`，banner/警示色渲染；「检索方式」做成必显字段。

### B11 智能体装载假禁用 + 未应用无高亮
- **现象**：`_availabilityGate` 用 `IgnorePointer+Opacity` 而非真 disabled（保留 hover，像「加载中」）；「应用装载」按钮在有未应用改动时不高亮，用户易以为已自动保存。
- **修法**：透传 `ActionButton.disabled`；`hasPendingChanges` 时切 `ActionButtonTone.warm` 或加 dot badge。

### B12 恢复路径踢皮球 + detail 加载失败与空态混淆 + resume 语义模糊
- **现象**：`record_relative_path` 缺失时提示「去任务中心」，但任务中心又不自动选中该 run；总站 detail 把「读取失败」与「干净空」用相同弱文案呈现；「重试当前步骤」与「恢复推进」底层都跑整条队列重入，「重试」可能跳过失败任务。
- **修法**：错误文案带项目/运行上下文 + 自动选中 run（`onTaskCenterLongTaskRunSelected`）；detail 在加载失败时折叠元数据、放大错误 + 重试；resume label 与底层语义对齐（或真正单步重试）。

### B13 重设计后的死代码
- `_providerConnectionValidationResults` 缓存、`SettingsViewData.providerConnectionValidationResult`、`ProviderEndpointViewData.connectionValidationResult`：重设计后无写入、无 widget 消费，write-only。移除安全但牵连投影/copyWith。
- `_settingsSections` / `tabSections` / `SettingsOverviewPanel`：7 个 tab 都有专属面板，overview 永不命中，死代码。

---

## C. 已诚实（核验无缺陷，备忘）

- 附件入口三处事实源全 `false`，门面二次 refuse，无可达路径。
- 作品库删除路径安全（projectsRoot 子路径校验、不能删根、当前项目清理、defaultProjectPath 清空、forceRefresh）。
- 流式中断正确区分「已停止」与「已停止但保留已完成阶段」。
- 生成失败走 `UserFacingErrorHumanizer`；`_hydrateLoadedProject` finally 清「正在…」态，不会永久转圈。
- 接口/模型重设计后 grep 无悬空引用（`preferredModelId`/`onProviderConnectionTestRequested` 全清）。

---

## 建议下一波优先级
1. **B1 设置反馈通道** —— 影响所有设置保存的感知，ROI 最高。
2. **B8 任务中心空队列报成功 + B9 数字校验/Markdown** —— 长任务卖点可信度。
3. **B2 首次运行引导 + B5 无项目空态** —— 新用户第一印象。
4. **B3/B4 创建按钮置灰 + 发送置灰 + 设置入口** —— 防误操作与闭环。
5. 其余 copy/视觉/dead-code 随手清。

---

## 第十轮（2026-07-29）—— 第九轮搁置的 3 条 feature-sized 全部收口

用户明确「把搁置的攻完」。第九轮记录为 feature-sized、附实现路径的 3 条，本轮全部实现并验证。

### 1. 资源树删除 / 重命名 / 移动
- 价值：写小说却不能在应用内删/改名章节文件——最高频缺口。
- 实现：`ProjectToolHostPort.deleteEntry / moveEntry`（适配器层已含 SQLite 结构化内容同步、目录递归删除、文件/目录分支）首次接到 UI。
  - `WorkbenchFilePanelActionHandler` 加 `onDeleteResourceEntryRequested(entryId)` / `onRenameResourceEntryRequested(entryId, nextName)`；`ResourceManagerActionHandler` 经 `implements` 自动继承。
  - `WorkbenchWorkspaceController` 新增字段 `_projectToolHostPort`（构造早已注入，此前只透传给服务、未存）；私有 `_deleteResourceEntry`（删除前先 `_closeOpenDocumentsUnder` 关闭路径匹配的已开标签、含目录递归）与 `_renameResourceEntry`（`moveEntry` 后 `_rebaseOpenDocuments` 把文件/目录下已开标签的 `id`/`relativePath`/`title` 一并迁移，保留 `isDirty`/`isRendered`，避免重命名后「编辑内容看似丢失」）。
  - `WorkbenchProjectActionFacade` + 控制器 `@override` 转发；`resource_manager_panel` 把 view-model 形态回调桥接为 primitive；`resource_tree_card` → `resource_tree_entry_tile` 增加 `_EntryMenuTrigger`（⋯ `PopupMenu`），删除走共享 `showConfirmationDialog`（目录提示含子项数 + 未保存草稿会丢，文件提示同理），重命名走 `_RenameEntryDialog`（预填 basename、默认选中主名部分以便整体替换）。
  - 约定：`entry.id == relativePath`（既有投影已如此），故接口保持 primitive 风格。

### 2. Ctrl+F 查找
- 实现：完全收在 `DocumentTextEditorSurface`（它持有正文 `TextEditingController`，是唯一直接知道全文又能定位/选中匹配的位置）——零控制器 plumbing、零视图数据改动。
  - `CallbackShortcuts` 绑定 Ctrl+F（展开/聚焦查找栏）与 Escape（收起）；另加一个常驻放大镜 `IconButton`（右下角）作为移动端 / 可发现入口（查找栏打开时让位给其关闭按钮）。
  - `_buildFindBar`：查询输入 + `x/y` 匹配计数（无匹配用警示色）+ 上/下一个（回绕）+ 关闭；回车跳下一个。
  - 定位：`_refreshMatches`（indexOf 循环）→ `_applySelectionForCurrentMatch`（选中匹配，EditableText 自动滚动）+ `_scrollToOffset`（按固定 strut 行高估算，尽量把匹配带到视口中部）。
  - 只读模式也可用（选择不需编辑）；外部内容更新时若查找栏开着则重算匹配。

### 3. 子智能体全屏 · Android 返回键陷阱
- 问题：根 `PopScope(canPop:false)` 把所有系统返回事件收到 `handleSystemBackRequested` → 全屏开着时弹「退出应用？」而非关闭全屏。嵌套 `PopScope` 在本工程不可靠（同路由多 `PopScope` 触发顺序不利）。
- 实现：壳层加**通用「前台返回键接管」注册表**，让侧栏的本地态（`_detailRoute`）对返回键可见——不必把本地态搬到视图数据：
  - `ConversationActionHandler.setForegroundBackHandler(void Function()? handler)`（侧栏经此注册/取消）。
  - `WorkbenchConversationController` 转发到壳层注入的可选回调（`setForegroundBackHandler` 为可选构造参，单测不传则空操作）。
  - `AppShellController`：字段 `_foregroundBackHandler` + `handleSystemBackRequested` 顶部先消费它（优先于所有覆盖层）。
  - `conversation_sidebar`：`_detailRoute` 监听器 + `didUpdateWidget` 同步——全屏打开注册 `_clearActiveSubAgentRun`，关闭/无全屏取消；`dispose` 先取消再释放。
  - 接口用 `void Function()` 而非 `VoidCallback`（contracts 文件不引 flutter）。

### 影响 / 测试
- 接口新增方法 → 机械补 no-op 测试假桩：`WorkbenchFilePanelActionHandler`（13 桩）+ `ConversationActionHandler`（10 桩），用子代理批量处理。
- 新增 3 个行为测试：资源菜单删除/重命名经 handler、查找匹配计数与回绕、全屏注册/清返回键接管（模拟系统返回调用注册回调→关闭全屏→取消接管）。

### 验证
- `dart analyze lib test`：**0 error**（17 既有 info/warning，零新增）。
- 全量 `flutter test`：**649 过 / 12 跳 / 2 失败**——失败仅 `hfvv_*_real_run`（需 `local/probe_api.txt` 真实 API，环境依赖）；646→649 的增量正是新增 3 测试。
- `flutter build windows --debug`：成功（20.5s 增量）。

---

