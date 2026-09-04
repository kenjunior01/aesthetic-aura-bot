/// app.dart — AuraStyle Mobile: MultiProvider + MaterialApp com a identidade
/// Platina Glacial. O splash espera o perfil carregar e decide: onboarding de
/// primeira utilização ou a concha principal.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/store/profile_store.dart';
import 'core/theme/aura_colors.dart';
import 'core/theme/aura_decorations.dart';
import 'core/theme/aura_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/nav_shell.dart';

class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileStore()..load()),
      ],
      child: MaterialApp(
        title: 'AuraStyle',
        debugShowCheckedModeBanner: false,
        theme: buildAuraTheme(),
        home: const AuraSplash(),
      ),
    );
  }
}

/// Splash mínimo — observidana com a marca a acender; entrega a concha
/// mal o perfil esteja carregado (nunca mais de ~600ms).
class AuraSplash extends StatefulWidget {
  const AuraSplash({super.key});

  @override
  State<AuraSplash> createState() => _AuraSplashState();
}

class _AuraSplashState extends State<AuraSplash> {
  bool _navigated = false;

  void _maybeNavigate() {
    if (_navigated || !mounted) return;
    final store = context.read<ProfileStore>();
    if (!store.loaded) return;
    // Dá um respiro para a marca acender antes de entregar a concha.
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted || _navigated) return;
      _navigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 460),
          pageBuilder: (_, _, _) =>
              store.onboarded ? const NavShell() : const OnboardingScreen(),
          transitionsBuilder: (_, anim, _, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: child,
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
  }

  @override
  Widget build(BuildContext context) {
    // Se o load demorar mais que o respiro, a store notifica e decide.
    context.watch<ProfileStore>();
    _maybeNavigate();
    return Scaffold(
      backgroundColor: AuraColors.backgroundDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AuraDecor.auraMetal,
                boxShadow: AuraDecor.glowShadow(alpha: 0.45),
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AuraColors.backgroundDeep,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 34,
                  color: AuraColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AURA STYLE',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AuraColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'a tua aura, esculpida em platina',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11.5,
                letterSpacing: 0.6,
                color: AuraColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
