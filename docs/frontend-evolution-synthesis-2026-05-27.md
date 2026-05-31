# 前端演化综合方案（2026-05-27）

最后更新：2026-05-27

## 1. 这份文档的目的

这不是一份“微调当前 UI”的文档。

这是一次正式的前端演化收束，目标是把 NovelAgentFlutter 重构成：

- 易用的
- 可用的
- 美观的
- 轻便的
- 流畅的
- 面向长期扩展的

工作台。

本轮综合吸收的参考对象：

- `references/DeepSeek-TUI-main`
- `references/Writingway-main`
- `references/assets/ai_images_052601/*`
- `docs/conversation-system-audit-2026-05-27.md`
- `docs/ui-absorption-analysis-2026-05-26.md`

说明：

- `DeepSeek-TUI-main` 与 `Writingway-main` 都是 **MIT** 许可项目
- 本文吸收的是 **信息架构、交互思想、状态边界、性能意识、视觉语言方向**
- 不应机械复制其源码结构或具体实现细节

---

## 2. 新的总体判断

之前我们的判断偏向：

- “把现有三栏工作台继续打磨”

现在这个判断要升级成：

- “把工作台重构为一个 **以创作工作流为中心** 的多层工作区系统”

也就是说，未来前端不再是“资源栏 + 文档栏 + 会话栏”的静态拼盘，而是：

1. **全局壳层**
2. **工作区导航层**
3. **主画布层**
4. **智能体协作层**
5. **辅助工作层**

共同组成的正式产品前端。

这一点，是这次从 DeepSeek TUI 和 Writingway 里最值得吸收的共同精神：

- DeepSeek TUI 强在“**运行时节奏、事件可见性、低干扰状态表达**”
- Writingway 强在“**写作主工作区、辅助面板切换、创作上下文围绕正文组织**”

我们的新方案，应该是二者融合，而不是偏向其中之一。

---

## 3. 对两个参考项目的批判性吸收

## 3.1 DeepSeek TUI：应该吸收什么

### 3.1.1 Streaming-first，但不是 token-first 乱刷

DeepSeek TUI 最有价值的一点，不是终端皮肤，而是它对流式更新有明确节奏控制：

- chunker
- commit tick
- adaptive chunking
- 工具输出与正文流式分轨

可吸收理念：

- 流式 UI 不是“来一个 token 刷一次树”
- 应该有单独的 **streaming cadence 层**
- 正文流、工具流、状态流不能共用同一刷新节奏

对我们的要求：

- 会话系统必须从“数据来了就全量投影”升级到“分轨、合帧、按层提交”

### 3.1.2 Transcript 是事件时间线，不是字符串堆

DeepSeek TUI 对 transcript 的理解更成熟：

- 普通消息
- 工具卡片
- pending input preview
- 子智能体完成事件
- 状态 chip

这些都是不同的时间线对象。

可吸收理念：

- 会话卷轴应该渲染 **语义块**
- 不能只靠 `title/body/detailBody` 这种弱结构字符串模型撑下去

对我们的要求：

- 建立正式的 transcript block 合同
- 让工具、子智能体、选项、检查点、重试、待发送输入都成为一等块类型

### 3.1.3 运行时状态要低干扰、持续可见

DeepSeek TUI 里很重要的一点是：

- 状态不是大块弹窗
- 不是把主内容顶来顶去
- 而是用 footer / chip / card / queue preview 这种低干扰方式表达

可吸收理念：

- “正在生成”
- “有待发送输入”
- “有后台子任务”
- “有工具执行”

这些都应该以轻量、持续、稳定的位置表达。

对我们的要求：

- 不要再让“工具调用/运行状态”不断挤压正文和会话主体
- 需要专门的 runtime status strip / pending area / task badge

### 3.1.4 持久任务与前台对话要解耦

DeepSeek TUI 的任务、子智能体、runtime thread 是分开的。

可吸收理念：

- 长任务不是页面状态
- 子智能体不是“补一段文本”
- 后台执行对象应该有独立生命周期

对我们的要求：

- 长任务站、子智能体运行、会话主线程必须继续拆开
- 前端只做关联与投影，不把它们塞回单个会话 controller

### 3.1.5 模式与权限是显式的

DeepSeek TUI 会显式暴露：

- plan / agent / yolo
- reasoning 强度
- provider/model
- queue/task/job

可吸收理念：

- 用户要知道当前智能体处于什么运行姿态
- 不能只看到“一个输入框 + 一段输出”

对我们的要求：

- 在会话/长任务运行时，要有清晰的 mode/status/profile 表达

---

## 3.2 DeepSeek TUI：不该直接吸收什么

### 3.2.1 终端式强密度排布本身

它的高密度是终端环境的产物，不是我们 GUI 的终局。

不该吸收：

- 纯终端式压缩密度
- 过度命令化入口
- 对普通用户不友好的键盘优先表达方式

我们的 GUI 应保持：

- 可扫描
- 可点击
- 可折叠
- 可回看

### 3.2.2 把所有高级运行概念都暴露出来

DeepSeek TUI 会把很多运行时概念公开给重度用户。

我们不能直接照搬，否则会让写作用户感到系统太硬核。

应该做的是：

- 底层保留
- 上层用更人类的创作语义表达

---

## 3.3 Writingway：应该吸收什么

### 3.3.1 写作工作区围绕“正文主画布”组织

Writingway 的核心不是聊天，而是：

- 左侧切换面板
- 中间主编辑器
- 下面辅助生成/总结/上下文区

这说明它把“写作对象”而不是“AI 对话”放在中心。

可吸收理念：

- 对小说项目来说，正文/章节/资源是主对象
- AI 协作是围绕正文发生的

对我们的要求：

- 中间栏必须继续是主画布
- 会话栏要强，但不能把正文区压成附庸

### 3.3.2 Activity bar + switchable side panels

Writingway 的 activity bar 很值得吸收：

- 一个稳定、窄而明确的入口层
- 左侧大栏位只展示当前选中的一个工作面板

可吸收理念：

- 导航层与内容层分离
- 资源树、搜索、资产、提示模板、上下文，不该一起堆出来

对我们的要求：

- 左侧应该是：
  - 极窄稳定入口条
  - 可切换的侧边工作面板

### 3.3.3 Bottom stack / auxiliary work area

Writingway 的 bottom stack 很关键。

它说明创作工具并不总适合塞到右栏会话里。

可吸收理念：

- 有些 AI 能力是“对正文进行加工”
- 有些能力是“对会话进行协作”
- 这两者应该有不同的空间位置

对我们的要求：

- 我们需要一个 **辅助工作层**
- 例如：
  - 章节分析
  - 重写预览
  - Prompt 预览
  - 上下文选择
  - 片段润色

它们不该都挤到会话卷轴里

### 3.3.4 Focus mode 是正式能力，不是装饰页

Writingway 的 focus mode 表达了一个重要方向：

- 写作时，沉浸式单任务画布是独立需求

对我们的要求：

- 未来 NovelAgent 应该有正式 focus mode
- 但它应服务于真实写作，而不是只做视觉秀

### 3.3.5 Prompt preview / send / stop / context toggle 明确分离

Writingway 在底部把这些动作拆开了：

- prompt 配置
- preview
- send
- stop
- context

可吸收理念：

- 不同性质的动作不能用一个“发送”吞掉

对我们的要求：

- 我们的 composer 区必须继续拆成多个明确定义的动作区块

---

## 3.4 Writingway：不该直接吸收什么

### 3.4.1 单个窗口类过度臃肿

Writingway 的 `project_window.py` 很典型：

- 能力很丰富
- 但控制器/窗口类过重

这正是我们不该重复犯的错误。

不能吸收：

- 一个主窗口管所有布局与业务
- 直接在 UI 类里调度大量状态和线程

### 3.4.2 过多次级功能直接挂顶层

Writingway 有不少顶层工具入口：

- workshop
- whisper
- web llm
- archive
- focus mode

理念可以吸收，但入口组织不能照搬。

我们的系统需要：

- 统一入口策略
- 分层导航
- 不让顶栏变成功能堆场

---

## 4. 我们的新前端目标模型

## 4.1 五层模型

未来前端应按以下五层组织：

### 第一层：Shell Layer

负责：

- 全局导航
- 主题
- 桌面/窄屏骨架
- 全局通知

不负责：

- 会话数据
- 文档数据
- 资源数据

### 第二层：Workbench Navigation Layer

负责：

- Activity rail
- Side panel 切换
- 当前工作区入口

这层吸收 Writingway。

### 第三层：Primary Canvas Layer

负责：

- 文档正文
- Markdown / 纯文本 / 结构化资源 / 图谱 / 预览
- focus mode 的主对象

这层是创作核心。

### 第四层：Assistant Collaboration Layer

负责：

- 会话时间线
- 工具块
- 子智能体块
- 用户选项块
- pending input preview
- runtime status strip
- composer

这层吸收 DeepSeek TUI。

### 第五层：Auxiliary Work Layer

负责：

- prompt preview
- rewrite preview
- review / analysis / repair
- 上下文挑选
- 章节分析与建议

这层吸收 Writingway 的 bottom stack 思想。

---

## 4.2 工作台新的信息架构

### 桌面端

建议正式收束为：

1. **全局活动轨**
   - 极窄
   - 负责项目、工作区、长任务站、资产中心、设置等一级切换

2. **工作区侧栏**
   - 单次只展示一个面板
   - 面板来源：
     - 项目树
     - 搜索
     - 资产
     - Prompt/模式
     - 任务/检查点

3. **主画布区**
   - 文档/资源为主
   - 可垂直分裂出辅助工作层

4. **协作区**
   - 会话时间线
   - 状态条
   - 输入与模型控制

这依然满足“三栏模式保留”，但会变成更正式的：

- 入口轨
- 可切换侧栏
- 主画布
- 协作区

而不是简单三块固定拼接。

### 窄屏端

建议收束为：

- 主视图默认会话或正文二选一
- 保留你认可的抽拉式功能栏
- 文件/资产/搜索等不常驻
- 会话为主时，仍保有稳定入口，不再“功能消失”

---

## 5. 会话系统的新目标

这部分与 `docs/conversation-system-audit-2026-05-27.md` 联动。

## 5.1 Transcript block model

新的会话卷轴应渲染这些块类型：

- `message.user`
- `message.assistant.streaming`
- `message.assistant.final`
- `tool.compact`
- `tool.detail`
- `subagent.preview`
- `subagent.detail`
- `choice.group`
- `pending.input.preview`
- `retry.banner`
- `checkpoint.card`
- `runtime.notice`

而不是继续只靠通用 message tile。

## 5.2 Streaming cadence model

吸收 DeepSeek TUI 之后，我们应该明确：

- streaming text cadence
- tool status cadence
- shell/job/subagent completion cadence

三者是不同的。

## 5.3 Pending input preview

这是 DeepSeek TUI 最应该尽快吸收的一个 GUI 思想。

当 AI 正在生成时：

- 用户后续输入
- 待发送选项
- 追加上下文

不该静默丢失，也不该只能塞在输入框里。

应有专门 preview 区。

## 5.4 Tool cards

工具不应再只是平铺文本。

应吸收：

- 语义家族
- 完成/失败状态
- 可展开细节
- 折叠态摘要

但要以 GUI 方式表达，不照搬终端卡片。

---

## 6. 主画布系统的新目标

## 6.1 主画布是资源画布，不只是文本编辑器

这点与之前 `ui-absorption-analysis-2026-05-26.md` 一致，但现在要升级。

主画布未来应支持：

- 章节正文
- Markdown 资源
- 纯文本资源
- 项目结构资源
- 角色 / 组织 / 时间线 / 伏笔等资产
- 图谱 / 时间线 / 关系预览
- review / analysis / rewrite preview

因此必须有：

- renderer registry
- display mode contract
- resource type contract

## 6.2 辅助工作层作为主画布的子层

建议不要把所有分析都塞右栏。

更好的方式是：

- 主画布下方可展开辅助层
- 用于：
  - prompt preview
  - rewrite diff / rewrite result
  - review suggestion
  - chapter analysis
  - context selection

这会让“围绕正文工作”的体验明显更合理。

---

## 7. 视觉语言新方向

## 7.1 总体风格

综合参考后，推荐的视觉方向是：

- 安静
- 明确
- 结构化
- 偏专业创作工具
- 不营销化
- 不游戏化

应该避免：

- 大面积装饰性背景
- 不必要的发光和模糊
- 过重的拟物卡片堆叠

## 7.2 哪些风格来自哪里

### 来自 DeepSeek TUI

- 清晰的状态层级
- 工具状态轻量外显
- 低干扰运行反馈
- 统一语义组件词汇

### 来自 Writingway

- 写作导向布局
- 工作区层次
- 可切换侧边功能面板
- 主画布优先

### 来自参考图

- 更好的桌面三栏配色比例
- 更克制的背景和区块分隔
- 输入区与模型控制区的统一编排

---

## 8. 对我们当前设计的推翻与保留

## 8.1 必须保留

- 多项目模式 / 多策略模式
- 长任务与普通项目平行
- 三栏桌面模式
- 会话卷轴模式
- 文件/资源入口

## 8.2 必须推翻

- `AppShellController` 作为超大广播源的现状
- `WorkbenchViewData` 过度一体化
- 会话区“只要流式就整页刷新”的现状
- 中间栏“本质仍只是文档编辑器”的现状
- AI 能力都挤在右栏会话里的现状

## 8.3 应该新增

- activity rail
- switchable side panel host
- primary canvas renderer registry
- auxiliary work layer
- transcript block registry
- page-scope notifier
- streaming cadence model

---

## 9. 正式架构建议

## 9.1 前端领域切分

建议在 Flutter 端正式切成：

- `shell`
- `workbench_navigation`
- `workspace_canvas`
- `assistant_transcript`
- `auxiliary_work`

而不是继续由 `workbench` 一域吞掉。

## 9.2 状态边界

必须拆成至少这些 notifier / controller 边界：

- `ShellState`
- `WorkbenchNavigationState`
- `WorkspaceCanvasState`
- `ConversationPaneState`
- `AuxiliaryWorkState`

## 9.3 组件注册机制

建议正式采用注册式设计：

- `SidePanelRegistry`
- `ResourceRendererRegistry`
- `TranscriptBlockRendererRegistry`
- `WorkbenchModeRegistry`

这比写死 if/else 更符合我们“多策略、可持续演化”的项目方向。

---

## 10. 实施优先级

## 第一优先级：性能与状态边界

先做：

- Shell 监听边界拆分
- WorkbenchViewData 拆分
- Conversation pane 独立 notifier
- Streaming appendix / cadence 正式化

原因：

- 这是“流畅”的基础

## 第二优先级：工作台骨架重构

再做：

- activity rail
- side panel host
- desktop 三栏骨架重排
- compact 抽拉工作区

原因：

- 这是“易用、正式项目化”的基础

## 第三优先级：主画布升级

再做：

- renderer registry
- display mode contract
- auxiliary work layer

原因：

- 这是“真正围绕小说创作工作”的基础

## 第四优先级：会话语义块升级

再做：

- tool cards
- pending input preview
- subagent block system
- checkpoint / retry / runtime notice blocks

原因：

- 这是“协作体验优雅”的基础

## 第五优先级：沉浸模式与高级工作流

最后做：

- focus mode
- richer prompt preview
- review / rewrite / analysis integrated workspace

---

## 11. 这轮之后的基线结论

从现在开始，我们不再把前端目标理解为：

- “把已有工作台补齐”

而应理解为：

- “构建一个以创作主画布为中心、以协作智能体为右侧运行层、以切换式工作面板为导航层、以辅助工作层承接分析/重写/预览的正式工作台系统”

一句话收束：

- **DeepSeek TUI 教我们如何让智能体运行时优雅可见**
- **Writingway 教我们如何让写作工作区围绕正文组织**
- **NovelAgentFlutter 要做的是把这两者融合成真正适合长篇创作的现代前端**

---

## 12. 后续文档关系

这份文档是新的总纲。

后续建议：

- `docs/conversation-system-audit-2026-05-27.md`
  - 继续作为会话性能与状态审计文档
- `docs/ui-absorption-analysis-2026-05-26.md`
  - 保留为第一轮图片吸收记录
- 后续新增：
  - `docs/frontend-evolution-session-order.md`
  - 用于真正按会话切分实施
