import 'package:flutter_test/flutter_test.dart';

import 'package:pmob_aval2/app.dart';

void main() {
  testWidgets('navega entre listagem e cadastro', (tester) async {
    await tester.pumpWidget(const AplicativoAchadosPerdidos());

    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);

    await tester.tap(find.text('Cadastrar item'));
    await tester.pumpAndSettle();

    expect(
      find.text('O formulário de cadastro será adicionado em uma próxima etapa.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Voltar à listagem'));
    await tester.pumpAndSettle();

    expect(find.text('Ainda não há itens cadastrados.'), findsOneWidget);
  });
}
