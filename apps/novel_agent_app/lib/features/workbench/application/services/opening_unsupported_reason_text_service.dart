class OpeningUnsupportedReasonTextService {
  const OpeningUnsupportedReasonTextService();

  List<String> buildDetails(List<String> reasonCodes) {
    // 中文注释: 不可用原因文案在这里统一投影，避免 UI 组件直接理解 core reason code。
    final details = <String>[];
    final seen = <String>{};
    for (final code in reasonCodes) {
      final text = _textOf(code);
      if (text.isEmpty || !seen.add(text)) {
        continue;
      }
      details.add(text);
    }
    if (details.isEmpty) {
      return const <String>['当前项目条件暂不满足该智能体组。'];
    }
    return details;
  }

  String buildSummary(List<String> reasonCodes) {
    // 中文注释: 概要文案尽量收束成一句话，避免高级入口展开前就堆过多解释。
    final details = buildDetails(reasonCodes);
    return details.first;
  }

  String _textOf(String reasonCode) {
    switch (reasonCode.trim()) {
      case 'disabledByProjectBinding':
        return '当前项目已显式禁用该智能体组。';
      case 'projectTypeMismatch':
        return '项目类型与该智能体组的适用范围不匹配。';
      case 'modeMismatch':
        return '当前模式与该智能体组的作用域不匹配。';
      case 'stageMismatch':
        return '当前阶段不在该智能体组的支持范围内。';
      case 'missingRequiredTraits':
        return '项目特征还不满足该智能体组的前置要求。';
      case 'excludedTraitsPresent':
        return '项目命中了该智能体组排除的特征。';
      case 'missingRequiredMembers':
        return '该智能体组缺少当前必须可用的成员。';
      case 'primaryMemberUnavailable':
        return '该智能体组的主智能体当前不可用。';
      case 'degradedRunNotAllowed':
        return '该智能体组当前不能以降级成员形态运行。';
      case 'noSupportedMembers':
        return '该智能体组当前没有可用成员。';
      default:
        return '';
    }
  }
}
