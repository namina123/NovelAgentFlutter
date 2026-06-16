# NovelAgentFlutter 项目级永久约束

本文件是项目级长期约束。  
后续新增功能、重构、脚手架、测试和原生接入都必须遵守这里的规则。

## 1. 项目目标

本项目支持两类应用:

- Flutter GUI: `windows / linux / macos / android / ios`
- Dart CLI: `windows / linux / macos`

本项目第一优先级不是“先把功能堆出来”，而是保证功能增长时仍然可拆、可换、可复用。

## 2. 核心技术决策

### 2.1 当前默认决策

当前默认采用:

- `Flutter` 负责 GUI 壳
- `Dart CLI` 负责桌面命令行壳
- `纯 Dart core` 负责共享核心逻辑
- `adapters` 负责平台、存储、网络、进程、原生接入

这不是临时方案，而是当前阶段的正式基线。

### 2.2 关于 Dart CLI 与 C++ 核心

当前结论如下:

1. `Dart` 可以稳定构建 CLI。
2. `Flutter` 与 `Dart CLI` 可以共享同一套纯 Dart 核心。
3. 因此，第一阶段不应把整个核心提前下沉为 C++。

原因:

- 业务规则、会话编排、项目状态、任务状态本质上更适合放在高层语言里快速演化。
- 如果现在直接上 C++ 核心，会显著提高迭代成本、调试成本和跨平台维护成本。
- 我们当前最大的风险不是算力不够，而是边界失控、职责混乱和演化成本失控。

### 2.3 当前路线不包含 C++ 核心

当前 roadmap 不包含:

- 全量 C++ 核心
- Flutter 直接调用 native 业务层
- 为 CLI 单独维护一套 native 状态机

也就是说，现阶段默认认为:

- `纯 Dart core` 就是正式核心方案

### 2.4 何时允许引入 C++

只有在满足以下条件之一时，才允许把局部能力下沉到 C++:

- 经过 profiling 证明某段逻辑是明确热点。
- 该能力需要稳定复用到多个宿主，且 Dart 实现性能或资源占用不可接受。
- 该能力天然依赖成熟 native 库，Dart 直接实现代价过高。
- 该能力属于底层引擎而非高层业务规则，例如索引引擎、增量解析器、本地向量检索、超大文本流处理。

### 2.5 C++ 的接入方式

如果后续确实需要 C++:

- C++ 只能作为 `native engine` 存在。
- Flutter / CLI 不直接依赖 C++ 业务细节。
- C++ 必须通过 `adapters` 层封装。
- 调用方式优先考虑 `dart:ffi`。
- C++ 不能成为新的“万能核心”。

也就是说:

- 高层业务合同仍在 `novel_agent_core`
- 低层高性能实现可以在 `native/` 中出现
- `novel_agent_adapters` 负责把 native 实现接进来

## 3. 目录职责

### `apps/novel_agent_app`

Flutter GUI 壳层，只负责:

- 页面
- 组件
- 交互
- 路由
- 主题
- 生命周期
- 权限 UX

禁止负责:

- 共享业务规则
- provider 协议细节
- 文件存储规则
- 桌面进程逻辑

### `apps/novel_agent_cli`

CLI 壳层，只负责:

- 参数解析
- 命令分发
- 输出格式
- 退出码
- 自动化入口
- 配置与诊断等正式命令族的壳层投影

禁止负责:

- 共享业务规则重写
- GUI 状态
- Flutter 组件逻辑

### `packages/novel_agent_core`

纯 Dart 核心，只负责:

- 领域模型
- 用例
- 工作流
- 状态合同
- ports
- 策略

禁止负责:

- Flutter UI
- 具体文件系统实现
- 具体 HTTP 实现
- 具体进程执行实现
- 原生绑定细节

### `packages/novel_agent_adapters`

适配器层，只负责:

- 本地存储实现
- provider 接入
- host 能力实现
- 平台探测
- native 封装

禁止负责:

- 页面逻辑
- feature UI 状态
- 新的业务规则中心

### `native/`

保留给未来可选 native engine。

禁止:

- 提前把业务规则搬进去
- 在没有性能证据时下沉

## 4. 依赖方向

依赖方向只允许:

```text
app -> core
cli -> core
bootstrap -> adapters
adapters -> core
native adapter -> native
```

进一步约束:

- `features/` 不允许直接 import `adapters`
- `presentation/` 不允许直接 import `adapters`
- `core` 不允许 import `Flutter`
- `core` 不允许 import `adapters`
- `app` 不允许 import `cli`
- `cli` 不允许 import `app`

## 5. composition root 规则

系统组装只能发生在:

- `apps/novel_agent_app/lib/app/bootstrap/`
- `apps/novel_agent_cli/lib/bootstrap/`

也就是说:

- feature 页面不 new adapter
- command 不直接 new provider 实现
- 依赖注入不允许散落到功能代码中

## 6. 解耦合硬约束

### 6.1 不允许新的全能中心文件

禁止出现以下类型的文件:

- 万能主控制器
- 万能全局状态中心
- 万能工具注册中心
- 万能平台门面且混入业务规则

### 6.2 文件体量阈值

- 单文件超过 `400` 行时，必须复核职责。
- 单文件超过 `700` 行时，除生成文件外必须拆分。
- 单个类或服务如果同时承担 3 类以上职责，必须拆分。

补充约束：

- 行数阈值只是报警器，不是设计目标。
- 不能因为文件还没到某个数字，就继续把本应拆开的职责硬塞在一起。
- 也不能为了压低行数，机械拆出一组空壳文件却仍保留同一坨耦合逻辑。
- 真正的拆分依据始终是：职责边界、依赖方向、复用语义、运行时合同。

### 6.3 跨模块访问规则

- `project` 不能直接操纵 `workflow` 内部状态。
- `workflow` 不能直接读写 UI 状态。
- `tools` 不能直接了解具体页面结构。
- `session` 不能偷偷承担项目存储。

模块之间只通过:

- 明确的模型
- 明确的用例
- 明确的 port

## 6.4 策略模式优先

从现在开始，项目级正式采用“策略模式优先”的长期演化原则。

这不是某个功能点的临时抽象，而是整个项目的基石。

### 核心定义

上层先定义“项目要如何工作”，底层再服务这种定义。

也就是说：

- 先有 `project_strategy`
- 再有 `mode_strategy`
- 再有 `workflow_strategy`
- 最后才有底层实现细节

禁止反过来演化成：

- 先做一堆底层实现
- 再让上层页面或控制器去硬拼出一种流程

## 6.5 存储策略优先

从现在开始，项目级正式采用“多存储策略并存”的长期原则。

当前已明确的两种策略是：

- `markdown_project_store`
- `sqlite_project_store`

后续允许扩展更多轻量存储策略，但必须继续遵守相同约束。

### 核心定义

这里的 `Markdown + SQLite`，不是指“同一个项目默认同时混用 Markdown 和 SQLite 作为主内容存储”。

真正的含义是：

- 系统支持多种项目主存储策略
- 一种策略把主内容存成分散的 `Markdown / 普通文件`
- 另一种策略把主内容存进 `SQLite`
- 这些策略在 core 合同层必须尽量保持可互转、可迁移、可共用上层工作流

也就是说，优先目标是：

1. 不同存储策略可兼容
2. 若某些能力暂时不能完全互转，必须明确隔离
3. 项目创建时必须知道自己使用哪种主存储策略

### Markdown 策略约束

当项目使用 `markdown_project_store` 时：

- 用户资产以 Markdown / 普通文本文件为主
- 正文、章纲、风格、角色卡等使用 Markdown 允许表达的文本形态
- SQLite 如果存在，也只能作为索引、缓存、关系投影或恢复加速层

### SQLite 策略约束

当项目使用 `sqlite_project_store` 时：

- 主内容以数据库中的结构化字段、普通文本字段或分段文本字段存储
- 正文内容不应存成“Markdown 文档字符串再塞进 SQLite”的做法
- SQLite 策略下的正文是正文文本，不是 Markdown 文件内容搬运体
- Markdown 视图如果需要，只能作为导出、投影、预览或互转产物

### 如果互转做不到，必须先隔离

如果某一阶段做不到高质量互转，那么必须采用：

- 项目创建时明确选择主存储策略
- 不同策略项目各自独立运行
- 共享上层 use case，分开底层 adapter

禁止出现这种含糊状态：

- 用户以为自己是 Markdown 项目，实际正文写进了 SQLite blob
- 用户以为自己是 SQLite 项目，实际核心内容仍散落在 Markdown 文件里

### GUI / CLI 约束

- `GUI / CLI` 只能通过共享 core 合同访问存储
- `app / cli / controller` 不允许直接写 SQL
- `app / cli / controller` 不允许直接拼接 Markdown 主内容存储规则

### 禁止演化成

- 把 SQLite 直接暴露给用户作为唯一编辑入口却没有投影层
- 把 Markdown 内容原样塞进 SQLite 正文字段冒充 SQLite 存储策略
- 在 app / cli / controller 中直接写 SQL 或耦合数据库细节
- 不声明项目存储策略就让同一项目半 Markdown、半 SQLite 地漂移

### 内部路径规则

项目内部隐藏状态统一放在：

- `.novel_agent/`

普通资源树默认隐藏：

- `.novel_agent/`
- SQLite 文件
- 内部状态 JSON

### 结构化字段规则

SQLite 表设计优先：

- 拆表
- 拆字段
- 稳定 ID
- 可回指 Markdown 路径

禁止长期依赖大 JSON blob 作为默认结构化存储方案。

## 6.6 GPL 参考边界

旧项目 `D:\\GODOTProject\\NOVELAgent` 为 `GPL-3.0` 开源。

因此，本项目后续一律只允许：

- 参考产品目标
- 参考交互理念
- 参考架构问题与演化教训
- 参考“需要哪些能力”这一层的抽象结论

明确禁止：

- 转译旧项目源码
- 复制旧项目字段设计
- 复制旧项目文本内容
- 复制旧项目类结构、函数结构或文件组织后仅做语法改写
- 把旧项目具体实现当作“迁移模板”直接搬入 Dart / Flutter

如果某一能力来自旧项目启发，新的实现必须满足：

1. 先在本项目自己的架构约束下重新定义职责
2. 用本项目自己的合同、命名和数据模型独立实现
3. 不保留一一对应的实现痕迹

如后续发现已有实现过度贴近旧项目具体实现，应优先重构为独立表达。

## 6.7 多协议兼容边界

项目必须从一开始考虑：

- `OpenAI Chat Completions`
- `OpenAI Responses API`
- `Anthropic Messages API`
- `Gemini native`
- `Gemini OpenAI compatibility`

### 核心原则

- 调度、上下文、重试、工具归一化在 core 共用
- 请求封装、流式事件、工具消息回传、thinking / reasoning 承载在 adapters 分流

### 禁止事项

禁止把下列假设写死进 core：

- 所有提供商都用 OpenAI 的 `tool_calls`
- 所有流式返回都是 Chat delta
- 所有接口都支持强制 tool choice
- 所有接口都支持 Responses API
- 所有接口都能暴露 reasoning / thinking

### 实现要求

1. 所有网关都必须先声明 capability，再接入共享运行链
2. Responses API 必须单独适配，不得继续伪装成 Chat Completions
3. Anthropic 必须独立处理 `tool_use / tool_result` 内容块语义
4. Gemini OpenAI compatibility 只视作“部分 OpenAI 兼容层”
5. Gemini 原生能力若接入，必须使用独立 adapter

## 6.8 长任务稳定性共享骨架

从现在开始，长任务稳定性正式固定为：

- `共享骨架优先`
- `类型扩展后挂`

这条约束适用于：

1. 当前已有长任务类型
2. 拆书派生长任务类型
3. 特殊情节长任务类型
4. 后续新增的任何长任务类型

### 共享骨架至少包括

1. 生命周期
2. 运行现场快照
3. artifact gate
4. runtime health / stale / stuck 判定
5. failure taxonomy
6. resume brief / scene handoff
7. ownership / lock policy

### 类型扩展只负责

1. 阶段定义
2. 关键工件画像
3. 专属失败附加信息
4. 恢复建议细节

### 硬约束

1. 不允许默认把“长任务”理解成当前某一条章节队列主链。
2. 不允许每增加一种长任务类型，就复制一套 runtime 稳定性实现。
3. 新增长任务类型时，优先新增：
   - type profile
   - artifact profile
   - snapshot extension
   - failure context extension
4. 稳定性判定逻辑必须优先留在 `core + adapters`，不允许回流到 widget、controller 或单个 view-data service 成为事实源。

### GUI / CLI / probe 消费边界

1. GUI、CLI、probe 只能消费共享 `run_center_contract / stop_diagnosis / review_contract / repair lane / checkpoint action package`，不允许各自重建一套停点判断或动作判断。
2. `waiting_user / manual_attention / delivery_failure / technical_failure / completed_naturally` 等用户可见停点分类，必须继续优先来自 production truth，而不是宿主私有字符串映射。
3. GUI/CLI 的人工动作入口必须继续经由共享 runtime service 或 action service 执行，不允许页面、控制器或命令直接改底层 run/task/research request 记录。
4. `watchdog` 只处理 runtime health，`supervisor` 只处理结构结果调度；后续若扩 GUI/CLI，也不得把这两层边界重新揉回单一宿主控制器。

## 6.9 特殊机制优先进入 continuity / mechanics

从现在开始，以下类型的故事机制默认不应继续长成题材硬编码工作流：

1. 多世界
2. 快穿
3. 死亡回归
4. 回档 / 读档
5. 梦境线 / 异常线 / 幻境线

这些机制应优先进入：

1. `continuity scope`
2. `continuity frame`
3. `mechanic profile`
4. `runtime resolver`

禁止演化成：

1. 每出现一种机制，就新增一条题材专用 workflow 主链
2. 在 workflow runtime 中不断堆叠题材 if/else
3. 让拆书、普通项目、长任务各自拥有一套平行的特殊机制实现

## 6.10 写作稳定性与执行约束偏靠原则

从现在开始，下面这些能力默认视为“写作稳定性共享层”的组成部分：

1. 字数控制
2. 表达限制
3. 去 AI
4. 输出后置 gate
5. 关键工件存在性 / 路径正确性检查
6. 严重偏离后的修复或阻断策略

### 核心原则

1. 这些能力不能继续只做在某个长任务宿主里。
2. 普通写作任务、当前长任务类型、未来新增长任务类型都应尽量共享这批稳定性能力。
3. 即使近期不全面启动统一执行约束架构，相关改动也必须尽量向该方向偏靠。

### 近期硬约束

如果某次修改碰到了：

- 字数
- 表达限制
- 去 AI
- continuity guard
- 输出评估
- 任务后置修复

那么至少必须遵守：

1. 不要把表达限制重新吞回模型参数、技能语义或宿主私有 prompt 分支。
2. 不要把字数继续写成更散的特例字段。
3. 不要让 continuity / 特殊机制重新硬编码回 workflow 主链。
4. 优先做小范围去耦、预留扩展位、统一合同，而不是继续加宿主特判。

### 表达限制执行策略维护边界

后续凡是继续修改表达限制相关能力，都必须额外遵守：

1. `profile / binding` 继续只表达“项目有哪些表达规则”，`execution policy` 只表达“本次运行如何使用这些规则”，不允许重新混回一个对象。
2. `force` 或其他强策略也不得污染工具 schema、工具参数、文件路径、研究执行、权限 payload 与纯技术轮次。
3. probe、mock suite、GUI/CLI 摘要都只能消费 production 同源 contracts，不允许重新扫描正文后长成第二套私有业务判定中心。

### 用户可见与内部事实层边界

1. 用户可以继续看到业务语言，例如：
   - 目标字数
   - 表达限制
   - 去 AI
2. 内部可以逐步把这些收口到更统一的执行约束事实层。
3. 不允许用内部抽象名义，直接消灭已有用户可理解的产品语义。

### 链路合同与修复原则

这部分属于项目级长期硬约束。

以后凡是涉及以下类型的修改：

- provider 兼容
- 工具调用链
- 工作流中间件
- postprocess / gate / repair
- 主链 / 子链共享逻辑
- 流式结果聚合
- 工具轮消息转录

都必须优先遵守下面这些规则：

1. 不允许让单个字段同时承载多重语义。
   - 例如不能既把某字段当“给下一轮看的 assistant transcript”，又把它当“本轮真实正文证据”。
   - 如果两种信息生命周期不同、消费方不同、错误恢复策略不同，就必须拆开表达。

2. 中间层优先传“合同对象 / context object”，不要继续传零散补丁参数。
   - 如果一轮执行天然需要多份上下文，就显式建小 contract。
   - 不允许长期依赖 `foo_text`、`bar_fallback`、`extra_hint` 这类临时参数把链路越补越散。

3. 错误修复优先修“协议断裂 / 合同缺口”，不要新增隐式副作用。
   - 发现内容丢失、路径错位、状态漂移时，先查是哪一层没有把应有事实稳定传下去。
   - 不允许因为修 bug，偷偷增加一条绕过正式工具、正式状态机或正式存储边界的旁路。

4. 主链、子链、普通任务、长任务，共用同一类合同形态。
   - 只要语义相同，就要优先复用相同 contract，而不是每条链各长一套近似但不同的字段组织。
   - 不允许主链先优雅，子链继续堆私有修复。

5. assistant transcript、tool round evidence、tool result transcript 必须分清职责。
   - transcript 用于“下一轮继续对话 / 回放”
   - evidence 用于“本轮事实恢复 / gate / repair / write 参数修补”
   - result transcript 用于“工具执行后的稳定回传”
   - 三者允许互相投影，但不允许长期混在同一个字段里。

6. 新 contract 一旦成立，就要尽快收口调用点，不允许长期双轨。
   - 不允许新旧入口并存太久。
   - 如果本轮建立了更清晰的 context / contract，后续相关调用点和测试应尽快一起迁移。

7. 所有这类修复都要配套测试，且测试要贴近真实失效形态。
   - 不能只测理想路径。
   - 至少要覆盖“真实上游有产出，但在中间层或执行边界丢失”的故障形态。

8. 命名必须反映职责，不允许继续用含混名字掩盖多义性。
   - 像 `assistant_message`、`narrative_content`、`tool_round_context` 这种命名，优先于模糊的 `content`、`extra_data`、`payload2`。

9. 这条约束同时适用于人类开发与项目内智能体。
   - 智能体在实现修复时，不应满足于“先补上能跑”。
   - 如果发现自己正在增加特判、旁路、双重语义字段或散落补丁，应主动回退一步，优先寻找更自然的合同边界。

### 三层策略基线

#### 1. `project_strategy`

定义一个项目属于哪种大类策略，例如：

- 一般小说
- 长任务长篇
- 短文集
- 拆书
- 知识整理

它决定的是“这个项目的总工作方式”，不是某一轮按钮点击。

#### 2. `mode_strategy`

定义同一项目策略内部的具体模式，例如长任务长篇中的：

- 灵感托管式
- 全书共拟式
- 分卷检查点式
- 章纲监督式
- 旧稿抢救重构式

它决定的是“进入和推进的协作方式”。

#### 3. `workflow_strategy`

定义某一类动作如何执行，例如：

- 先问选项还是先读资产
- 先分析还是先生成
- 是否允许自动推进
- 检查点密度如何
- 是否允许子智能体参与

它决定的是“当前动作的执行规则”。

### 设计硬约束

1. 新功能进入前，必须先判断它属于：
   - 策略定义
   - 共享资产
   - 共享工作流
   - 宿主适配
   - UI 展示
2. 任何新模式都不能通过复制页面逻辑或复制用例来实现。
3. 任何新模式都应优先复用：
   - 共享资产层
   - 共享上下文层
   - 共享工具层
   - 共享长任务调度层
4. `app` 层只能消费策略结果，不能成为策略规则中心。
5. `adapters` 层只能实现能力，不能决定项目采用什么策略。
6. `native/` 若未来存在，也只能服务策略层，不得反向主导策略形状。

### 底层服务上层的长期原则

无论底层如何变动，例如：

- 文件格式变化
- SQLite 结构变化
- provider 协议变化
- 是否引入 native engine
- UI 页面布局变化

都不得破坏上层策略层的稳定表达。

正式要求：

- 底层实现永远为上层策略模式服务
- 不允许底层实现反向决定项目策略形状
- 不允许把“某个 provider / 某个平台 / 某个页面”固化成策略本身

### 共享资产与策略的关系

以下对象默认视为“策略可复用资产”，不得只绑定在某一个页面或单一模式里：

- 风格
- 世界规则
- 角色 / 组织 / 地点 / 物品等实体卡
- 伏笔
- 章节分析结果
- 提示模板
- 导入导出包
- 长任务边界与检查点

策略层负责决定何时使用这些资产；
资产层负责稳定表达这些对象本身。

### 创作约束三层基线

从现在开始，项目级创作约束正式固定为三层，不允许再混成一段散 prompt：

1. `ProjectConstitution`
2. `ModeGuidance`
3. `StyleProfile / ProjectStyleBinding`

它们的职责边界必须始终明确：

- `ProjectConstitution`
  - 表达项目长期创作宪法、质量底线、禁止事项、自然表达约束
  - 这是长期上位约束，不能被 mode guidance 冒充
- `ModeGuidance`
  - 表达某个模式当前已经收束的目标、边界、已确认事实
  - 它只约束当前模式推进，不应反向改写项目宪法
- `StyleProfile / ProjectStyleBinding`
  - 表达语言风格、叙事声音、风格护栏与作用域绑定
  - 风格不是宪法，也不是模式流程

统一优先级：

- 用户当前明确指令
- `ProjectConstitution`
- `ModeGuidance`
- `StyleProfile / ProjectStyleBinding`
- 其他上下文与即时发挥

统一读取规则：

- 宪法优先读取：
  - `specs/project_spec.md`
  - `specs/constitution.md`
  - `premise/project_constitution.md`
  - `premise/constitution.md`
- 模式引导优先读取：
  - `tracking/modes/<mode_id>/guidance.md`
  - 或内部状态映射出的正式 guidance 投影
- 风格优先读取：
  - `styles/*.md`
  - `assets/styles/*.md`

禁止事项：

- 不要把 `constitution` 写成 `style` 的一部分
- 不要让 `mode guidance` 冒充长期项目宪法
- 不要把三层优先级散落在多个 prompt builder、controller 或 adapter 里

### 信息 / 证据纪律的落位

信息收集、资料来源与联网研究属于跨项目的证据纪律，不属于表达限制 preset，也不是技能或智能体人设本身。

最小落位原则：

1. 平台证据底线在 `ProjectConstitution / ModeGuidance / StyleProfile` 三层之外，由宿主权限、工具执行和运行审计维护；项目规则可以加严，不能削弱。
2. 用户可见层只暴露“资料规则 / 研究偏好 / 来源要求 / 是否允许联网”等人话配置；不要把 `information policy`、raw tool request、runtime gate 直接推到普通 GUI。
3. 实现上优先复用现有 `information` 合同、prompt/tool guidance、权限设置、runtime evidence gate；不要为了信息收集新增一个全能配置中心。
4. 智能体可以判断何时需要收集资料，但不能靠自身声明绕过宿主权限，也不能把未验证外部事实写成已验证事实。

### 新增功能的判断顺序

以后新增任意能力时，按下面顺序判断：

1. 它服务哪种 `project_strategy`
2. 它属于哪个 `mode_strategy`
3. 它改变了哪种 `workflow_strategy`
4. 它依赖哪些共享资产
5. 它需要哪些 adapter 能力
6. 最后才考虑 UI 如何呈现

如果无法先回答前 4 个问题，就不应该先写 UI 或底层实现。

## 6.11 协作就绪分块与防双实现约束

从现在开始，项目级正式增加“协作就绪分块”硬约束。

这条约束的第一目标不是把目录拆得好看，而是防止后续协作时出现：

1. 我动你的
2. 你动我的
3. 最后因为同步失配，让同一逻辑长出两个实现

### 核心原则

1. 新功能默认必须先归属到某个稳定能力块，再开始实现。
2. 如果现有块不适合承载该功能，必须先定义新块的：
   - 目标职责
   - 事实源
   - 公开合同
   - 验证入口
   然后再写实现。
3. 一个能力块必须能被单独充实、单独测试、单独修改、单独交付、单独回滚。
4. 一个能力块如果重到无法独立验收，就说明需要继续拆块，而不是继续往里堆。

### 单一主实现出口约束

1. 同一能力块同一时间只能存在一个正式主实现出口。
2. `fallback`、`bridge`、`compat`、`probe`、`viewmodel`、`widget helper` 都不得偷偷长成第二条业务主链。
3. 如果迁移期间必须新旧并存，必须显式标明：
   - 谁是主链
   - 谁是兼容层
   - 何时移除旧链
4. 不允许长期保留“两套都能跑”的模糊状态。

### 单块单主负责约束

1. 同一能力块在同一阶段只能有一个主负责会话或主负责智能体。
2. 其他会话如果需要协作，只能消费该块已经稳定暴露的合同，不能顺手补第二套实现。
3. 如果多个会话都发现同一缺口，优先先停下来确认块边界和主负责方，而不是各自开修。

### 跨块共享缺口处理约束

1. 如果问题跨越多个块，先抽共享合同，再串行落地。
2. 禁止 A 在 app 层补一份、B 在 adapter 层补一份、C 在 probe 层再补一份“差不多能跑”的逻辑。
3. 共享缺口没有合同前，不允许把 UI、probe、脚本或 fallback 变成临时真相源。

### 巡检与改造时的强制检查项

以后对任何现有模块做巡检、补完、重构或协作交接时，必须额外检查：

1. 当前是否已有两个以上入口在做近似同一逻辑
2. 当前是否有 probe / fallback / viewmodel 在复制主链判断
3. 当前是否有新旧链并存但未明确主次
4. 当前是否存在一个会话很容易“顺手改别人的块”的共享地带

如果上述任一项成立，优先先清理分叉风险，再继续加功能。

## 7. 注释规则

### 7.1 中文注释是硬约束

所有函数实现都应有中文注释。

最低要求:

- 函数体开头有中文注释说明“这段实现为什么存在”
- 如果函数有副作用，要写清副作用
- 如果函数有平台限制，要写清限制

### 7.2 注释风格

注释应简洁、真实、面向维护者。

允许:

- 说明意图
- 说明约束
- 说明边界
- 说明为什么不用别的方法

禁止:

- 空话注释
- 把代码逐句翻译成中文
- 明显过时却不更新的注释

## 8. 平台规则

### 8.1 desktop-only 能力

以下能力默认 desktop-only:

- shell / process
- watcher
- 本地批处理
- CLI 自动化链路

这些能力必须通过 capability 判断和 port 暴露，不能直接在共享逻辑里假定可用。

### 8.2 mobile 约束

Android / iOS 不能依赖:

- 外部进程
- 本地 shell 语义
- 桌面路径约定
- 任意目录写权限

### 8.3 GUI 与 CLI 差异

GUI 与 CLI 是两个壳，不是一个模式切换。

禁止:

- 在 GUI 内部硬塞一个伪 CLI 子系统
- 在 CLI 内复制一份 GUI 业务逻辑

## 9. 状态管理规则

- 不使用全局可写单例作为默认状态中心
- feature 状态应尽量局部化
- 共享状态通过明确 facade / use case / session context 暴露
- 持久化状态与界面状态必须分离

## 10. 测试规则

- `core` 的规则优先做单元测试
- `adapters` 的实现优先做集成测试
- GUI 先保证关键流程测试，不追求一次铺满
- CLI 至少保证核心命令的输入/输出与退出码测试

## 10.1 探针与真实接口脚本规则

从现在开始，所有 `probe`、`debug`、`compat`、`connect`、`timing`、`sandbox` 一类脚本，默认视为：

- 排障脚手架
- 临时验收脚本
- 本地人工运行工具

而不是正式产品能力。

必须遵守：

1. 不允许再把“一次性排障探针”直接长期堆进正式 `apps/*/tool/` 或 `packages/*/tool/` 目录。
2. 只有满足“被长期回归、被文档引用、被测试引用、具备稳定输入输出合同”这几个条件的脚本，才允许留在正式 `tool/` 目录。
3. 临时真实接口探针优先放在：
   - 本地未跟踪脚本
   - `artifacts/` 对应工作区
   - 或未来专门的 `devtools/experimental/`、`scratch/`、`local_only/` 之类隔离目录
4. 真实 API 探针默认不得把密钥、固定 provider、固定模型、固定计费入口硬编码进脚本。
5. 真实 API 探针如果需要保留，必须：
   - 明确标注用途
   - 明确标注会消耗真实额度
   - 使用统一本地配置读取
   - 输出稳定报告
   - 尽量具备最小化预算控制
6. 不允许为了临时排障，继续新增一批互相重叠、职责相近、名字只差前缀的 probe 脚本。
7. 如果某条探针已经完成历史使命，但又被正式文档、测试、回归记录依赖，下一步优先做“归档 / 迁移 / 合并”，而不是继续在原地扩张。
8. 真实计费探针默认必须显式开闸后才能运行，不能靠“正好本地配了 provider”就直接消耗额度。
9. 真实计费探针不得把用户机器上的绝对路径、默认项目目录或个人环境目录写死进仓库脚本。

默认判断原则：

1. 能用单元测试、集成测试、现有共享 probe support 完成验证的，不新增新的真实探针脚本。
2. 能放进已有共享 probe 框架的，不再单独长一个新脚本。
3. 需要真实计费模型时，优先复用现有稳定探针入口，不为了单次问题再开新入口。

当前正式约定：

1. 本地真实探针配置优先放在 `local/probe_api.txt`
2. 需要仓库外配置时，用环境变量 `NOVEL_AGENT_PROBE_API_FILE`
3. 真实探针运行前必须设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`
4. 提交前可运行 `dart tools/repository_secret_scan.dart` 做高信号明文密钥自检

## 10.2 项目整洁性维护规则

从现在开始，项目级正式增加“维护工作区与目录整洁性”的长期硬约束。

这条约束同时适用于：

1. 人类开发者
2. 项目内智能体
3. 脚本化批处理或临时修复流程

必须遵守：

1. 不允许长期把大量无关改动、半成品重构、一次性排障残留同时堆在同一个工作区里。
2. 开始新的实现前，如果当前工作区已经明显失控，优先先做：
   - 归档
   - stash
   - 局部提交
   - 或迁移到隔离目录
3. 不允许把本地密钥、接口配置、人工备份、临时报告直接散落在仓库根目录。
4. 一次性排障产物、恢复备份、手工草稿、临时说明，优先放进：
   - `local/`
   - `artifacts/`
   - 或明确的 archive / experimental / scratch 目录
5. 修复完成后，要主动清理本轮新增的：
   - 死文件
   - 过时脚本
   - 已失效注释
   - 多余中间文件
   - 失去职责的临时目录
6. 不允许为了“先能跑”长期保留含混命名、双轨入口、重复脚本、占位常量或失效默认值。
7. 如果因为高风险操作需要先重写历史、硬重置或大规模清理，必须先留下可恢复现场，例如：
   - 带名 stash
   - 明确备份目录
   - patch / snapshot
8. 清理动作本身也必须保持职责清晰：
   - 正式代码回正式目录
   - 本地秘密回本地目录
   - 历史探针回归档目录
   - 临时工作区不反客为主

默认判断原则：

1. 一个改动如果只服务单次排障，就不应长期占据正式实现入口。
2. 一个目录如果开始同时承载正式能力、临时实验和本地私货，就说明需要拆层。
3. 一个工作区如果已经脏到影响判断、验证或恢复，就应先整理，再继续扩张。

## 11. 文档规则

以下变化必须同步更新文档:

- 新增 package
- 新增 native 依赖
- 改变依赖方向
- 改变平台策略
- 改变注释规则
- 改变目录职责

至少更新:

- `agent.md`
- `docs/architecture.md`

## 11.1 技能包规则

技能包必须遵守以下长期约束：

1. 标准目录优先使用 `skills/<id>/SKILL.md`，入口文件名大小写不敏感。
2. `SKILL.md` 优先使用 YAML frontmatter；至少包含 `name` 与 `description`。
3. 技能元数据必须分层:
   - 顶层只放“可移植核心字段”，例如 `id`、`name`、`description`、`version`、`tags`
   - NovelAgent 私有扩展统一放入 `metadata.novel_agent`
   - 不允许把 NovelAgent 专用字段长期散落在顶层
4. 技能要声明“能力需求”，不要把宿主内置工具名写成硬依赖前提。
5. 技能在没有工具时也应尽量能降级为流程指导、结构草案或人工步骤。
6. 详细资料优先放 `references/`，确定性步骤优先放 `scripts/`，最终产出模板优先放 `assets/`。
7. 不要把同一份长信息同时堆在 `SKILL.md` 和 `references/`。
8. 默认加载技能时优先返回摘要，不默认把整份超长技能正文塞入上下文；完整正文必须按需读取。
9. 内置技能与外部技能使用同一包结构与解析规则，不允许内置另搞一套私有格式。

## 11.2 智能体包规则

智能体包必须遵守以下长期约束：

1. 标准目录优先使用 `agents/<id>/AGENT.md`，入口文件名大小写不敏感。
2. `AGENT.md` 优先使用 YAML frontmatter；至少包含 `name`、`description`、`role`、`objective`。
3. 智能体元数据必须分层:
   - 顶层只放“可移植核心字段”，例如 `id`、`name`、`description`、`role`、`objective`、`can_do`、`must_not_do`
   - NovelAgent 私有运行参数统一放入 `metadata.novel_agent`
   - 不允许把宿主专用 provider / preset / model override 长期散落在顶层
4. 智能体必须显式声明边界：建议至少给出 `can_do` 与 `must_not_do`。
5. 智能体应声明其知识来源与能力依赖，优先写“能力类型”，不要把具体宿主工具名写成唯一前提。
6. 预期输出可以通过 `preferred_output`、`output_schema_path` 或 `output_schema` 表达。
7. 智能体应声明记忆与反思策略，例如 `short_term_memory_policy`、`long_term_memory_paths`、`reflection_mode`。
8. `references/`、`scripts/`、`assets/`、`schemas/`、`memory/` 等资源目录可以按需存在，但含义必须稳定。
9. 内置智能体与外部智能体使用同一包结构与解析规则，不允许内置另搞一套私有格式。

## 12. 演化策略

### 第一阶段

- 先立边界
- 先立 contracts
- 先做最小共享核心

### 第二阶段

- 打通 GUI 与 CLI 的第一条共享链路
- 只在需要时补 adapters

### 第三阶段

- 通过 profiling 判断是否需要 native hotspot
- 如果需要，再局部引入 C++ engine

## 13. 决策总结

当前正式路线是:

- `Flutter GUI + Dart CLI + 纯 Dart core`

当前明确不做:

- 一开始就全量 C++ 化
- 一开始就插件系统化
- 一开始就过度拆 package

未来允许:

- 针对热点局部引入 C++ / FFI

但前提永远是:

- 先有边界
- 再有实现
- 先能演化
- 再追求更重的底层优化
