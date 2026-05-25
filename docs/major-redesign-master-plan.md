# NovelAgentFlutter 大重构总设计

最后更新：2026-05-25

## 0. 文档定位

这是一份面向下一阶段“大刀阔斧重构”的总设计文档。

它不是单个功能说明，也不是单个模式设计，而是要统一回答下面这些问题：

1. 当前项目哪些地方已经明显不合理，为什么必须重构
2. 哪些既有方向必须保留，不能在重构中丢失
3. 参考项目中有哪些可吸收优点，应如何融合到我们的架构
4. 新的项目结构、运行结构、长任务结构、资产结构应怎样定义
5. GUI、CLI、core、adapters 之后应怎样继续收口
6. 长任务模式如何扩展成一组真正平行、可持续演化的策略

这份文档是以下文档的上位收束：

- `agent.md`
- `docs/architecture.md`
- `docs/strategy-first-predesign.md`
- `docs/long-task-mode-1-architecture.md`
- `docs/long-task-mode-2-implementation-order.md`
- `docs/mumuainovel-absorption-analysis.md`
- `docs/absorption/20-synthesis/*`

它的角色不是替代这些文档，而是把它们提升为一份“下一轮全面改造的总图”。

## 1. 先给结论

项目下一阶段不应该继续沿着“在现有页面和控制器上不断补洞”的方向前进。

应该直接进入：

`策略重整 + 运行层收束 + 资产层统一 + 项目结构重排 + 长任务中心化`

也就是说，我们要同时做五件事：

1. 保留“多项目类型 + 多模式策略”的正确方向
2. 把长任务从“项目内部的一个页面功能”提升为“全局可持续运行的运行系统”
3. 把风格、角色卡、伏笔、上下文策略、审稿、重写这些共享能力从模式里剥出来，形成真正的共用层
4. 把项目目录和隐藏状态重新规划成“用户可读资产 + 系统可恢复索引”的双层结构
5. 把 GUI 和 CLI 继续压到同一套 runtime / strategy / asset core 之上

## 2. 这次重构必须保留的东西

### 2.1 必须保留：多新建项目模式

这个方向是对的，不能砍。

项目不是只有“一种小说项目”，而应该允许平行存在多种 `project_strategy`，例如：

- 一般小说项目
- 长任务小说项目
- 拆书项目
- 短文集项目
- 设定集项目
- 纯分析/审稿项目

这些项目类型之间不是父子关系，而是平行策略。

### 2.2 必须保留：每个项目类型有不同策略

“项目类型”和“执行策略”不是同一个层级，但二者必须联动。

例如：

- 一般小说项目偏“人类主导，按需生成”
- 长任务项目偏“智能体持续推进，用户在关键节点确认”
- 拆书项目偏“导入、识别、结构化提取、应用”

这条原则必须保留。

### 2.3 必须保留：GUI 与 CLI 共核

不允许 GUI 和 CLI 在核心逻辑上再次分叉。

一切以下能力都必须继续由共享 core 负责：

- 项目策略
- 模式策略
- 工作流策略
- 工具调度
- 任务状态
- 长任务运行
- 资产读写合同
- 上下文组装
- 审稿 / 重写 / 复盘

### 2.4 必须保留：多存储策略兼容

这条不能退。

必须坚持：

- 项目主存储策略要明确可声明
- 当前至少支持 `markdown_project_store` 与 `sqlite_project_store`
- 两种策略尽量共享上层工作流与资产模型
- 做不到完全互转时，必须在创建项目时明确选择策略并隔离运行

同时必须坚持以下底线：

- Markdown 项目里，Markdown / 普通文件是主内容
- SQLite 项目里，SQLite 是主内容事实来源
- SQLite 项目正文不能只是 Markdown 文本原样入库
- JSON 和 DB 都不能以无设计的方式泄漏为用户主编辑面

## 3. 当前项目已有的不合理之处

这一节不是为了否定现有成果，而是为了明确为什么下一阶段必须重构。

### 3.1 项目类型、模式、工作流、运行态边界仍不够清晰

当前项目已经有：

- `project_strategy`
- `mode_strategy`
- `workflow`
- 长任务
- 一般会话

但它们之间还没有完全收束成一套统一的运行模型。

问题表现为：

- 有些模式逻辑仍然偏“页面入口逻辑”
- 有些工作流逻辑仍然偏“现有功能拼装”
- 长任务的“项目引导态”和“运行执行态”仍然不是同一个完整系统

结论：

- 项目类型、模式、工作流、运行基准、运行实例，必须在领域层彻底分开

### 3.2 长任务还没有被提升为“全局运行系统”

当前长任务更多还是“某个项目内的一条功能链”。

但用户真正要的是：

- 长任务开始后持续运行
- 切换到别的项目它也不停
- 出错时自动进入暂停与恢复机制
- 可以统一查看、管理、恢复、停止

这说明：

- 长任务不该只是项目页中的一个 feature
- 它必须上升为 app 级、甚至 runtime 级的全局对象

### 3.3 共享写作资产还没有完全统一

当前已经在做：

- 风格
- 伏笔
- 项目资产包

但还没有形成足够清晰的“共享资产中心”。

问题是：

- 上下文策略可能在模式里体现
- 角色卡可能在长任务里体现
- 审稿建议可能又是另一套结构

这会导致一个风险：

- 本来应该所有项目和模式共用的东西，被做成某个模式专属附属物

需要纠正为：

- 角色卡、风格、伏笔、时间线、关系、上下文规则、字数约束、审稿策略、重写策略，都是共享能力

### 3.4 项目目录结构还不够“策略友好”

现在的目录更多是迁移过程中的逐步累积结果，已经比旧项目好很多，但还不够“最终形态”。

典型问题：

- 有些目录更像技术落盘结果，而不是用户认知结构
- 有些模式自己的状态与共享资产之间边界不够清楚
- 运行记录、任务、检查点、复盘、审稿产物之间还没有一条非常稳定的目录原则

结论：

- 项目结构要从“逐步迁移形成”升级为“按产品心智和恢复心智重新设计”

### 3.4.1 现有“双兼容”表述也不够准确

此前文档中对 `Markdown + SQLite` 的表达，更偏向：

- 一个项目里 Markdown 做主内容
- SQLite 做索引和恢复

这只覆盖了其中一种存储策略。

而你现在明确要求的是：

- Markdown 存储是一种项目策略
- SQLite 存储是另一种项目策略
- 二者最好可兼容互转
- 若暂时不能无损互转，就必须在建项目时明确选择

结论：

- 存储也必须被纳入策略模式，而不是只作为底层实现细节

### 3.5 app 层仍有过重中心文件风险

你已经明确指出：

- `apps/novel_agent_app/lib/app/state/app_shell_controller.dart` 过大

这不是个案，而是一个信号：

- 运行态编排、页面切换、项目切换、长任务状态、工具通知、会话展示，很容易继续往这种文件里堆

所以这次重构必须明确：

- app 层只做装配和投影
- 运行态不能继续长在单控制器上

### 3.6 工具、任务、会话、复盘链虽然已接通，但还不够统一

当前已经做通很多链：

- 工具执行
- checkpoint review
- review task
- repair task
- postprocess

但从“真正长期稳定可用”的视角看，还存在一个整合问题：

- 会话是会话
- 长任务是长任务
- review / repair 又是一组任务
- GUI 和 CLI 观察这些对象的角度也还不完全一致

所以必须进一步收束为：

- thread
- run
- task
- step
- artifact
- checkpoint
- resolution action

这一套统一 runtime 数据模型。

### 3.7 设置、权限、模式、审批等维度后面仍有混淆风险

参考 `DeepSeek-TUI` 后，这个风险更清楚了。

当前项目后续如果不主动拆开，容易继续混成一团的维度包括：

- 当前项目类型
- 当前会话模式
- 当前长任务模式
- 是否自动推进
- 是否允许某些工具
- 是否允许自动恢复
- 是否需要用户审批

这些其实不是同一件事。

后续必须分层。

## 4. 参考项目中值得系统吸收的优点

### 4.1 `MuMuAINovel`

重点吸收：

- 风格中心
- 伏笔中心
- 结构化分析结果
- 分析 -> 建议 -> 重写 闭环
- 卡片资产化

### 4.2 `Writingway`

重点吸收：

- 工作台意识
- 创作结构树与物理资源树并存
- 可选上下文面板
- 编辑区和结构区解耦

### 4.3 `AIxiezuo`

重点吸收：

- 最小可用项目骨架
- 前文章节正文参与生成
- 章节状态与世界设定分离
- 模板组三分法

### 4.4 `novel-writer`

重点吸收：

- constitution / specification / plan / tasks 的前置规范链
- tracking 资产
- 专家角色模板
- “写作动作是执行包”而不是一句 prompt

### 4.5 `book-os`

重点吸收：

- Standards / Novel / Manuscripts 三层上下文
- lite 资产
- command / instruction / agent 三层拆分
- 旧稿接管分析

### 4.6 `DeepSeek-TUI`

重点吸收：

- 结构化工具表面
- 持久线程与事件时间线
- 模式与审批分层
- 子智能体持久会话
- 长输出句柄化
- 持久任务与恢复

### 4.7 `MuMuAINovel` 里还没完全吸收，但这轮设计必须预留的部分

这一节单独列出来，是因为这些内容虽然已经在 `docs/mumuainovel-absorption-analysis.md` 中被判定为值得吸收，但目前项目和上面这份总设计里还没有完整落位。

如果这次大改不把它们显式编进设计，那么后面极容易再次以“零散功能补丁”的方式回流进 app 层或模式私有逻辑。

#### 1. 灵感模式

不是普通聊天前的一句“你想写什么”，而是独立的创意收束工作流。

这意味着后续必须有：

- 独立的灵感模式入口
- 从灵感到项目资产的转换链
- 灵感结果可沉淀为 premise / style / world / characters 的能力

#### 2. 数据导入导出

不是一个“导入按钮”和“导出按钮”而已，而是：

- 项目包
- 角色卡包
- 风格包
- 模板包
- 资产 bundle

的一整套版本化体系。

#### 3. Prompt 调整界面

这不是让用户直接乱改底层 prompt 文本，而是要建立：

- 模板层
- 变量层
- 策略层

三层结构，并为它们提供可视化调优入口。

#### 4. 章节字数限制

这必须成为共享生成参数，而不是某个模式里的局部 UI 选项。

后续至少要支持：

- 目标字数
- 最小字数
- 最大字数
- 是否启用
- 适用对象：章节 / 场景 / 重写

#### 5. 思维链与章节关系图谱

这里吸收的是“结构化分析图谱”，不是暴露模型原始思考。

后续必须预留：

- 章节关系图
- 角色关系图
- 伏笔回收图
- 结构问题分析侧栏

#### 6. 根据分析一键重写

这必须成为正式闭环，而不是分析页上的附属按钮。

后续要支持：

- 整章重写
- 局部重写
- 仅生成建议
- 建议转任务

#### 7. 职业等级体系

这部分非常适合我们的题材范围，但必须做成统一 schema，而不是写死某一类题材词汇。

它后续应能服务：

- 修仙境界
- 魔法等级
- 势力阶层
- 职业成长

#### 8. 角色/组织卡片导入导出

这不是“顺手支持一下”，而是共享资产中心的重要组成部分。

后续应明确支持：

- 单卡导出
- 卡组导出
- 跨项目导入
- 从外部包复制到当前项目

#### 9. 本地提示词工坊

我们不做社区版，但要保留本地版。

后续应支持：

- 模板包
- 技能包
- agent 包
- 风格模板包

并与项目内生态体系相接。

#### 10. 拆书功能

这不是长任务附属功能，而是平行项目策略。

但它的输出资产必须能被：

- 一般小说项目
- 长任务项目
- 风格中心
- 角色卡中心

复用。

#### 当前结论

因此，这轮大改除了处理当前已暴露出来的结构问题，还必须把下面这些东西提前编进总设计：

- 灵感模式
- 版本化导入导出
- prompt 模板调优
- 共享字数约束
- 图谱化分析结果
- 分析到重写闭环
- progression schema
- 卡片跨项目流转
- 本地模板工坊
- 拆书项目策略

它们不要求在第一天全做完，但必须在现在就有明确的位置、依赖方向和共享边界。

## 5. 下一阶段的总设计原则

### 5.1 策略优先，但运行层必须统一

我们继续坚持：

- `project_strategy`
- `mode_strategy`
- `workflow_strategy`

但再向下必须补一层：

- `runtime_baseline`

原因是：

- 同一个项目类型、同一个模式策略，也可能跑在不同的运行基准上

比如长任务就可以有多种运行基准。

### 5.2 共享能力优先，不让模式各自长私货

只要一项能力不只服务单一模式，就不允许把它实现为模式内私有逻辑。

例如：

- 角色卡
- 伏笔
- 风格
- 字数约束
- 上下文策略
- 连续性检查
- 审稿
- 重写

都应该是共享能力。

### 5.3 运行实例优先，不以页面停留状态作为真实状态

真实状态应存在于：

- core runtime
- project hidden state
- task / run / thread persistence

而不是只存在于某个页面还开着没有。

### 5.4 项目结构优先服务流程和恢复，而不是服务技术实现

目录设计优先考虑：

- 用户怎么理解项目
- 智能体怎么稳定引用
- 长任务怎么恢复
- 资产怎么复用

而不是先看哪种实现方便。

## 6. 新的核心概念模型

这次重构后，建议把核心领域概念固定为下面这套。

### 6.1 ProjectType

定义“这是哪一类项目”。

示例：

- `standard_novel`
- `long_form_novel`
- `book_deconstruction`
- `short_story_collection`
- `setting_only`
- `analysis_only`

### 6.2 ProjectStrategy

定义“这一类项目默认怎样组织资产、入口和工作方式”。

它负责：

- 项目骨架模板
- 默认目录映射
- 可用模式集
- 默认共享资产集
- 新建引导入口

### 6.3 ModeStrategy

定义“用户或智能体当前走的是哪种工作模式”。

例如：

- 一般小说协作
- 灵感开局
- 长任务开局
- 章节审稿
- 结构分析
- 拆书分析

### 6.4 RuntimeBaseline

这是本轮最关键的新概念。

它定义：

- 同一模式进入真正运行时，如何推进、在哪里确认、何时自动恢复、何时切换任务

对长任务尤其重要。

### 6.5 WorkflowStrategy

定义一段具体工作流如何编排。

例如：

- 新建项目工作流
- 章节生成工作流
- 长任务章节推进工作流
- 审稿与返工工作流
- 旧稿接管工作流

### 6.6 SharedCapability

定义被多个项目类型和模式复用的能力组。

例如：

- 风格
- 角色卡
- 伏笔
- 关系
- 时间线
- 上下文注入策略
- 审稿
- 重写
- 字数约束
- 导入导出

### 6.7 RunInstance

定义一个真正正在运行的实例。

这不是页面对象，而是持久运行对象。

包括：

- 所属项目
- 关联模式
- 运行基准
- 当前阶段
- 当前任务
- 心跳与恢复策略
- 状态：运行中 / 暂停 / 失败待恢复 / 已停止 / 已完成

### 6.8 ProjectStorageStrategy

定义“这个项目的主内容以哪种策略存储”。

当前至少包括：

- `markdown_project_store`
- `sqlite_project_store`

它负责决定：

- 主内容事实来源
- 用户主浏览形态
- codec 与 repository 组合
- 导出与兼容投影方式

## 7. 长任务模式重构设计

## 7.1 长任务选择后，必须进入独立的“运行基准选择界面”

当前结论：这是必要的，而且是正确方向。

理由：

- “长任务”只是项目类型或模式入口
- 真正决定它怎样跑的，是运行基准

所以应改成：

1. 创建项目
2. 选择 `长任务小说项目`
3. 进入独立的“长任务运行基准选择页”
4. 再进入对应的引导与执行系统

### 7.2 长任务运行基准 1：连续托管式

这是当前已经存在并应保留的第一种基准。

定义：

- 人类给灵感、方向、约束
- 智能体持续推进
- 在关键检查点暂停，而不是每章都要人确认

建议命名：

- `continuous_autonomous`

### 7.3 长任务运行基准 2：逐章协作式自动推进

这是你希望扩展的第二种基准，我判断：

- 必要
- 可行
- 不难落地

原因是：

- 它不需要新造一整套系统
- 本质上只是把“普通章节协作流程”和“长任务持续推进框架”组合起来

定义：

- 每一章都走类似一般小说项目的生成、审稿、协作链
- 可用多智能体协作
- 但不需要用户手动点下一章
- 当前一章完成且满足章级 gate 后，自动进入下一章

建议命名：

- `chapter_collaboration_autorun`

### 7.4 第二种基准为什么确实可行

如果我们按正确解耦来做，那么第二种基准主要复用：

- 项目引导状态机
- 章节任务工厂
- 章级字数约束
- 上下文策略
- 多智能体协作
- checkpoint review
- review task / repair task
- 任务完成判定
- 下一章任务派生

也就是说它不是新系统，而是：

`长任务持续运行框架 + 一般章节协作工作流 + 自动章级推进策略`

因此它的实现复杂度远低于重新做一种完全不同的模式。

### 7.5 后续还可以预留的运行基准

不要求现在立刻实现，但应在设计上预留位置。

例如：

- `outline_first_batch_run`
  - 先批量产出全卷 / 全章规划，再进入正文
- `quality_first_gate_run`
  - 每章必须完成更多审稿 gate 才能前进
- `human_checkpoint_dense_run`
  - 检查点密度更高，但仍然不是逐章手点

## 8. 长任务必须升级为全局运行系统

这是本轮改造的另一条主线。

### 8.1 基本原则

长任务开始后，它不应该依赖当前是否正停留在该项目页面。

它应该：

- 在 GUI 下持续运行
- 切换到其他项目时仍保留
- 出错时自动进入暂停态
- 根据心跳策略尝试恢复
- 直到用户手动暂停或停止

### 8.2 需要新增的核心对象

#### LongTaskSupervisor

全局长任务调度监督器。

职责：

- 管理所有 `RunInstance`
- 分配心跳
- 处理恢复时机
- 处理状态转移
- 处理并发上限

#### LongTaskRunRegistry

全局运行注册表。

职责：

- 列出所有项目的长任务运行实例
- 记录项目归属
- 记录状态摘要
- 为 GUI / CLI 提供统一查询入口

#### LongTaskHeartbeatPolicy

心跳与恢复策略。

职责：

- 定义运行中轮询间隔
- 定义失败后的冷却与重试间隔
- 定义最大连续重试次数
- 定义进入人工干预的阈值

#### LongTaskRecoveryService

恢复服务。

职责：

- 判断某个失败是否可自动恢复
- 重新加载上下文
- 重新构建执行包
- 恢复到安全检查点

### 8.3 GUI 必须新增“长任务中心”

这个入口不是某个项目页里的子面板，而是 app 级入口。

建议命名：

- `Long Task Station`
- 中文映射可按最终产品名调整

它至少要能做：

- 查看所有项目的运行中长任务
- 查看暂停中的长任务
- 查看失败待恢复的长任务
- 手动暂停 / 恢复 / 停止
- 进入某个运行实例详情

### 8.4 切换项目时的行为

切换项目不会停止长任务。

只会改变：

- 当前资源树
- 当前工作区
- 当前打开文档

不会改变：

- 全局长任务监督器
- 已存在的运行实例

### 8.5 自动恢复策略

需要明确几种故障级别：

#### 瞬时传输错误

例如：

- 网络短断
- `Connection closed before full header`
- provider 空响应
- SSE 中途断开

策略：

- 内置有限重试
- 不计入正常上下文
- 超过阈值进入暂停待恢复

#### 工具执行错误

例如：

- 文件不存在
- 读取失败
- 结构化写入失败

策略：

- 若可重构输入则自动重试
- 若属于状态不一致，先恢复检查点再重试
- 若连续失败则暂停

#### 逻辑 gate 未通过

例如：

- 章级审稿没通过
- 连续性问题严重

策略：

- 不是错误
- 而是进入“等待修复 / 自动返工 / 等待用户选择”的状态

## 9. 哪些能力必须抽成共享层

这一节直接回答你强调的那件事：

- 长任务需要的很多能力，一般小说项目也需要

所以它们不能继续被模式私有化。

### 9.1 角色卡 / 组织卡 / 地点卡 / 物品卡

归属：

- `shared asset capability`

服务对象：

- 一般小说项目
- 长任务
- 拆书
- 旧稿接管

### 9.2 风格

归属：

- `shared style capability`

服务对象：

- 一般小说生成
- 长任务
- 审稿
- 重写

### 9.3 伏笔

归属：

- `shared foreshadow capability`

服务对象：

- 长任务
- 一般小说续写
- 审稿
- 图谱分析

### 9.4 上下文策略

归属：

- `shared context policy capability`

服务对象：

- 一般会话
- 一般章节生成
- 长任务
- 分析任务

### 9.5 字数约束

归属：

- `shared generation constraint capability`

服务对象：

- 一般章节
- 长任务章节
- 重写任务

### 9.6 审稿 / 重写 / 返工

归属：

- `shared review and repair capability`

服务对象：

- 一般小说项目
- 长任务逐章推进
- 旧稿分析修复

### 9.7 关系 / 时间线 / 世界规则

归属：

- `shared graph and world capability`

服务对象：

- 长任务
- 一般小说项目
- 拆书
- 接管旧稿

### 9.8 灵感模式与创意收束

归属：

- `shared ideation capability`

服务对象：

- 一般小说项目开局
- 长任务项目开局
- 拆书后二次创作

### 9.9 版本化导入导出

归属：

- `shared bundle capability`

服务对象：

- 项目迁移
- 卡片共享
- 风格共享
- 模板共享

### 9.10 Prompt 模板调优

归属：

- `shared prompt-template capability`

服务对象：

- 一般协作模式
- 长任务模式
- agent / skill / template 生态

### 9.11 图谱化分析结果

归属：

- `shared narrative-graph capability`

服务对象：

- 审稿
- 长任务
- 一般小说项目
- 拆书

### 9.12 拆书与结构化提取

归属：

- `shared extraction capability` + `book_deconstruction project strategy`

服务对象：

- 拆书项目
- 一般小说项目资产预填
- 长任务项目资产预填

## 10. 新的项目目录结构设计

先强调一条：

下面的目录结构主要描述 `markdown_project_store` 的默认用户可见形态。

对于 `sqlite_project_store`，这些目录可以是：

- 投影视图
- 导出视图
- 按需生成视图

而不一定是主事实来源。

下面给出建议的新结构。

原则：

- 用户可见目录服务创作认知
- 内部隐藏目录服务恢复与运行
- 英文目录为真实目录
- 中文仅做 UI 映射显示

## 10.1 用户可见目录

```text
<project_root>/
  premise/
  outlines/
    story/
    volumes/
    chapters/
  drafts/
    chapters/
    scenes/
  assets/
    characters/
    organizations/
    locations/
    items/
    styles/
    world/
    foreshadows/
    relationships/
    timeline/
  tasks/
    plans/
    reviews/
    revisions/
  analysis/
  exports/
```

### 目录含义

#### `premise/`

放：

- 题材
- 核心设定
- 开局摘要
- constitution / project promise / writing intent

#### `outlines/`

放：

- 总纲
- 分卷纲
- 章纲

#### `drafts/`

放：

- 正文
- 场景稿
- 正式章节稿

#### `assets/`

放：

- 角色卡
- 组织卡
- 地点卡
- 物品卡
- 风格
- 世界规则
- 伏笔
- 关系
- 时间线

#### `tasks/`

放：

- 面向用户可理解的任务文档
- 审稿任务文档
- 返工任务文档

#### `analysis/`

放：

- 分析结果
- 图谱导出
- 结构化审稿摘要

#### `exports/`

放：

- 导出包
- 共享资产包

## 10.2 隐藏系统目录

```text
<project_root>/.novel_agent/
  project.db
  state/
  runtime/
  runs/
  threads/
  tasks/
  checkpoints/
  indexes/
  cache/
  settings/
  logs/
```

### 目录含义

#### `project.db`

SQLite 主库。

只负责：

- 索引
- 引用关系
- 状态镜像
- 恢复加速

#### `state/`

放：

- 项目隐藏状态
- 模式引导状态
- 运行配置快照

#### `runtime/`

放：

- 当前活跃运行实例状态
- 心跳信息
- 恢复信息

#### `runs/`

放：

- 每个运行实例的阶段记录
- 运行摘要

#### `threads/`

放：

- 会话线程
- turn / item / event 时间线投影

#### `tasks/`

放：

- durable tasks
- checklist
- gate records

#### `checkpoints/`

放：

- 回退点
- checkpoint review
- 恢复锚点

#### `indexes/`

放：

- 搜索索引
- 资源树投影
- 资产索引

#### `cache/`

放：

- 临时生成缓存
- 工具大结果 spill

#### `settings/`

放：

- 项目级设置
- 模式级覆盖设置

#### `logs/`

放：

- 宿主级运行日志
- 恢复尝试日志

## 10.3 目录结构的几个重要原则

### 原则 1

用户可见目录永远不展示无意义技术文件。

### 原则 2

真实英文目录名稳定存在，UI 只做中文映射。

### 原则 3

同一概念只在一个主目录拥有“权威原件”。

例如：

- 角色主档在 `assets/characters/`
- 不允许正文目录再长一份角色主档

### 原则 4

运行记录不污染创作资产目录。

## 11. 新的运行架构设计

## 11.1 Core 分层建议

建议继续收束成下面这些子域：

```text
packages/novel_agent_core/lib/src/
  strategy/
  projects/
  modes/
  runtime/
  sessions/
  tasks/
  context/
  assets/
  reviews/
  generation/
  tools/
  approvals/
  ports/
```

### `strategy/`

放：

- project strategy
- mode strategy
- runtime baseline
- workflow strategy

### `projects/`

放：

- 项目模板
- 项目骨架
- 项目类型元数据
- 项目存储策略元数据

### `modes/`

放：

- 引导状态机
- 模式阶段
- 模式完成条件

### `runtime/`

放：

- run instance
- supervisor contracts
- recovery policies
- heartbeat
- event timeline

### `sessions/`

放：

- thread
- turn
- items
- session replay

### `tasks/`

放：

- durable tasks
- chapter tasks
- review tasks
- repair tasks
- gates

### `context/`

放：

- context policies
- context budgeter
- lite/full asset selection
- task-aware injection

### `assets/`

放：

- 风格
- 角色卡
- 世界规则
- 伏笔
- 时间线
- 关系

### `storage/`

建议在 core 中单列一个子域，明确表达：

- `ProjectStorageStrategy`
- 内容 codec 合同
- repository 合同
- 跨策略迁移合同
- 可读投影合同

### `reviews/`

放：

- review report
- checkpoint review
- repair proposal
- revision resolution

### `generation/`

放：

- 生成参数
- 字数约束
- 章节输出策略

### `tools/`

放：

- 结构化工具 contracts
- tool schemas
- tool categories

### `approvals/`

放：

- approval policy
- permission profiles
- auto-run limits

## 11.2 Adapters 分层建议

```text
packages/novel_agent_adapters/lib/src/
  storage/
  runtime/
  providers/
  tools/
  host/
  import_export/
  indexing/
```

重点新增：

- `runtime/`
  - 全局长任务监督器落盘实现
  - run registry
  - heartbeat scheduler
- `storage/`
  - Markdown 项目仓储
  - SQLite 项目仓储
  - 策略识别
  - 内容 codec
  - 跨策略迁移
- `indexing/`
  - SQLite 投影
  - 搜索索引
- `import_export/`
  - 资产包
  - 项目包
  - 拆书输入

## 11.3 App 层拆分建议

app 层不要再以一个总控制器为中心。

建议拆成：

```text
app/
  bootstrap/
  shell/
  navigation/
  workbench/
  long_task_station/
  project_creation/
  settings/
```

其中：

- `shell/` 只负责应用框架和全局状态装配
- `workbench/` 只负责当前项目工作台
- `long_task_station/` 只负责全局长任务中心
- `project_creation/` 只负责新建/打开项目流程

## 11.4 UI 层拆分建议

UI 要按“一个区域一个职责”继续拆。

尤其要避免：

- 一个页面同时承担资源树、编辑器、会话、任务、设置逻辑

应拆成更细的子组件树：

- 资源树区
- 编辑区
- 会话区
- 任务区
- 长任务运行区
- 长任务详情区
- 资产中心区

## 12. GUI 交互重构设计

### 12.1 首次启动 / 无有效项目时

必须强制进入：

- 创建新项目
- 打开已有项目

桌面端：

- 两个入口都给

移动端：

- 默认只给“创建新项目”
- “打开已有项目”默认不给，除非以后有更稳的沙盒方案

### 12.2 新建项目流程

应该变成卡片式、铺开式，而不是下拉。

流程建议：

1. 选择项目类型
2. 选择项目主存储策略
3. 若为长任务项目，进入长任务运行基准选择页
4. 选择基础模板 / 风格预设 / 资产预设
5. 创建项目

其中“主存储策略”至少要明确给出：

- Markdown 项目
- SQLite 项目

如果某些项目类型暂时只支持其中一种策略，也必须在这里明确说明，而不是隐式决定。

### 12.3 工作台结构

继续保持“三栏为主、双栏和单栏为退化”的原则，但不要把布局策略写死在某个页面文件里。

工作台应该由布局策略对象驱动：

- `three_pane`
- `two_pane`
- `single_pane`

资源树始终是主视图之一。

### 12.4 长任务中心入口

建议固定为 app 级入口。

用户无论打开哪个项目，都能进入。

### 12.5 项目内与全局入口区分

需要清楚区分：

- 当前项目资源和资产
- 全局长任务运行实例
- 用户级设置与记忆

## 13. CLI 侧设计

CLI 仍然不做 CLI 内设置。

继续坚持：

- 读取同目录或已解析的设置文件
- 调用共享 core
- 输出结构化结果

但 CLI 应继续增强：

- 查看全局运行实例
- 恢复长任务
- 暂停 / 停止长任务
- 查看任务与复盘

也就是说，GUI 的长任务中心概念，CLI 也应有对应入口。

## 14. 新的长任务状态机设计

建议统一为下面这些状态：

- `drafting_guidance`
- `ready_to_start`
- `running`
- `waiting_gate`
- `paused`
- `recovering`
- `failed_manual_attention`
- `stopped`
- `completed`

### 状态含义

#### `drafting_guidance`

仍在引导与开局阶段。

#### `ready_to_start`

引导完成，尚未真正启动运行实例。

#### `running`

正在执行。

#### `waiting_gate`

不是报错，而是在等待章级或阶段级 gate 结果。

#### `paused`

被用户手动暂停，或系统为了安全主动暂停。

#### `recovering`

系统正在做自动恢复。

#### `failed_manual_attention`

自动恢复失败，需要用户决定。

#### `stopped`

用户明确停止，不再自动恢复。

#### `completed`

已完成。

## 15. 第二种长任务基准的工作流设计

这里单独给出，因为它是你最关心的新增项之一。

### 15.1 目标

它不是“更自由的托管”，而是“更稳的逐章推进”。

### 15.2 单章流程

每章建议固定为：

1. 选取章级上下文包
2. 生成章计划 / 章目标
3. 生成正文
4. 运行章级审稿
5. 必要时自动返工
6. 通过章级 gate
7. 更新资产状态
8. 派生下一章任务

### 15.3 多智能体协作位置

多智能体不应铺满整章，而应只出现在专职节点：

- 结构检查
- 连续性检查
- 风格检查
- 章后总结

主写作智能体仍保持唯一主线。

### 15.4 为什么这比第一种更容易复用已有能力

因为它大量复用现有：

- 一般章节生成链
- review / repair 链
- checkpoint 链
- 任务派生链

它的新增点更多在：

- 自动章级推进
- 章级 gate 定义
- 与全局长任务运行实例结合

## 16. 设置与策略分层设计

必须形成四层：

### 16.1 用户级设置

例如：

- 默认模型接口偏好
- 默认主题
- 默认桌面项目目录
- 默认心跳策略

### 16.2 项目级设置

例如：

- 当前项目默认智能体
- 当前项目默认风格
- 项目级上下文策略
- 项目级章字数约束
- 项目级智能体模型绑定与参数覆写

这里需要额外明确一条硬规则：

- 智能体的具体运行参数属于项目级，而不是全局级

这包括但不限于：

- 该项目中某个智能体默认使用哪个模型
- 该项目中该模型是否开启流式
- 该项目中该模型是否开启深度思考
- 该项目中该智能体覆写的温度、`top_p`、高级参数

也就是说：

- 同一个内置或项目级智能体，在 `Project A` 中绑定 `Model X`
- 在 `Project B` 中可以绑定 `Model Y`
- 两边的参数互不影响

这条规则同时意味着：

1. 智能体定义本身负责“它是谁、它会做什么”
2. 项目级智能体配置负责“在这个项目里它用什么模型、带什么参数跑”
3. 全局设置只负责“用户默认偏好”，不能反向污染已存在项目内的智能体绑定

因此后续在领域上应显式区分：

- `AgentProfile`
- `ProjectAgentBinding`
- `ProjectAgentModelOverride`

其中：

- `AgentProfile` 是可复用身份与能力定义
- `ProjectAgentBinding` 是项目内启用与选择关系
- `ProjectAgentModelOverride` 是项目内模型与参数覆写

这样才能保证：

- 同一个智能体跨项目复用时身份稳定
- 但其模型选择和推理参数仍然严格限定在项目作用域内

### 16.3 模式级设置

例如：

- 当前长任务模式用哪种运行基准
- 检查点密度
- 自动审稿强度

### 16.4 运行实例级临时覆盖

例如：

- 本次暂停后恢复时间
- 本次临时改用别的模型
- 本次临时提高审稿等级

## 17. 可靠性设计

### 17.1 重试不计入正常上下文

继续保留并制度化。

### 17.2 错误要分级

至少分：

- 瞬时错误
- 可恢复错误
- 结构错误
- 人工决策错误

### 17.3 工具结果要结构化留证

继续坚持：

- 摘要留在主会话
- 大结果句柄化
- 关键证据进 artifact

### 17.4 恢复必须尽量回到稳定检查点

不要从一个半坏状态生硬继续。

## 18. 对当前代码改造的实际顺序建议

### Phase 1：先立新合同

先做：

- `RuntimeBaseline`
- `RunInstance`
- `LongTaskSupervisor`
- `LongTaskRunRegistry`
- `LongTaskHeartbeatPolicy`
- `ProjectStorageStrategy`
- `ProjectContentRepository`
- `ProjectReadableProjectionService`

当前这一步已经有第一批实际代码落点：

- core：
  - `project_storage_strategy.dart`
  - `project_directory_layout.dart`
  - `project_directory_layout_service.dart`
  - `project_content_repository.dart`
  - `project_readable_projection_service.dart`
- adapters：
  - `markdown_project_content_repository.dart`
  - `sqlite_project_content_repository.dart`
  - `project_storage_strategy_resolver.dart`
  - `delegating_project_content_repository.dart`
  - `delegating_project_readable_projection_service.dart`

注意这只代表“合同与基础壳已经落地”，不代表新目录树、SQLite schema、跨策略迁移已经完成。

### Phase 2：把长任务从项目页提到全局

先做：

- 全局长任务中心
- 运行实例列表
- 项目切换不终止运行

### Phase 3：实现第二种运行基准

先复用：

- mode guidance
- review / repair
- task progression

### Phase 4：重排项目目录与隐藏状态

迁到：

- 新的 visible / hidden 双层结构
- 并同时把 Markdown 项目与 SQLite 项目的策略边界立清楚

### Phase 5：收束共享资产层

把：

- 风格
- 角色卡
- 伏笔
- 关系
- 时间线
- 字数约束

彻底统一为共享能力。

同时把下面这些此前在 `MuMuAINovel` 中已确认值得吸收、但尚未完全进入我们项目主骨架的能力，一并编入共享层路线：

- 灵感模式
- 版本化导入导出
- prompt 模板调优
- 图谱化分析结果
- 一键重写计划
- progression schema
- 卡片跨项目流转
- 本地模板工坊
- 拆书结构化输入

### Phase 6：拆 app 层过重中心

重点拆：

- `app_shell_controller.dart`

## 19. 最后的总判断

这次重构的重点，不是“再多加几个功能页”，而是让整个项目真正进入：

- 可持续演化
- 可持续运行
- 可持续恢复
- 可持续扩模式

的状态。

如果按这份设计推进，后面我们新增的将不再只是“新功能”，而是：

- 新项目类型
- 新模式策略
- 新运行基准
- 新共享能力

它们都能落到同一套稳定骨架里。

这才是我们这次真正该做的大改方向。
