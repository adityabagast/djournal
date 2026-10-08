import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../providers.dart';
import '../../ui/common.dart';

/// Bottom sheet untuk menambah dompet baru.
class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const WalletFormSheet(),
    );
  }

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  String _type = 'bank';
  bool _showNameError = false;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    await ref
        .read(moneyRepositoryProvider)
        .addWallet(
          name: _name.text,
          type: _type,
          openingBalance: parseAmount(_opening.text),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final types = [
      ('cash', l.walletTypeCash),
      ('bank', l.walletTypeBank),
      ('ewallet', l.walletTypeEwallet),
      ('other', l.walletTypeOther),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
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
                color: const Color(0xFFD9D6CD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.addWallet,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_showNameError) setState(() => _showNameError = false);
            },
            decoration: InputDecoration(
              labelText: l.walletName,
              hintText: l.walletNameHint,
              errorText: _showNameError ? l.walletNameRequired : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.walletType,
            style: t.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final (key, text) in types)
                ChoiceChip(
                  label: Text(text),
                  selected: _type == key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _type = key),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _opening,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsInputFormatter()],
            decoration: InputDecoration(
              labelText: l.openingBalance,
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(l.save),
          ),
        ],
      ),
    );
  }
}
