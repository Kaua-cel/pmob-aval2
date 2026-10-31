import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/app.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/ui/components/empty_state.dart';
import 'package:pmob_aval2/ui/screens/cadastro_screen.dart';
import 'package:pmob_aval2/ui/screens/listagem_screen.dart';

void main() {
  testWidgets('navega entre listagem e cadastro', (WidgetTester tester) async {
    await tester.pumpWidget(const AplicativoAchadosPerdidos());

    expect(find.byType(EstadoVazio), findsOneWidget);

    await tester.tap(find.text('Cadastrar item'));
    await tester.pumpAndSettle();

    expect(find.byType(TelaCadastro), findsOneWidget);
  });

  testWidgets('exibe os quatro dados de um registro recebido', (WidgetTester tester) async {
    final ItemRecord record = ItemRecord(
      name: 'Mochila azul',
      description: 'Mochila deixada no laboratório.',
      location: 'Laboratório 2',
      status: ItemStatus.found,
    );

    await tester.pumpWidget(MaterialApp(home: TelaListagem(records: <ItemRecord>[record])));

    expect(find.text(record.name), findsOneWidget);
    expect(find.text(record.location), findsOneWidget);
    expect(find.text(record.description), findsOneWidget);
    expect(find.text('Encontrado'), findsOneWidget);
  });

  testWidgets('exibe tentativa novamente no estado de falha', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: TelaListagem(state: EstadoListaObjetos.falha)));

    expect(find.text('Não foi possível carregar os objetos.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
