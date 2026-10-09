import 'package:flutter/material.dart';
import 'package:na_tesoreria/core/theme/brand.dart';

/// Elementos visuales del espacio de trabajo. No modifican datos ni Supabase.
/// Todas las interfaces públicas se mantienen compatibles con workspace.dart.
class WorkspacePalette {
  WorkspacePalette(BuildContext context)
      : dark = Theme.of(context).brightness == Brightness.dark,
        scheme = Theme.of(context).colorScheme;

  final bool dark;
  final ColorScheme scheme;

  Color get canvas => scheme.surface;
  Color get soft => dark ? const Color(0xFF203450) : const Color(0xFFF0F4FB);
  Color get ink => scheme.onSurface;
  Color get muted => scheme.onSurfaceVariant;
  Color get line => dark ? const Color(0xFF455873) : const Color(0xFFD9E2EF);
  Color get accent => dark ? brandGold : brandNavy;
  Color get accentInk => dark ? brandNavy : Colors.white;
  Color get selectedBackground => dark ? const Color(0xFF364C6C) : const Color(0xFFE4EDFC);
  Color get selectedInk => dark ? const Color(0xFFF3F6FD) : brandNavy;
}

class WorkspaceSurface extends StatelessWidget {
  const WorkspaceSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 15),
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.canvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.line.withOpacity(p.dark ? .75 : .9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(p.dark ? .09 : .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class WorkspaceHeadline extends StatelessWidget {
  const WorkspaceHeadline({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    final largeText = MediaQuery.textScalerOf(context).scale(16) > 23;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: largeText ? 42 : 46,
            height: largeText ? 42 : 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.soft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: p.line),
            ),
            child: Icon(icon, size: 23, color: p.accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: p.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.24,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: TextStyle(color: p.muted, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceMetricCard extends StatelessWidget {
  const WorkspaceMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.featured = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    final textScale = MediaQuery.textScalerOf(context).scale(16);
    final amountSize = textScale > 23 ? 27.0 : 33.0;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: featured ? null : p.canvas,
        gradient: featured
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [brandNavy, Color(0xFF17417C), Color(0xFF0C2856)],
              )
            : null,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: featured ? brandGold.withOpacity(.65) : p.line),
        boxShadow: [
          BoxShadow(
            color: brandNavy.withOpacity(featured ? .17 : (p.dark ? .08 : .045)),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (featured)
            Positioned(
              right: -54,
              top: -52,
              child: IgnorePointer(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: brandGold.withOpacity(.14), width: 27),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: featured ? Colors.white.withOpacity(.12) : p.soft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: featured ? brandGold.withOpacity(.35) : p.line,
                        ),
                      ),
                      child: Icon(icon, color: featured ? brandGold : p.accent, size: 23),
                    ),
                    const Spacer(),
                    if (featured)
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: brandGold, size: 22),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: featured ? const Color(0xFFE2EAFA) : p.muted,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                // FittedBox solo reduce valores extensos; conserva la lectura
                // y evita overflow en teléfonos pequeños.
                LayoutBuilder(
                  builder: (context, constraints) => SizedBox(
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        style: TextStyle(
                          color: featured ? Colors.white : p.ink,
                          fontSize: amountSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
                if (featured) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: 62,
                    height: 3,
                    decoration: BoxDecoration(
                      color: brandGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WorkspaceActionButton extends StatelessWidget {
  const WorkspaceActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onPressed,
    this.secondary = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    final enabled = onPressed != null;
    final color = secondary ? p.accent : Colors.white;
    final disabled = p.muted.withOpacity(.65);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(48, 56)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return p.soft;
        return secondary ? p.soft : brandNavy;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disabled;
        return color;
      }),
      overlayColor: WidgetStatePropertyAll((secondary ? p.accent : Colors.white).withOpacity(.09)),
      side: WidgetStatePropertyAll(
        BorderSide(color: secondary ? p.line : brandNavy),
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: enabled ? color : disabled),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: enabled ? color : disabled),
          ),
        ),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: secondary
          ? OutlinedButton(onPressed: onPressed, style: style, child: child)
          : FilledButton(onPressed: onPressed, style: style, child: child),
    );
  }
}

class WorkspaceSearchPanel extends StatelessWidget {
  const WorkspaceSearchPanel({
    super.key,
    required this.hint,
    this.controller,
    required this.onChanged,
    this.onClear,
    required this.filters,
    required this.selected,
    required this.onFilter,
    this.countLabel,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final Map<String, String> filters;
  final String selected;
  final ValueChanged<String> onFilter;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    final searchIsActive = controller?.text.isNotEmpty ?? false;
    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune_rounded, color: p.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar y filtrar',
                  style: TextStyle(color: p.ink, fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: onClear != null && searchIsActive
                  ? IconButton(
                      tooltip: 'Limpiar búsqueda',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
            ),
          ),
          if (filters.isNotEmpty) ...[
            const SizedBox(height: 15),
            Builder(
              builder: (context) {
                // Chips distribuidos en líneas, no en una fila cortada.
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in filters.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: selected == entry.key,
                        showCheckmark: false,
                        onSelected: (_) => onFilter(entry.key),
                        backgroundColor: p.canvas,
                        selectedColor: p.selectedBackground,
                        side: BorderSide(
                          color: selected == entry.key ? p.accent : p.line,
                          width: selected == entry.key ? 1.5 : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        labelStyle: TextStyle(
                          color: selected == entry.key ? p.selectedInk : p.ink,
                          fontWeight: selected == entry.key
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (countLabel != null && countLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 15),
            Divider(color: p.line.withOpacity(.75), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 17, color: p.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    countLabel!,
                    style: TextStyle(fontSize: 13, color: p.muted, height: 1.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WorkspaceThemeSelector extends StatelessWidget {
  const WorkspaceThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    return WorkspaceSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: p.accent, size: 22),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Apariencia de la aplicación',
                  style: TextStyle(color: p.ink, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Elige cómo quieres ver Tesorería en este dispositivo.',
            style: TextStyle(color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(16) > 23;
              final vertical = constraints.maxWidth < 350 || largeText;
              const options = <_ThemeChoice>[
                _ThemeChoice(ThemeMode.system, Icons.brightness_auto_outlined, 'Automático'),
                _ThemeChoice(ThemeMode.light, Icons.light_mode_outlined, 'Claro'),
                _ThemeChoice(ThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro'),
              ];
              if (vertical) {
                return Column(
                  children: [
                    for (var i = 0; i < options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      SizedBox(width: double.infinity, child: options[i]),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: options[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice(this.mode, this.icon, this.title);

  final ThemeMode mode;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = WorkspacePalette(context);
    final selected = appearance.mode == mode;
    final textScaler = MediaQuery.textScalerOf(context);
    final color = selected ? p.selectedInk : p.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Apariencia $title',
      child: Material(
        color: selected ? p.selectedBackground : p.canvas,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => appearance.setMode(mode),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? p.accent : p.line,
                width: selected ? 1.7 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: selected ? p.accent : p.muted, size: 24),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: textScaler.scale(14) > 20 ? 12 : 13,
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 17,
                  color: selected ? p.accent : p.line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}