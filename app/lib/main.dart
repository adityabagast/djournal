import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/sync/backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nama hari/bulan dalam bahasa Indonesia & Inggris untuk DateFormat.
  await initializeDateFormatting();
  if (backendConfigured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
  }
  // ProviderScope = "container DI" untuk seluruh app.
  runApp(const ProviderScope(child: DJournalApp()));
}
