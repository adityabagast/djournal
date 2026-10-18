import 'package:djournal/core/theme.dart';
import 'package:djournal/data/attachment_repository.dart';
import 'package:djournal/data/db/app_database.dart';
import 'package:djournal/data/journal_repository.dart';
import 'package:djournal/data/money_repository.dart';
import 'package:djournal/l10n/app_localizations.dart';
import 'package:djournal/ui/image_viewer.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrapWithTheme(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Attachment Feature Tests', () {
    late AppDatabase db;
    late AttachmentRepository attachRepo;
    late JournalRepository journalRepo;
    late MoneyRepository moneyRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      attachRepo = AttachmentRepository(db);
      journalRepo = JournalRepository(db);
      moneyRepo = MoneyRepository(db);
    });

    tearDown(() => db.close());

    test('Sinkronisasi dan pengambilan lampiran gambar untuk entri jurnal', () async {
      final entryId = await journalRepo.saveEntry(
        entryDate: '2026-10-18',
        entryTime: '10:00',
        mood: 3,
        title: 'Jalan Pagi',
        body: 'Foto-foto pemandangan',
        tags: ['foto'],
      );

      final initialPaths = ['/mock/path/img1.jpg', '/mock/path/img2.jpg'];
      await attachRepo.syncEntryAttachments(entryId, initialPaths);

      final loaded = await attachRepo.getAttachmentsForEntry(entryId);
      expect(loaded.length, 2);
      expect(loaded.map((a) => a.localPath), containsAll(initialPaths));
      expect(loaded.first.entryId, entryId);
      expect(loaded.first.transactionId, isNull);

      // Hapus satu gambar, tambah gambar baru
      final updatedPaths = ['/mock/path/img1.jpg', '/mock/path/img3.jpg'];
      await attachRepo.syncEntryAttachments(entryId, updatedPaths);

      final reloaded = await attachRepo.getAttachmentsForEntry(entryId);
      expect(reloaded.length, 2);
      expect(reloaded.map((a) => a.localPath), containsAll(updatedPaths));
      expect(reloaded.map((a) => a.localPath), isNot(contains('/mock/path/img2.jpg')));
    });

    test('Sinkronisasi dan penggantian foto struk untuk transaksi keuangan', () async {
      final wallets = await db.select(db.wallets).get();
      final walletId = wallets.first.id;

      final txId = await moneyRepo.saveTransaction(
        type: 'expense',
        amount: 50000,
        walletId: walletId,
        categoryId: null,
        note: 'Beli ATK',
        occurredAt: DateTime.now(),
      );

      // Simpan struk pertama
      await attachRepo.syncTxAttachment(txId, '/mock/path/receipt1.jpg');
      final receipt1 = await attachRepo.getAttachmentForTx(txId);
      expect(receipt1, isNotNull);
      expect(receipt1!.transactionId, txId);
      expect(receipt1.localPath, '/mock/path/receipt1.jpg');
      expect(receipt1.entryId, isNull);

      // Ganti dengan struk baru
      await attachRepo.syncTxAttachment(txId, '/mock/path/receipt2.jpg');
      final receipt2 = await attachRepo.getAttachmentForTx(txId);
      expect(receipt2, isNotNull);
      expect(receipt2!.localPath, '/mock/path/receipt2.jpg');

      // Hapus struk
      await attachRepo.syncTxAttachment(txId, null);
      final receiptDeleted = await attachRepo.getAttachmentForTx(txId);
      expect(receiptDeleted, isNull);
    });

    testWidgets('JournalImageGrid me-render tombol tambah dan batas maksimal gambar', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          JournalImageGrid(
            imagePaths: const ['/mock/1.jpg', '/mock/2.jpg'],
            onAddImage: () {},
            onRemoveImage: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Galeri'), findsOneWidget);
      expect(find.text('Kamera'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
      expect(find.textContaining('Maks 10 gambar'), findsOneWidget);
    });

    testWidgets('TxReceiptSection me-render tombol foto struk bila belum ada', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TxReceiptSection(
            receiptPath: null,
            onPickReceipt: () {},
            onRemoveReceipt: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Foto Struk Belanja'), findsOneWidget);
      expect(find.text('Ambil dari kamera atau galeri'), findsOneWidget);
    });

    testWidgets('TxReceiptSection me-render opsi ganti dan hapus bila struk ada', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          TxReceiptSection(
            receiptPath: '/mock/receipt.jpg',
            onPickReceipt: () {},
            onRemoveReceipt: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Struk terlampir'), findsOneWidget);
      expect(find.text('Ganti'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });
}

