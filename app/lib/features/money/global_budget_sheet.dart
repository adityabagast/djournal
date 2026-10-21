import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers.dart';

class GlobalBudgetSheet extends ConsumerStatefulWidget {
  const GlobalBudgetSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const GlobalBudgetSheet(),
    );
  }

  @override
  ConsumerState<GlobalBudgetSheet> createState() => _GlobalBudgetSheetState();
}

class _GlobalBudgetSheetState extends ConsumerState<GlobalBudgetSheet> {
  final _dailyController = TextEditingController();
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final budget = ref.read(globalBudgetProvider);
    if (budget.dailyLimit > 0) _dailyController.text = thousands(budget.dailyLimit);
    if (budget.weeklyLimit > 0) _weeklyController.text = thousands(budget.weeklyLimit);
    if (budget.monthlyLimit > 0) _monthlyController.text = thousands(budget.monthlyLimit);
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Target Budget Global',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tentukan batas pengeluaran menyeluruh untuk mengontrol keuangan harian, mingguan, atau bulanan.',
            style: t.bodySmall?.copyWith(color: context.colors.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _dailyController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Target Harian (Rp)',
              prefixText: 'Rp ',
              hintText: 'Misal: 75.000',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _weeklyController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Target Mingguan (Rp)',
              prefixText: 'Rp ',
              hintText: 'Misal: 500.000',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _monthlyController,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Target Bulanan (Rp)',
              prefixText: 'Rp ',
              hintText: 'Misal: 2.500.000',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('Simpan Target Budget'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final daily = parseAmount(_dailyController.text);
    final weekly = parseAmount(_weeklyController.text);
    final monthly = parseAmount(_monthlyController.text);

    final settings = ref.read(settingsRepositoryProvider);
    await settings.set('budget_daily_limit', daily.toString());
    await settings.set('budget_weekly_limit', weekly.toString());
    await settings.set('budget_monthly_limit', monthly.toString());

    if (mounted) Navigator.pop(context);
  }
}
