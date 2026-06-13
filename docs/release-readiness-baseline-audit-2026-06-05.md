# Release Readiness Baseline Audit

最后更新：2026-06-05 11:53:07

关联文档：

- `docs/release-readiness-productization-session-order-2026-06-05.md`
- `docs/release-readiness-gui-core-consolidation-analysis-2026-06-05.md`
- `docs/project-information-substrate-implementation-audit-2026-06-05.md`
- `docs/project-information-substrate-mock-regression-suite-2026-06-05.md`
- `agent.md`

---

## 1. 本轮范围

本记录只服务 `RRP-01`：

1. 核对 RRP 文档中的代码锚点是否与当前仓库一致。
2. 建立一份简短发布收口 baseline，区分“已实现 / 半成品 / 明确缺口”。
3. 判断 session 顺序是否需要调整。
4. 记录一组当前工作区可复跑的低成本 focused checks。

本轮不做：

1. 不修大块业务代码。
2. 不改 GUI 主路径。
3. 不开启真实 provider probe。

---

## 2. 锚点核对结果

RRP 文档列出的锚点目录本轮全部存在，包括：

1. `packages/novel_agent_core/lib/src/workflow/`
2. `packages/novel_agent_core/lib/src/runtime/`
3. `packages/novel_agent_core/lib/src/information/`
4. `packages/novel_agent_core/lib/src/agents/`
5. `packages/novel_agent_core/lib/src/creative/`
6. `packages/novel_agent_core/lib/src/tools/domain/`
7. `packages/novel_agent_adapters/lib/src/workflow/`
8. `packages/novel_agent_adapters/lib/src/runtime/`
9. `packages/novel_agent_adapters/lib/src/tools/`
10. `packages/novel_agent_adapters/lib/src/storage/`
11. `apps/novel_agent_app/lib/features/workbench/`
12. `apps/novel_agent_app/lib/features/long_task_station/`
13. `apps/novel_agent_app/lib/features/agent_ecosystem/`
14. `apps/novel_agent_app/lib/features/book_deconstruction/`
15. `apps/novel_agent_app/lib/features/settings/`
16. `apps/novel_agent_app/lib/app/theme/`
17. `apps/novel_agent_app/lib/app/navigation/`

结论：

```text
RRP 文档的主锚点与当前仓库一致，可以继续按既定 session 顺序推进。
```

---

## 3. 当前 baseline

### 3.1 已实现，可直接复用

1. 章节交付、长任务恢复、长任务详情和运行摘要已经有稳定底座，方向与 RRP 主线一致。
2. `information` 子域已经落进 `core + adapters`，并且已有 mock regression suite 文档与对应测试入口，不需要回退到 `knowledge/` 目录式事实源。
3. 多智能体、技能组、项目级装载、子智能体隔离与权限过滤已经有明确对象和 focused tests，可作为后续产品化基础。
4. App 侧已经具备工作台、长任务总站、拆书、生态页、设置页等正式入口，后续重点是收口默认路径和用户暴露协议，而不是重新建壳。

### 3.2 半成品，已接上但还不能算发布完成

1. 普通写作、长任务、拆书续写之间的共享写作结果合同仍未显式收口；当前已有能力分散在 delivery、constraint、activation、recovery、sub-agent 结果里。
2. 长任务和普通写作已经能消费部分稳定合同，但还缺统一的人话投影、失败分类收口和真实长链验收。
3. information 主线实现量已经较大，但“真实模型自然命中并复用 information”的发布证明仍未完成。
4. 多智能体底座正确，但“GUI 当前所选协作组真实进入运行链、子智能体失败可降级”的产品级证明仍缺。

### 3.3 明确缺口 / 风险

1. 发布主路径仍偏工程控制台，首次使用、新建作品、模型测试连接、普通写作默认动作还未产品化。
2. 中文字体方框、主题工程感、长文本溢出仍是发布阻断级风险。
3. 工作区当前存在大量已修改和未跟踪文件；虽然本轮不清理它们，但后续 session 必须继续避免把新收口逻辑塞进失控工作区。
4. 超大文件风险仍在，而且比分析文档记录值更高：
   - `apps/novel_agent_app/lib/app/state/app_shell_controller.dart`：`4759` 行
   - `packages/novel_agent_adapters/lib/src/workflow/project_workflow_runtime_service.dart`：`2697` 行
   - `packages/novel_agent_adapters/lib/src/workflow/project_context_activation_service.dart`：`641` 行
5. 发布包隔离、probe 归档、真实 provider 开闸和最终打包冒烟仍未做，不应被 UI 变更掩盖。

---

## 4. 顺序判断

本轮未发现需要调整 RRP session 顺序的证据。

原因：

1. `RRP-02 ~ RRP-06` 先收口共享写作结果、状态、gate、supervisor、真实 probe 框架，仍然是后续 GUI/产品化工作的依赖前置。
2. `PIS` 主线已有进展，但它更多是为 `RRP-07 / RRP-08 / RRP-20 / RRP-21 / RRP-29` 提供底座，不构成把 GUI session 前移的理由。
3. 当前最大风险仍是“共享事实层未统一就开始过度包装 GUI”，因此顺序保持不变更安全。

结论：

```text
RRP 顺序保持不变，下一步仍应进入 RRP-02。
```

---

## 5. 本轮 focused checks

执行命令：

```text
dart tools/repository_secret_scan.dart
dart test test/long_task_runtime_services_test.dart
dart test test/project_conversation_draft_runtime_service_test.dart
flutter test test/long_task_station_view_data_service_test.dart test/conversation_tool_entry_projection_service_test.dart
```

结果：

1. 密钥扫描通过。
2. `packages/novel_agent_core` 的长任务运行时 focused tests 通过，覆盖 run record、postprocess、recovery 与 waiting-user signal。
3. `packages/novel_agent_adapters` 的普通写作 runtime focused tests 通过，覆盖 activation、safe information tools、formal delivery backfill 与 changed paths 保留。
4. `apps/novel_agent_app` 的长任务 view-data 与工具投影 focused tests 通过，说明 GUI 侧仍在消费稳定合同，而不是重新拼业务判断。

---

## 6. 下一步建议

下一轮直接执行 `RRP-02`，只做共享写作运行结果合同：

1. 把 delivery、constraint、information、collaboration、recovery 拆成纯 Dart 子合同。
2. 不接 GUI，不改真实 provider，不在本轮大规模迁调用点。
3. 优先为后续 `RRP-03 ~ RRP-05` 提供稳定输入输出，而不是做大而全执行包。
