/// Alamat project Supabase. Keduanya memang publik (ditaruh di app);
/// keamanan data dijaga Row Level Security dan fungsi sync di database.
/// Jangan pernah menaruh "secret key" / "service_role" di sini.
///
/// Bisa diganti saat build tanpa mengubah kode, misalnya untuk self-host:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_KEY=...
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://lxytuobvqwxwiojpphto.supabase.co',
);
const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_VYQCFM31Cqn5wqhfqAzU1Q_Zt8FbLWk',
);

bool get backendConfigured => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
