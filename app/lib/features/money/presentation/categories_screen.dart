import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/database/app_database.dart';
import '../domain/money_snapshot.dart';
import '../../../providers.dart';
import 'category_icons.dart';
import '../../../core/widgets/common.dart';
import 'money_widgets.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_sheet.dart';

/// Pilihan warna kategori: 10 warna yang mudah dibedakan, termasuk warna
/// beberapa kategori bawaan.
const categoryPalette = [
  '#9A3412', // karat
  '#B45309', // jingga
  '#7A5A00', // mustard
  '#4D7C0F', // zaitun
  '#1F5F4E', // hijau Nyawtat
  '#0E7490', // biru laut
  '#1E4E79', // biru tua
  '#6B2C7A', // ungu
  '#8A2D5C', // magenta
  '#4A4E4C', // abu-abu
];

/// Jumlah transaksi kategori ini, termasuk subkategorinya.
int _txCount(MoneySnapshot snap, String categoryId) => snap.transactions
    .where(
      (t) =>
          t.categoryId != null &&
          (t.categoryId == categoryId ||
              snap.categoryById[t.categoryId]?.parentId == categoryId),
    )
    .length;

/// Halaman "Kelola kategori": urutkan (tahan & geser), sembunyikan,
/// gabungkan, hapus, dan tambah kategori. Dibuka dari Pengaturan › Data dan
/// dari form catat transaksi.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key, this.kind = 'expense'});

  /// Tab yang dibuka pertama: 'expense' atau 'income'.
  final String kind;

  static Future<void> open(BuildContext context, {String kind = 'expense'}) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => CategoriesScreen(kind: kind)),
      );

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  late String _kind = widget.kind;
  bool _hiddenOpen = true;

  /// Kategori utama yang daftar subkategorinya sedang dibuka.
  final _expanded = <String>{};

  /// Urutan yang baru digeser, dipakai sampai database selesai menyimpan
  /// supaya daftar tidak "melompat balik" sesaat.
  List<String>? _pendingOrder;

  Future<void> _onReorder(
    List<Category> active,
    List<Category> hidden,
    int oldIndex,
    int newIndex,
  ) async {
    final ids = active.map((c) => c.id).toList();
    ids.insert(newIndex, ids.removeAt(oldIndex));
    setState(() => _pendingOrder = ids);
    await ref.read(moneyRepositoryProvider).reorderCategories([
      ...ids,
      ...hidden.map((c) => c.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;

    Widget sectionTitle(String text) => Text(
      text.toUpperCase(),
      style: t.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.muted,
        fontSize: AppFontSize.body,
      ),
    );

    var active = snap == null
        ? <Category>[]
        : snap.categories.where((c) => c.kind == _kind).toList();
    final hidden = snap == null
        ? <Category>[]
        : snap.hiddenCategories.where((c) => c.kind == _kind).toList();
    final pending = _pendingOrder;
    if (pending != null) {
      if (active.map((c) => c.id).join() == pending.join()) {
        _pendingOrder = null;
      } else if (pending.toSet().containsAll(active.map((c) => c.id))) {
        final byId = {for (final c in active) c.id: c};
        active = [for (final id in pending) ?byId[id]];
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l.manageCategories,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.md),
            child: FilledButton.icon(
              onPressed: () => CategoryFormSheet.open(context, kind: _kind),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.add),
            ),
          ),
        ],
      ),
      body: snap == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.xl, AppSpace.xxxl),
              children: [
                _KindTabs(
                  value: _kind,
                  onChanged: (k) => setState(() {
                    _kind = k;
                    _pendingOrder = null;
                  }),
                ),
                const SizedBox(height: AppSpace.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: Text(
                    l.categoryReorderHint,
                    style: t.bodySmall?.copyWith(color: context.colors.muted),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                AppCard(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxs, AppSpace.sm, AppSpace.xxs),
                  // Latar baris tidak boleh keluar dari sudut kartu.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorderItem: (from, to) =>
                          _onReorder(active, hidden, from, to),
                      children: [
                        for (final (i, c) in active.indexed)
                          _CategoryRow(
                            key: ValueKey(c.id),
                            index: i,
                            category: c,
                            snapshot: snap,
                            showDivider: i < active.length - 1,
                            expanded: _expanded.contains(c.id),
                            onToggle: () => setState(() {
                              if (!_expanded.remove(c.id)) _expanded.add(c.id);
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                InkWell(
                  onTap: () => setState(() => _hiddenOpen = !_hiddenOpen),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xs,
                      vertical: AppSpace.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: sectionTitle(
                            l.hiddenCategoriesTitle(hidden.length),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _hiddenOpen ? 0.5 : 0,
                          duration: AppMotion.short,
                          child: Icon(
                            Icons.expand_more,
                            color: context.colors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hiddenOpen) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.xs, 0, AppSpace.xs, AppSpace.sm),
                    child: Text(
                      l.hiddenCategoriesHint,
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                    decoration: BoxDecoration(
                      color: context.colors.subtle,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: context.colors.handle),
                    ),
                    child: hidden.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                            child: Text(
                              l.noHiddenCategories,
                              style: t.bodySmall?.copyWith(
                                color: context.colors.muted,
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final (i, c) in hidden.indexed)
                                _HiddenRow(
                                  category: c,
                                  snapshot: snap,
                                  showDivider: i < hidden.length - 1,
                                ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: context.colors.track,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          for (final (kind, text) in [
            ('expense', l.expense),
            ('income', l.income),
          ])
            Expanded(
              child: Semantics(
                selected: value == kind,
                button: true,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(kind);
                  },
                  child: AnimatedContainer(
                    duration: AppMotion.short,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == kind
                          ? context.colors.raised
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: value == kind
                          ? [
                              BoxShadow(
                                color: context.colors.shadow.withValues(
                                  alpha: 0.12,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: value == kind
                            ? context.colors.ink
                            : context.colors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    super.key,
    required this.index,
    required this.category,
    required this.snapshot,
    required this.showDivider,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final Category category;
  final MoneySnapshot snapshot;
  final bool showDivider;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final budget = snapshot.budgetFor(category.id, toMonthKey(DateTime.now()));
    final subs = snapshot.childrenOf(category.id, includeHidden: true);
    final meta = [
      if (subs.isNotEmpty) l.subcategoryCount(subs.length),
      l.walletTxCount(_txCount(snapshot, category.id)),
      if (budget > 0) l.categoryBudgetMeta(rupiah(budget)),
    ].join(' · ');

    return Material(
      color: context.colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: context.colors.divider))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: Icon(
                      Icons.drag_indicator,
                      color: context.colors.faint,
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => CategoryFormSheet.open(
                      context,
                      kind: category.kind,
                      existing: category,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                      child: Row(
                        children: [
                          CategoryBadge(category: category, size: 36),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        categoryLabel(l, category),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: t.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (category.systemKey != null) ...[
                                      const SizedBox(width: AppSpace.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpace.sm,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.colors.track,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          l.categorySystemBadge,
                                          style: TextStyle(
                                            fontSize: AppFontSize.caption,
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  meta,
                                  style: t.bodySmall?.copyWith(
                                    color: context.colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.addSubcategory,
                  onPressed: onToggle,
                  icon: AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: AppMotion.short,
                    child: Icon(Icons.expand_more, color: context.colors.muted),
                  ),
                ),
              ],
            ),
            if (expanded)
              _SubcategoryList(
                parent: category,
                subs: subs,
                snapshot: snapshot,
              ),
          ],
        ),
      ),
    );
  }
}

/// Subkategori di bawah kategori utama yang dibuka, plus tombol tambah.
class _SubcategoryList extends StatelessWidget {
  const _SubcategoryList({
    required this.parent,
    required this.subs,
    required this.snapshot,
  });

  final Category parent;
  final List<Category> subs;
  final MoneySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(52, 0, AppSpace.md, AppSpace.md),
      padding: const EdgeInsets.only(left: AppSpace.md),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: context.colors.line, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final s in subs)
            InkWell(
              onTap: () => CategoryFormSheet.open(
                context,
                kind: s.kind,
                existing: s,
                parent: parent,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoryLabel(l, s),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodyMedium?.copyWith(
                          color: s.isArchived ? context.colors.muted : null,
                          decoration: s.isArchived
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      l.walletTxCount(_txCount(snapshot, s.id)),
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => CategoryFormSheet.open(
                context,
                kind: parent.kind,
                parent: parent,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.addSubcategory),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenRow extends ConsumerWidget {
  const _HiddenRow({
    required this.category,
    required this.snapshot,
    required this.showDivider,
  });

  final Category category;
  final MoneySnapshot snapshot;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final name = categoryLabel(l, category);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: context.colors.divider))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => CategoryFormSheet.open(
                context,
                kind: category.kind,
                existing: category,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.muted,
                      ),
                    ),
                    Text(
                      l.walletTxCount(_txCount(snapshot, category.id)),
                      style: t.bodySmall?.copyWith(color: context.colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          OutlinedButton(
            onPressed: () async {
              await ref
                  .read(moneyRepositoryProvider)
                  .setCategoryHidden(category.id, false);
              if (context.mounted) {
                showMascotSnackBar(
                  context,
                  MascotPose.senang,
                  l.toastCategoryShown(name),
                );
              }
            },
            child: Text(l.showCategory),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet tambah / ubah kategori, plus sembunyikan, gabungkan, hapus.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    required this.kind,
    this.existing,
    this.parent,
  });

  final String kind;
  final Category? existing;

  /// Terisi = form subkategori (warna ikut induk).
  final Category? parent;

  static Future<void> open(
    BuildContext context, {
    required String kind,
    Category? existing,
    Category? parent,
  }) {
    return showAppSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          CategoryFormSheet(kind: kind, existing: existing, parent: parent),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _name = TextEditingController();
  late String _color;
  String? _icon;
  bool _showNameError = false;

  Category? get _existing => widget.existing;
  bool get _isSystem => _existing?.systemKey != null;
  Category? get _parent => widget.parent;

  @override
  void initState() {
    super.initState();
    final e = _existing;
    _color = widget.parent?.color ?? e?.color ?? categoryPalette[6];
    _icon = categoryIcons.containsKey(e?.icon) ? e!.icon : null;
    if (e != null) _name.text = e.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done(String message) {
    if (!mounted) return;
    Navigator.of(context).pop();
    showMascotSnackBar(context, MascotPose.senang, message);
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (!_isSystem && _name.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final repo = ref.read(moneyRepositoryProvider);
    final e = _existing;
    if (e == null) {
      await repo.addCategory(
        kind: widget.kind,
        name: _name.text,
        color: _color,
        icon: _icon,
        parentId: _parent?.id,
      );
    } else {
      await repo.updateCategory(
        id: e.id,
        name: _isSystem ? null : _name.text,
        color: _color,
        icon: _icon,
      );
    }
    _done(l.toastCategorySaved);
  }

  Future<void> _toggleHidden(String name) async {
    final l = context.l10n;
    final e = _existing!;
    await ref
        .read(moneyRepositoryProvider)
        .setCategoryHidden(e.id, !e.isArchived);
    _done(
      e.isArchived ? l.toastCategoryShown(name) : l.toastCategoryHidden(name),
    );
  }

  Future<void> _merge(MoneySnapshot snap, String name, int txCount) async {
    final l = context.l10n;
    final e = _existing!;
    // Subkategori boleh digabung ke kategori mana pun (utama atau sub);
    // kategori utama hanya ke kategori utama lain.
    final targets = [
      for (final c in snap.categories.where((c) => c.kind == e.kind)) ...[
        if (c.id != e.id) c,
        if (_parent != null)
          for (final s in snap.childrenOf(c.id))
            if (s.id != e.id) s,
      ],
    ];
    final target = await showAppSheet<Category>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.xxl),
          children: [
            Text(
              l.mergeCategoryTitle(name),
              style: Theme.of(ctx).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(
              l.mergeCategoryHint(txCount, name),
              style: Theme.of(ctx).textTheme.bodySmall
                  ?.copyWith(color: context.colors.muted),
            ),
            const SizedBox(height: AppSpace.sm),
            for (final c in targets)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CategoryBadge(category: c, size: 32),
                title: Text(
                  categoryPath(l, snap, c),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        ),
      ),
    );
    if (target == null || !mounted) return;
    final targetName = categoryLabel(l, target);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.mergeConfirmTitle),
        content: Text(l.mergeConfirmBody(txCount, name, targetName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.mergeAction),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref
        .read(moneyRepositoryProvider)
        .mergeCategory(fromId: e.id, toId: target.id);
    _done(l.toastCategoryMerged(name, targetName));
  }

  Future<void> _delete() async {
    final l = context.l10n;
    await ref.read(moneyRepositoryProvider).deleteCategory(_existing!.id);
    _done(l.toastCategoryDeleted);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final snap = ref.watch(moneySnapshotProvider).value;
    final e = _existing;
    final name = e == null ? '' : categoryLabel(l, e);
    final txCount = e == null || snap == null ? 0 : _txCount(snap, e.id);
    final canDelete = e != null && !_isSystem && txCount == 0;
    final raw = hexColor(_color);
    final fg = context.colors.fg(raw);
    final previewName = _isSystem ? name : _name.text.trim();
    final letter = previewName.isEmpty
        ? '?'
        : previewName.characters.first.toUpperCase();
    final parentName = _parent == null ? '' : categoryLabel(l, _parent!);
    final title = _parent != null
        ? (e != null ? l.editSubcategory : l.newSubcategory(parentName))
        : e != null
        ? l.editCategory
        : widget.kind == 'income'
        ? l.newIncomeCategory
        : l.newExpenseCategory;

    Widget action(
      IconData icon,
      String text,
      VoidCallback? onTap, {
      Color? color,
    }) => TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color ?? context.colors.primary,
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(44),
      ),
      icon: Icon(icon, size: 20),
      label: Text(text),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.colors.soft(raw),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: _icon != null
                      ? Icon(categoryIcons[_icon], color: fg, size: 24)
                      : Text(
                          letter,
                          style: TextStyle(
                            color: fg,
                            fontSize: AppFontSize.heading,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    title,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            TextField(
              controller: _name,
              enabled: !_isSystem,
              autofocus: e == null,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _showNameError = false),
              decoration: InputDecoration(
                labelText: l.categoryName,
                hintText: l.categoryNameHint,
                errorText: _showNameError ? l.categoryNameRequired : null,
                helperText: _isSystem ? l.systemCategoryNameNote : null,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              '${l.categoryIcon} ${l.optional}',
              style: t.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colors.muted,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final key in [null, ...categoryIcons.keys])
                  _IconChoice(
                    selected: _icon == key,
                    color: fg,
                    tooltip: key == null
                        ? l.categoryIconNone
                        : categoryIconLabel(l, key),
                    onTap: () => setState(() => _icon = key),
                    child: key == null
                        ? Text(
                            letter,
                            style: const TextStyle(
                              fontSize: AppFontSize.title,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : Icon(categoryIcons[key], size: 20),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (_parent != null)
              Text(
                l.subcategoryColorNote(parentName),
                style: t.bodySmall?.copyWith(color: context.colors.muted),
              )
            else ...[
              Text(
                l.categoryColor,
                style: t.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.muted,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
                children: [
                  for (final hex in categoryPalette)
                    Semantics(
                      selected: hex == _color,
                      button: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _color = hex),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.fg(hexColor(hex)),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: hex == _color
                                  ? context.colors.ink
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: hex == _color
                              ? Icon(
                                  Icons.check,
                                  color: context.colors.isDark
                                      ? context.colors.background
                                      : Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.xl),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l.save),
            ),
            if (e != null && snap != null) ...[
              const SizedBox(height: AppSpace.sm),
              Divider(color: context.colors.divider),
              action(
                e.isArchived
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                e.isArchived ? l.showInForm : l.hideFromForm,
                () => _toggleHidden(name),
              ),
              action(
                Icons.call_merge,
                l.mergeCategory,
                () => _merge(snap, name, txCount),
              ),
              action(
                Icons.delete_outline,
                l.deleteCategory,
                canDelete ? _delete : null,
                color: context.colors.expense,
              ),
              if (!canDelete)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpace.md),
                  child: Text(
                    _isSystem
                        ? l.deleteSystemCategoryHint
                        : l.deleteUsedCategoryHint(txCount),
                    style: t.bodySmall?.copyWith(color: context.colors.muted),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu kotak di pemilih ikon kategori.
class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.selected,
    required this.color,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        selected: selected,
        button: true,
        label: tooltip,
        child: Material(
          color: selected ? context.colors.soft(color) : context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: selected ? color : context.colors.line,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: IconTheme.merge(
              data: IconThemeData(
                color: selected ? color : context.colors.muted,
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: selected ? color : context.colors.muted,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
