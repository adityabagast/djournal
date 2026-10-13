import 'dart:convert';

import '../db/app_database.dart';

// Konversi baris database <-> JSON. Dipakai sync (bentuknya sama dengan
// fungsi SQL sync_push/sync_pull) dan file backup.
//
// [dirty] menentukan is_dirty baris hasil konversi: false untuk data dari
// server, true untuk data impor yang masih harus dikirim ke server.

String _ts(DateTime dt) => dt.toUtc().toIso8601String();
DateTime _parseTs(Object? v) => DateTime.parse(v as String).toUtc();
DateTime? _parseTsOrNull(Object? v) => v == null ? null : _parseTs(v);

Map<String, dynamic> _base(String id, DateTime c, DateTime u, DateTime? d) => {
  'id': id,
  'createdAt': _ts(c),
  'updatedAt': _ts(u),
  'deletedAt': d == null ? null : _ts(d),
};

Map<String, dynamic> walletToJson(Wallet w) => {
  ..._base(w.id, w.createdAt, w.updatedAt, w.deletedAt),
  'name': w.name,
  'type': w.type,
  'openingBalance': w.openingBalance,
  'color': w.color,
  'sortOrder': w.sortOrder,
  'isArchived': w.isArchived,
};

Wallet walletFromJson(Map<String, dynamic> j, {bool dirty = false}) => Wallet(
  id: j['id'] as String,
  createdAt: _parseTs(j['createdAt']),
  updatedAt: _parseTs(j['updatedAt']),
  deletedAt: _parseTsOrNull(j['deletedAt']),
  isDirty: dirty,
  name: j['name'] as String,
  type: j['type'] as String,
  openingBalance: (j['openingBalance'] as num).toInt(),
  color: j['color'] as String?,
  sortOrder: (j['sortOrder'] as num).toInt(),
  isArchived: j['isArchived'] as bool,
);

Map<String, dynamic> categoryToJson(Category c) => {
  ..._base(c.id, c.createdAt, c.updatedAt, c.deletedAt),
  'name': c.name,
  'kind': c.kind,
  'color': c.color,
  'icon': c.icon,
  'sortOrder': c.sortOrder,
  'systemKey': c.systemKey,
  'isArchived': c.isArchived,
};

Category categoryFromJson(Map<String, dynamic> j, {bool dirty = false}) =>
    Category(
      id: j['id'] as String,
      createdAt: _parseTs(j['createdAt']),
      updatedAt: _parseTs(j['updatedAt']),
      deletedAt: _parseTsOrNull(j['deletedAt']),
      isDirty: dirty,
      name: j['name'] as String,
      kind: j['kind'] as String,
      color: j['color'] as String,
      icon: j['icon'] as String?,
      sortOrder: (j['sortOrder'] as num).toInt(),
      systemKey: j['systemKey'] as String?,
      isArchived: j['isArchived'] as bool,
    );

Map<String, dynamic> transactionToJson(MoneyTx t) => {
  ..._base(t.id, t.createdAt, t.updatedAt, t.deletedAt),
  'type': t.type,
  'amount': t.amount,
  'walletId': t.walletId,
  'toWalletId': t.toWalletId,
  'categoryId': t.categoryId,
  'note': t.note,
  'occurredAt': _ts(t.occurredAt),
  'localDate': t.localDate,
};

MoneyTx transactionFromJson(Map<String, dynamic> j, {bool dirty = false}) =>
    MoneyTx(
      id: j['id'] as String,
      createdAt: _parseTs(j['createdAt']),
      updatedAt: _parseTs(j['updatedAt']),
      deletedAt: _parseTsOrNull(j['deletedAt']),
      isDirty: dirty,
      type: j['type'] as String,
      amount: (j['amount'] as num).toInt(),
      walletId: j['walletId'] as String,
      toWalletId: j['toWalletId'] as String?,
      categoryId: j['categoryId'] as String?,
      note: j['note'] as String?,
      occurredAt: _parseTs(j['occurredAt']),
      localDate: j['localDate'] as String,
    );

Map<String, dynamic> budgetToJson(Budget b) => {
  ..._base(b.id, b.createdAt, b.updatedAt, b.deletedAt),
  'categoryId': b.categoryId,
  'amount': b.amount,
  'startMonth': b.startMonth,
};

Budget budgetFromJson(Map<String, dynamic> j, {bool dirty = false}) => Budget(
  id: j['id'] as String,
  createdAt: _parseTs(j['createdAt']),
  updatedAt: _parseTs(j['updatedAt']),
  deletedAt: _parseTsOrNull(j['deletedAt']),
  isDirty: dirty,
  categoryId: j['categoryId'] as String,
  amount: (j['amount'] as num).toInt(),
  startMonth: j['startMonth'] as String,
);

Map<String, dynamic> entryToJson(JournalEntry e) => {
  ..._base(e.id, e.createdAt, e.updatedAt, e.deletedAt),
  'entryDate': e.entryDate,
  'entryTime': e.entryTime,
  'mood': e.mood,
  'title': e.title,
  'body': e.body,
  // Lokal disimpan sebagai string JSON, di API sebagai array.
  'tags': e.tags == null ? <String>[] : _decodeTags(e.tags!),
  'audioPath': e.audioPath,
  'audioDurationMs': e.audioDurationMs,
  'audioTranscript': e.audioTranscript,
};

JournalEntry entryFromJson(Map<String, dynamic> j, {bool dirty = false}) {
  final tags = ((j['tags'] as List?) ?? const []).cast<String>();
  return JournalEntry(
    id: j['id'] as String,
    createdAt: _parseTs(j['createdAt']),
    updatedAt: _parseTs(j['updatedAt']),
    deletedAt: _parseTsOrNull(j['deletedAt']),
    isDirty: dirty,
    entryDate: j['entryDate'] as String,
    entryTime: j['entryTime'] as String?,
    mood: (j['mood'] as num?)?.toInt(),
    title: j['title'] as String?,
    body: j['body'] as String?,
    tags: tags.isEmpty ? null : _encodeTags(tags),
    audioPath: j['audioPath'] as String?,
    audioDurationMs: (j['audioDurationMs'] as num?)?.toInt(),
    audioTranscript: j['audioTranscript'] as String?,
  );
}

List<String> _decodeTags(String json) =>
    (jsonDecode(json) as List).cast<String>();
String _encodeTags(List<String> tags) => jsonEncode(tags);
