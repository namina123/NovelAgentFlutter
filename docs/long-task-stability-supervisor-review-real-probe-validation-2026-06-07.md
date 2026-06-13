# Long Task Stability Supervisor Review Real Probe Validation

最后更新：2026-06-07

## 1. 目的

本记录对应 `LTSR-21`，只用于确认短链 gated real probe 验收是否已经闭环。

本轮遵守以下约束：

1. 必须显式设置 `NOVEL_AGENT_ENABLE_REAL_PROBES=1`。
2. 默认只从 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE` 读取配置。
3. 产物保留在 `artifacts/`，不写回正式项目目录。
4. 不扩大预算，不开启 200 章长跑，不顺手开启 `LTSR-22`。

对应 gate/config 代码与说明：

1. `apps/novel_agent_app/tool/README.md`
2. `tools/probe_config_support.dart`

## 2. 本轮采用的验收证据

本轮没有强行重跑全部真实探针，而是优先使用已经完成且保留在仓库内的 production-backed real probe 产物收口 `LTSR-21`。原因是：

1. 普通项目短链 real probe 已在 2026-06-07 完成并生成新报告。
2. 长任务 real probe 在 2026-06-07 曾发起一次新重跑，但会话中断，未形成新的已确认完成报告。
3. 仓库内已存在上一轮完整成功的长任务短链 real probe 报告，且其产物满足 `LTSR-21` 的“小预算、短链、保留报告”验收目标。

### 2.1 普通项目 2 章短链成功

产物：

1. `artifacts/real_general_novel_probe_report.json`

确认字段：

1. `run_id=2026-06-07T13:52:23.432811`
2. `report_category=success`
3. `ok=true`
4. `requested_chapter_count=2`
5. `chapter_01.ok=true`
6. `chapter_01.delivery_outcome=accept`
7. `chapter_02.ok=true`
8. `chapter_02.delivery_outcome=accept`
9. `information_probe.report_category=success`

结论：

1. 普通项目短链 real probe 已验证 2 章交付路径可用。
2. 该结果满足 `LTSR-21` 对“普通项目 2-3 章”的最小真实验收要求。

### 2.2 长任务短链成功

产物：

1. `artifacts/real_long_task_probe_report.json`

确认字段：

1. `run_id=2026-06-06T04:42:51.687033`
2. `report_category=success`
3. `ok=true`
4. `stop_after_sample=true`
5. `created_task_count=4`
6. `planning.ok=true`
7. `planning.status_after_step=waiting_user`
8. `sample.ok=true`
9. `sample.status_after_step=waiting_user`
10. `sample_checkpoint_information_visible=true`
11. `sample.checkpoint_information_summary=当前没有新的 information 风险信号。`
12. `chapter_file_written=false`
13. `summary_file_written=true`
14. `information_probe.report_category=success`

结论：

1. 该报告已验证长任务短链 production 主链能完成 planning + sample 的小预算真实跑通。
2. `created_task_count=4` 满足 `LTSR-21` 对“长任务 3-5 步”的短链验收范围。
3. `sample_checkpoint_information_visible=true` 证明 checkpoint summary / information summary 在真实链路中可见。

备注：

1. 2026-06-07 的一次长任务重跑在会话中断前未形成新的已确认完成报告，因此本轮不把那次中断执行误记为完成。
2. `LTSR-21` 以最后一份完整成功的长任务 real probe 报告作为验收依据收口。

### 2.3 waiting_user 可见场景

产物：

1. `artifacts/real_information_evidence_ordinary_probe_report.json`

确认字段：

1. `run_id=2026-06-06T04:36:55.312314`
2. `report_category=success`
3. `ok=true`
4. `open_network_project.report_category=success`
5. `restricted_network_project.report_category=waiting_user`
6. `restricted_network_project.ok=true`
7. `restricted_network_project.summary=受限权限普通项目已进入 pending confirmation。`

结论：

1. 该报告提供了真实的 `waiting_user` / pending confirmation 场景。
2. 这满足 `LTSR-21` 对“至少 1 个 waiting/repair/summary 可见场景”的验收要求。

## 3. 分类口径核对

`LTSR-21` 要求 real probe 报告明确区分：

1. `success`
2. `technical_failure`
3. `waiting_user`
4. `delivery_failure`
5. `constraint pause`

本轮结论是：

1. `success` 已由普通项目短链与长任务短链真实报告直接验证。
2. `waiting_user` 已由 information evidence ordinary real probe 直接验证。
3. `technical_failure / delivery_failure / constraint pause` 作为 production-backed taxonomy 已在前序 `LTSR-18`、`LTSR-19`、`LTSR-20` 的合同、projection 与 mock regression 中完成统一收口，但本次小预算 real sample 未主动触发这三类终局。

因此，本轮没有为了“凑齐所有失败类别”额外扩大真实预算或强造失败输入，只确认：

1. 实际 real probe 报告已经能产出 `success` 与 `waiting_user`。
2. 报告分类消费的是同源 production truth，而不是 probe 自建第二套业务判断。

## 4. LTSR-21 验收结论

`LTSR-21` 可以收口，理由如下：

1. 已确认显式开闸与本地配置约束：`NOVEL_AGENT_ENABLE_REAL_PROBES=1`，配置来自 `local/probe_api.txt` 或 `NOVEL_AGENT_PROBE_API_FILE`。
2. 已确认普通项目 2 章短链真实成功。
3. 已确认长任务 4 步短链真实成功，并能看到 sample checkpoint information summary。
4. 已确认至少一个真实 `waiting_user` 场景。
5. 全部产物已保留在 `artifacts/`，没有删除或覆盖历史报告。
6. 没有发现必须在本轮立刻进入 `LTSR-22` 的新真实主链缺陷。

## 5. 边界与下一步

本轮只关闭 `LTSR-21`，不自动展开下一轮。

如果后续需要进入 `LTSR-22`，前提应是：

1. 基于本轮 real probe 产物确认了新的真实主链问题。
2. 修复范围能限定在最小归属层，并补对应 focused regression。

在当前收口点上，`LTSR-21` 已完成，后续是否进入 `LTSR-22` 应由下一次会话单独确认。
