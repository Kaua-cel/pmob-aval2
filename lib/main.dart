import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/services/supabase_configuration.dart';
import 'data/services/supabase_item_record_repository.dart';
import 'state/item_list_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SupabaseConfiguration configuration = SupabaseConfiguration.fromEnvironment();
  await Supabase.initialize(url: configuration.url, publishableKey: configuration.anonKey);

  final ItemListController itemListController = ItemListController(
    SupabaseItemRecordRepository.fromInitializedClient(),
  );

  runApp(AplicativoAchadosPerdidos(itemListController: itemListController));
}
