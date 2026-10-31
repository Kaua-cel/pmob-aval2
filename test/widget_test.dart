import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/app.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/state/item_list_controller.dart';
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

  testWidgets('atualiza a listagem quando o controlador termina a consulta', (
    WidgetTester tester,
  ) async {
    final Completer<List<ItemRecord>> response = Completer<List<ItemRecord>>();
    final ItemListController controller = ItemListController(
      _ListRepository(onList: () => response.future),
    );
    final ItemRecord record = ItemRecord(
      name: 'Estojo vermelho',
      description: 'Estojo encontrado na sala de aula.',
      location: 'Sala 4',
      status: ItemStatus.found,
    );

    await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));

    expect(find.text('Carregando objetos...'), findsOneWidget);

    response.complete(<ItemRecord>[record]);
    await tester.pumpAndSettle();

    expect(find.text(record.name), findsOneWidget);
    expect(find.text('Encontrado'), findsOneWidget);
  });
}

final class _ListRepository implements ItemRecordRepository {
  _ListRepository({required this.onList});

  final Future<List<ItemRecord>> Function() onList;

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItemRecord>> listItemRecords() => onList();
  testWidgets('valida os campos obrigatórios do cadastro', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TelaCadastro(onSave: (_) async {})));

    await _tapSaveButton(tester);
    await tester.pump();

    expect(find.text('O nome do objeto é obrigatório.'), findsOneWidget);
    expect(find.text('A descrição é obrigatória.'), findsOneWidget);
    expect(find.text('Informe o local do objeto.'), findsOneWidget);
  });

  testWidgets('rejeita nome e descrição acima dos limites', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: TelaCadastro(onSave: (_) async {})));

    await tester.enterText(find.byType(TextFormField).at(0), 'a' * 61);
    await tester.enterText(find.byType(TextFormField).at(1), 'b' * 201);
    await tester.enterText(find.byType(TextFormField).at(2), 'Biblioteca');
    await _tapSaveButton(tester);
    await tester.pump();

    expect(find.text('O nome do objeto deve ter no máximo 60 caracteres.'), findsOneWidget);
    expect(find.text('A descrição deve ter no máximo 200 caracteres.'), findsOneWidget);
  });

  testWidgets('envia um registro válido com a situação selecionada', (WidgetTester tester) async {
    ItemRecord? savedRecord;
    await tester.pumpWidget(
      MaterialApp(home: TelaCadastro(onSave: (ItemRecord record) async => savedRecord = record)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Chave do laboratório');
    await tester.enterText(find.byType(TextFormField).at(1), 'Chave com chaveiro azul.');
    await tester.enterText(find.byType(TextFormField).at(2), 'Laboratório 2');
    await tester.tap(find.text('Encontrado'));
    await tester.pump();
    await _tapSaveButton(tester);
    await tester.pumpAndSettle();

    expect(savedRecord?.name, 'Chave do laboratório');
    expect(savedRecord?.description, 'Chave com chaveiro azul.');
    expect(savedRecord?.location, 'Laboratório 2');
    expect(savedRecord?.status, ItemStatus.found);
  });
}

Future<void> _tapSaveButton(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -600));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Salvar objeto'));
}
