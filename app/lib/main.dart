import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nama hari/bulan dalam bahasa Indonesia & Inggris untuk DateFormat.
  await initializeDateFormatting();
  // ProviderScope = "container DI" untuk seluruh app.
  runApp(const ProviderScope(child: DJournalApp()));
}
