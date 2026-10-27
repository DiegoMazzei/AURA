import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  testWidgets('color updates an open settings route and survives restart', (
    tester,
  ) async {
    final store = MemoryLibraryStore();
    final c = AuraController(audio: FakeAudioEngine(), store: store);
    await c.initialize();
    await tester.pumpWidget(AuraApp(controller: c));
    final context = tester.element(find.byType(AuraShell));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsScreen(controller: c)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byTooltip('Verde'), 250);
    final original = Theme.of(tester.element(find.byType(SettingsScreen)))
        .colorScheme
        .primary;
    await tester.tap(find.byTooltip('Verde'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(SettingsScreen))).colorScheme.primary,
      isNot(original),
    );
    expect(c.accentColor, 0xff29834b);
    await c.save();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    final restored = AuraController(audio: FakeAudioEngine(), store: store);
    await restored.initialize();
    expect(restored.accentColor, 0xff29834b);
    restored.dispose();
  });
  testWidgets('invalid custom color is rejected and valid HEX is applied', (
    tester,
  ) async {
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
    );
    await c.initialize();
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: c)));
    await tester.scrollUntilVisible(find.text('Colore personalizzato'), 250);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Colore personalizzato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Colore personalizzato'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no');
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(find.text('Inserisci sei cifre, ad esempio 9750E8'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '#123ABC');
    await tester.tap(find.text('Applica'));
    await tester.pumpAndSettle();
    expect(c.accentColor, 0xff123abc);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
