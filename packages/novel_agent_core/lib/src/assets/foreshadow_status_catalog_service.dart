class ForeshadowStatusCatalogService {
  const ForeshadowStatusCatalogService();

  static const String planted = 'planted';
  static const String pendingPayoff = 'pending_payoff';
  static const String partialPayoff = 'partial_payoff';
  static const String resolved = 'resolved';
  static const String abandoned = 'abandoned';
  static const String atRisk = 'at_risk';

  String normalize(String raw) {
    // 中文注释: 伏笔状态需要稳定枚举，避免普通项目和长任务各自发明同义词。
    final value = raw.trim().toLowerCase();
    return switch (value) {
      '已埋下' || '埋下' || 'planted' => planted,
      '待回收' || 'pending' || 'pending_payoff' => pendingPayoff,
      '部分回收' || 'partial' || 'partial_payoff' => partialPayoff,
      '已回收' || 'resolved' || 'paid_off' || 'payoff' => resolved,
      '弃用' || 'abandoned' || 'dropped' => abandoned,
      '风险中' || 'at_risk' || 'risk' => atRisk,
      _ => value.isEmpty ? pendingPayoff : value,
    };
  }

  bool isTerminal(String status) {
    final normalized = normalize(status);
    return normalized == resolved || normalized == abandoned;
  }

  int priority(String status) {
    final normalized = normalize(status);
    return switch (normalized) {
      atRisk => 0,
      pendingPayoff => 1,
      partialPayoff => 2,
      planted => 3,
      resolved => 4,
      abandoned => 5,
      _ => 6,
    };
  }
}
