import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config.dart';
import 'data/sync/backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nama hari/bulan dalam bahasa Indonesia & Inggris untuk DateFormat.
  await initializeDateFormatting();
  // Font Poppins sudah dibundel di assets/google_fonts/: tidak perlu
  // internet, dan app tidak menghubungi server Google saat dibuka.
  GoogleFonts.config.allowRuntimeFetching = false;
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
  runApp(const ProviderScope(child: NyawtatApp()));
}
