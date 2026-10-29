import 'package:flutter/material.dart';

import '../components/empty_state.dart';
import '../routes.dart';

class TelaListagem extends StatelessWidget {
  const TelaListagem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achados e Perdidos')),
      body: const EstadoVazio(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(RotasAplicativo.cadastro),
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar item'),
      ),
    );
  }
}
