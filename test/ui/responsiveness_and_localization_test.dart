import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmob_aval2/app.dart';
import 'package:pmob_aval2/models/item_record.dart';
import 'package:pmob_aval2/ui/components/item_record_card.dart';
import 'package:pmob_aval2/ui/screens/cadastro_screen.dart';
import 'package:pmob_aval2/ui/screens/listagem_screen.dart';
import 'package:pmob_aval2/ui/theme/app_theme.dart';

void main() {
  const List<Size> testedViewports = <Size>[
    Size(320, 568), // Compact portrait phone
    Size(390, 844), // Standard portrait phone
    Size(640, 320), // Landscape phone
    Size(1024, 768), // Tablet / wide viewport
  ];

  final List<ItemRecord> sampleRecords = <ItemRecord>[
    ItemRecord(
      id: 'item-1',
      name: 'Guarda-chuva retrátil preto com cabo emborrachado longo',
      description:
          'Deixado próximo à bancada de atendimento do bloco principal após a chuva da tarde.',
      location: 'Bloco Central — Corredor do 2º andar próximo ao auditório',
      status: ItemStatus.lost,
      createdAt: DateTime.utc(2026, 11, 5, 14, 0),
    ),
    ItemRecord(
      id: 'item-2',
      name: 'Garrafa térmica inox',
      description: 'Garrafa prateada com adesivo acadêmico na tampa.',
      location: 'Biblioteca Setorial',
      status: ItemStatus.found,
      createdAt: DateTime.utc(2026, 11, 5, 16, 30),
    ),
  ];

  testWidgets('utiliza Material 3 e apresenta textos e tooltips em português nas duas telas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AplicativoAchadosPerdidos());

    final BuildContext listContext = tester.element(find.byType(TelaListagem));
    expect(Theme.of(listContext).useMaterial3, isTrue);

    expect(find.text('Achados e Perdidos'), findsOneWidget);
    expect(find.byTooltip('Atualizar listagem'), findsOneWidget);
    expect(find.byTooltip('Cadastrar item'), findsOneWidget);
    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);

    await tester.tap(find.text('Cadastrar item'));
    await tester.pumpAndSettle();

    final BuildContext formContext = tester.element(find.byType(TelaCadastro));
    expect(Theme.of(formContext).useMaterial3, isTrue);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(find.text('Informe os dados do objeto'), findsOneWidget);
    expect(find.text('Perdido'), findsOneWidget);
    expect(find.text('Encontrado'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Salvar objeto'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.text('Salvar objeto'), findsOneWidget);
  });

  testWidgets('renderiza estados da listagem sem overflow em telas compactas, paisagem e largas', (
    WidgetTester tester,
  ) async {
    for (final Size viewport in testedViewports) {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Estado carregando
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTemaAplicativo(),
          home: const TelaListagem(state: EstadoListaObjetos.carregando),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Carregando objetos...'), findsOneWidget);

      // 2. Estado de falha com botão Tentar novamente acessível
      bool retryTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTemaAplicativo(),
          home: TelaListagem(
            state: EstadoListaObjetos.falha,
            onRefresh: () async => retryTriggered = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentar novamente'));
      expect(retryTriggered, isTrue);

      // 3. Estado vazio
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTemaAplicativo(),
          home: const TelaListagem(state: EstadoListaObjetos.sucesso),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);

      // 4. Lista populada com registros Perdido e Encontrado
      await tester.pumpWidget(
        MaterialApp(
          theme: criarTemaAplicativo(),
          home: TelaListagem(state: EstadoListaObjetos.sucesso, records: sampleRecords),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CartaoRegistroItem), findsWidgets);
      expect(find.text('Perdido'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Encontrado'), findsOneWidget);
    }
  });

  testWidgets(
    'renderiza formulário de cadastro sem overflow em diferentes tamanhos, erros e com teclado aberto',
    (WidgetTester tester) async {
      for (final Size viewport in testedViewports) {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        bool retryCalled = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: criarTemaAplicativo(),
            builder: (BuildContext context, Widget? child) {
              final MediaQueryData mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(viewInsets: const EdgeInsets.only(bottom: 220)),
                child: child!,
              );
            },
            home: TelaCadastro(
              key: ValueKey<Size>(viewport),
              hasError: true,
              onSave: (_) async {},
              onRetry: () async => retryCalled = true,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Aciona validação com campos vazios garantindo que o botão Salvar objeto é alcançável
        await tester.dragUntilVisible(
          find.text('Salvar objeto'),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.ensureVisible(find.text('Salvar objeto'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Salvar objeto'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Volta ao topo para preencher os campos
        await tester.dragUntilVisible(
          find.widgetWithText(TextFormField, 'Nome do objeto'),
          find.byType(ListView),
          const Offset(0, 150),
        );
        await tester.ensureVisible(find.widgetWithText(TextFormField, 'Nome do objeto'));
        await tester.pumpAndSettle();

        await tester.enterText(find.widgetWithText(TextFormField, 'Nome do objeto'), 'Chave USB');
        await tester.dragUntilVisible(
          find.widgetWithText(TextFormField, 'Descrição'),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.ensureVisible(find.widgetWithText(TextFormField, 'Descrição'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Descrição'),
          'Pendrive preto 32GB.',
        );
        await tester.dragUntilVisible(
          find.widgetWithText(TextFormField, 'Local'),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.ensureVisible(find.widgetWithText(TextFormField, 'Local'));
        await tester.pumpAndSettle();
        await tester.enterText(find.widgetWithText(TextFormField, 'Local'), 'Sala 05');

        await tester.dragUntilVisible(
          find.text('Tentar novamente'),
          find.byType(ListView),
          const Offset(0, -150),
        );
        await tester.ensureVisible(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tentar novamente'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(retryCalled, isTrue);
      }
    },
  );
}
