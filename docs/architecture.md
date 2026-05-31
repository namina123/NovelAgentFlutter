# NovelAgentFlutter 架构基线

## 目标

这个项目同时支持两类应用:

- Flutter GUI: `windows / linux / macos / android / ios`
- Dart CLI: `windows / linux / macos`

第一阶段不追求大而全，先保证三件事:

1. GUI 和 CLI 共享同一套核心业务规则。
2. 平台差异被隔离在边界层，而不是渗透到所有功能里。
3. 仓库默认鼓励“小而可演化”的模块，而不是新的巨型中心文件。

## 非目标

当前阶段不做这些事:

- 不提前抽很多 package。
- 不为了“看起来高级”引入复杂插件系统。
- 不先做全部功能地图。
- 不把旧项目逐文件平移过来。

## 仓库形状

第一版采用最小可行 monorepo:

```text
apps/
  novel_agent_app/
  novel_agent_cli/
packages/
  novel_agent_core/
  novel_agent_adapters/
docs/
```

只保留两个共享包:

- `novel_agent_core`
- `novel_agent_adapters`

这样做是为了先把边界立住，而不是一开始就拆成很多半空包。

## 职责边界

### `apps/novel_agent_app`

Flutter GUI 壳层，职责只有:

- 页面和导航
- 组件和交互
- 响应式布局
- 权限申请的用户体验
- 平台入口和生命周期接线

它不负责:

- 核心工作流规则
- Provider 请求协议
- 项目存储规则
- 桌面 CLI 命令语义

### `apps/novel_agent_cli`

桌面 CLI 壳层，职责只有:

- 命令解析
- stdout/stderr 呈现
- 退出码
- 批处理 / 自动化入口

它不负责:

- GUI 状态管理
- Flutter 组件状态
- 业务核心规则重写

### `packages/novel_agent_core`

纯 Dart 核心层，负责:

- 领域模型
- 用例
- 工作流编排
- 会话/项目/任务/智能体的状态合同
- 能力接口定义

它不负责:

- Flutter UI
- 文件系统具体实现
- HTTP 客户端具体实现
- 进程执行具体实现
- 平台判断细节

建议的内部结构:

```text
lib/src/
  project/
  session/
  workflow/
  agents/
  llm/
  tools/
  settings/
  ports/
```

当前已经开始承接旧项目纯逻辑迁移的子域:

- `creative`
- `context`
- `llm/catalog`
- `llm/capabilities`
- `llm/profile`
- `project`
- `records`
- `review`
- `session`
- `tools`
- `workflow`

旧项目模块的去向判定详见 `docs/legacy-migration-boundary.md`。

### 创作约束共享子域

`novel_agent_core/lib/src/creative/` 负责项目级创作约束三层：

- `ProjectConstitution`
- `ModeGuidance`
- `StyleProfile / ProjectStyleBinding` 的运行期收束

这个子域只负责：

- 三层正式模型
- 解析优先级
- 上下文注入摘要
- 供 review / revision / long task / 普通生成共用的稳定合同

它不负责：

- 文件系统读取实现
- Flutter 页面状态
- provider 私有提示词拼接

统一优先级固定为：

`用户当前明确指令 > ProjectConstitution > ModeGuidance > StyleProfile / ProjectStyleBinding > 其他上下文`

### `packages/novel_agent_adapters`

适配器层，负责:

- 本地项目存储
- 模型 provider 接入
- 文件系统读写
- 桌面进程执行
- 配置加载
- 平台能力探测

它实现 `novel_agent_core` 定义的 ports，但不反向把 UI 逻辑带回核心。

建议的内部结构:

```text
lib/src/
  storage/
  providers/
  host/
  config/
  bootstrap/
```

## 依赖规则

依赖方向只能这样走:

```text
app -> core
cli -> core
bootstrap -> adapters
adapters -> core
core -> nobody
```

禁止:

- `core -> adapters`
- `core -> Flutter`
- `cli -> app`
- `app -> cli`
- `feature -> adapters`

## 平台与应用矩阵

### GUI

| 能力 | Windows | Linux | macOS | Android | iOS |
| --- | --- | --- | --- | --- | --- |
| Flutter GUI | yes | yes | yes | yes | yes |
| 本地项目读写 | yes | yes | yes | sandbox-aware | sandbox-aware |
| 外部进程执行 | yes | yes | yes | no | no |
| 桌面 CLI | no | no | no | no | no |

### CLI

| 能力 | Windows | Linux | macOS |
| --- | --- | --- | --- |
| Dart CLI | yes | yes | yes |
| 批处理工作流 | yes | yes | yes |
| 外部进程执行 | yes | yes | yes |

结论:

- CLI 是一个独立应用，不是 GUI 的“附属模式”。
- desktop-only 能力必须经过 adapter 边界暴露。
- mobile 端不能依赖桌面进程和 shell 语义。

## 核心技术策略

当前正式策略:

- 用 `Flutter` 做 GUI
- 用 `Dart` 做桌面 CLI
- 用 `纯 Dart` 做共享核心

原因不是“Dart 万能”，而是当前最需要解决的是演化成本和边界问题。

### 为什么现在不先做 C++ 核心

- 大量核心逻辑属于业务编排，不是原生性能热点。
- 如果过早下沉到 C++，调试和演化成本会明显提高。
- 当前主要风险来自架构失控，而不是 CPU 不够。

### 什么时候引入 C++

只有在经过 profiling 后确认以下情况之一时，才考虑引入:

- 明确性能热点
- 明确内存热点
- 明确需要复用成熟 native 库
- 明确属于底层引擎能力而不是高层业务规则

### 如果未来引入 C++

引入方式必须是:

```text
core contracts -> adapters -> ffi/native engine
```

不能变成:

```text
ui -> native business core
```

也就是说，C++ 未来只能是局部下沉的 native engine，不是项目第一阶段的总核心。

## 核心模块划分

第一阶段只保留 6 个核心模块概念，不再比这更碎:

### 1. `project`

负责:

- 项目结构
- 项目配置
- 项目文件索引

### 2. `session`

负责:

- 会话
- 消息
- 流式事件
- 运行上下文

### 3. `workflow`

负责:

- 任务编排
- 长任务
- 可恢复运行
- 状态机

### 4. `agents`

负责:

- Agent profile
- agent 调度
- 子 agent 运行合同

### 5. `tools`

负责:

- 工具合同
- 权限模型
- 工具调用记录

### 6. `settings`

负责:

- provider/profile/settings 的聚合合同
- 面向应用层的配置读取与保存接口

## 演化原则

### 原则 1: 先做垂直切片，再做横向抽象

先打通一个完整链路，例如:

- 打开项目
- 创建会话
- 发起一次模型请求
- 接收流式结果
- 落盘

只有当 GUI 和 CLI 都要复用一段逻辑时，才把它稳定放进 `core`。

### 原则 2: 先包内分层，后包间拆分

如果 `novel_agent_core` 内某个子模块开始明显膨胀，先在包内整理目录和接口，再判断是否值得独立成新 package。

### 原则 3: composition root 只放在 app 边界

依赖组装应发生在:

- `apps/novel_agent_app`
- `apps/novel_agent_cli`

不要把“如何实例化全系统”变成另一个共享大文件。

同时补一条更强的约束:

- `adapters` 只允许在 bootstrap / composition root 被组装
- feature 页面和 CLI command 不允许直接 new adapter

### 原则 4: desktop-only 必须显式

例如:

- shell process
- watcher
- CLI batch tools

这些能力必须通过显式 port 暴露，并返回明确的 capability 状态。

## 防发胖规则

1. 单文件超过 400 行时要做职责复核。
2. 单文件超过 700 行时，除生成文件外必须拆分。
3. 不引入全局可写单例作为默认状态中心。
4. 不允许 UI 层直接依赖 provider 实现。
5. 不允许 CLI 复制 GUI 的业务逻辑。
6. 不允许把平台分支散落在 feature 代码里。

## 第一阶段落地顺序

### Phase 1

- 建立仓库骨架
- 明确边界
- 定义核心模块词汇表

### Phase 2

- 初始化 `novel_agent_core`
- 定义第一批 ports
- 定义项目 / 会话 / 运行事件模型

### Phase 3

- 初始化 `novel_agent_app`
- 初始化 `novel_agent_cli`
- 分别建立各自 composition root

### Phase 4

- 初始化 `novel_agent_adapters`
- 接入本地存储
- 接入第一个模型 provider

### Phase 5

- 打通第一个共享用例
- GUI 可跑
- CLI 可跑
- 两边复用同一核心逻辑

## 当前决定

当前我们明确选择:

- 少 package
- 强边界
- 纯 Dart 核心
- GUI / CLI 双壳
- 桌面能力显式隔离

这就是新项目的第一版架构层。
