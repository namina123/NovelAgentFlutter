# 全局 UI 卡死根因分析（2026-06-19）

## 1. 这份文档解决什么

这份文档不讨论某一个按钮、某一个页面、某一个组件的局部 bug。

它只回答一个问题：

**为什么当前应用会出现“几乎整个 GUI 都有概率未响应”的现象，以及为什么这类问题不能再靠局部补丁解决。**

这里的“卡死”包括但不限于：

1. 启动后恢复项目时卡顿或无响应。
2. 左侧导航切换时卡顿或无响应。
3. 打开项目创建、新建作品、拆书、智能体生态、项目资产等页面时卡顿或无响应。
4. 明明只是做 UI 选择，却像触发了整条项目恢复链一样变慢。
5. 页面切来切去后，卡死范围从单个功能扩散到几乎整个壳层。

本分析的目标是给出：

1. 真实共因。
2. 文件级证据。
3. 为什么前面一些优化只能缓解、不能根治。
4. 下一阶段应如何重构，而不是继续“修一个点，坏另一片”。

---

## 2. 结论先行

这轮分析后的结论很明确：

**当前 UI 普遍卡死的根本原因，不是某个单独页面里还有一点同步 IO 没改完，而是“壳层导航、页面生命周期、项目恢复、全局投影同步、子域自刷新”五套机制被耦合在一起，形成了系统性的重入刷新风暴。**

更具体地说，当前系统同时存在五个共因：

1. **导航切页会重建整页子树。**
2. **页面一重建，就会再次触发自己的 `initialize/refresh`。**
3. **项目加载采用了“先显示，再后台恢复”，但后台恢复仍通过同一个全局壳层持续回写 UI。**
4. **壳层控制器仍然是全局状态与多子域状态的共享瓶颈。**
5. **大量文件扫描、目录遍历、信息投影与列表重建虽然写成了 `async`，但仍在主 isolate 上高频发生。**

所以用户看到的现象才会是：

1. 不只某一个功能卡。
2. 不是只有某一处切页卡。
3. 甚至只是新建项目里切换一个类型，也能把应用拖到未响应。

这不是偶然，而是结构决定的。

---

## 3. 本轮观察到的症状类型

结合近期真实使用与本轮代码审查，当前卡死可分成四类：

### 3.1 启动/恢复型卡死

表现：

1. 应用启动后恢复默认项目时卡。
2. 明明用户还在创建项目，后台却像在恢复一个旧项目。
3. 启动后的首屏交互经常“不干净”。

### 3.2 导航切页型卡死

表现：

1. 左栏切换到作品库、创作台、智能体生态、设置等页面时卡。
2. 有时切过去卡，有时切回来卡。
3. 范围越来越像“整个 UI 都可能卡”。

### 3.3 子域自刷新型卡死

表现：

1. 打开长任务总站就刷新。
2. 打开作品库就扫描项目目录。
3. 打开项目资产就加载整套资产与 RAG 状态。
4. 某些页签切过去的一瞬间，实际上在后台跑了不止一层加载。

### 3.4 项目生命周期穿透型卡死

表现：

1. 创建项目、打开项目、派生项目、跳转到长任务对应项目时，都会重新卷入项目加载链。
2. 项目恢复还没彻底稳定，用户已经在别的页面操作，于是两个生命周期互相打架。

---

## 4. 这轮已确认的关键事实

这部分不是推测，而是从代码里能直接看到的事实。

### 4.1 根壳按 `destination` 重建页面子树

在 [app_shell.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/shared/widgets/app_shell.dart:49) 到 [app_shell.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/shared/widgets/app_shell.dart:52)：

1. 当前页面被包在 `KeyedSubtree(key: ValueKey(destination))` 里。
2. 这意味着只要 `destination` 变化，就不是“同页数据更新”，而是“整页子树按目的地重新挂载”。

这本身就很关键，因为一旦重挂载：

1. `StatefulWidget.initState` 会再跑。
2. 页面内 `addPostFrameCallback` 会再跑。
3. 某些 feature controller 的 `initialize()` / `refresh()` 会再次触发。

所以“切一下导航”在当前架构里，并不轻。

### 4.2 多个页面本身就会在挂载时自初始化/自刷新

已确认的例子包括：

1. [long_task_station_page.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/long_task_station/presentation/pages/long_task_station_page.dart:28) 到 [long_task_station_page.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/long_task_station/presentation/pages/long_task_station_page.dart:32)  
   页面 `initState` 里会调 `controller.initialize()`。
2. [long_task_station_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart:88) 到 [long_task_station_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/long_task_station/application/controllers/long_task_station_controller.dart:95)  
   `initialize()` 里直接 `await refresh()`。
3. [app_shell_destination_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart:54) 到 [app_shell_destination_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart:74)  
   切到任务中心或长任务总站时，导航动作本身也会触发刷新或初始化。

换句话说：

1. 切页本身会重建页面。
2. 页面重建后自己又会主动刷新。
3. 导航动作自身有时还会再触发一次刷新。

这已经形成了天然的重入风险。

### 4.3 `AppShellController` 仍是全局通知瓶颈

在 [app_shell_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_controller.dart:5017) 到 [app_shell_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_controller.dart:5026)：

1. `_safeNotifyListeners()` 每次都会先 `_listenableState.syncFrom(...)`
2. 然后 `notifyListeners()`

而 `AppShellController` 本身仍是一个超大控制器，承担：

1. 初始化。
2. 目的地切换。
3. 项目打开。
4. 设置页动作。
5. 生态页动作。
6. 项目入口页动作。
7. 长任务联动。
8. 各种子控制器装配与跨域联动。

这意味着很多互不相干的动作，最后都会汇到同一个壳层通知出口。

### 4.4 项目恢复虽然已经拆成 deferred hydration，但仍持续回写全局 UI

在 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:330) 到 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:609)：

项目加载已经拆成：

1. 先拿 workspace snapshot。
2. 先显示项目壳。
3. 后台继续做 hydration。

这是正确方向。

但问题是，hydration 的每个阶段仍会通过同一条 `mutateWorkbench -> AppShellController._safeNotifyListeners` 链持续回写：

1. 运行时配置恢复。
2. 会话恢复。
3. 资料面板恢复。
4. 最近项目落盘。
5. 智能体生态刷新。
6. 工作台快照恢复。
7. 默认文档恢复。
8. 长任务摘要刷新。
9. 目标页刷新。

也就是说：

**项目加载虽然不再一次性堵住首帧，但它仍会在后台持续搅动整个壳层。**

### 4.5 作品库扫描和资料投影仍在主 isolate 上做大量遍历

#### 作品库

在 [project_open_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/project_open/application/services/project_open_view_data_service.dart:19) 到 [project_open_view_data_service.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/project_open/application/services/project_open_view_data_service.dart:100)：

1. 会遍历默认项目目录。
2. 对每个候选目录读 manifest。
3. 还会做时间戳读取和排序。

它用的是 `async` API，没有 `sync`，这比以前好。

但它仍然是：

1. 在 UI 触发链上。
2. 在主 isolate 上。
3. 伴随页面切换高频发生。

#### 资料投影

在 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:887) 到 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:932)：

1. `_buildInformationViewData(...)` 会先合并 workspace entries。
2. 再扫描 `.novel_agent/information`、`tracking`、`.novel_agent` 下的一批文件。
3. 再逐个读取这些文件内容。
4. 再生成资料视图投影。

继续往下，在 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:2174) 到 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:2250)：

1. 目录扫描是 `await for directory.list(...)`
2. 逐个文件存在性检查也是主 isolate 上的异步文件系统调用

这类代码不是“错”，但在当前架构下，它们会：

1. 跟导航切换叠加。
2. 跟项目 hydration 叠加。
3. 跟壳层频繁通知叠加。

于是就会把“只是切个 UI”的体感拖成“像在全盘扫项目”。

### 4.6 资源树与页面投影存在高频重算

在 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:2080) 到 [workbench_workspace_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/features/workbench/application/controllers/workbench_workspace_controller.dart:2127)：

1. `_resourceEntriesFrom(...)` 每次都会重建树形结构。
2. 目录排序、深度展开、显示映射都在这里做。

在 [app_shell_listenable_state.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_listenable_state.dart:109) 到 [app_shell_listenable_state.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_listenable_state.dart:180)：

虽然已经做了“仅同步当前目的地主要数据”的收口，但：

1. 只要当前目的地是 `workbench`，就仍会根据比较结果刷新资源、画布、会话、overlay 等投影。
2. 而 hydration 期间 `workbench` 数据会连续变化。

所以现在的状态更像：

1. 旧的“全量乱刷”被削掉了一部分。
2. 但主工作台仍然是一个高频投影中心。

### 4.7 导航动作本身不只是导航

在 [app_shell_destination_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart:22) 到 [app_shell_destination_controller.dart](/d:/FlutterProjects/NovelAgentFlutter/apps/novel_agent_app/lib/app/state/app_shell_destination_controller.dart:114)：

各个目标页的“show”动作已经不是纯路由：

1. `showProjectOpen()` 会切页后后台刷新作品库。
2. `showTaskCenter()` 会切页后立刻刷新任务中心。
3. `showLongTaskStation()` 会切页后初始化或刷新总站。

也就是说当前导航层不是一个轻壳，而是已经绑定了子域数据生命周期。

---

## 5. 真正的根因不是一个，而是一组结构性共因

## 5.1 根因一：页面生命周期和导航生命周期没有分开

当前最核心的问题，是路由切换并不只是“切换当前可见页面”，而是在多数情况下等价于：

1. 销毁旧页子树。
2. 创建新页子树。
3. 新页自己初始化。
4. 导航控制器再刷新一次该页数据。

这会导致：

1. 同一个功能页没有稳定驻留。
2. 页面很难只做轻量展示。
3. 任何“初始化就刷新”的页面，在频繁切页下都会变成性能放大器。

这也是为什么“切一下 UI 就卡”的问题具有普遍性。

## 5.2 根因二：项目生命周期和页面生命周期互相穿透

项目恢复是一个独立的大生命周期。

页面切换也是一个独立的小生命周期。

但当前这两者没有被隔开，表现为：

1. 项目恢复完成前，用户已经可以做别的页面动作。
2. 某些页面动作又会反过来依赖当前项目数据。
3. hydration 中途还会刷新当前目标页。

于是系统形成了这样的状态：

1. 项目在恢复。
2. 页面在切换。
3. 子域在刷新。
4. 壳层在同步。

四件事同时发生，而且共享同一层状态出口。

## 5.3 根因三：`AppShellController` 仍是过重的系统性共享瓶颈

尽管前面已经做过职责清理，但从运行表现看，它依然承担了过多系统性责任：

1. 目的地切换。
2. 页面动作分发。
3. 项目打开与恢复入口。
4. 子控制器装配。
5. 设置投影与状态保存。
6. 多个 feature 之间的跨域联动。

结果就是：

1. 很多问题最终都要穿过它。
2. 很多性能问题最终也要经过它。
3. 很多本应局部结束的动作，会因为它的共享同步机制扩散到壳层。

## 5.4 根因四：`async` 被误当成了“已经不会卡 UI”

这是这类问题最容易误判的地方。

现在很多链路确实已经不是 `sync` 了，但这不代表它们就不会影响 UI：

1. 主 isolate 上的大量异步目录遍历、文件读取、列表合并，仍会占用调度机会。
2. 每一步完成后还会引发新的状态写回和投影重建。
3. 如果这些动作在短时间内连续发生，用户看到的仍是掉帧甚至未响应。

所以当前问题不是“还有几个 `existsSync` 没改完”这么简单。

真正的问题是：

**主 isolate 仍承载了太多与页面切换同时发生的异步工作。**

## 5.5 根因五：缺少面向“卡死”的运行时诊断层

目前已经有一些项目加载阶段 trace，这是好的。

但还没有真正意义上的：

1. UI 主线程 stall 探针。
2. 页面切换耗时埋点。
3. feature refresh 重入统计。
4. hydration 与切页并发冲突记录。

这会导致团队容易陷入：

1. 感觉像修好了。
2. 某个点的确快了。
3. 但另一条路径仍然能把应用拖死。

没有 stall-level 诊断，后续即便重构，也仍然容易再次回到“凭体感修性能”。

---

## 6. 为什么前面的修复只能缓解，不能根治

这点要说清楚，不然很容易误以为之前那些工作白做了。

实际上，前面的修复是有效的，只是它们解决的是“显性阻塞点”，而不是“全局生命周期耦合”。

### 6.1 已经有效的部分

这几项改动方向是对的：

1. 项目加载拆成首屏可见 + deferred hydration。
2. 一部分目录扫描挪到 isolate。
3. 不再把任意目录误识别成默认项目。
4. `AppShellListenableState.syncFrom(...)` 已经缩小到只同步当前目的地主要数据。

它们都确实降低了某些路径的纯阻塞时长。

### 6.2 为什么仍然不够

因为当前真正拖死 UI 的，不再只是“一个特别重的同步函数”，而是：

1. 切页重建。
2. 重建自刷新。
3. hydration 连续回写。
4. 壳层集中通知。
5. 主 isolate 上的目录/文件/投影工作。

这些动作单独看都“还能接受”，叠起来就不行了。

所以之前的修复像是：

1. 把最粗的几根阻塞钢筋拆掉了。
2. 但整张网还在互相拽。

---

## 7. 这次最关键的新判断

如果只提炼这轮和前几轮相比最关键的新判断，我会定成三条：

### 7.1 现在的主要问题不是“还有几个重函数”

而是：

**页面切换本身就会重新触发一整批功能生命周期。**

这使得卡死具有普遍性。

### 7.2 现在的主要风险不是“某个页面自己的实现太重”

而是：

**项目恢复、子域刷新、壳层投影同步会跨页面传播。**

这使得卡死具有扩散性。

### 7.3 现在的主要架构缺口不是“少一个优化点”

而是：

**缺少把壳层导航、项目生命周期、工作台运行时、子域刷新完全拆开的正式模型。**

这使得卡死具有复发性。

---

## 8. 这一步不该再怎么做

下一阶段最不该继续做的是：

1. 继续只改某个页面的 `refresh()`。
2. 继续只把某几个 `File` / `Directory` 调用改成 `await`。
3. 继续只在壳层里补“如果当前在某页就别刷新”的条件分支。
4. 继续让 `AppShellController` 或 `WorkbenchWorkspaceController` 承担新的“临时协调”。

这些做法短期可能还能让某一处变好，但会继续放大系统复杂度。

---

## 9. 应有的重构主线

## 9.1 第一主线：把“导航壳”从“页面数据生命周期”中剥离

目标：

1. 切换目的地不再默认重建整个页面子树。
2. 页面是否初始化、何时刷新，不再由“是否被重新挂载”决定。
3. 路由壳只负责显隐与焦点，不再决定 feature 数据刷新。

直白说：

**先让“切个页”重新变回一件轻的事。**

### 具体方向

1. 去掉基于 `destination` 的整页重建策略。
2. 对主要目的地改成稳定页面宿主。
3. 页面首次初始化与页面重新可见要分成两套生命周期。

## 9.2 第二主线：把“项目生命周期协调器”从 workbench/controller 壳里抽出来

目标：

1. 项目加载、hydration、默认项目恢复、项目切换、派生项目打开，统一归到单独协调器。
2. 页面层不再直接感知整条项目恢复链。
3. 当前页面只订阅“项目壳已可用”“项目恢复进度”“项目恢复完成”等稳定事件。

### 具体方向

建议形成独立对象，例如：

1. `ProjectLifecycleCoordinator`
2. `ProjectHydrationRuntime`
3. `ProjectVisibilitySession`

名称可以再定，但职责应固定：

1. 壳层不直接写项目恢复细节。
2. workbench 不直接充当项目恢复入口。
3. 页面不直接参与项目恢复顺序。

## 9.3 第三主线：把子域刷新改成“驻留态 + 显式刷新策略”

目标：

1. 作品库、长任务总站、项目资产、智能体生态不再依赖重新挂载来刷新。
2. 它们各自有自己的驻留态和刷新策略。
3. 进入页面只决定“是否需要拉新数据”，而不是无脑重刷。

### 具体方向

例如：

1. `ProjectOpenController` 维护自己的缓存快照与刷新时机。
2. `LongTaskStationController` 的自动刷新不再跟页面重建绑定。
3. `ProjectAssetsController` 把“加载主资产”“加载 RAG 状态”“执行提取后刷新”拆成更细的刷新源。

## 9.4 第四主线：在主 isolate 之外建立明确的后台投影/扫描通道

目标：

1. 目录扫描、资料投影、项目发现、长列表整理，不再默认跑在 UI 交互热路径上。
2. 哪些要 isolate 化，哪些要缓存，哪些要延迟到空闲帧后做，需要明确分层。

### 重点不是“一律丢 isolate”

而是要区分：

1. 首屏必须要的。
2. 当前页面必须要的。
3. 可以后台生成再回填的。
4. 可以增量更新的。

## 9.5 第五主线：补上 UI stall 级别的诊断与验收基线

没有这一步，后续重构也很容易“看上去合理，但其实还是卡”。

建议补：

1. 页面切换耗时 trace。
2. hydration 分阶段耗时与回写次数统计。
3. 主线程 stall probe。
4. feature refresh 重入计数。
5. “一次切页引发了多少次壳层通知”的观测点。

---

## 10. 后续验收标准应怎么变

下一阶段如果真要把这类问题收掉，验收标准不能再只是：

1. 页面能打开。
2. 功能能用。
3. 没报异常。

而应至少包含：

1. 从无项目启动到进入创建页，首屏无明显停顿。
2. 从创作台切到作品库、设置、智能体生态、长任务总站，各自第一次和第二次切换都不应出现明显冻结。
3. 项目 hydration 进行中切页，不应把整个壳层拖死。
4. 作品库扫描、资料投影、长任务刷新在大项目下仍要保持可交互。
5. 一次切页引发的刷新次数、通知次数、主线程 stall 时长要可量化。

---

## 11. 最终判断

最终判断可以收成一句话：

**当前应用的 UI 卡死，本质上是“壳层导航”和“应用运行时”没有真正分家。**

所以它才会表现成：

1. 到处都像个别 bug。
2. 但实际上哪里都不只是个别 bug。

前面的修复没有白做，它们已经证明：

1. 纯同步阻塞点可以拆。
2. 项目恢复可以分阶段。
3. 一部分扫描可以搬离热路径。

但这一步之后，问题已经升级了。

接下来要解决的，不再是“哪个函数太重”，而是：

1. 谁拥有页面生命周期。
2. 谁拥有项目生命周期。
3. 谁拥有子域刷新策略。
4. 谁负责把后台工作隔离出主交互路径。

在这几条没彻底拆清之前，这个应用很难真正达到可发布的稳定度。

---

## 12. 本轮建议的直接后续

如果紧接着要进入实施阶段，我建议按下面顺序推进，而不是乱序补点：

1. 先做一份基于本文的任务顺序文档。
2. 第一刀先收壳层导航与页面驻留模型。
3. 第二刀收项目生命周期协调器。
4. 第三刀收作品库 / 长任务总站 / 项目资产三大高频刷新子域。
5. 第四刀补 stall probe 和切页性能验收。

只有这样，后面的“修卡死”才会开始变成真正的系统性收口，而不是继续和它打游击。
