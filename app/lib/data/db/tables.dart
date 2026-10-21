import 'package:drift/drift.dart';

/// Simpan DateTime sebagai epoch milidetik UTC (lihat docs/data-model.md §6).
class EpochMsConverter extends TypeConverter<DateTime, int> {
  const EpochMsConverter();

  @override
  DateTime fromSql(int fromDb) =>
      DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

/// Kolom standar untuk semua tabel yang disinkronkan.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  IntColumn get createdAt => integer().map(const EpochMsConverter())();
  IntColumn get updatedAt => integer().map(const EpochMsConverter())();
  IntColumn get deletedAt =>
      integer().map(const EpochMsConverter()).nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Wallets extends Table with SyncColumns {
  TextColumn get name => text()();

  /// cash | bank | ewallet | other
  TextColumn get type => text()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

class Categories extends Table with SyncColumns {
  TextColumn get name => text()();

  /// expense | income
  TextColumn get kind => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// Kunci kategori bawaan (food, transport, …) supaya namanya bisa
  /// diterjemahkan. NULL = kategori buatan user.
  TextColumn get systemKey => text().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
}

@DataClassName('MoneyTx')
@TableIndex(name: 'idx_tx_local_date', columns: {#localDate})
@TableIndex(name: 'idx_tx_wallet', columns: {#walletId})
@TableIndex(name: 'idx_tx_category', columns: {#categoryId})
class Transactions extends Table with SyncColumns {
  /// expense | income | transfer
  TextColumn get type => text()();

  /// Selalu positif, dalam Rupiah. Arah ditentukan [type].
  IntColumn get amount => integer()();
  @ReferenceName('outgoingTransactions')
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('incomingTransfers')
  TextColumn get toWalletId => text().nullable().references(Wallets, #id)();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get note => text().nullable()();
  IntColumn get occurredAt => integer().map(const EpochMsConverter())();

  /// YYYY-MM-DD di zona waktu user.
  TextColumn get localDate => text()();
}

@TableIndex(
  name: 'idx_budget_category_month',
  columns: {#categoryId, #startMonth},
  unique: true,
)
class Budgets extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get amount => integer()();

  /// YYYY-MM
  TextColumn get startMonth => text()();
}

@TableIndex(name: 'idx_entry_date_time', columns: {#entryDate, #entryTime})
class JournalEntries extends Table with SyncColumns {
  /// YYYY-MM-DD lokal. Tidak unik.
  TextColumn get entryDate => text()();

  /// HH:mm lokal, opsional.
  TextColumn get entryTime => text().nullable()();

  /// 1–5
  IntColumn get mood => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text().nullable()();

  /// JSON array string.
  TextColumn get tags => text().nullable()();

  /// Path lokal file audio rekaman (.m4a).
  TextColumn get audioPath => text().nullable()();

  /// Durasi rekaman dalam milidetik.
  IntColumn get audioDurationMs => integer().nullable()();

  /// Teks hasil transkripsi speech-to-text.
  TextColumn get audioTranscript => text().nullable()();
}

class Wishlists extends Table with SyncColumns {
  TextColumn get title => text()();

  /// Target nominal dalam Rupiah.
  IntColumn get targetAmount => integer()();

  /// Nominal yang sudah terkumpul dalam Rupiah.
  IntColumn get savedAmount => integer().withDefault(const Constant(0))();

  /// Estimasi durasi pencapaian dalam bulan.
  IntColumn get targetMonths => integer().withDefault(const Constant(12))();

  /// Tanggal target tercapai (YYYY-MM-DD atau YYYY-MM).
  TextColumn get targetDate => text().nullable()();

  /// Dompet tempat dana dialokasikan.
  TextColumn get walletId => text().nullable().references(Wallets, #id)();

  TextColumn get notes => text().nullable()();
  BoolColumn get isFulfilled => boolean().withDefault(const Constant(false))();
}

class Bills extends Table with SyncColumns {
  TextColumn get title => text()();

  /// Nominal tagihan dalam Rupiah.
  IntColumn get amount => integer()();

  /// Tanggal jatuh tempo (YYYY-MM-DD).
  TextColumn get dueDate => text()();

  /// once | monthly | yearly
  TextColumn get repeatInterval => text().nullable()();

  /// Dompet yang diprioritaskan untuk pembayaran.
  TextColumn get walletId => text().nullable().references(Wallets, #id)();

  /// Kategori transaksi saat dibayar.
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  IntColumn get paidAt => integer().map(const EpochMsConverter()).nullable()();
}

@TableIndex(name: 'idx_attachment_entry', columns: {#entryId})
@TableIndex(name: 'idx_attachment_tx', columns: {#transactionId})
class Attachments extends Table with SyncColumns {
  TextColumn get entryId =>
      text().nullable().references(JournalEntries, #id)();
  TextColumn get transactionId =>
      text().nullable().references(Transactions, #id)();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteKey => text().nullable()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
}

/// Key-value lokal, tidak disinkronkan.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
