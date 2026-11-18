// .mmbak adalah database SQLite: hanya bisa dibaca di platform dengan
// dart:ffi (Android, desktop), tidak di web.
export 'mm_backup_reader_stub.dart'
    if (dart.library.ffi) 'mm_backup_reader_io.dart';
