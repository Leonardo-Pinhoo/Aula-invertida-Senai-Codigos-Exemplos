import 'package:flutter_test/flutter_test.dart';

import 'package:app_ferramentas/main.dart';

void main() {
  testWidgets('abre a tela de ferramentas', (tester) async {
    await tester.pumpWidget(const AppFerramentas());
    expect(find.text('Controle de Ferramentas'), findsOneWidget);
  });
}
