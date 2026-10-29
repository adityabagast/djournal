import 'package:djournal/data/bill_repository.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/wishlist_repository.dart';
import 'package:djournal/domain/models/global_budget.dart';
import 'package:djournal/domain/models/streak_info.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GlobalBudget Unit Tests', () {
    test('deteksi level peringatan budget dengan tepat', () {
      const budget = GlobalBudget(
        dailyLimit: 100000,
        weeklyLimit: 700000,
        monthlyLimit: 3000000,
      );

      // Safe (< 75%)
      expect(
        GlobalBudget.alertLevelFor(50000, budget.dailyLimit),
        BudgetAlertLevel.safe,
      );

      // Warning (>= 75% dan < 100%)
      expect(
        GlobalBudget.alertLevelFor(80000, budget.dailyLimit),
        BudgetAlertLevel.warning,
      );
      expect(
        GlobalBudget.alertLevelFor(99000, budget.dailyLimit),
        BudgetAlertLevel.warning,
      );

      // Danger (>= 100%)
      expect(
        GlobalBudget.alertLevelFor(100000, budget.dailyLimit),
        BudgetAlertLevel.danger,
      );
      expect(
        GlobalBudget.alertLevelFor(150000, budget.dailyLimit),
        BudgetAlertLevel.danger,
      );
    });

    test('persentase budget ter-clamp dengan benar', () {
      expect(GlobalBudget.percentageOf(50000, 100000), 0.5);
      expect(GlobalBudget.percentageOf(150000, 100000), 1.0);
      expect(GlobalBudget.percentageOf(0, 100000), 0.0);
    });
  });

  group('StreakInfo Unit Tests', () {
    test('menghitung streak aktif dan rekor terpanjang', () {
      final now = DateTime(2026, 10, 21);
      final activeDates = {
        '2026-10-18',
        '2026-10-19',
        '2026-10-20',
        '2026-10-21',
      };

      final streak = StreakInfo.calculate(
        activeDates: activeDates,
        now: now,
      );

      expect(streak.currentStreak, 4);
      expect(streak.isTodayActive, true);
      expect(streak.longestStreak, 4);
    });

    test('streak tetap hidup jika kemarin aktif meskipun hari ini belum selesai', () {
      final now = DateTime(2026, 10, 21);
      final activeDates = {
        '2026-10-19',
        '2026-10-20', // Kemarin
      };

      final streak = StreakInfo.calculate(
        activeDates: activeDates,
        now: now,
      );

      expect(streak.currentStreak, 2);
      expect(streak.isTodayActive, false);
    });

    test('streak putus jika kemarin dan hari ini tidak ada aktivitas', () {
      final now = DateTime(2026, 10, 21);
      final activeDates = {
        '2026-10-18', // 3 hari yang lalu
        '2026-10-19', // 2 hari yang lalu
      };

      final streak = StreakInfo.calculate(
        activeDates: activeDates,
        now: now,
      );

      expect(streak.currentStreak, 0);
      expect(streak.isTodayActive, false);
      expect(streak.longestStreak, 2);
    });
  });

  group('Wishlist & Bills Database Repository Tests', () {
    late AppDatabase db;
    late WishlistRepository wishlistRepo;
    late BillRepository billRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.seed();
      wishlistRepo = WishlistRepository(db);
      billRepo = BillRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('tambah wishlist dan setor tabungan', () async {
      final wallets = await db.select(db.wallets).get();
      final walletId = wallets.first.id;

      final id = await wishlistRepo.createWishlist(
        title: 'Beli HP Baru',
        targetAmount: 8000000,
        targetMonths: 12,
        walletId: walletId,
      );

      var wishlist = await wishlistRepo.getWishlist(id);
      expect(wishlist, isNotNull);
      expect(wishlist!.title, 'Beli HP Baru');
      expect(wishlist.savedAmount, 0);
      expect(wishlist.isFulfilled, false);

      // Setor tabungan pertama
      await wishlistRepo.deposit(
        wishlistId: id,
        amount: 500000,
        sourceWalletId: walletId,
      );

      wishlist = await wishlistRepo.getWishlist(id);
      expect(wishlist!.savedAmount, 500000);
      expect(wishlist.isFulfilled, false);

      // Setor hingga lunas
      await wishlistRepo.deposit(
        wishlistId: id,
        amount: 7500000,
        sourceWalletId: walletId,
      );

      wishlist = await wishlistRepo.getWishlist(id);
      expect(wishlist!.savedAmount, 8000000);
      expect(wishlist.isFulfilled, true);
    });

    test('jadwalkan tagihan dan bayar tagihan otomatis mencatat transaksi pengeluaran', () async {
      final wallets = await db.select(db.wallets).get();
      final walletId = wallets.first.id;

      final id = await billRepo.createBill(
        title: 'Wi-Fi IndiHome',
        amount: 375000,
        dueDate: '2026-10-25',
        walletId: walletId,
      );

      var bill = await billRepo.getBill(id);
      expect(bill, isNotNull);
      expect(bill!.isPaid, false);

      // Bayar tagihan
      await billRepo.payBill(
        billId: id,
        walletId: walletId,
      );

      bill = await billRepo.getBill(id);
      expect(bill!.isPaid, true);
      expect(bill.paidAt, isNotNull);

      // Pastikan ada transaksi pengeluaran yang tercatat di database
      final txs = await db.select(db.transactions).get();
      final billTx = txs.firstWhere((t) => t.note?.contains('Wi-Fi IndiHome') ?? false);
      expect(billTx.type, 'expense');
      expect(billTx.amount, 375000);
      expect(billTx.walletId, walletId);
    });
  });

  group('Tagihan berulang', () {
    test('nextDueDate: bulanan, tahunan, dan potong ke akhir bulan', () {
      expect(BillRepository.nextDueDate('2026-10-25', 'monthly'), '2026-11-25');
      expect(BillRepository.nextDueDate('2026-12-15', 'monthly'), '2027-01-15');
      expect(BillRepository.nextDueDate('2027-01-31', 'monthly'), '2027-02-28');
      expect(BillRepository.nextDueDate('2028-01-31', 'monthly'), '2028-02-29');
      expect(BillRepository.nextDueDate('2028-02-29', 'yearly'), '2029-02-28');
      expect(BillRepository.nextDueDate('2026-10-25', 'yearly'), '2027-10-25');
      expect(BillRepository.nextDueDate('2026-10-25', 'once'), isNull);
      expect(BillRepository.nextDueDate('2026-10-25', null), isNull);
      expect(BillRepository.nextDueDate('bukan-tanggal', 'monthly'), isNull);
    });

    late AppDatabase db;
    late BillRepository billRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.seed();
      billRepo = BillRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('bayar tagihan bulanan menjadwalkan jatuh tempo berikutnya', () async {
      final walletId = (await db.select(db.wallets).get()).first.id;
      final id = await billRepo.createBill(
        title: 'Internet rumah',
        amount: 350000,
        dueDate: '2026-10-25',
        repeatInterval: 'monthly',
        walletId: walletId,
      );

      final next = await billRepo.payBill(billId: id, walletId: walletId);
      expect(next, '2026-11-25');

      final bill = await billRepo.getBill(id);
      expect(bill!.isPaid, false);
      expect(bill.dueDate, '2026-11-25');
      expect(bill.paidAt, isNotNull);

      // Bisa dibayar lagi untuk periode berikutnya.
      expect(
        await billRepo.payBill(billId: id, walletId: walletId),
        '2026-12-25',
      );
      final txs = await db.select(db.transactions).get();
      expect(
        txs.where((t) => t.note?.contains('Internet rumah') ?? false).length,
        2,
      );
    });

    test('tagihan sekali bayar ditandai lunas dan tidak bisa dibayar dua kali', () async {
      final walletId = (await db.select(db.wallets).get()).first.id;
      final id = await billRepo.createBill(
        title: 'Servis motor',
        amount: 150000,
        dueDate: '2026-10-25',
        repeatInterval: 'once',
        walletId: walletId,
      );

      expect(await billRepo.payBill(billId: id, walletId: walletId), isNull);
      expect((await billRepo.getBill(id))!.isPaid, true);

      await billRepo.payBill(billId: id, walletId: walletId);
      final txs = await db.select(db.transactions).get();
      expect(
        txs.where((t) => t.note?.contains('Servis motor') ?? false).length,
        1,
      );
    });
  });

  group('Deteksi setoran wishlist', () {
    test('hanya transfer setoran wishlist yang dihitung menabung', () {
      expect(
        WishlistRepository.isDepositTransfer(
          type: 'transfer',
          note: '${WishlistRepository.depositNotePrefix}HP baru',
        ),
        true,
      );
      // Tarik tunai biasa bukan menabung.
      expect(
        WishlistRepository.isDepositTransfer(type: 'transfer', note: 'Tarik tunai'),
        false,
      );
      expect(
        WishlistRepository.isDepositTransfer(type: 'transfer', note: null),
        false,
      );
      expect(
        WishlistRepository.isDepositTransfer(
          type: 'expense',
          note: '${WishlistRepository.depositNotePrefix}HP baru',
        ),
        false,
      );
    });
  });
}
