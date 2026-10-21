import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/global_budget.dart';
import 'database_providers.dart';

final dailyBudgetLimitProvider = StreamProvider<int>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch('budget_daily_limit')
      .map((val) => int.tryParse(val ?? '') ?? 0);
});

final weeklyBudgetLimitProvider = StreamProvider<int>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch('budget_weekly_limit')
      .map((val) => int.tryParse(val ?? '') ?? 0);
});

final monthlyBudgetLimitProvider = StreamProvider<int>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watch('budget_monthly_limit')
      .map((val) => int.tryParse(val ?? '') ?? 0);
});

final globalBudgetProvider = Provider<GlobalBudget>((ref) {
  final daily = ref.watch(dailyBudgetLimitProvider).value ?? 0;
  final weekly = ref.watch(weeklyBudgetLimitProvider).value ?? 0;
  final monthly = ref.watch(monthlyBudgetLimitProvider).value ?? 0;
  return GlobalBudget(
    dailyLimit: daily,
    weeklyLimit: weekly,
    monthlyLimit: monthly,
  );
});

enum BudgetPeriod {
  daily,
  weekly,
  monthly,
}

class BudgetPeriodNotifier extends Notifier<BudgetPeriod> {
  @override
  BudgetPeriod build() => BudgetPeriod.daily;

  void setPeriod(BudgetPeriod period) => state = period;
}

final budgetPeriodProvider =
    NotifierProvider<BudgetPeriodNotifier, BudgetPeriod>(BudgetPeriodNotifier.new);
