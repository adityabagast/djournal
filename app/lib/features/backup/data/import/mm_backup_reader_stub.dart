import 'dart:typed_data';

import 'money_manager_import.dart';

Future<MmData> readMoneyManagerBackup(Uint8List bytes) async =>
    throw MmFormatException('file .mmbak tidak didukung di platform ini');
