# 职责矩阵

## 分层矩阵

| 层 | 位置 | 负责 | 不负责 |
| --- | --- | --- | --- |
| App Shell | `apps/novel_agent_app` | 页面、路由、交互、生命周期 | 共享业务规则、adapter 实现 |
| CLI Shell | `apps/novel_agent_cli` | 命令、输出、退出码 | GUI 状态、共享业务规则重写 |
| Core | `packages/novel_agent_core` | 模型、用例、workflow、ports | UI、具体 IO、平台实现 |
| Adapters | `packages/novel_agent_adapters` | 存储、provider、host、native 封装 | 页面逻辑、业务总控 |
| Native | `native/` | 可选高性能引擎 | 高层业务编排 |

## 模块矩阵

| 模块 | 输入 | 输出 | 约束 |
| --- | --- | --- | --- |
| `project` | 项目路径、项目配置 | 项目描述、文件索引 | 不直接做 UI，不直接管 workflow 内部状态 |
| `session` | 用户输入、模型流事件 | 会话消息、会话状态 | 不承担项目存储 |
| `workflow` | 任务定义、运行上下文 | 运行状态、任务事件 | 不直接读写 UI |
| `agents` | profile、上下文、能力 | agent 计划、agent 结果 | 不直接依赖具体 provider 实现 |
| `tools` | 工具合同、权限策略 | 工具调用结果、工具事件 | 不知道页面结构 |
| `settings` | 配置读取请求 | 配置快照 | 不直接依赖界面控件 |

## bootstrap 规则

只有以下位置可以组装系统:

- `apps/novel_agent_app/lib/app/bootstrap/`
- `apps/novel_agent_cli/lib/bootstrap/`

feature 或 command 内禁止:

- 直接实例化 adapter
- 直接决定 native 或 mock 实现
- 直接读取平台能力细节
