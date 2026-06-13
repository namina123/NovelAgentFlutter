# Docker 长任务运行可行性分析 - 2026-06-05

最后更新：2026-06-05

关联文档：

- `README.md`
- `docs/architecture.md`
- `docs/release-readiness-final-closeout-2026-06-05.md`
- `docs/cli-release-boundary-2026-06-05.md`
- `agent.md`

---

## 1. 问题定义

这次讨论的不是“要不要把整个应用塞进 Docker”，而是：

**Docker 是否适合作为 NovelAgentFlutter 的长任务/拆书类无界面运行壳层，以及应该在什么时候开始做、做到什么边界、工作量大概有多大。**

用户已经明确收缩了范围：

1. Docker 一般只应支持与长任务相关的创作流程。
2. Docker 应能覆盖拆书及拆书后续承接的头部流程。
3. Docker 不应试图承载 Flutter GUI。
4. Docker 的价值应更多偏向：
   - 长时间运行
   - 无界面运行
   - 可挂载项目目录
   - 可恢复
   - 可自动化

所以这里要分析的是：

**Docker 作为第三壳层是否合理。**

不是：

**Docker 作为 GUI 替代品是否合理。**

---

## 2. 当前现实基线

先不谈理想状态，只谈当前仓库的真实情况。

### 2.1 已经具备的基础

1. `packages/novel_agent_core` 是纯 Dart 核心层。
2. `packages/novel_agent_adapters` 已经把：
   - 本地项目存储
   - provider 接入
   - 长任务 registry / supervisor
   - 工作流运行时
   - 工具分发
   放在共享适配层。
3. `apps/novel_agent_cli` 已经不是空壳：
   - 已有 `workflow` 命令族
   - 已有 `project` 命令族
   - 已有 `asset` / `review` / `template` 命令族
   - 已能直接驱动共享 `ProjectWorkflowRuntimeService`
4. CLI bootstrap 已经是正式 composition root，不需要从 GUI 里借壳运行。
5. 设置、默认项目根、Provider 等已经支持环境变量与文件混合解析。

### 2.2 还没有准备好的地方

1. 真实 provider 下的长任务稳定性仍是当前 P0 阻断：
   - 缺章
   - 早停
   - 失败后继续推进
   - focused probe 技术性失败
2. CLI 目前已经能跑长任务链，但**拆书专属 headless 命令还没有独立长出来**。
3. GUI 里的拆书流仍带有明显宿主/UI 假设，例如：
   - 桌面文件选择
   - GUI 控制器与状态消息
4. 当前 CLI 仍被定义为：
   - 共享 core/adapters 的运维/实验壳层
   - 不是成熟产品入口
5. 当前 release 结论已经明确：
   - GUI 只能做受限 beta
   - 长任务自主连续推进不能对外承诺可用

### 2.3 这意味着什么

这意味着：

**Docker 在技术层面可以开始设计，但在产品层面还不能被包装成正式稳定能力。**

否则只是把当前长任务的不稳定，从桌面环境搬进容器环境而已。

---

## 3. 可行性结论

## 3.1 技术可行性

结论：**高。**

原因很直接：

1. 当前最适合进 Docker 的不是 GUI，而是 `apps/novel_agent_cli`。
2. CLI 依赖很轻：
   - `novel_agent_core`
   - `novel_agent_adapters`
3. 当前长任务主链本来就已经通过共享 runtime service 暴露给 CLI。
4. 本地项目目录、SQLite 项目存储、运行记录、长任务 registry 都是文件系统友好型形态。
5. 设置根目录与默认项目目录已经支持环境变量覆盖，天然适合容器挂载。

所以从工程上说：

**把 Docker 定位成“CLI 的容器宿主”是完全合理的。**

## 3.2 产品可行性

结论：**有限可行。**

更准确地说：

1. 作为内部开发/验证/批处理壳层：可行。
2. 作为受限 alpha 的长任务 worker：可行。
3. 作为对外承诺“稳定自动长篇创作”的正式能力：暂不可行。

原因不是 Docker 本身，而是当前真实长任务链还没有达到可放行状态。

## 3.3 架构可行性

结论：**合理，而且比把 GUI 容器化合理得多。**

最合理的定位是：

```text
Flutter GUI = 交互壳
Dart CLI = 无界面操作壳
Docker = CLI 的运行宿主 / 调度宿主
core + adapters = 三者共享的业务骨架
```

这与当前架构基线是一致的，没有逆着仓库方向走。

---

## 4. Docker 最合适承载什么

当前最合适的，不是“全功能应用容器”，而是：

## 4.1 第一优先：长任务运行壳

Docker 第一阶段最适合承载：

1. `workflow create`
2. `workflow list`
3. `workflow next`
4. `workflow preflight`
5. `workflow chain`
6. `workflow run-once`
7. `workflow run-next`
8. `workflow run-queue`
9. `workflow pause`
10. `workflow resume`
11. `workflow checkpoint-actions`
12. `workflow apply-checkpoint-action`
13. `workflow revision-resolution`
14. `workflow apply-revision-resolution`
15. `workflow accept-revision`
16. `workflow rollback-revision`

也就是说，Docker 首先应该是：

**长任务 headless 执行器。**

## 4.2 第二优先：项目导入与续写前置壳

为了让长任务真能在容器里跑起来，Docker 还需要最少量的前置项目操作能力：

1. `project summary`
2. `project import`
3. `project preview-package`
4. `project import-package`
5. `asset` 相关导入/预检能力

这类能力不是“Docker 要做通用项目管理”，而是：

**它们是长任务和拆书承接的必要前置动作。**

## 4.3 第三优先：拆书 headless 链

这一块当前还不适合直接宣称已可用，因为 CLI 里没有正式拆书命令族。

但从方向上看，Docker 最终应该支持：

1. 导入拆书源文本
2. 触发结构化拆书分析
3. 持久化拆书结果
4. 把拆书结果转入普通续写或长任务续写基座

换句话说：

**Docker 不只是跑“写作后半段”，还应该最终覆盖“拆书 -> 承接 -> 长任务续写”的头部链路。**

只是这一步必须建立在先把拆书流抽成共享 headless 用例之后。

---

## 5. Docker 明确不该承载什么

为了避免范围失控，以下内容不应作为第一阶段 Docker 目标：

1. Flutter GUI 容器化。
2. 桌面文件选择器相关流程。
3. 面向移动端的任何宿主假设。
4. 通用实时聊天式工作台体验。
5. 把容器做成“第二套产品前端”。
6. 默认开放任意宿主命令执行。
7. 用 Docker 去掩盖当前长任务稳定性问题。

第一阶段 Docker 应该是：

**无界面运行壳。**

不是：

**第二个交互产品。**

---

## 6. 当前最大的真实阻碍

## 6.1 不是 Dockerfile

当前最大的阻碍根本不是：

- 没写 Dockerfile
- 没写 compose
- 不会把 Dart 打进镜像

而是：

**共享长任务链还没有被证明在真实 provider 下足够稳定。**

如果现在就重做一轮 Docker 包装，最后只会得到：

1. 一个能启动的容器；
2. 一条依旧会缺章、早停、失败后继续推进的长任务链。

这在工程上是“可运行”，在产品上却不是“可交付”。

## 6.2 拆书流还没有 headless 收束

当前拆书更多还是：

1. GUI 流程；
2. 项目内预演；
3. 持久化与承接基础已经开始有了；
4. 但没有明确的 CLI 命令宿主。

所以如果 Docker 要支持拆书，不是简单加一层容器，而是要先做：

**拆书共享 headless 用例提炼。**

## 6.3 宿主命令与容器安全边界还没正式定义

当前 `ProjectGatewayProcessService` 已支持：

1. Windows 走 `powershell`
2. Unix 走 `/bin/sh -lc`

这说明 Docker 里技术上能运行宿主命令。

但问题是：

1. 容器是否默认允许这类工具？
2. 允许哪些命令？
3. 工作目录和挂载目录如何隔离？
4. 长任务里哪些工具必须禁用、哪些可以启用？

这需要一份专门的容器安全边界定义，不能直接沿用桌面宿主的宽松假设。

---

## 7. 什么时候适合开始做

## 7.1 可以“现在就开始”的部分

如果“开始做”的意思是：

1. 明确 Docker 边界；
2. 确定 CLI 命令矩阵；
3. 设计容器环境变量合同；
4. 设计挂载目录结构；
5. 做最小镜像 smoke test；

那么答案是：

**现在就可以开始。**

因为这些事情本质上是架构收口，不会放大现有长任务的不稳定性。

## 7.2 不适合现在就开始的部分

如果“开始做”的意思是：

1. 对外宣传 Docker 长任务可用；
2. 把 Docker 作为正式运行方式；
3. 让 Docker 承担长时间无人值守写作承诺；

那么答案是：

**现在不适合。**

至少要满足以下前提后再进入正式推进：

1. 真实 provider 长任务缺章问题收口；
2. supervisor / recovery 不再允许坏交付静默跨过去；
3. CLI 至少具备一条正式拆书 headless 命令链；
4. 容器运行目录、日志目录、设置目录、项目目录的挂载约定固定。

## 7.3 最合适的开始时机

最佳策略不是“完全等稳定后再碰 Docker”，也不是“现在就全量上 Docker”，而是：

### 阶段 A：现在开始设计和最小脚手架

只做：

1. 容器边界分析
2. Dockerfile 初版
3. Compose 初版
4. `novel_agent_cli help` / `workflow help` / `project summary` smoke

### 阶段 B：长任务 P0 稳定性阻断收口后

再做：

1. `workflow create/run-queue/pause/resume` 真链路容器验证
2. volume 持久化与恢复验证
3. 日志、退出码、失败重进容器策略

### 阶段 C：拆书 headless 化完成后

再接：

1. 拆书输入
2. 拆书结果持久化
3. 拆书 -> 续写 -> 长任务承接

这个节奏是最稳的。

---

## 8. 最合理的 Docker 形态

## 8.1 不建议先做常驻后台服务

当前最合理的第一形态不是 daemon，不是 API 服务，而是：

**job-first / command-first container**

也就是每次明确执行一条 CLI 命令，例如：

```text
docker run ... novel-agent workflow run-queue --project /workspace/project --steps 3
docker run ... novel-agent workflow resume --project /workspace/project
docker run ... novel-agent project summary --project /workspace/project
```

这样做的好处：

1. 与现有 CLI 形态完全一致；
2. 不需要先设计一整套长期驻留协议；
3. 容器失败与命令失败边界清楚；
4. 容易做 CI / cron / 调度器集成；
5. 不会过早把当前 supervisor 设计再包成第二层常驻系统。

## 8.2 第二阶段才考虑常驻 worker

只有当下面几件事都稳定之后，才值得考虑常驻 worker：

1. 长任务真实稳定性通过；
2. pause/resume/recover 行为在 CLI 与文件持久化层都稳定；
3. run registry 与 heartbeat 行为在单机无界面环境中验证足够；
4. 已经明确需要：
   - 自动续跑
   - 定时巡检
   - 后台运行
   - 更少人工敲命令

否则过早上 daemon，只会把当前问题再包一层。

## 8.3 第三阶段才考虑 HTTP/API 外壳

如果未来真有需要把 Docker 接进：

1. Web 面板
2. 远程调度器
3. 多节点执行器

那也是第三阶段的事情。

当前完全没必要为了 Docker 先引入 HTTP 服务层。

---

## 9. Docker 对当前仓库的具体要求

## 9.1 必须复用 `apps/novel_agent_cli`

Docker 不应新增一套“容器专用主程序”。

正确方向是：

1. 复用 `apps/novel_agent_cli/bin/novel_agent.dart`
2. 复用 `CliBootstrap`
3. 复用 `AdapterBundle.standard(...)`
4. 通过环境变量和 volume 调整宿主路径

这样 Docker 只是宿主变化，不是业务变化。

## 9.2 必须显式定义容器环境变量合同

至少应定义：

1. `NOVEL_AGENT_SETTINGS_ROOT`
2. `NOVEL_AGENT_SETTINGS_PATH`
3. `NOVEL_AGENT_DEFAULT_PROJECT_ROOT`
4. `NOVEL_AGENT_PROVIDER_ID`
5. `NOVEL_AGENT_MODEL_ID`
6. Provider 凭据相关环境变量
7. 代理/网络配置相关环境变量

否则容器内的设置目录、默认项目目录、密钥读取会很混乱。

## 9.3 必须固定 volume 语义

建议至少分为：

1. 项目工作区 volume
2. 设置与运行状态 volume
3. 日志/导出产物 volume

避免把所有东西都混进一个容器层目录里。

## 9.4 必须明确 Linux 宿主优先

虽然 CLI 架构支持 Windows/macOS/Linux，但 Docker 第一阶段应默认：

**Linux 容器优先。**

原因：

1. 容器生态默认就是 Linux 体验最稳；
2. 当前 `ProjectGatewayProcessService` 在 Unix 下已有 `/bin/sh -lc` 分支；
3. 可以避免把 Windows 宿主 shell 细节带进容器边界定义。

---

## 10. 工作量评估

这里按“受控范围内的 Docker 长任务壳”来评估，而不是按“全平台完整产品”来评估。

## 10.1 纯分析 + 最小脚手架

工作量：**小到中**

大致内容：

1. Docker 边界文档
2. `Dockerfile` 初版
3. `.dockerignore`
4. `docker-compose.yml` 初版
5. CLI help / summary smoke

如果只做这层，一般是 **2 到 4 个任务切片**。

## 10.2 可供内部使用的长任务 Docker Alpha

工作量：**中**

大致内容：

1. 上述最小脚手架
2. 长任务命令矩阵收口
3. 环境变量合同
4. volume 设计
5. 容器内真实 `workflow create/run-queue/pause/resume` 验证
6. 失败与退出码契约
7. release 文档与使用说明

这大概是 **6 到 10 个任务切片**。

## 10.3 可承接拆书链的 Docker Alpha

工作量：**中到大**

因为它额外要求：

1. 把拆书流从 GUI 依赖里抽出 headless 入口
2. 为 CLI 新增正式拆书命令
3. 验证拆书结果如何进入续写或长任务链
4. 做 volume/目录结构上的长期保存

这部分通常至少再加 **4 到 8 个任务切片**。

## 10.4 可对外描述的成熟 Docker 能力

工作量：**大**

只有在下面都完成后才有资格谈：

1. 长任务真实稳定性通过
2. 拆书 headless 化完成
3. CLI 边界完善
4. 容器安全边界明确
5. 日志、恢复、升级、文档、示例、运维习惯收口

这一层不应在当前阶段轻易承诺。

---

## 11. 建议的正式结论

可以把结论压缩成一句话：

**Docker 值得做，但当前最合理的做法不是把它当成熟产品能力立刻推进到底，而是把它作为“CLI 驱动的长任务/拆书 headless 运行壳”分阶段建设。**

更具体一点：

1. **现在就适合开始做分析、边界、脚手架。**
2. **现在还不适合把 Docker 当成长任务稳定性交付方案对外承诺。**
3. **Docker 第一阶段只应服务长任务和拆书相关流程，不做 GUI。**
4. **Docker 必须长在 CLI 这条线上，而不是绕开 CLI 再造一层。**
5. **在拆书 CLI 命令和长任务稳定性没有收口之前，Docker 只能算内部 alpha 壳，不算正式产品面。**

---

## 12. 推荐的下一步

如果后续要正式推进，最合理的下一轮不是直接写一堆 Docker 文件，而是先确认下面两件事：

1. Docker 第一阶段是否明确只做：
   - `novel_agent_cli`
   - `workflow`
   - 必要 `project/asset` 前置链
   - 不含 GUI
2. 拆书是否先补一条正式 CLI / headless 命令链，再谈 Docker 承接拆书。

如果这两点确认了，Docker 就可以作为一条独立但收敛的主线开始做。

