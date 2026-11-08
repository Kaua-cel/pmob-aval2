import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/supabase_item_record_repository.dart';
import 'package:pmob_aval2/models/item_record_mapper.dart';
import 'package:pmob_aval2/state/item_list_controller.dart';
import 'package:pmob_aval2/ui/components/empty_state.dart';
import 'package:pmob_aval2/ui/components/item_record_card.dart';
import 'package:pmob_aval2/ui/screens/listagem_screen.dart';

void main() {
  final ItemRecordStorage itemMaisAntigoStorage = <String, Object?>{
    'id': 'item-1',
    'name': 'Garrafa térmica',
    'description': 'Garrafa metálica vermelha 500ml.',
    'location': 'Refeitório',
    'status': 'lost',
    'created_at': '2026-11-01T08:30:00.000Z',
  };

  final ItemRecordStorage itemMaisRecenteStorage = <String, Object?>{
    'id': 'item-2',
    'name': 'Calculadora científica',
    'description': 'Calculadora preta com tampa adesivada.',
    'location': 'Laboratório de Física',
    'status': 'found',
    'created_at': '2026-11-01T10:15:00.000Z',
  };

  testWidgets(
    'carrega e exibe os registros vindos do repositório remoto oficial sem dados fictícios locais',
    (WidgetTester tester) async {
      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
        () async => <ItemRecordStorage>[itemMaisRecenteStorage],
      );
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      expect(dataSource.listCalls, 1);
      expect(find.byType(CartaoRegistroItem), findsOneWidget);
      expect(find.text('Calculadora científica'), findsOneWidget);
      expect(find.text('Laboratório de Física'), findsOneWidget);
      expect(find.text('Calculadora preta com tampa adesivada.'), findsOneWidget);
      expect(find.text('Encontrado'), findsOneWidget);
    },
  );

  testWidgets(
    'ordena decrescente no repositório real mesmo se a fonte remota retornar registros fora de ordem',
    (WidgetTester tester) async {
      // Fornece propositalmente o item mais antigo primeiro na resposta bruta da rede
      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
        () async => <ItemRecordStorage>[itemMaisAntigoStorage, itemMaisRecenteStorage],
      );
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      final Iterable<Widget> cartoes = tester.widgetList(find.byType(CartaoRegistroItem));
      expect(cartoes.length, 2);

      final CartaoRegistroItem primeiroCartao = cartoes.first as CartaoRegistroItem;
      final CartaoRegistroItem segundoCartao = cartoes.last as CartaoRegistroItem;

      // O repositório real deve ordenar por data mais recente primeiro
      expect(primeiroCartao.record.id, 'item-2');
      expect(primeiroCartao.record.name, 'Calculadora científica');
      expect(segundoCartao.record.id, 'item-1');
      expect(segundoCartao.record.name, 'Garrafa térmica');
    },
  );

  testWidgets(
    'mapeia e exibe os quatro campos obrigatórios e badges corretos a partir do formato do banco',
    (WidgetTester tester) async {
      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
        () async => <ItemRecordStorage>[itemMaisRecenteStorage, itemMaisAntigoStorage],
      );
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      // Item 2: encontrado
      expect(find.text('Calculadora científica'), findsOneWidget);
      expect(find.text('Calculadora preta com tampa adesivada.'), findsOneWidget);
      expect(find.text('Laboratório de Física'), findsOneWidget);
      expect(find.text('Encontrado'), findsOneWidget);

      // Item 1: perdido
      expect(find.text('Garrafa térmica'), findsOneWidget);
      expect(find.text('Garrafa metálica vermelha 500ml.'), findsOneWidget);
      expect(find.text('Refeitório'), findsOneWidget);
      expect(find.text('Perdido'), findsOneWidget);
    },
  );

  testWidgets(
    'ao clicar no botão de atualizar no AppBar, consulta o repositório e reflete item de outra instalação',
    (WidgetTester tester) async {
      final List<ItemRecordStorage> registrosRemotos = <ItemRecordStorage>[itemMaisAntigoStorage];

      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
        () async => List<ItemRecordStorage>.from(registrosRemotos),
      );
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Garrafa térmica'), findsOneWidget);
      expect(find.text('Calculadora científica'), findsNothing);
      expect(dataSource.listCalls, 1);

      // Simula inserção remota por outra instalação
      registrosRemotos.insert(0, itemMaisRecenteStorage);

      // Clica no botão de atualizar da AppBar
      await tester.tap(find.byTooltip('Atualizar listagem'));
      await tester.pumpAndSettle();

      expect(dataSource.listCalls, 2);
      expect(find.text('Calculadora científica'), findsOneWidget);
      expect(find.text('Garrafa térmica'), findsOneWidget);
    },
  );

  testWidgets(
    'ao puxar para atualizar (RefreshIndicator), dispara nova consulta remota e renderiza novidades',
    (WidgetTester tester) async {
      final List<ItemRecordStorage> registrosRemotos = <ItemRecordStorage>[itemMaisAntigoStorage];

      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
        () async => List<ItemRecordStorage>.from(registrosRemotos),
      );
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      expect(dataSource.listCalls, 1);

      // Simula inserção em outra instalação
      registrosRemotos.insert(0, itemMaisRecenteStorage);

      // Arrasta para baixo para acionar RefreshIndicator
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(dataSource.listCalls, 2);
      expect(find.text('Calculadora científica'), findsOneWidget);
    },
  );

  testWidgets('exibe o estado vazio quando o repositório remoto não possui registros persistidos', (
    WidgetTester tester,
  ) async {
    final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(
      () async => <ItemRecordStorage>[],
    );
    final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
    final ItemListController controller = ItemListController(repository);

    await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoVazio), findsOneWidget);
    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);
    expect(find.byType(CartaoRegistroItem), findsNothing);
  });

  testWidgets(
    'desabilita botão de atualizar durante carregamento e permite recuperar de falha com Tentar novamente',
    (WidgetTester tester) async {
      final Completer<List<ItemRecordStorage>> primeiraConsulta =
          Completer<List<ItemRecordStorage>>();
      int tentativa = 0;

      final _FakeRemoteDataSource dataSource = _FakeRemoteDataSource(() {
        tentativa++;
        if (tentativa == 1) {
          return primeiraConsulta.future;
        }
        return Future<List<ItemRecordStorage>>.value(<ItemRecordStorage>[itemMaisRecenteStorage]);
      });
      final SupabaseItemRecordRepository repository = SupabaseItemRecordRepository(dataSource);
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));

      // Enquanto carrega, o botão de atualizar na AppBar fica desabilitado
      final IconButton refreshButtonWhileLoading = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.refresh),
      );
      expect(refreshButtonWhileLoading.onPressed, isNull);

      // Falha na primeira consulta
      primeiraConsulta.completeError(TimeoutException('tempo esgotado'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar os objetos.'), findsOneWidget);
      expect(
        find.text(
          'A consulta demorou mais que o esperado. Verifique sua conexão e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Clica em Tentar novamente e recupera a listagem
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(dataSource.listCalls, 2);
      expect(find.text('Calculadora científica'), findsOneWidget);
    },
  );
}

final class _FakeRemoteDataSource implements ItemRecordRemoteDataSource {
  _FakeRemoteDataSource(this._onList);

  final Future<List<ItemRecordStorage>> Function() _onList;
  int listCalls = 0;

  @override
  Future<ItemRecordStorage> insertItemRecord(ItemRecordStorage payload) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItemRecordStorage>> listNewestFirst() async {
    listCalls++;
    return _onList();
  }
}
