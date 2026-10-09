import 'package:flutter/material.dart';
import 'package:na_tesoreria/core/theme/brand.dart';

/// Visual navigation only. Workspace owns the selected tab and its business logic.
class _NavDestination {
  const _NavDestination(this.name, this.icon, this.activeIcon);
  final String name;
  final IconData icon;
  final IconData activeIcon;
}

const _destinations = <_NavDestination>[
  _NavDestination('Resumen', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _NavDestination('Movimientos', Icons.swap_horiz_rounded, Icons.swap_horiz_rounded),
  _NavDestination('Aportes', Icons.volunteer_activism_outlined, Icons.volunteer_activism_rounded),
  _NavDestination('Más', Icons.widgets_outlined, Icons.widgets_rounded),
];

class TreasuryNavigationBar extends StatelessWidget {
  const TreasuryNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.compactLabels = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool compactLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    // ignore: unused_local_variable
    final c = theme.colorScheme;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 230);
    final panel = dark ? const Color(0xff15223a) : Colors.white;
    final tint = dark ? const Color(0xff283f60) : const Color(0xffe9effb);
    final activeInk = dark ? const Color(0xfff3f6ff) : brandNavy;
    final inactiveInk = dark ? const Color(0xffabb9d0) : const Color(0xff5a6780);

    return Material(
      color: panel,
      child: Container(
        decoration: BoxDecoration(
          color: panel,
          border: Border(top: BorderSide(color: dark ? Colors.white.withOpacity(.09) : brandNavy.withOpacity(.09))),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(dark ? .2 : .07), blurRadius: 24, offset: const Offset(0, -7))],
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          child: LayoutBuilder(builder: (context, constraints) {
            final veryNarrow = constraints.maxWidth < 340;
            final showLabels = !compactLabels && !veryNarrow;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: veryNarrow ? 4 : 12, vertical: 7),
              child: Row(children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(child: _NavButton(
                    destination: _destinations[i],
                    selected: selectedIndex == i,
                    showLabel: showLabels,
                    duration: duration,
                    activeInk: activeInk,
                    inactiveInk: inactiveInk,
                    tint: tint,
                    onTap: () => onSelect(i),
                  )),
              ]),
            );
          }),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.destination, required this.selected, required this.showLabel,
    required this.duration, required this.activeInk, required this.inactiveInk,
    required this.tint, required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final bool showLabel;
  final Duration duration;
  final Color activeInk, inactiveInk, tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.name,
      child: Tooltip(
        message: destination.name,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  height: 37,
                  width: selected ? 60 : 47,
                  decoration: BoxDecoration(
                    color: selected ? tint : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    border: selected ? Border.all(color: brandGold.withOpacity(.7), width: 1) : null,
                  ),
                  child: Center(child: Icon(
                    selected ? destination.activeIcon : destination.icon,
                    size: 23,
                    color: selected ? activeInk : inactiveInk,
                  )),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 5),
                  Text(destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected ? activeInk : inactiveInk),
                  ),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class TreasuryNavigationRail extends StatelessWidget {
  const TreasuryNavigationRail({super.key, required this.selectedIndex, required this.onSelect});
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final background = dark ? const Color(0xff15223a) : Colors.white;
    final ink = dark ? const Color(0xffe9eeff) : brandNavy;
    return Material(
      color: background,
      child: SafeArea(
        right: false,
        child: SizedBox(
          width: 106,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(height: 4, width: 32, decoration: BoxDecoration(color: brandGold, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 22),
            for (var i = 0; i < _destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Semantics(
                  button: true, selected: selectedIndex == i, label: _destinations[i].name,
                  child: Material(
                    color: selectedIndex == i ? (dark ? const Color(0xff304462) : const Color(0xffe9effb)) : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => onSelect(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Column(children: [
                          Icon(selectedIndex == i ? _destinations[i].activeIcon : _destinations[i].icon,
                            color: selectedIndex == i ? ink : theme.colorScheme.onSurfaceVariant, size: 24),
                          const SizedBox(height: 6),
                          Text(_destinations[i].name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5,
                              fontWeight: selectedIndex == i ? FontWeight.w800 : FontWeight.w500,
                              color: selectedIndex == i ? ink : theme.colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
