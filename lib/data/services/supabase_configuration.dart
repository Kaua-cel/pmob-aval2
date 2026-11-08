/// Reads and validates public Supabase client configuration.
final class SupabaseConfiguration {
  /// Creates validated configuration from a project URL and an anonymous client key.
  SupabaseConfiguration({required String url, required String anonKey})
    : url = url.trim(),
      anonKey = anonKey.trim() {
    if (this.url.isEmpty) {
      throw const SupabaseConfigurationException(
        'SUPABASE_URL is required. Start the app with --dart-define=SUPABASE_URL=<project-url>.',
      );
    }
    final Uri? parsedUrl = Uri.tryParse(this.url);
    if (parsedUrl == null ||
        !parsedUrl.hasAuthority ||
        parsedUrl.host.isEmpty ||
        (parsedUrl.scheme != 'http' && parsedUrl.scheme != 'https')) {
      throw const SupabaseConfigurationException(
        'SUPABASE_URL must be an absolute HTTP or HTTPS URL with a host.',
      );
    }
    if (this.anonKey.isEmpty) {
      throw const SupabaseConfigurationException(
        'SUPABASE_ANON_KEY is required. Start the app with --dart-define=SUPABASE_ANON_KEY=<anon-key>.',
      );
    }
  }

  /// Reads configuration passed with Flutter `--dart-define` values.
  factory SupabaseConfiguration.fromEnvironment() {
    return SupabaseConfiguration(
      url: const String.fromEnvironment('SUPABASE_URL'),
      anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  }

  /// Public project URL used by the client SDK.
  final String url;

  /// Public anonymous client key protected by Row Level Security.
  final String anonKey;
}

/// Reports a missing or malformed public Supabase client setting.
final class SupabaseConfigurationException implements Exception {
  /// Creates an exception with a clear action for the application operator.
  const SupabaseConfigurationException(this.message);

  /// Configuration problem detected before a network request.
  final String message;

  @override
  String toString() => 'SupabaseConfigurationException: $message';
}
