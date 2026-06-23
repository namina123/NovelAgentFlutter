/// 技能 ID 归一化器。
///
/// 技能包经 `SkillMarkdownPackageParserService` 解析后，id 直接取自 SKILL.md 的
/// `name` 字段（仓库内置包统一是 kebab-case，例如 `generate-outline`）；而智能体文档、
/// 内置技能组目录、技能路由策略在历史上大量使用 snake_case 引用同一批技能（例如
/// `generate_outline`）。两端都是逐字字符串比较，没有任何归一化，于是会出现“技能明明已
/// 安装，却被判定为 unavailable 而被静默过滤掉、load_agent_skill 也匹配不到包”的调度失败。
///
/// 这里把任意形态的技能 id 统一收敛到 canonical kebab-case（下划线→连字符），供所有
/// 匹配/查找边界调用。归一化只发生在“比较”环节，不会改写持久化或回显的原始 id，因此
/// 旧的 snake_case 数据和现有测试都不受影响。
class SkillIdNormalizer {
  const SkillIdNormalizer();

  String normalize(String id) {
    var result = id.trim().toLowerCase();
    if (result.isEmpty) {
      return '';
    }
    result = result.replaceAll('_', '-'); // snake_case → kebab-case
    result = result.replaceAll(RegExp(r'\s+'), '-');
    result = result.replaceAll(RegExp(r'[^a-z0-9-]'), '-');
    result = result.replaceAll(RegExp(r'-+'), '-');
    result = result.replaceAll(RegExp(r'^-+|-+$'), '');
    if (result.isEmpty) {
      // 整段都是非法字符时，退回小写原值，避免把有效引用归一成空串。
      return id.trim().toLowerCase();
    }
    return result;
  }
}
