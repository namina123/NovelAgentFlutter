# NovelAgentFlutter 协作栏组优先重构顺序文档

最后更新：2026-05-28

关联文档：

- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`
- `docs/ui-simplification-session-order-2026-05-28.md`

---

## 1. 目标

这条线只做一件事：

**把当前工作台的协作栏、项目栏和输入区，收束成真正的“组优先、单主智能体、动态能力、低噪声”交互。**

它不是新功能堆叠，而是把已经存在但互相打架的能力重新组织。

---

## 2. 总执行规则

后续按本文件推进时，默认遵循：

1. 一次会话只完成一个 session。
2. 如果上轮停在半截，或出现强关联回归，先补完，不开启下一轮。
3. 优先拆合同和服务，不把判断继续塞进大 widget 或大 controller。
4. 尽量不要让单文件过重；如果目标文件已经很大，应先抽小组件或小服务。
5. 先做可复用逻辑，再做 UI 层压缩。
6. 合适时补 focused test，不把这条线拖成纯手工点点看。

---

## 3. Session GF-01：建立 group-first 协作选择合同

### 本轮目标

把“当前项目协作选择”的正式入口从单智能体切到智能体组，并让 UI 读到“当前组 + 当前主智能体派生结果”，而不是继续直接读一堆 agent 选项。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/ui-simplification-cli-alignment-plan-2026-05-28.md`

### 必须完成

1. 梳理并固定“当前项目默认只选择一个智能体组”的读写合同
2. 明确“当前主智能体”为组解析结果，而不是独立主选择器
3. 会话 view data 中补齐：
   - 当前组显示文案
   - 当前主智能体显示文案
   - 是否允许切换组
4. 停止把右下角第二选择器继续建模为“智能体”
5. 保持现有 opening 绑定、项目绑定、默认组兜底逻辑可回归

### 本轮不要做

- 不做右栏视觉紧凑化
- 不接附件和深度思考按钮
- 不改左栏项目面板

### 本轮重点拆耦

- `group-first conversation selector contract`
- `project group -> primary agent projection`
- `conversation view data projection`

### 完成判定

- 当前项目协作选择在语义上正式以智能体组为主
- 当前主智能体从组中派生，不再作为平级主入口暴露
- 后续 UI 压缩时不必再猜“到底该显示组还是显示智能体”

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-01 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/ui-simplification-cli-alignment-plan-2026-05-28.md。只处理 group-first 合同：把当前项目协作选择正式收束为“只选一个智能体组”，并从组解析当前主智能体显示结果；不要继续把右下角第二选择器建模成单智能体入口。不要顺手做附件、深度思考按钮和右栏视觉压缩。注意把判断留在服务层和 view data 投影层，不要堆回大 controller。
```

---

## 4. Session GF-02：建立输入能力投影合同

### 本轮目标

把输入区从“所有非发送能力都先硬编码关闭”的过渡状态，升级成正式能力投影。

### 预计改动量

- 约 `700 ~ 1500` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`

### 必须完成

1. 为输入区建立正式 capability projection
2. 至少支持这些能力位：
   - 附件
   - 深度思考
   - 停止
   - 工具显示入口是否保留
3. 附件入口只在桌面端显示
4. 深度思考按模型能力与当前主智能体/当前模型动态显示
5. 生成态停止按钮要成为正式能力，不再永久隐藏

### 本轮不要做

- 不压缩右栏整体布局
- 不重做 opening panel
- 不改左栏项目操作

### 本轮重点拆耦

- `composer capability projection service`
- `model-aware reasoning toggle contract`
- `desktop-only attachment exposure policy`

### 完成判定

- 输入区能力不再靠硬编码常关
- 能力显隐可解释、可复用、可测试
- 右栏后续只需换布局，不必重写能力判断

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-02 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/collaboration-pane-group-first-session-order-2026-05-28.md。只处理输入能力投影：为附件、深度思考、停止、工具显示入口建立正式 capability projection，附件仅桌面端显示，深度思考按当前模型/主智能体动态出现。不要顺手压缩右栏整体布局，也不要改左栏。注意把能力判断放进独立服务，不要塞进 widget if/else。
```

---

## 5. Session GF-03：右栏协作区紧凑化与组入口正式化

### 本轮目标

在前两轮合同稳定后，正式把右栏收成“组优先的紧凑协作区”。

### 预计改动量

- 约 `1000 ~ 1800` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`

### 必须完成

1. 右下角只保留：
   - 模型
   - 智能体组
2. 当前主智能体改成只读摘要，不再作为第二主选择器
3. 上下文/工具/运行状态改成紧凑单行摘要优先
4. 输入区与选择区作为一个连续 composer 区，而不是两个相互割裂的面板
5. 收掉明显双行、双列、双块的冗余占高

### 本轮不要做

- 不改左栏项目面板
- 不扩新业务能力
- 不重做中栏文档渲染

### 本轮重点拆耦

- `compact conversation status projection`
- `composer block layout`
- `group-first selector strip`

### 完成判定

- 右栏看起来更像正式协作区，而不是调试面板堆
- 用户能直接找到智能体组入口
- 智能体选择不再和组选择打架

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-03 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/collaboration-pane-group-first-session-order-2026-05-28.md。只处理右栏协作区紧凑化：右下角只保留模型和智能体组选择，当前主智能体改成只读摘要；上下文、工具显示、运行状态收成紧凑单行摘要；输入区与选择区合成一个连续 composer。不要顺手改左栏和中栏 renderer。注意拆分状态投影和布局组件，不要把所有压缩逻辑塞进一个 widget。
```

---

## 6. Session GF-04：左栏项目面板去工具条化

### 本轮目标

去掉左栏“主导航旁边又挂一组小图标工具条”的旧味道，把项目面板收成真正的项目侧栏。

### 预计改动量

- 约 `700 ~ 1400` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`

### 必须完成

1. 收掉 `ProjectActionGroup` 这种小图标工具条式入口
2. 保留少量明确项目动作，但换成更语义化的入口形态
3. 左栏继续只表达三类对象：
   - 文件
   - 项目
   - 长任务
4. 减少项目面板中“动作区 / 信息区 / 配置区”之间的重复边框和切割
5. 不再让左栏看起来像二级工具箱

### 本轮不要做

- 不重做资源树
- 不改右栏能力判断
- 不扩新项目操作

### 本轮重点拆耦

- `project panel semantic action list`
- `project metadata summary`
- `sidebar visual density cleanup`

### 完成判定

- 左栏主语义清晰
- 小图标按钮不再显得像遗留调试工具条
- 项目面板更像“当前项目说明与配置”

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-04 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/collaboration-pane-group-first-session-order-2026-05-28.md。只处理左栏项目面板：去掉小图标工具条式项目动作，保留少量语义明确的项目入口，让左栏继续只表达 文件/项目/长任务 三类对象，并减少重复边框和切割。不要顺手重做资源树和右栏。注意把项目动作、项目信息和视觉密度处理分层。
```

---

## 7. Session GF-05：全局边框/分栏减噪与视觉回归

### 本轮目标

做一轮纯收口，把“到处是盒子、到处是分栏”的视觉噪声降下来，但不改业务边界。

### 预计改动量

- 约 `800 ~ 1600` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`

### 必须完成

1. 检查工作台中重复的分栏、边框、section 壳
2. 去掉无明确层级收益的边框和嵌套壳
3. 统一中栏、右栏、左栏的表面密度
4. 保持信息不丢失，只做视觉减噪
5. 回填哪些地方仍保留较重结构，以及原因

### 本轮不要做

- 不扩新业务能力
- 不再改 group-first 合同
- 不再重写主控制器

### 本轮重点拆耦

- `surface density cleanup`
- `section nesting audit`
- `visual regression notes`

### 完成判定

- 工作台整体不再显得像许多调试框拼起来
- 视觉重心重新回到内容与协作
- 剩余结构边框都有明确理由

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-05 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/collaboration-pane-group-first-session-order-2026-05-28.md。只做边框和分栏减噪回归：清掉工作台里无明确收益的重复边框、section 壳和视觉分栏，统一左中右三栏的表面密度，但不要改变业务边界。注意把视觉减噪和业务逻辑完全分离，必要时新增小样式组件而不是往现有大组件里继续堆条件。
```

---

## 8. Session GF-06：联调、截图、探针与 Windows 打包前回归

### 本轮目标

确认这条线在实际路径上闭环，再进入打包。

### 预计改动量

- 约 `500 ~ 1200` 行

### 必读文档

- `agent.md`
- `docs/collaboration-pane-group-first-analysis-2026-05-28.md`
- `docs/collaboration-pane-group-first-session-order-2026-05-28.md`
- 前面各 session 完成记录

### 必须完成

1. 回归至少这些路径：
   - 打开已有项目
   - 继续已有项目协作
   - 切换项目智能体组
   - 观察当前主智能体派生显示
   - 附件入口桌面端可见性
   - 深度思考入口按模型动态可见性
   - 生成中停止动作
2. 做一次 focused widget/integration test 补强
3. 做一次实际界面截图核对
4. 回填文档与打包前结论

### 本轮不要做

- 不开新主线
- 不借回归之名再改信息架构

### 本轮重点拆耦

- `group-first regression probe`
- `composer capability regression`
- `packaging readiness notes`

### 完成判定

- 当前这条线已经从合同、UI 到体验闭环
- 可以安心继续打包验证

### 建议提示词

```text
按 docs/collaboration-pane-group-first-session-order-2026-05-28.md 的 Session GF-06 执行。先阅读 agent.md、docs/collaboration-pane-group-first-analysis-2026-05-28.md、docs/collaboration-pane-group-first-session-order-2026-05-28.md，以及前面各 session 完成记录。只做联调回归：验证打开项目、继续协作、切换项目智能体组、当前主智能体派生显示、桌面端附件入口、按模型动态出现的深度思考入口、生成中停止动作，并补 focused test 与截图结论。不要开新主线。
```
