/// nav_shell.dart — a concha do app: 4 destinos + Scan central elevado.
/// A barra é um pill de vidro flutuante; o Scan é um disco usinado de
/// platina que ergue acima da barra, como uma coroa.
library;

import 'package:flutter/material.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/aurora_background.dart';
import '../espelho/espelho_screen.dart';
import '../home/home_screen.dart';
import '../mercado/mercado_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;

  static const _destinations = <_Dest>[
    _Dest(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Início',
    ),
    _Dest(
      icon: Icons.face_retouching_natural_outlined,
      activeIcon: Icons.face_retouching_natural,
      label: 'Espelho',
    ),
    _Dest(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      label: 'Mercado',
    ),
    _Dest(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      EspelhoScreen(emTab: true),
      MercadoScreen(emTab: true),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.012),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_index), child: screens[_index]),
          ),
        ),
      ),
      // Scan central — rota própria por cima da concha.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _ScanCrown(
        active: _index == 4,
        onTap: () => Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 420),
            reverseTransitionDuration: const Duration(milliseconds: 320),
            pageBuilder: (_, _, _) => const ScanScreen(),
            transitionsBuilder: (_, anim, _, child) => SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
              child: child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: _GlassBar(
        destinations: _destinations,
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _Dest {
  const _Dest({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Disco usinado do Scan — meia coroa acima da barra.
class _ScanCrown extends StatelessWidget {
  const _ScanCrown({required this.onTap, required this.active});

  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AuraDecor.auraMetal,
          boxShadow: [
            ...AuraDecor.glowShadow(alpha: 0.4),
            BoxShadow(
              color: AuraColors.shadowCold.withValues(alpha: 0.9),
              offset: const Offset(0, 14),
              blurRadius: 30,
              spreadRadius: -10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.4),
        child: Container(
          decoration:  BoxDecoration(
            shape: BoxShape.circle,
            color: AuraColors.backgroundDeep,
          ),
          child: Icon(
            Icons.center_focus_strong,
            color: active ? AuraColors.primary : AuraColors.foreground,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _GlassBar extends StatelessWidget {
  const _GlassBar({
    required this.destinations,
    required this.index,
    required this.onChanged,
  });

  final List<_Dest> destinations;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    // O hueco central do Scan divide a barra em duas asas de 2 destinos.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(33),
            gradient: AuraDecor.softGlass,
            color: AuraColors.cardFill,
            border: Border.all(color: AuraColors.border),
            boxShadow: AuraDecor.elevatedShadow,
          ),
          child: Row(
            children: [
              for (var i = 0; i < 2; i++) Expanded(child: _item(i)),
              const SizedBox(width: 74),
              for (var i = 2; i < 4; i++) Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final d = destinations[i];
    final active = index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? AuraColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Icon(
              active ? d.activeIcon : d.icon,
              size: 21,
              color: active ? AuraColors.primary : AuraColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            d.label,
            style: AuraType.chip.copyWith(
              fontSize: 9,
              letterSpacing: 0.8,
              color: active ? AuraColors.primary : AuraColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
