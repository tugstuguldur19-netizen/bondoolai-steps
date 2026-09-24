/// Supabase project used for friends and the leaderboard.
/// Fill these in (or pass --dart-define=SUPABASE_URL=... etc. at build time).
/// The anon key is designed to be public; row-level security in
/// supabase/schema.sql is what protects the data.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

/// Where friends can download the app (included in invite messages).
const String appDownloadUrl =
    'https://github.com/tugstuguldur19-netizen/bondoolai-steps/releases/latest';

bool get socialConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
