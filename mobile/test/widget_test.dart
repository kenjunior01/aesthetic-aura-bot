/// widget_test.dart — fumaço do AuraStyle mobile:
/// fórmulas partilhadas, primeiro arranque (onboarding) e alternância
/// Noite ↔ Alvor. Sem rede, sem timers pendentes.
library;

import 'package:aurastyle_mobile/app.dart';
import 'package:aurastyle_mobile/core/store/profile_store.dart';
import 'package:aurastyle_mobile/core/theme/aura_colors.dart';
import 'package:aurastyle_mobile/features/onboarding/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fórmulas de nível idênticas ao web (floor(sqrt(xp/50))+1)', () {
    expect(calculateLevel(0), 1);
    expect(calculateLevel(49), 1);
    expect(calculateLevel(50), 2);
    expect(calculateLevel(200), 3);
    expect(calculateLevel(5000), 11);
    expect(computeLevelProgress(0), 0.0);
    expect(computeLevelProgress(25), closeTo(0.5, 0.01));
    expect(computeLevelProgress(50), 0.0); // recomeça no nível 2
  });

  test('marcos de streak em ordem crescente', () {
    expect(nextStreakMilestone(0)?.days, 3);
    expect(nextStreakMilestone(3)?.days, 7);
    expect(nextStreakMilestone(200), isNull);
  });

  test('ritual completo = streak +1 e +50 XP', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileStore();
    await store.load();
    expect(store.level, 1);
    expect(store.onboarded, isFalse);

    for (var i = 0; i < ProfileStore.kRitualSteps.length; i++) {
      store.toggleRitual(i);
    }
    expect(store.ritualComplete, isTrue);
    expect(store.streak, 1);
    // 5 passos × 5 XP + 25 de bónus = 50
    expect(store.xp, 50);
    expect(store.level, 2);
  });

  test('modo cromático alterna tokens vivos', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProfileStore();
    await store.load();
    expect(AuraColors.claro, isFalse);
    store.setModoClaro(true);
    expect(store.modoClaro, isTrue);
    expect(AuraColors.claro, isTrue);
    store.setModoClaro(false);
    expect(AuraColors.claro, isFalse);
  });

  testWidgets('primeira utilização entrega o onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AuraApp());
    // 1º pump: load completa + splash reconstrói; 2º: delay de 550ms dispara;
    // 3º: pushReplacement + transição de 460ms.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
