import 'resolved_agent_group_member_profile.dart';

class ResolvedAgentGroupProfile {
  const ResolvedAgentGroupProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.orchestration,
    required this.members,
    this.source = '',
    this.enabled = true,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String name;
  final String description;
  final String orchestration;
  final List<ResolvedAgentGroupMemberProfile> members;
  final String source;
  final bool enabled;
  final Map<String, Object?> metadata;

  ResolvedAgentGroupMemberProfile? get primaryMember {
    // 中文注释: 主成员是 group-first 运行路径中的唯一默认入口，因此统一由强类型对象提供查询。
    for (final member in members) {
      if (member.isPrimary) {
        return member;
      }
    }
    return null;
  }

  List<ResolvedAgentGroupMemberProfile> get requiredMembers =>
      members.where((member) => member.isRequired).toList(growable: false);

  List<ResolvedAgentGroupMemberProfile> get optionalMembers =>
      members.where((member) => member.isOptional).toList(growable: false);
}
