// Memastikan semua layar rapi (tidak ada teks/tombol yang keluar kotak) di
// berbagai ukuran HP, ukuran font sistem, dan bahasa. Data contoh sengaja
// panjang-panjang; bukan data asli.
//
// Gambar tiap layar bisa disimpan untuk dilihat:
//   flutter test test/layout_matrix_test.dart --dart-define=SHOTS=D:/folder
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:djournal/core/attachments/attachment_repository.dart';
import 'package:djournal/core/database/app_database.dart';
import 'package:djournal/core/format.dart';
import 'package:djournal/core/storage/settings_repository.dart';
import 'package:djournal/core/theme.dart';
import 'package:djournal/core/widgets/app_sheet.dart';
import 'package:djournal/features/account/data/backend.dart';
import 'package:djournal/features/account/presentation/account_screen.dart';
import 'package:djournal/features/account/presentation/account_sheets.dart';
import 'package:djournal/features/account/presentation/sign_in_screen.dart';
import 'package:djournal/features/account/providers/account_controller.dart';
import 'package:djournal/features/backup/data/google_drive_service.dart';
import 'package:djournal/features/backup/presentation/backup_screen.dart';
import 'package:djournal/features/settings/presentation/settings_pages.dart';
import 'package:djournal/features/feedback/presentation/feedback_screen.dart';
import 'package:djournal/features/games/presentation/games_hub_screen.dart';
import 'package:djournal/features/games/presentation/games_screen.dart';
import 'package:djournal/features/games/presentation/memory_screen.dart';
import 'package:djournal/features/games/presentation/prompt_screen.dart';
import 'package:djournal/features/home_widget/data/home_widget_sync.dart';
import 'package:djournal/features/journal/data/journal_repository.dart';
import 'package:djournal/features/journal/presentation/entry_form_screen.dart';
import 'package:djournal/features/journal/presentation/note/note_parts.dart';
import 'package:djournal/features/lock/presentation/lock_screen.dart';
import 'package:djournal/features/lock/presentation/pin_setup_screen.dart';
import 'package:djournal/features/lock/providers/lock_controller.dart';
import 'package:djournal/features/money/data/bill_repository.dart';
import 'package:djournal/features/money/data/money_repository.dart';
import 'package:djournal/features/money/data/wishlist_repository.dart';
import 'package:djournal/features/money/domain/money_snapshot.dart';
import 'package:djournal/features/money/presentation/bill_detail_sheet.dart';
import 'package:djournal/features/money/presentation/bill_form_sheet.dart';
import 'package:djournal/features/money/presentation/budget_screen.dart';
import 'package:djournal/features/money/presentation/categories_screen.dart';
import 'package:djournal/features/money/presentation/global_budget_sheet.dart';
import 'package:djournal/features/money/presentation/tx_draft_sheet.dart';
import 'package:djournal/features/money/presentation/tx_form_screen.dart';
import 'package:djournal/features/money/presentation/wallet_form_sheet.dart';
import 'package:djournal/features/money/presentation/wallets_screen.dart';
import 'package:djournal/features/money/presentation/wishlist_deposit_sheet.dart';
import 'package:djournal/features/money/presentation/wishlist_form_sheet.dart';
import 'package:djournal/features/plan/data/plan_repository.dart';
import 'package:djournal/features/plan/presentation/plan_add_sheet.dart';
import 'package:djournal/features/plan/presentation/plan_screen.dart';
import 'package:djournal/features/plan/presentation/plan_widgets.dart';
import 'package:djournal/features/search/presentation/search_screen.dart';
import 'package:djournal/features/settings/presentation/custom_accent_sheet.dart';
import 'package:djournal/features/settings/presentation/settings_screen.dart';
import 'package:djournal/features/shell/presentation/home_dock.dart';
import 'package:djournal/features/shell/presentation/home_shell.dart';
import 'package:djournal/features/update/domain/changelog.dart';
import 'package:djournal/features/update/presentation/version_history_screen.dart';
import 'package:djournal/features/update/providers/changelog_provider.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart' hide LockState;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _shots = String.fromEnvironment('SHOTS');

class _FakeAccount extends AccountController {
  @override
  AccountState build() => const AccountState(loading: false);

  @override
  Future<void> sync() async {}
}

class _FakeServerAccount extends AccountController {
  @override
  AccountState build() => AccountState(
    loading: false,
    email: 'server.nyawtat@contoh.id',
    lastSyncAt: DateTime(2026, 11, 25, 14, 32),
  );
}

class _FakeServerError extends AccountController {
  @override
  AccountState build() => const AccountState(
    loading: false,
    email: 'server.nyawtat@contoh.id',
    error: ApiError.network,
  );
}

class _FakeDrive extends GoogleDriveController {
  @override
  GoogleDriveInfo build() => const GoogleDriveInfo(
    email: 'nyaw.contoh.panjang@contoh.id',
    displayName: 'Nyaw Contoh Panjang',
  );
}

/// Layar dengan Drive terhubung dan keadaan server tertentu.
Widget _withAccount(AccountController Function() server, Widget child) =>
    ProviderScope(
  overrides: [
    accountProvider.overrideWith(server),
    googleDriveProvider.overrideWith(_FakeDrive.new),
  ],
  child: child,
);

class _FakeLock extends LockController {
  @override
  LockState build() => const LockState(
    loading: false,
    pinEnabled: true,
    biometricEnabled: true,
    biometricAvailable: true,
    locked: false,
  );

  @override
  Future<bool> unlockWithBiometric(String reason) async => false;
}

class _FakeAttachments extends AttachmentRepository {
  _FakeAttachments() : super(AppDatabase(NativeDatabase.memory()));

  @override
  Stream<List<Attachment>> watchAllAttachments() => Stream.value(const []);

  @override
  Future<List<Attachment>> getAttachmentsForEntry(String id) async => const [];

  @override
  Future<Attachment?> getAttachmentForTx(String id) async => null;

  @override
  Stream<List<Attachment>> watchAttachmentsForEntry(String id) =>
      Stream.value(const []);

  @override
  Stream<Attachment?> watchAttachmentForTx(String id) => Stream.value(null);
}

class _FakeSettings implements SettingsRepository {
  final _values = <String, String>{
    'daily_budget_limit': '150000',
    'weekly_budget_limit': '1000000',
    'monthly_budget_limit': '4000000',
  };
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<String?> watch(String key) async* {
    yield _values[key];
    await for (final _ in _changes.stream) {
      yield _values[key];
    }
  }

  @override
  Future<void> set(String key, String value) async {
    _values[key] = value;
    _changes.add(null);
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
    _changes.add(null);
  }
}

late MoneySnapshot _snap;
late List<JournalEntry> _entries;
late List<Bill> _bills;
late List<Wishlist> _wishes;
late List<DailyPlan> _plans;

Future<void> _buildData() async {
  final db = AppDatabase(NativeDatabase.memory());
  final money = MoneyRepository(db);
  final journal = JournalRepository(db);
  final bills = BillRepository(db);
  final wishes = WishlistRepository(db);
  final now = DateTime.now();
  String day(int ago) =>
      toLocalDate(DateTime(now.year, now.month, now.day - ago));

  await money.addWallet(
    name: 'Rekening Tabungan Bersama Keluarga',
    type: 'bank',
    openingBalance: 1234567890,
  );
  await money.addWallet(name: 'GoPay', type: 'ewallet', openingBalance: 250000);
  final wallets = await money.watchWallets().first;
  final cats = await money.watchCategories().first;
  final expense = cats.where((c) => c.kind == 'expense').toList();
  for (final c in expense) {
    await money.setBudget(
      categoryId: c.id,
      startMonth: toMonthKey(now),
      amount: 12500000,
    );
  }
  for (var i = 0; i < 24; i++) {
    await money.saveTransaction(
      type: i % 6 == 0 ? 'income' : 'expense',
      amount: i.isEven ? 123456789 : 25000,
      walletId: wallets[i % wallets.length].id,
      categoryId:
          (i % 6 == 0
                  ? cats.where((c) => c.kind == 'income').toList()
                  : expense)
              .elementAt(i % 3)
              .id,
      note: i.isEven
          ? 'Belanja mingguan di supermarket dekat rumah bersama keluarga'
          : 'Kopi',
      occurredAt: DateTime(now.year, now.month, now.day - i ~/ 2, 9, i),
    );
  }
  await money.saveTransaction(
    type: 'transfer',
    amount: 987654321,
    walletId: wallets.first.id,
    toWalletId: wallets.last.id,
    categoryId: null,
    note: 'Tarik tunai untuk kebutuhan bulanan',
    occurredAt: now,
  );
  for (var i = 0; i < 6; i++) {
    await journal.saveEntry(
      entryDate: day(i ~/ 2),
      entryTime: i == 3 ? null : '2$i:30',
      mood: i % 5 + 1,
      title: i.isEven ? 'Perjalanan panjang ke rumah nenek di kampung' : '',
      body:
          'Hari ini panjang sekali, dari pagi sampai malam banyak yang harus '
          'diselesaikan. Untungnya semua berjalan lancar.',
      tags: const ['keluarga', 'perjalananpanjang', 'akhirpekan', 'liburan'],
      audioPath: i == 0 ? 'demo.m4a' : null,
      audioDurationMs: i == 0 ? 3723000 : null,
    );
  }
  for (final (t, ago) in [
    ('Cicilan kendaraan bermotor bulanan', 3),
    ('Wifi', -2),
  ]) {
    await bills.createBill(
      title: t,
      amount: 123456789,
      dueDate: day(ago),
      repeatInterval: 'monthly',
      walletId: wallets.last.id,
      categoryId: expense.first.id,
    );
  }
  await wishes.createWishlist(
    title: 'Liburan keluarga besar ke luar negeri',
    targetAmount: 987654321,
    targetMonths: 12,
    walletId: wallets.last.id,
    notes: 'Catatan panjang tentang rencana liburan keluarga besar',
  );
  await wishes.createWishlist(
    title: 'HP',
    targetAmount: 5000000,
    targetMonths: 6,
  );

  _snap = MoneySnapshot(
    wallets: wallets,
    categories: cats,
    transactions: await money.watchTransactions().first,
    budgets: await money.watchBudgets().first,
  );
  _entries = await journal.watchEntries().first;
  _bills = await db.select(db.bills).get();
  _wishes = await db.select(db.wishlists).get();
  final plans = PlanRepository(db);
  for (final (title, ago) in [
    ('Belanja kebutuhan mingguan bersama keluarga di pasar', 0),
    ('Olahraga', 0),
    ('Balas pesan', 0),
    ('Rapikan meja kerja', 0),
    ('Baca buku', 0),
    ('Servis kendaraan bermotor', -1),
    ('Telepon rumah dan cuci sepatu', 1),
  ]) {
    final id = await plans.add(title: title, date: day(ago));
    if (title == 'Olahraga') await plans.setDone(id, true);
  }
  _plans = await db.select(db.dailyPlans).get();
  await db.close();
}

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
  }
  await loader.load();
}

typedef _Case = ({Size size, double scale, String lang, double keyboard});

const _cases = <_Case>[
  (size: Size(320, 640), scale: 1.0, lang: 'id', keyboard: 0),
  (size: Size(320, 640), scale: 1.3, lang: 'id', keyboard: 0),
  (size: Size(320, 640), scale: 1.3, lang: 'en', keyboard: 0),
  (size: Size(360, 780), scale: 1.0, lang: 'id', keyboard: 0),
  (size: Size(360, 780), scale: 1.3, lang: 'id', keyboard: 0),
  (size: Size(360, 780), scale: 1.6, lang: 'id', keyboard: 0),
  (size: Size(360, 780), scale: 1.0, lang: 'en', keyboard: 0),
  (size: Size(412, 915), scale: 1.0, lang: 'id', keyboard: 0),
  (size: Size(412, 915), scale: 2.0, lang: 'id', keyboard: 0),
  // Keyboard terbuka.
  (size: Size(320, 640), scale: 1.0, lang: 'id', keyboard: 280),
  (size: Size(360, 780), scale: 1.3, lang: 'id', keyboard: 320),
  (
    size: Size(673, 841),
    scale: 1.0,
    lang: 'id',
    keyboard: 0,
  ), // HP lipat terbuka
  (size: Size(844, 390), scale: 1.0, lang: 'id', keyboard: 0), // HP miring
];

/// Layar penuh, atau sheet kalau [sheet] true.
typedef _Screen = ({Widget Function() build, bool sheet, String? tab});

_Screen _page(Widget Function() b) => (build: b, sheet: false, tab: null);
_Screen _sheetOf(Widget Function() b) => (build: b, sheet: true, tab: null);
_Screen _tab(String id) =>
    (build: () => const HomeShell(), sheet: false, tab: id);

final _screens = <String, _Screen>{
  'hari-ini': _tab('navToday'),
  'jurnal': _tab('navJournal'),
  'keuangan': _tab('navMoney'),
  'laporan': _tab('navReport'),
  'tambah-cepat': _tab('add'),
  'pengaturan': _page(() => const SettingsScreen()),
  'pencarian': _page(() => const SearchScreen()),
  'dompet': _page(() => const WalletsScreen()),
  'kategori': _page(() => const CategoriesScreen()),
  'budget': _page(() => const BudgetScreen()),
  'rencana': _page(() => const PlanScreen()),
  's-rencana-baru': _sheetOf(
    () => PlanAddSheet(today: toLocalDate(DateTime.now()), tomorrow: true),
  ),
  's-rencana': _sheetOf(
    () => PlanEditSheet(plan: _plans.first, today: toLocalDate(DateTime.now())),
  ),
  'catat': _page(() => const TxFormScreen()),
  'catat-ubah': _page(() => TxFormScreen(existing: _snap.transactions.first)),
  'tulis': _page(() => const EntryFormScreen()),
  'tulis-pengingat': _page(
    () => const EntryFormScreen(
      initialTitle: 'Ngopi sambil menulis di kafe dekat kantor',
      initialAudioTranscript: 'Besok jam 7 servis kendaraan bermotor.',
    ),
  ),
  'tulis-transaksi': _page(
    () => const EntryFormScreen(
      initialTitle: 'Ngopi sambil menulis di kafe dekat kantor',
      initialAudioTranscript:
          'Beli es kopi susu gula aren 28rb pakai GoPay, parkir 2rb.',
    ),
  ),
  'tulis-ubah': _page(
    () => EntryFormScreen(existing: _entries.first, startEditing: true),
  ),
  'baca': _page(() => EntryFormScreen(existing: _entries.first)),
  's-transaksi-jurnal': _sheetOf(
    () => TxDraftSheet(draft: emptyTxDraft('m', _snap), isNew: true),
  ),
  's-keluar-jurnal': _sheetOf(() => const NoteLeaveSheet()),
  'masuk': _page(() => const SignInScreen()),
  'pengaturan-drive': _page(
    () => _withAccount(_FakeAccount.new, const SettingsScreen()),
  ),
  'akun-tamu': _page(() => const AccountScreen()),
  'akun-drive': _page(
    () => _withAccount(_FakeAccount.new, const AccountScreen()),
  ),
  'akun-keduanya': _page(
    () => _withAccount(_FakeServerAccount.new, const AccountScreen()),
  ),
  'akun-gagal-sinkron': _page(
    () => _withAccount(_FakeServerError.new, const AccountScreen()),
  ),
  'tampilan': _page(() => const AppearancePage()),
  'keamanan': _page(() => const SecurityPage()),
  'pengaturan-keuangan': _page(() => const FinancePage()),
  'versi': _page(() => const VersionPage()),
  'cadangan': _page(() => const BackupScreen()),
  'cadangan-drive': _page(
    () => _withAccount(_FakeAccount.new, const BackupScreen()),
  ),
  's-putus-drive': _sheetOf(() => const DriveDisconnectSheet()),
  's-keluar-server': _sheetOf(() => const ServerSignOutSheet(unsynced: true)),
  'masukan': _page(() => const FeedbackScreen()),
  'riwayat-versi': _page(() => const VersionHistoryScreen()),
  'permainan': _page(() => const GamesHubScreen()),
  'roda': _page(() => const WheelRpsScreen()),
  'suit': _page(() => const WheelRpsScreen(initialTab: 1)),
  'kartu': _page(() => const MemoryScreen()),
  'kocok': _page(() => const PromptScreen()),
  'kunci': _page(() => const LockScreen()),
  'atur-pin': _page(() => const PinSetupScreen()),
  's-dompet': _sheetOf(() => WalletFormSheet(existing: _snap.wallets.last)),
  's-kategori': _sheetOf(() => const CategoryFormSheet(kind: 'expense')),
  's-tagihan': _sheetOf(() => const BillFormSheet()),
  's-tagihan-detail': _sheetOf(
    () => BillDetailSheet(
      bill: _bills.first,
      now: DateTime.now(),
      moneySnap: _snap,
    ),
  ),
  's-impian': _sheetOf(() => WishlistFormSheet(existing: _wishes.first)),
  's-setor': _sheetOf(() => WishlistDepositSheet(wishlist: _wishes.first)),
  's-target': _sheetOf(() => const GlobalBudgetSheet()),
  's-aksen': _sheetOf(
    () => const CustomAccentSheet(initial: Color(0xFF1F5F4E)),
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFont('Poppins', [
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        'assets/fonts/Poppins-$w.ttf',
    ]);
    final root = Platform.environment['FLUTTER_ROOT'] ?? 'C:/dev/flutter';
    await _loadFont('MaterialIcons', [
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in ['home_widget', 'home_widget/updates']) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => Directory.systemTemp.path,
    );
    await _buildData();
  });

  for (final MapEntry(key: name, value: screen) in _screens.entries) {
    testWidgets('$name rapi di semua ukuran', (tester) async {
      final problems = <String, Set<String>>{};
      final shotKey = GlobalKey();
      addTearDown(tester.view.reset);

      for (final c in _cases) {
        final label =
            '${c.size.width.toInt()}x${c.size.height.toInt()}'
            '@${c.scale}${c.lang}${c.keyboard > 0 ? 'kb' : ''}';
        tester.view.physicalSize = c.size;
        tester.view.devicePixelRatio = 1;
        // Status bar dan navigasi 3 tombol.
        tester.view.padding = FakeViewPadding(
          top: 28,
          bottom: c.keyboard > 0 ? 0 : 48,
        );
        tester.view.viewPadding = const FakeViewPadding(top: 28, bottom: 48);
        // Tab dipilih dulu lewat dock, baru keyboard dibuka.
        tester.view.viewInsets = FakeViewPadding(
          bottom: screen.tab == null ? c.keyboard : 0,
        );

        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final text = d.toString();
          if (!text.contains('overflowed')) {
            final line = d.exceptionAsString().split('\n').first;
            (problems['ERR $line'] ??= {}).add(label);
            return;
          }
          final what = RegExp(
            r'overflowed by ([0-9.]+|Infinity) pixels on the (\w+)',
          ).firstMatch(text);
          final where = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text)?[0];
          (problems['$where ${what?[2]}'] ??= {}).add('$label(${what?[1]})');
        };

        final home = screen.sheet ? const Scaffold() : screen.build();
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              journalEntriesProvider.overrideWith(
                (ref) => Stream.value(_entries),
              ),
              moneySnapshotProvider.overrideWithValue(AsyncValue.data(_snap)),
              accountProvider.overrideWith(_FakeAccount.new),
              lockProvider.overrideWith(_FakeLock.new),
              homeWidgetSyncProvider.overrideWithValue(null),
              settingsRepositoryProvider.overrideWithValue(_FakeSettings()),
              walletsProvider.overrideWith(
                (ref) => Stream.value(_snap.wallets),
              ),
              categoriesProvider.overrideWith(
                (ref) => Stream.value(_snap.allCategories),
              ),
              transactionsProvider.overrideWith(
                (ref) => Stream.value(_snap.transactions),
              ),
              budgetsProvider.overrideWith(
                (ref) => Stream.value(_snap.budgets),
              ),
              wishlistsProvider.overrideWith((ref) => Stream.value(_wishes)),
              unpaidBillsProvider.overrideWith((ref) => Stream.value(_bills)),
              billsProvider.overrideWith((ref) => Stream.value(_bills)),
              allAttachmentsProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              attachmentRepositoryProvider.overrideWithValue(
                _FakeAttachments(),
              ),
              plansProvider.overrideWith((ref) => Stream.value(_plans)),
              planIgnoredThroughProvider.overrideWith(
                (ref) => Stream.value(null),
              ),
              upcomingRemindersProvider.overrideWith(
                (ref) => Stream.value(const []),
              ),
              changelogProvider.overrideWith(
                (ref) async => parseChangelog(
                  File('assets/changelog.md').readAsStringSync(),
                ),
              ),
              appVersionProvider.overrideWith(
                (ref) async => PackageInfo(
                  appName: 'Nyawtat',
                  packageName: 'dev.nyawtat.app',
                  version: '0.17.0',
                  buildNumber: '23',
                ),
              ),
            ],
            child: RepaintBoundary(
              key: shotKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildTheme(Brightness.light),
                locale: Locale(c.lang),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(c.scale)),
                  child: child!,
                ),
                home: home,
              ),
            ),
          ),
        );
        Future<void> settle() async {
          for (var i = 0; i < 8; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        Future<void> shoot(String suffix) async {
          if (_shots.isEmpty) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)),
          );
          await tester.pump();
          await tester.runAsync(() async {
            final b =
                shotKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await b.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$_shots/$name-$label$suffix.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png!.buffer.asUint8List());
          });
        }

        await settle();
        if (screen.sheet) {
          final ctx = tester.element(find.byType(Scaffold).first);
          unawaited(
            showAppSheet<void>(
              context: ctx,
              isScrollControlled: true,
              builder: (_) => screen.build(),
            ),
          );
          await settle();
        }
        if (screen.tab case final tab?) {
          final l = await AppLocalizations.delegate.load(Locale(c.lang));
          if (tab == 'add') {
            await tester.tap(find.byIcon(Icons.add).last);
          } else {
            final text = switch (tab) {
              'navJournal' => l.navJournal,
              'navMoney' => l.navMoney,
              'navReport' => l.navReport,
              _ => l.navToday,
            };
            await tester.tap(find.text(text).last, warnIfMissed: false);
          }
          await settle();
        }
        if (screen.tab != null && c.keyboard > 0) {
          tester.view.viewInsets = FakeViewPadding(bottom: c.keyboard);
          await settle();
          // Dock tidak boleh menutupi kolom yang sedang ditulis.
          if (find.byType(HomeDock).evaluate().isNotEmpty) {
            (problems['DOCK menutupi keyboard'] ??= {}).add(label);
          }
        }

        // Kata yang lebih lebar dari kotaknya akan patah di tengah kata.
        void checkWords() {
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            if (!p.attached || !p.hasSize || p.size.width == 0) continue;
            final word = p.getMinIntrinsicWidth(double.infinity);
            if (word <= p.size.width + 1) continue;
            final text = p.text.toPlainText();
            // Teks panjang satu baris memang boleh dipotong "…".
            final label1 = !text.contains(' ') && text.length <= 14;
            final oneLine =
                p.maxLines == 1 ||
                !p.softWrap ||
                (p.maxLines == null && p.overflow == TextOverflow.ellipsis);
            // HP sangat kecil dengan font besar: cukup tidak keluar kotak.
            if (c.scale > (c.size.width < 360 ? 1.0 : 1.3)) continue;
            if (text.length < 2) continue;
            if (oneLine && !label1 || text.contains('\uFFFC')) continue;
            final short = text.length > 28 ? text.substring(0, 28) : text;
            (problems['KATA "$short"'] ??= {}).add(label);
          }
        }

        // Teks terlalu dekat ke tepi kotak berlatar/bergaris di sekitarnya.
        void checkTight() {
          if (c.scale != 1.0 || c.keyboard > 0 || c.size.width > 420) return;
          for (final p in tester.renderObjectList<RenderParagraph>(
            find.byType(RichText),
          )) {
            if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
            final text = p.text.toPlainText();
            final boxes = p.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            );
            if (text.trim().isEmpty || boxes.isEmpty) continue;
            // Ikon juga RichText; hanya huruf/angka yang diperiksa.
            if (text.runes.first >= 0xE000 && text.runes.first <= 0xF8FF) {
              continue;
            }
            final rect = MatrixUtils.transformRect(
              p.getTransformTo(null),
              boxes
                  .map((b) => b.toRect())
                  .reduce((a, b) => a.expandToInclude(b)),
            );
            RenderObject? o = p.parent;
            RenderBox? box;
            while (o != null && box == null) {
              final found = switch (o) {
                RenderDecoratedBox(decoration: final BoxDecoration d) =>
                  (d.color?.a ?? 0) > 0 ||
                      d.border != null && d.border!.isUniform,
                RenderPhysicalShape(:final color) => color.a > 0,
                RenderPhysicalModel(:final color) => color.a > 0,
                _ => false,
              };
              if (found) box = o as RenderBox;
              o = o.parent;
            }
            if (box == null || !box.hasSize) continue;
            final b = MatrixUtils.transformRect(
              box.getTransformTo(null),
              Offset.zero & box.size,
            );
            if (b.width >= c.size.width - 1) continue;
            final side = [
              rect.left - b.left,
              b.right - rect.right,
            ].reduce((a, b) => a < b ? a : b);
            final vert = [
              rect.top - b.top,
              b.bottom - rect.bottom,
            ].reduce((a, b) => a < b ? a : b);
            if (side < 5 || vert < 0.5) {
              final short = text.length > 26 ? text.substring(0, 26) : text;
              (problems['MEPET "$short" sisi ${side.toStringAsFixed(1)} tegak ${vert.toStringAsFixed(1)}'] ??=
                      {})
                  .add(label);
            }
          }
        }

        checkTight();
        checkWords();
        await shoot('');

        // Gulir sampai bawah supaya semua bagian ikut digambar.
        final scrollables = find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        );
        for (var i = 0; i < 14 && scrollables.evaluate().isNotEmpty; i++) {
          await tester.drag(
            scrollables.last,
            Offset(0, -c.size.height * 0.5),
            warnIfMissed: false,
          );
          await tester.pump(const Duration(milliseconds: 50));
          checkWords();
          checkTight();
          if (i % 4 == 0 && c == _cases[4]) await shoot('-s$i');
        }
        await tester.pump(const Duration(milliseconds: 300));
        FlutterError.onError = old;
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }

      for (final e in problems.entries) {
        // ignore: avoid_print
        print("MATRIX $name | ${e.key} | ${e.value.join(" ")}");
      }
      if (problems.isNotEmpty) {
        fail(
          [
            for (final e in problems.entries)
              '  $name | ${e.key} | ${e.value.join(' ')}',
          ].join('\n'),
        );
      }
    });
  }
}
