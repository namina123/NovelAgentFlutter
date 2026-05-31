# ProviderCatalogPort 职责切片

最后更新：2026-05-30

## 1. 当前分组

### 1.1 已可降级

- `providerOptions`
- `bestProviderMatch`
- `modelSuggestions`

原因：

- 接口候选已迁到 `ProviderInterfaceTemplateService`
- 主模型候选已迁到 `WritingModelOfferingCatalogService`
- 旧实现只保留为 legacy fallback

### 1.2 正在降级

- `providerById`

原因：

- runtime 的 `provider_label` 已优先改走 `ProviderInterfaceTemplateService`
- 旧 `providerById` 现在只作为兜底读取

### 1.3 仍在兼容桥上

- `matchModel`
- `modelProfileDefaults`
- `catalogParameterSummary`

原因：

- 虽然 runtime defaults / offering facts 已经成为主来源
- 但旧 catalog 里仍保留部分 provider-specific 旧字段
- 在新 registry 完全补齐前，这三项还不能直接删除

## 2. 本轮已迁走的调用点

1. 设置页模型建议的 legacy fallback 已通过：
   - `LegacyProviderCatalogBridgeService`
   包起来，不再让业务服务直接依赖旧 catalog 实现
2. runtime 的 `provider_label` 已优先改走：
   - `ProviderInterfaceTemplateService`

## 3. 下一轮优先迁走的目标

### 3.1 `matchModel`

优先尝试改成：

- `WritingModelOfferingCatalogService.bestMatch`
- 旧 catalog 仅作为 unknown/legacy provider fallback

### 3.2 `modelProfileDefaults`

优先尝试改成：

- `WritingModelRuntimeDefaultsService.resolveDefaults`
- 旧 catalog 仅补 provider-specific 老字段

### 3.3 `catalogParameterSummary`

优先尝试改成：

- `WritingModelRuntimeDefaultsService.parameterSummary`
- offering override / canonical facts 为主
- 旧 catalog 为兜底
