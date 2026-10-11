import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../../data/journal_repository.dart';
import '../../data/money_snapshot.dart';
import '../../data/search.dart';
import '../../providers.dart';
import '../../ui/common.dart';
import '../../ui/mascot.dart';
import '../../ui/mood.dart';
import '../journal/entry_form_screen.dart';
import '../money/tx_form_screen.dart';

/// Kunci app_settings (lokal) untuk pencarian terakhir.
const _recentKey = 'search_recent';
const _maxRecent = 5;

final _recentSearchesProvider = StreamProvider<List<String>>(
  (ref) => ref
      .watch(settingsRepositoryProvider)
      .watch(_recentKey)
      .map(
        (v) => v == null ? const [] : (jsonDecode(v) as List).cast<String>(),
      ),
);

/// Tombol kaca pembesar di kepala halaman Hari Ini, Jurnal, dan Keuangan.
class SearchButton extends StatelessWidget {
  const SearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: context.l10n.search,
      onPressed: () => SearchScreen.open(context),
      style: IconButton.styleFrom(
        backgroundColor: context.colors.surface,
        side: BorderSide(color: context.colors.line),
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.search, size: 22),
    );
  }
}

/// Pencarian jurnal dan transaksi.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  SearchScope _scope = SearchScope.all;
  SearchPeriod _period = SearchPeriod.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setQuery(String text) {
    _query.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  /// Simpan ke pencarian terakhir (paling baru di atas).
  Future<void> _remember() async {
    final text = _query.text.trim();
    if (text.isEmpty) return;
    final recent = ref.read(_recentSearchesProvider).value ?? const [];
    final next = [
      text,
      ...recent.where((r) => r.toLowerCase() != text.toLowerCase()),
    ].take(_maxRecent).toList();
    await ref
        .read(settingsRepositoryProvider)
        .set(_recentKey, jsonEncode(next));
  }

  Future<void> _open(SearchHit hit) async {
    await _remember();
    if (!mounted) return;
    if (hit.entry != null) {
      await EntryFormScreen.open(context, existing: hit.entry);
    } else {
      await TxFormScreen.open(context, existing: hit.tx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final money = ref.watch(moneySnapshotProvider).value;
    final entries = ref.watch(journalEntriesProvider).value ?? const [];
    final query = _query.text.trim();

    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: context.colors.primary,
      backgroundColor: context.colors.surface,
      side: BorderSide(
        color: selected ? context.colors.primary : context.colors.line,
      ),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: selected ? context.colors.onPrimary : context.colors.ink,
      ),
    );

    final Widget body;
    if (money == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (query.isEmpty) {
      body = _StartView(
        entries: entries,
        money: money,
        onPick: (text) {
          _setQuery(text);
          _remember();
        },
      );
    } else {
      final results = searchAll(
        query: query,
        entries: entries,
        money: money,
        categoryName: (c) => categoryLabel(l, c),
        transferLabel: l.transfer,
        scope: _scope,
        period: _period,
      );
      body = results.hits.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: [
                MascotEmpty(
                  pose: MascotPose.mencari,
                  tint: MascotTint.sky,
                  title: l.searchNotFound,
                  message: _period == SearchPeriod.all
                      ? l.searchNotFoundBody(query)
                      : l.searchNotFoundPeriodBody(query),
                  size: 140,
                ),
              ],
            )
          : _Results(
              results: results,
              money: money,
              terms: searchTerms(query),
              onOpen: _open,
            );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _remember(),
            style: t.bodyLarge,
            decoration: InputDecoration(
              hintText: l.searchHint,
              prefixIcon: Icon(Icons.search, color: context.colors.muted),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l.clearText,
                      onPressed: () => _setQuery(''),
                      icon: const Icon(Icons.close, size: 20),
                    ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: context.colors.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: context.colors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: context.colors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              spacing: 8,
              children: [
                for (final (s, text) in [
                  (SearchScope.all, l.searchScopeAll),
                  (SearchScope.journal, l.navJournal),
                  (SearchScope.transactions, l.searchScopeTx),
                ])
                  chip(text, _scope == s, () => setState(() => _scope = s)),
                Container(width: 1, height: 24, color: context.colors.line),
                for (final (p, text) in [
                  (SearchPeriod.all, l.periodAll),
                  (SearchPeriod.thisMonth, l.periodThisMonth),
                  (SearchPeriod.threeMonths, l.periodThreeMonths),
                ])
                  chip(text, _period == p, () => setState(() => _period = p)),
              ],
            ),
          ),
        ),
      ),
      body: body,
    );
  }
}

/// Sebelum mengetik: pencarian terakhir dan saran (tag, kategori, dompet).
class _StartView extends ConsumerWidget {
  const _StartView({
    required this.entries,
    required this.money,
    required this.onPick,
  });

  final List<JournalEntry> entries;
  final MoneySnapshot money;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final recent = ref.watch(_recentSearchesProvider).value ?? const [];

    // Saran: tag dan kategori yang paling sering dipakai, plus dompet.
    final tagCount = <String, int>{};
    for (final e in entries) {
      for (final tag in entryTags(e)) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    final catCount = <String, int>{};
    for (final tx in money.transactions) {
      if (tx.categoryId case final id?) catCount[id] = (catCount[id] ?? 0) + 1;
    }
    List<K> top<K>(Map<K, int> counts, int n) =>
        (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(n)
            .map((e) => e.key)
            .toList();
    final suggestions = <(String label, String query, Color color)>[
      for (final tag in top(tagCount, 3))
        ('#$tag', tag, context.colors.primary),
      for (final id in top(catCount, 3))
        if (money.categoryById[id] case final c?)
          (
            categoryLabel(l, c),
            categoryLabel(l, c),
            context.colors.fg(hexColor(c.color)),
          ),
      for (final w in money.wallets.take(2))
        (w.name, w.name, context.colors.muted),
    ];

    Widget sectionTitle(String text, {Widget? trailing}) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: t.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.muted,
                fontSize: 13,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (recent.isNotEmpty) ...[
          sectionTitle(
            l.recentSearches,
            trailing: TextButton(
              onPressed: () =>
                  ref.read(settingsRepositoryProvider).remove(_recentKey),
              child: Text(l.clearRecentSearches),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                for (final (i, r) in recent.indexed)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.history, color: context.colors.muted),
                    title: Text(r, style: t.bodyMedium),
                    trailing: Icon(
                      Icons.north_west,
                      size: 16,
                      color: context.colors.faint,
                    ),
                    shape: i < recent.length - 1
                        ? Border(
                            bottom: BorderSide(color: context.colors.divider),
                          )
                        : null,
                    onTap: () => onPick(r),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (suggestions.isNotEmpty) ...[
          sectionTitle(l.trySearching),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, query, color) in suggestions)
                ActionChip(
                  label: Text(label),
                  onPressed: () => onPick(query),
                  backgroundColor: context.colors.soft(color),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.money,
    required this.terms,
    required this.onOpen,
  });

  final SearchResults results;
  final MoneySnapshot money;
  final List<String> terms;
  final ValueChanged<SearchHit> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final count = [
      if (results.entryCount > 0) l.searchCountEntries(results.entryCount),
      if (results.txCount > 0) l.walletTxCount(results.txCount),
    ].join(' · ');
    final sums = [
      if (results.expense > 0) l.searchSumOut(rupiah(results.expense)),
      if (results.income > 0) l.searchSumIn(rupiah(results.income)),
    ].join(' · ');

    final groups = <String, List<SearchHit>>{};
    for (final hit in results.hits) {
      groups.putIfAbsent(hit.date, () => []).add(hit);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  count,
                  style: t.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (sums.isNotEmpty)
                Text(
                  sums,
                  style: t.bodySmall?.copyWith(color: context.colors.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              dayLabel(context, entry.key),
              style: t.bodySmall?.copyWith(
                color: context.colors.muted,
                fontSize: 13,
              ),
            ),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (final (i, hit) in entry.value.indexed)
                  _HitRow(
                    hit: hit,
                    money: money,
                    terms: terms,
                    showDivider: i < entry.value.length - 1,
                    onTap: () => onOpen(hit),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

/// Teks dengan bagian yang cocok disorot.
List<TextSpan> _highlighted(String text, List<String> terms, Color highlight) {
  final lower = text.toLowerCase();
  final marks = List.filled(text.length, false);
  for (final term in terms) {
    if (term.isEmpty) continue;
    var i = lower.indexOf(term);
    while (i != -1) {
      for (var k = i; k < i + term.length && k < marks.length; k++) {
        marks[k] = true;
      }
      i = lower.indexOf(term, i + term.length);
    }
  }
  final spans = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= text.length; i++) {
    if (i == text.length || marks[i] != marks[start]) {
      spans.add(
        TextSpan(
          text: text.substring(start, i),
          style: marks[start] ? TextStyle(backgroundColor: highlight) : null,
        ),
      );
      start = i;
    }
  }
  return spans;
}

/// Potongan isi di sekitar kata pertama yang cocok, supaya sorotannya
/// kelihatan walau isinya panjang.
String _snippet(String body, List<String> terms) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  final lower = flat.toLowerCase();
  final hit = terms
      .map(lower.indexOf)
      .where((i) => i >= 0)
      .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
  if (hit == null || hit < 60) return flat;
  final from = flat.lastIndexOf(' ', hit - 30);
  return '…${flat.substring(from < 0 ? hit - 30 : from + 1)}';
}

class _HitRow extends StatelessWidget {
  const _HitRow({
    required this.hit,
    required this.money,
    required this.terms,
    required this.showDivider,
    required this.onTap,
  });

  final SearchHit hit;
  final MoneySnapshot money;
  final List<String> terms;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final titleStyle = t.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    final metaStyle = t.bodySmall?.copyWith(color: context.colors.muted);

    final Widget badge;
    final String title;
    String? body;
    final String meta;
    Widget? trailing;

    if (hit.entry case final e?) {
      badge = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: context.colors.primarySoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(
          Icons.menu_book_outlined,
          size: 18,
          color: context.colors.primary,
        ),
      );
      title = e.title?.trim().isNotEmpty == true ? e.title! : l.untitled;
      if (e.body?.trim().isNotEmpty == true) body = _snippet(e.body!, terms);
      meta = [
        ?e.entryTime,
        if (e.mood != null) moodLabel(l, e.mood!),
        for (final tag in entryTags(e)) '#$tag',
      ].join(' · ');
    } else {
      final tx = hit.tx!;
      final category = money.categoryById[tx.categoryId];
      final isTransfer = tx.type == 'transfer';
      final isOut = tx.type == 'expense';
      final wallet = money.walletById[tx.walletId]?.name ?? '?';
      badge = isTransfer
          ? const TransferBadge(size: 36)
          : CategoryBadge(category: category, size: 36);
      title =
          tx.note ??
          (isTransfer
              ? l.transfer
              : category == null
              ? ''
              : categoryLabel(l, category));
      meta = [
        hhmm(tx.occurredAt),
        if (category != null) categoryLabel(l, category),
        if (isTransfer)
          // Poppins tidak punya karakter panah, jadi pakai kata "ke".
          '$wallet ${l.transferTo.toLowerCase()} '
              '${money.walletById[tx.toWalletId]?.name ?? '?'}'
        else
          wallet,
      ].join(' · ');
      trailing = Text(
        isTransfer
            ? rupiah(tx.amount)
            : '${isOut ? '−' : '+'}${rupiah(tx.amount)}',
        style: titleStyle?.copyWith(
          color: isTransfer
              ? context.colors.ink
              : isOut
              ? context.colors.expense
              : context.colors.income,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Row(
          crossAxisAlignment: hit.entry != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            badge,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: _highlighted(
                        title,
                        terms,
                        context.colors.highlight,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  if (body != null)
                    Text.rich(
                      TextSpan(
                        children: _highlighted(
                          body,
                          terms,
                          context.colors.highlight,
                        ),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: metaStyle?.copyWith(fontSize: 13),
                    ),
                  if (meta.isNotEmpty)
                    Text.rich(
                      TextSpan(
                        children: _highlighted(
                          meta,
                          terms,
                          context.colors.highlight,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: hit.entry != null
                          ? metaStyle?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
                            )
                          : metaStyle,
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing],
          ],
        ),
      ),
    );
  }
}
