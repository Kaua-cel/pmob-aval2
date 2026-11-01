import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/state/item_list_controller.dart';
import 'package:pmob_aval2/ui/components/empty_state.dart';
import 'package:pmob_aval2/ui/components/item_record_card.dart';
import 'package:pmob_aval2/ui/screens/listagem_screen.dart';

void main() {
  final ItemRecord itemMaisAntigo = ItemRecord(
    id: 'item-1',
    name: 'Garrafa térmica',
    description: 'Garrafa metálica vermelha 500ml.',
    location: 'Refeitório',
    status: ItemStatus.lost,
    createdAt: DateTime.utc(2026, 11, 1, 8, 30),
  );

  final ItemRecord itemMaisRecente = ItemRecord(
    id: 'item-2',
    name: 'Calculadora científica',
    description: 'Calculadora preta com tampa adesivada.',
    location: 'Laboratório de Física',
    status: ItemStatus.found,
    createdAt: DateTime.utc(2026, 11, 1, 10, 15),
  );

  testWidgets(
    'carrega e exibe os registros vindos do repositório remoto sem dados fictícios locais',
    (WidgetTester tester) async {
      final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
        onList: () async => <ItemRecord>[itemMaisRecente],
      );
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));

      // Aguarda resolver a carga assíncrona
      await tester.pumpAndSettle();

      expect(repository.listCalls, 1);
      expect(find.byType(CartaoRegistroItem), findsOneWidget);
      expect(find.text('Calculadora científica'), findsOneWidget);
      expect(find.text('Laboratório de Física'), findsOneWidget);
      expect(find.text('Calculadora preta com tampa adesivada.'), findsOneWidget);
      expect(find.text('Encontrado'), findsOneWidget);
    },
  );

  testWidgets('renderiza registros na ordem fornecida pelo repositório (mais recente primeiro)', (
    WidgetTester tester,
  ) async {
    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async => <ItemRecord>[itemMaisRecente, itemMaisAntigo],
    );
    final ItemListController controller = ItemListController(repository);

    await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
    await tester.pumpAndSettle();

    final Iterable<Widget> cartoes = tester.widgetList(find.byType(CartaoRegistroItem));
    expect(cartoes.length, 2);

    final CartaoRegistroItem primeiroCartao = cartoes.first as CartaoRegistroItem;
    final CartaoRegistroItem segundoCartao = cartoes.last as CartaoRegistroItem;

    expect(primeiroCartao.record.id, 'item-2');
    expect(primeiroCartao.record.name, 'Calculadora científica');
    expect(segundoCartao.record.id, 'item-1');
    expect(segundoCartao.record.name, 'Garrafa térmica');
  });

  testWidgets('exibe os quatro campos obrigatórios e badges corretos para perdido e encontrado', (
    WidgetTester tester,
  ) async {
    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async => <ItemRecord>[itemMaisRecente, itemMaisAntigo],
    );
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
  });

  testWidgets(
    'ao clicar no botão de atualizar no AppBar, consulta o repositório e reflete item de outra instalação',
    (WidgetTester tester) async {
      final List<ItemRecord> registrosRemotos = <ItemRecord>[itemMaisAntigo];

      final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
        onList: () async => List<ItemRecord>.from(registrosRemotos),
      );
      final ItemListController controller = ItemListController(repository);

      await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Garrafa térmica'), findsOneWidget);
      expect(find.text('Calculadora científica'), findsNothing);
      expect(repository.listCalls, 1);

      // Simula inserção remota por outra instalação
      registrosRemotos.insert(0, itemMaisRecente);

      // Clica no botão de atualizar da AppBar
      await tester.tap(find.byTooltip('Atualizar listagem'));
      await tester.pumpAndSettle();

      expect(repository.listCalls, 2);
      expect(find.text('Calculadora científica'), findsOneWidget);
      expect(find.text('Garrafa térmica'), findsOneWidget);
    },
  );

  testWidgets('ao puxar para atualizar (RefreshIndicator), dispara nova consulta remota', (
    WidgetTester tester,
  ) async {
    final List<ItemRecord> registrosRemotos = <ItemRecord>[itemMaisAntigo];

    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async => List<ItemRecord>.from(registrosRemotos),
    );
    final ItemListController controller = ItemListController(repository);

    await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
    await tester.pumpAndSettle();

    expect(repository.listCalls, 1);

    // Simula inserção em outra instalação
    registrosRemotos.insert(0, itemMaisRecente);

    // Arrasta para baixo para acionar RefreshIndicator
    await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    expect(repository.listCalls, 2);
    expect(find.text('Calculadora científica'), findsOneWidget);
  });

  testWidgets('exibe o estado vazio quando o repositório remoto não possui registros', (
    WidgetTester tester,
  ) async {
    final _FakeItemRecordRepository repository = _FakeItemRecordRepository(
      onList: () async => <ItemRecord>[],
    );
    final ItemListController controller = ItemListController(repository);

    await tester.pumpWidget(MaterialApp(home: TelaListagemComEstado(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.byType(EstadoVazio), findsOneWidget);
    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);
    expect(find.byType(CartaoRegistroItem), findsNothing);
  });
}

final class _FakeItemRecordRepository implements ItemRecordRepository {
  _FakeItemRecordRepository({required this.onList});

  final Future<List<ItemRecord>> Function() onList;
  int listCalls = 0;

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<ItemRecord>> listItemRecords() {
    listCalls++;
    return onList();
  }
}
