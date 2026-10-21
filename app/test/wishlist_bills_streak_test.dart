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
}

