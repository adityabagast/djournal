import 'dart:io';

import 'package:drift/drift.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'db/app_database.dart';

class AttachmentRepository {
  AttachmentRepository(this._db);

  final AppDatabase _db;
  final ImagePicker _picker = ImagePicker();

  /// Mengambil semua lampiran aktif yang belum dihapus.
  Stream<List<Attachment>> watchAllAttachments() {
    final q = _db.select(_db.attachments)
      ..where((a) => a.deletedAt.isNull())
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt)]);
    return q.watch();
  }

  /// Mengambil semua lampiran aktif untuk satu entri jurnal tertentu.
  Stream<List<Attachment>> watchAttachmentsForEntry(String entryId) {
    final q = _db.select(_db.attachments)
      ..where((a) => a.deletedAt.isNull() & a.entryId.equals(entryId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt)]);
    return q.watch();
  }

  /// Mengambil lampiran (struk) untuk transaksi keuangan tertentu.
  Stream<Attachment?> watchAttachmentForTx(String txId) {
    final q = _db.select(_db.attachments)
      ..where((a) => a.deletedAt.isNull() & a.transactionId.equals(txId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)])
      ..limit(1);
    return q.watchSingleOrNull();
  }

  Future<List<Attachment>> getAttachmentsForEntry(String entryId) {
    final q = _db.select(_db.attachments)
      ..where((a) => a.deletedAt.isNull() & a.entryId.equals(entryId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt)]);
    return q.get();
  }

  Future<Attachment?> getAttachmentForTx(String txId) {
    final q = _db.select(_db.attachments)
      ..where((a) => a.deletedAt.isNull() & a.transactionId.equals(txId))
      ..orderBy([(a) => OrderingTerm(expression: a.createdAt, mode: OrderingMode.desc)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// Mengambil foto dari Kamera atau Galeri, mengompresnya (JPEG 80%, maks 1600px),
  /// lalu menyimpannya secara persisten di folder dokumen aplikasi.
  /// Mengembalikan path lokal absolut file yang tersimpan, atau null jika dibatalkan.
  Future<String?> pickAndStoreImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final attachDir = Directory(p.join(appDir.path, 'attachments'));
    if (!await attachDir.exists()) {
      await attachDir.create(recursive: true);
    }

    final ext = p.extension(picked.path).toLowerCase();
    final safeExt = (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.webp')
        ? ext
        : '.jpg';
    final fileName = 'att_${newId()}$safeExt';
    final targetPath = p.join(attachDir.path, fileName);

    final file = File(picked.path);
    await file.copy(targetPath);
    return targetPath;
  }

  /// Menyinkronkan daftar gambar lokal untuk sebuah entri jurnal.
  /// Gambar yang dihilangkan akan di-soft-delete, gambar baru akan di-insert.
  Future<void> syncEntryAttachments(String entryId, List<String> currentLocalPaths) async {
    final now = DateTime.now().toUtc();
    final existing = await getAttachmentsForEntry(entryId);

    // Hapus attachment lama yang sudah tidak ada di list
    for (final att in existing) {
      if (att.localPath == null || !currentLocalPaths.contains(att.localPath)) {
        await (_db.update(_db.attachments)..where((a) => a.id.equals(att.id))).write(
          AttachmentsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            isDirty: const Value(true),
          ),
        );
      }
    }

    // Tambah attachment baru yang belum tercatat
    final existingPaths = existing.map((a) => a.localPath).toSet();
    for (final path in currentLocalPaths) {
      if (!existingPaths.contains(path)) {
        int size = 0;
        final f = File(path);
        if (await f.exists()) {
          size = await f.length();
        }
        await _db.into(_db.attachments).insert(
          AttachmentsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            entryId: Value(entryId),
            localPath: Value(path),
            mimeType: 'image/jpeg',
            sizeBytes: size,
          ),
        );
      }
    }
  }

  /// Menyimpan atau memperbarui foto struk untuk transaksi keuangan.
  Future<void> syncTxAttachment(String txId, String? currentLocalPath) async {
    final now = DateTime.now().toUtc();
    final existing = await getAttachmentForTx(txId);

    if (currentLocalPath == null) {
      // Hapus jika ada
      if (existing != null) {
        await (_db.update(_db.attachments)..where((a) => a.id.equals(existing.id))).write(
          AttachmentsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            isDirty: const Value(true),
          ),
        );
      }
      return;
    }

    // Jika struknya sama, tidak perlu ubah
    if (existing != null && existing.localPath == currentLocalPath) {
      return;
    }

    // Hapus yang lama jika ada
    if (existing != null) {
      await (_db.update(_db.attachments)..where((a) => a.id.equals(existing.id))).write(
        AttachmentsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(true),
        ),
      );
    }

    // Insert yang baru
    int size = 0;
    final f = File(currentLocalPath);
    if (await f.exists()) {
      size = await f.length();
    }
    await _db.into(_db.attachments).insert(
      AttachmentsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        transactionId: Value(txId),
        localPath: Value(currentLocalPath),
        mimeType: 'image/jpeg',
        sizeBytes: size,
      ),
    );
  }

  /// Soft delete attachment by id.
  Future<void> deleteAttachment(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.attachments)..where((a) => a.id.equals(id))).write(
      AttachmentsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(true),
      ),
    );
  }
}

