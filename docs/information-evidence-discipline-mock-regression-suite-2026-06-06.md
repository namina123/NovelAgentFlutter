# Information Evidence Discipline Mock Regression Suite

最后更新：2026-06-06

## 1. 目的

这套 mock regression suite 是 `IED-14` 的一键回归入口，用来在不触发真实 provider、不联网、不走 GUI 真交互的前提下，验证信息收集证据纪律主线已经通过 production contracts 稳定覆盖：

1. 开放权限自动研究。
2. 受限权限待确认。
3. import collection。
4. hybrid partial。
5. gateway failed。
6. rigorous source insufficient。
7. ordinary runtime 信息摘要。
8. long task checkpoint / recovery evidence gate。

运行入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_information_evidence_discipline_mock_regression_suite.ps1
```

规则：

1. 只跑 `dart test`。
2. 不访问真实 API，不执行真实联网。
3. 不在脚本层重写业务判定，分类直接对应 production-contract 测试场景。
4. 报告始终写入 `artifacts/`，不删除历史产物。

## 2. 报告产物

每次运行都会在下面目录生成时间戳工作区：

```text
artifacts/information_evidence_mock_regression_suite/<timestamp>/
```

其中包含：

1. `information_evidence_mock_regression_report.json`
2. `information_evidence_mock_regression_report.md`

报告至少包含：

1. scenario id
2. layer
3. expected report category
4. pass / fail
5. duration
6. command
7. summary

## 3. 当前覆盖场景

1. `open_network_auto_execute`
   分类：`success`
   验证开放权限下 `request_external_research` 会自动执行 fake gateway。

2. `restricted_network_pending_confirmation`
   分类：`waiting_user`
   验证受限权限会覆盖模型自声明并保留待确认 research request。

3. `import_collection_auto_execute`
   分类：`success`
   验证 import collection 在允许导入时自动完成。

4. `hybrid_partial_waiting_confirmation`
   分类：`waiting_user`
   验证 hybrid request 先导入，再把联网部分留给用户确认。

5. `gateway_failed_request`
   分类：`technical_failure`
   验证 fake gateway 故障不会被吞成成功或内容问题。

6. `rigorous_source_insufficient`
   分类：`information_quality_failure`
   验证严谨来源不足保持为 evidence warning / quality risk。

7. `ordinary_runtime_auto_research`
   分类：`success`
   验证普通写作 runtime 会回写自动研究摘要与 changed paths。

8. `ordinary_runtime_pending_confirmation`
   分类：`waiting_user`
   验证普通写作 runtime 会把待确认 research 映射为 waiting_user。

9. `long_task_checkpoint_waiting_confirmation`
   分类：`waiting_user`
   验证长任务 checkpoint 会把 information awaiting confirmation 映射为 shared waiting state。

10. `long_task_checkpoint_gateway_failed`
    分类：`technical_failure`
    验证长任务 checkpoint 保持 gateway failed 为 repair / technical path，而不是误判正文失败。

## 4. 失败时怎么读

1. 如果 `technical_failure` 场景失败，优先看 request state、gateway summary、repair / waiting 映射有没有回退。
2. 如果 `waiting_user` 场景失败，优先看 host permission context、pending request state、shared outcome status 有没有断链。
3. 如果 `information_quality_failure` 场景失败，优先看 source quality audit、evidence gate severity、recommended disposition 有没有回退。
4. 如果 `success` 场景失败，优先看 changed paths、projection summary、runtime artifacts 是否还在消费 production contracts。

## 5. 与其他套件的关系

1. 这套脚本是 `IED-14` 的主回归入口，关注信息收集证据纪律闭环本身。
2. `tools/run_project_information_substrate_mock_regression_suite.ps1` 仍然是 PIS 基座层的大回归入口，不需要回退或替换。
3. 如果这套 `IED-14` suite 失败，先修 contracts / runtime / coordinator / summary 接线，不要去 GUI、CLI 或真实 probe 层打补丁。
