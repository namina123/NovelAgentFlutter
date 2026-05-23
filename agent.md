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

### 6.3 跨模块访问规则

- `project` 不能直接操纵 `workflow` 内部状态。
- `workflow` 不能直接读写 UI 状态。
- `tools` 不能直接了解具体页面结构。
- `session` 不能偷偷承担项目存储。

模块之间只通过:

- 明确的模型
- 明确的用例
- 明确的 port

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
3. 技能要声明“能力需求”，不要把宿主内置工具名写成硬依赖前提。
4. 技能在没有工具时也应尽量能降级为流程指导、结构草案或人工步骤。
5. 详细资料优先放 `references/`，确定性步骤优先放 `scripts/`，最终产出模板优先放 `assets/`。
6. 不要把同一份长信息同时堆在 `SKILL.md` 和 `references/`。
7. 内置技能与外部技能使用同一包结构与解析规则，不允许内置另搞一套私有格式。

## 11.2 智能体包规则

智能体包必须遵守以下长期约束：

1. 标准目录优先使用 `agents/<id>/AGENT.md`，入口文件名大小写不敏感。
2. `AGENT.md` 优先使用 YAML frontmatter；至少包含 `name`、`description`、`role`、`objective`。
3. 智能体必须显式声明边界：建议至少给出 `can_do` 与 `must_not_do`。
4. 智能体应声明其知识来源与能力依赖，优先写“能力类型”，不要把具体宿主工具名写成唯一前提。
5. 预期输出可以通过 `preferred_output`、`output_schema_path` 或 `output_schema` 表达。
6. 智能体应声明记忆与反思策略，例如 `short_term_memory_policy`、`long_term_memory_paths`、`reflection_mode`。
7. `references/`、`scripts/`、`assets/`、`schemas/`、`memory/` 等资源目录可以按需存在，但含义必须稳定。
8. 内置智能体与外部智能体使用同一包结构与解析规则，不允许内置另搞一套私有格式。

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
