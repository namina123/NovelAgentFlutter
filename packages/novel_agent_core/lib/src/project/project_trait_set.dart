import 'project_trait.dart';

class ProjectTraitSet {
  ProjectTraitSet(Iterable<ProjectTrait> traits)
    : _traitsById = _buildMap(traits);

  factory ProjectTraitSet.fromIds(Iterable<String> traitIds) {
    // 中文注释: 这里允许从任意字符串列表恢复 trait 集合，供项目、模式和运行时入口统一复用。
    return ProjectTraitSet(
      traitIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .map(ProjectTrait.fromId),
    );
  }

  final Map<String, ProjectTrait> _traitsById;

  List<ProjectTrait> get items =>
      List<ProjectTrait>.unmodifiable(_traitsById.values);

  List<String> get ids => List<String>.unmodifiable(_traitsById.keys);

  bool get isEmpty => _traitsById.isEmpty;

  bool get isNotEmpty => _traitsById.isNotEmpty;

  bool contains(ProjectTrait trait) => containsId(trait.id);

  bool containsId(String traitId) => _traitsById.containsKey(traitId.trim());

  ProjectTraitSet mergedWith(Iterable<ProjectTrait> traits) {
    // 中文注释: trait 集合的组合在 resolver 和后续 overlay 合并时会频繁出现，因此单独给出不可变合并入口。
    return ProjectTraitSet(<ProjectTrait>[..._traitsById.values, ...traits]);
  }

  ProjectTraitSet mergedWithIds(Iterable<String> traitIds) {
    // 中文注释: 这里保留字符串级合并入口，方便从配置文档或模式 id 推导后直接叠加。
    return mergedWith(
      traitIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .map(ProjectTrait.fromId),
    );
  }

  static Map<String, ProjectTrait> _buildMap(Iterable<ProjectTrait> traits) {
    final result = <String, ProjectTrait>{};
    for (final trait in traits) {
      final cleanId = trait.id.trim();
      if (cleanId.isEmpty) {
        continue;
      }
      result[cleanId] = trait.id == cleanId
          ? trait
          : ProjectTrait(
              id: cleanId,
              name: trait.name,
              description: trait.description,
            );
    }
    return result;
  }
}
