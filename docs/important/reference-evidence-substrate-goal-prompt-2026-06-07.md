# 参考证据基座实现目标提示

适用时间：2026-06-07 之后  
用途：给其他会话窗口的 Codex 直接开启目标模式使用  
关联主文档：`docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`

---

## 1. 直接可用的目标提示

把下面整段作为目标模式提示使用：

```text
请以 `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md` 作为本轮唯一最高优先级架构依据，在当前仓库中一次性完成“参考证据基座 + 项目参考挂载层 + 项目知识能力层”的正式落地，不要再生成新的任务顺序文档，也不要只停留在分析。

目标不是做一个演示品，而是把这套架构做成后续可以长期演化、能稳定复用、不会明显长歪的正式底座。你必须严格保留以下核心判断，不得回退：

1. 现有 `ProjectKnowledgeCard / DesignElementCard / ResearchNote / ReferenceWorkRecord` 保留，但正式定位为 `ProjectInformationCapabilityLayer`，即项目知识能力层，而不是应用级全局大库。
2. 新的大框架正式命名为 `ReferenceEvidenceSubstrate`，中文正式名为“参考证据基座”，用户可见名可采用“参考资产库”。
3. 项目级必须单独存在 `ProjectReferenceAttachmentLayer`，即项目参考挂载层，负责项目与应用级资料包之间的挂载、可见性、版本快照与权限映射。
4. 应用级与项目级必须分离，关系只能是挂载、提取、投影、派生、显式提升；禁止项目知识自动反写全局，禁止全局资料无边界覆盖项目当前真相。
5. SQLite 必须用在应用级基座和项目挂载映射层；项目知识能力层短中期可以继续保留当前 JSON 事实源加投影，不要为了“统一”而强行大迁移。
6. 不采用“每个条目一个 SQLite 文件”的默认方案；必须采用“共享 SQLite 基座 + 逻辑独立 package/entry/version + bundle 导入导出”的方案。
7. 可分发性必须通过 bundle contract 保证，而不是依赖运行时物理拆库。
8. 当前实现策略优先原生 SQL + 轻量 mapper / repository，不以 ORM 为先验中心；即使后续引入 ORM，也不得让 core contracts 依赖 ORM 语义。

本轮必须真正完成以下结果，而不是只定义接口名：

1. 在 core 中补齐 `ReferenceEvidenceSubstrate`、`ProjectReferenceAttachmentLayer`、bundle contract、package/entry/version identity、promotion contract、visibility/permission contract、查询 contract 所需的领域模型与 ports。
2. 在 adapters 中正式落 SQLite 主基座与项目挂载映射的持久化实现，包括最小可用 migration、repository、query service、bundle import/export 骨架、完整性校验骨架。
3. 明确把当前项目级信息对象与新架构桥接起来：支持从应用级资料包提取/投影到项目知识能力层，支持显式 promotion，但禁止隐式双向混写。
4. 把资料访问做成工具化、权限化、策略化调用链，而不是默认把全库塞进 prompt。
5. 为后续普通写作、长任务、拆书、解书共用这套能力打通最小主链，不允许把能力写死在某个特定项目类型里。
6. 处理并实现至少这些硬边界的正式骨架：schema migration、bundle contract、索引/检索策略入口、附件/大文本承载边界、projection 重建入口、权限不足、缺包、版本不匹配、删除/级联、并发一致性预留。
7. 不允许新增新的全能中心服务，不允许把实现堆回 `ProjectWorkflowRuntimeService`、`ProjectContextActivationService`、`knowledge/` 或 probe 脚本。
8. 所有新增实现必须遵守现有项目级约束：解耦、单一职责、避免大文件、core 先行、adapter 承接实现、GUI/CLI 不成为业务中心。

完成标准必须是可验证的，而不是“看起来差不多”：

1. 代码层已有正式命名与目录落点，且不再继续使用“大框架”作为正式实现名。
2. 新增 core/adapters 代码能通过本仓库现有的静态检查与相关测试；若缺测试，必须补最小可运行测试或 mock regression。
3. 至少有一条从应用级参考包 -> 项目挂载 -> 项目知识能力层投影/提取 的真实或 mock 验证链。
4. 至少有一条 bundle export/import 的真实或 mock 验证链。
5. 至少有一条权限/可见性限制生效的验证链。
6. 至少有一条显式 promotion 生效、且未发生隐式反写全局的验证链。
7. 文档需要同步更新，只更新真正必要的架构与交接文档，不再生成新的任务顺序文档。

范围边界：

1. 本轮主目标是核心架构正式落地，不要求把 GUI/CLI 做成完整资料管理器，但必须把后续 UI/CLI 接入所需合同和最小调用面打稳。
2. 不要把“快穿”“死亡回归”等测试题材硬编码进 core；它们永远只能作为验证输入，不得变成显式程序分支。
3. 不要为了追求一次做满而把文件做得很重；如果某个文件明显会过大，先拆再实现。
4. 如果遇到局部做不完，可以留下清晰未完成边界，但前提是主链已经可用、合同已经稳定、验证已经成立，而不是停在半分析半脚手架状态。

你在执行中必须优先参考并吸收：

1. `docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md`
2. `docs/project-information-substrate-implementation-audit-2026-06-05.md`
3. `docs/shared-narrative-information-and-long-task-gap-analysis-2026-06-05.md`
4. `docs/important/information-collection-agent-boundary-analysis-2026-06-05.md`

执行风格要求：

1. 直接实施，不重复输出泛泛计划。
2. 每完成一个关键切片就验证。
3. 不要做丑陋补丁堆叠，优先修合同和层级边界。
4. 如果需要权衡，优先选择：分层清晰、复用稳定、长期不长歪、对 GUI/CLI 友好、对长任务和普通任务共用友好。
```

---

## 2. 这份目标提示的成功标准

这份提示被用于目标模式时，理想状态下应能直接驱动出：

1. 一条真正可运行的参考证据基座主链。
2. 一条真正可运行的项目挂载主链。
3. 一条应用级到项目级的知识投影/提取主链。
4. 一条最小 bundle 导入导出主链。
5. 一条权限/可见性验证主链。
6. 一条 promotion 主链。

如果执行到最后，仍然只有：

1. 新文档。
2. 新接口。
3. 新空壳类。
4. 没有验证的脚手架。

那就不算达成目标。

---

## 3. 推荐的目标工具 objective 写法

如果要压缩成 goal tool 的一句 objective，推荐用下面这个版本：

```text
在当前仓库中依照 docs/important/reference-evidence-substrate-architecture-analysis-2026-06-07.md 正式落地 ReferenceEvidenceSubstrate、ProjectReferenceAttachmentLayer 与 ProjectInformationCapabilityLayer：完成 core contracts、SQLite adapters、bundle import/export、visibility/permission、projection/promotion 主链与最小验证，并以至少 4 条可运行或 mock 验证链证明应用级参考包到项目知识层的挂载、提取、权限限制和显式提升均成立，且未引入新的全能中心或把题材测试写死进 core。
```

---

## 4. 不应作为完成的假信号

以下情况都不应被当作“已经完成目标”：

1. 只是补了文档，没有代码主链。
2. 只是新建了很多模型和接口，没有存储和验证。
3. 只是做了 SQLite 表，但没有 bundle/import/export 或挂载验证。
4. 只是能写入应用级库，但不能投影/提取到项目知识层。
5. 只是做了权限字段，但没有真正限制读取。
6. 只是能 promotion，但项目层与应用层仍然隐式混写。
7. 只是 GUI 假入口，没有 core/adapters 正式闭环。

