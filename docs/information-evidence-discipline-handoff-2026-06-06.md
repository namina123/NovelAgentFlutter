# 信息收集证据纪律交接说明

日期：2026-06-06

适用主线：

- `docs/information-evidence-discipline-session-order-2026-06-05.md`

---

## 1. 如何开启或禁用联网研究

日常运行时，联网研究是否允许，优先由宿主权限设置决定，而不是模型自声明决定。

当前维护口径：

1. `allow_network=true` 且 permission mode 为开放语义时：
   - `request_external_research` 可在 accepted 后自动进入 gateway research。

2. `allow_network=false` 或 safe/restricted 语义时：
   - `request_external_research` 会进入待确认，不会偷偷联网。

3. `import` 收集不等于联网：
   - 导入资料路径可在不开放联网时继续成立。

4. 不要通过改 prompt 或改模型 payload 去“伪授权”联网：
   - 真正授权来自宿主 settings -> host permission context -> executor/runtime。

---

## 2. 如何确认或拒绝 pending research

GUI：

1. 长任务总站和工作台资料侧栏都已有最小 `确认 / 拒绝` 动作。
2. 当前只对 pending research 提供轻动作；其他资料对象仍以只读查看为主。

CLI：

1. 查看待确认：

```powershell
cd apps/novel_agent_cli
dart run bin/novel_agent_cli.dart workflow pending-research list --project <project_root>
```

2. 确认：

```powershell
dart run bin/novel_agent_cli.dart workflow pending-research approve --project <project_root> --request-id <id>
```

3. 拒绝：

```powershell
dart run bin/novel_agent_cli.dart workflow pending-research reject --project <project_root> --request-id <id>
```

说明：

1. 确认/拒绝只通过统一 action service 改状态，不应手改 `.novel_agent/information/research_requests/*.json`。
2. 拒绝后要保留 evidence gap 与审计事件，不把它伪装成“已研究完成”。

---

## 3. 如何查看资料投影与报告

资料投影：

1. `knowledge/项目知识摘要.md`
2. `knowledge/设计元素摘要.md`
3. `research/资料研究摘要.md`
4. `references/引用作品边界.md`

说明：

1. 这些文件是 projection，便于人看，不是结构化事实源。
2. 真正事实源仍在 `.novel_agent/information/*`。

mock regression 报告：

1. 入口：

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_information_evidence_discipline_mock_regression_suite.ps1
```

2. 报告目录：
   - `artifacts/information_evidence_mock_regression_suite/<timestamp>/`

real probe 报告：

1. 运行前必须显式开闸：

```powershell
$env:NOVEL_AGENT_ENABLE_REAL_PROBES='1'
```

2. 本地配置默认来自：
   - `local/probe_api.txt`

3. 已有报告：
   - `artifacts/real_information_evidence_ordinary_probe_report.json`
   - `artifacts/real_long_task_probe_report.json`

4. 已保留工作区：
   - `artifacts/real_information_evidence_ordinary_probe_workspace/...`
   - `artifacts/real_long_task_probe_workspace/...`

---

## 4. 后续维护时不要回退的约束

1. 不要把 raw tool payload、runtime gate 术语直接推回普通 GUI。
2. 不要把 projection Markdown 当事实源编辑入口。
3. 不要让 probe 脚本变成 production repair 逻辑。
4. 不要新增新的全能 information center 来绕过现有 contracts/services。
5. 如果后续要扩资料浏览器、批量审批或更强治理能力，单独开新主线。
