import 'package:flutter/material.dart';

import 'ui/routes.dart';
import 'ui/screens/cadastro_screen.dart';
import 'ui/screens/listagem_screen.dart';
import 'ui/theme/app_theme.dart';
import 'state/item_list_controller.dart';

class AplicativoAchadosPerdidos extends StatelessWidget {
  const AplicativoAchadosPerdidos({super.key, this.itemListController});

  final ItemListController? itemListController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Achados e Perdidos',
      theme: criarTemaAplicativo(),
      initialRoute: RotasAplicativo.listagem,
      routes: {
        RotasAplicativo.listagem: (_) => itemListController == null
            ? const TelaListagem()
            : TelaListagemComEstado(controller: itemListController!),
        RotasAplicativo.cadastro: (_) => const TelaCadastro(),
      },
    );
  }
}
