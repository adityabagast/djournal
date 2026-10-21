enum BudgetAlertLevel {
  safe,
  warning,
  danger,
}

class GlobalBudget {
  const GlobalBudget({
    this.dailyLimit = 0,
    this.weeklyLimit = 0,
    this.monthlyLimit = 0,
  });

  final int dailyLimit;
  final int weeklyLimit;
  final int monthlyLimit;

  bool get hasDailyLimit => dailyLimit > 0;
  bool get hasWeeklyLimit => weeklyLimit > 0;
  bool get hasMonthlyLimit => monthlyLimit > 0;
  bool get hasAnyLimit => hasDailyLimit || hasWeeklyLimit || hasMonthlyLimit;

  static BudgetAlertLevel alertLevelFor(int spent, int limit) {
    if (limit <= 0) return BudgetAlertLevel.safe;
    final pct = spent / limit;
    if (pct >= 1.0) return BudgetAlertLevel.danger;
    if (pct >= 0.75) return BudgetAlertLevel.warning;
    return BudgetAlertLevel.safe;
  }

  static double percentageOf(int spent, int limit) {
    if (limit <= 0) return 0.0;
    return (spent / limit).clamp(0.0, 1.0);
  }
}
