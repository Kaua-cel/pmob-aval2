import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/services/supabase_configuration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SupabaseConfiguration configuration = SupabaseConfiguration.fromEnvironment();
  await Supabase.initialize(url: configuration.url, publishableKey: configuration.anonKey);

  runApp(const AplicativoAchadosPerdidos());
}
