import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/app.dart';
import 'package:pmob_aval2/data/services/item_record_repository.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/state/item_form_controller.dart';
import 'package:pmob_aval2/state/item_list_controller.dart';
import 'package:pmob_aval2/ui/components/item_record_card.dart';
import 'package:pmob_aval2/ui/screens/cadastro_screen.dart';

void main() {
  testWidgets('cadastra um objeto com sucesso, exibe snackbar, notifica sucesso e fecha a tela', (
    WidgetTester tester,
  ) async {
    ItemRecord? gravado;
    final _FakeRepository repository = _FakeRepository(
      onCreate: (ItemRecord draft) async {
        gravado = draft;
        return ItemRecord(
          id: 'id-gerado-1',
          name: draft.name,
          description: draft.description,
          location: draft.location,
          status: draft.status,
          createdAt: DateTime.utc(2026, 11, 1, 12, 0),
        );
      },
    );
    final ItemFormController formController = ItemFormController(repository);
    bool sucessoChamado = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TelaCadastroComEstado(
            controller: formController,
            onSuccess: () => sucessoChamado = true,
          ),
        ),
      ),
    );

    // Preenche os campos
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nome do objeto'),
      'Caderno quadriculado',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Caderno de capa preta com espiral.',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Sala 102');

    // Clica em salvar
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar objeto'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(gravado?.name, 'Caderno quadriculado');
    expect(gravado?.description, 'Caderno de capa preta com espiral.');
    expect(gravado?.location, 'Sala 102');
    expect(gravado?.status, ItemStatus.lost);
    expect(sucessoChamado, isTrue);
    expect(find.text('Objeto cadastrado com sucesso!'), findsOneWidget);
  });

  testWidgets('cadastra com a situação Encontrado selecionada', (WidgetTester tester) async {
    ItemRecord? gravado;
    final _FakeRepository repository = _FakeRepository(
      onCreate: (ItemRecord draft) async {
        gravado = draft;
        return ItemRecord(
          id: 'id-gerado-2',
          name: draft.name,
          description: draft.description,
          location: draft.location,
          status: draft.status,
          createdAt: DateTime.utc(2026, 11, 1, 12, 10),
        );
      },
    );
    final ItemFormController formController = ItemFormController(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TelaCadastroComEstado(controller: formController)),
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do objeto'), 'Óculos de grau');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Armação metálica dourada.',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Bancada do laboratório');

    // Seleciona Encontrado
    await tester.tap(find.text('Encontrado'));
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar objeto'));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(gravado?.status, ItemStatus.found);
  });

  testWidgets(
    'em caso de falha remota, exibe erro em português e mantém os campos intactos sem fechar',
    (WidgetTester tester) async {
      final _FakeRepository repository = _FakeRepository(
        onCreate: (ItemRecord draft) async => throw StateError('falha de conexão'),
      );
      final ItemFormController formController = ItemFormController(repository);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TelaCadastroComEstado(controller: formController)),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do objeto'),
        'Chaveiro de moto',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descrição'),
        'Chave com fita vermelha.',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Estacionamento');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar objeto'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);
      expect(find.text('Não foi possível cadastrar o objeto. Tente novamente.'), findsOneWidget);

      // Os campos permanecem intactos para nova tentativa
      expect(find.text('Chaveiro de moto'), findsOneWidget);
      expect(find.text('Chave com fita vermelha.'), findsOneWidget);
      expect(find.text('Estacionamento'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.byType(TelaCadastro), findsOneWidget);
    },
  );

  testWidgets(
    'permite tentar novamente após falha de gravação sem duplicar o registro quando a conexão volta',
    (WidgetTester tester) async {
      int tentativa = 0;
      final List<ItemRecord> gravados = <ItemRecord>[];
      final _FakeRepository repository = _FakeRepository(
        onCreate: (ItemRecord draft) async {
          tentativa++;
          if (tentativa == 1) {
            throw TimeoutException('tempo limite excedido');
          }
          final ItemRecord criado = ItemRecord(
            id: 'id-recuperado-1',
            name: draft.name,
            description: draft.description,
            location: draft.location,
            status: draft.status,
            createdAt: DateTime.utc(2026, 11, 1, 15, 0),
          );
          gravados.add(criado);
          return criado;
        },
      );
      final ItemFormController formController = ItemFormController(repository);
      bool sucessoChamado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TelaCadastroComEstado(
              controller: formController,
              onSuccess: () => sucessoChamado = true,
            ),
          ),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Nome do objeto'), 'Estetoscópio');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descrição'),
        'Estetoscópio azul marinho.',
      );
      await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Bloco de Saúde');

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar objeto'));
      await tester.pumpAndSettle();

      // Primeira tentativa falhou por timeout
      expect(repository.createCalls, 1);
      expect(gravados, isEmpty);
      expect(
        find.text('O envio demorou mais que o esperado. Verifique sua conexão e tente novamente.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);

      // Garante que o botão Tentar novamente esteja visível e aciona a recuperação
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 2);
      expect(gravados, hasLength(1));
      expect(gravados.single.name, 'Estetoscópio');
      expect(sucessoChamado, isTrue);
      expect(find.text('Objeto cadastrado com sucesso!'), findsOneWidget);
    },
  );

  testWidgets('bloqueia envios concorrentes e exibe estado de salvando enquanto processa', (
    WidgetTester tester,
  ) async {
    final Completer<ItemRecord> submissaoCompleter = Completer<ItemRecord>();
    final _FakeRepository repository = _FakeRepository(onCreate: (_) => submissaoCompleter.future);
    final ItemFormController formController = ItemFormController(repository);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TelaCadastroComEstado(controller: formController)),
      ),
    );

    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do objeto'), 'Guarda-chuva');
    await tester.enterText(find.widgetWithText(TextFormField, 'Descrição'), 'Preto grande.');
    await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Portaria');

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar objeto'));
    await tester.pump();

    // Indicador de progresso visível e botão desabilitado
    expect(find.text('Salvando...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(repository.createCalls, 1);

    // Tentativa de segundo clique enquanto processa
    await tester.tap(find.text('Salvando...'));
    await tester.pump();
    expect(repository.createCalls, 1);

    // Conclui a submissão
    submissaoCompleter.complete(
      ItemRecord(
        id: '1',
        name: 'Guarda-chuva',
        description: 'Preto grande.',
        location: 'Portaria',
        status: ItemStatus.lost,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Objeto cadastrado com sucesso!'), findsOneWidget);
  });

  testWidgets('fluxo completo: abre cadastro pela listagem, salva item e listagem atualiza', (
    WidgetTester tester,
  ) async {
    final List<ItemRecord> registrosNoBanco = <ItemRecord>[];

    final _FakeRepository repository = _FakeRepository(
      onList: () async => List<ItemRecord>.from(registrosNoBanco),
      onCreate: (ItemRecord draft) async {
        final ItemRecord criado = ItemRecord(
          id: 'gerado-${registrosNoBanco.length + 1}',
          name: draft.name,
          description: draft.description,
          location: draft.location,
          status: draft.status,
          createdAt: DateTime.now().toUtc(),
        );
        registrosNoBanco.insert(0, criado);
        return criado;
      },
    );

    final ItemListController listController = ItemListController(repository);
    final ItemFormController formController = ItemFormController(repository);

    await tester.pumpWidget(
      AplicativoAchadosPerdidos(
        itemListController: listController,
        itemFormController: formController,
      ),
    );
    await tester.pumpAndSettle();

    // Lista inicialmente vazia
    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);

    // Abre cadastro
    await tester.tap(find.text('Cadastrar item'));
    await tester.pumpAndSettle();
    expect(find.byType(TelaCadastro), findsOneWidget);

    // Preenche
    await tester.enterText(find.widgetWithText(TextFormField, 'Nome do objeto'), 'Fone de ouvido');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descrição'),
      'Fone bluetooth branco.',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Auditório');
    await tester.tap(find.text('Encontrado'));
    await tester.pump();

    // Salva
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar objeto'));
    await tester.pumpAndSettle();

    // Retornou para a tela de listagem e novo item é exibido!
    expect(find.byType(CartaoRegistroItem), findsOneWidget);
    expect(find.text('Fone de ouvido'), findsOneWidget);
    expect(find.text('Auditório'), findsOneWidget);
    expect(find.text('Encontrado'), findsOneWidget);
  });
}

final class _FakeRepository implements ItemRecordRepository {
  _FakeRepository({this.onCreate, this.onList});

  final Future<ItemRecord> Function(ItemRecord draft)? onCreate;
  final Future<List<ItemRecord>> Function()? onList;
  int createCalls = 0;
  int listCalls = 0;

  @override
  Future<ItemRecord> createItemRecord(ItemRecord draft) {
    createCalls++;
    if (onCreate != null) {
      return onCreate!(draft);
    }
    throw UnimplementedError();
  }

  @override
  Future<List<ItemRecord>> listItemRecords() {
    listCalls++;
    if (onList != null) {
      return onList!();
    }
    return Future.value(<ItemRecord>[]);
  }
}
