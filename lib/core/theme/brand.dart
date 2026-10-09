import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:na_tesoreria/shared/widgets/group_logo.dart';

// Identidad institucional. Mantener estos nombres: otros archivos los importan.

const brandNavy = Color(0xFF071D49);

const brandGold = Color(0xFFD9B96D);

const _navyLight = Color(0xFF173F83);

const _darkBackground = Color(0xFF091325);

const _darkSurface = Color(0xFF15243A);

final appearance = Appearance();

class Appearance extends ChangeNotifier {

  ThemeMode mode = ThemeMode.system;

  SharedPreferences? preferences;

  Future<void> load() async {

    try {

      preferences = await SharedPreferences.getInstance();

      final saved = preferences!.getString('appearance');

      mode = saved == 'dark'

          ? ThemeMode.dark

          : saved == 'light' ? ThemeMode.light : ThemeMode.system;

    } catch (_) {

      mode = ThemeMode.system;

    }

    notifyListeners();

  }

  Future<void> setMode(ThemeMode next) async {

    if (mode == next) return;

    mode = next;

    notifyListeners();

    try {

      preferences ??= await SharedPreferences.getInstance();

      await preferences!.setString('appearance', next.name);

    } catch (_) {

      // Se mantiene la preferencia en memoria si falla el guardado local.

    }

  }

}

ThemeData groupTheme(Brightness brightness) {

  final dark = brightness == Brightness.dark;

  const lightInk = Color(0xFF14223A);

  const darkInk = Color(0xFFF1F5FC);

  final primary = dark ? const Color(0xFFBDD0FF) : brandNavy;

  final onSurface = dark ? darkInk : lightInk;

  final surface = dark ? _darkSurface : Colors.white;

  final outline = dark ? const Color(0xFF52647D) : const Color(0xFFBAC6D7);

  final scheme = ColorScheme.fromSeed(

    seedColor: brandNavy,

    brightness: brightness,

  ).copyWith(

    primary: primary,

    onPrimary: dark ? brandNavy : Colors.white,

    secondary: dark ? brandGold : const Color(0xFF77591F),

    onSecondary: dark ? brandNavy : Colors.white,

    surface: surface,

    onSurface: onSurface,

    outline: outline,

    primaryContainer: dark ? const Color(0xFF293F61) : const Color(0xFFE8EEFA),

    onPrimaryContainer: dark ? const Color(0xFFF0F5FF) : brandNavy,

    secondaryContainer: dark ? const Color(0xFF554525) : const Color(0xFFF8EBCF),

    onSecondaryContainer: dark ? const Color(0xFFFFEDBD) : const Color(0xFF514015),

  );

  final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);

  final radius = BorderRadius.circular(18);

  final outlineBorder = OutlineInputBorder(borderRadius: radius);

  return base.copyWith(

    scaffoldBackgroundColor: dark ? _darkBackground : const Color(0xFFF2F5FA),

    canvasColor: surface,

    dividerColor: outline.withOpacity(dark ? .32 : .40),

    splashColor: primary.withOpacity(.10),

    textTheme: base.textTheme.copyWith(

      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.50, color: onSurface),

      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.48, color: onSurface),

      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 23, height: 1.25, fontWeight: FontWeight.w800, color: onSurface),

      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onSurface),

    ),

    appBarTheme: const AppBarTheme(

      backgroundColor: brandNavy,

      foregroundColor: Colors.white,

      iconTheme: IconThemeData(color: Colors.white),

      actionsIconTheme: IconThemeData(color: Colors.white),

      elevation: 0,

      scrolledUnderElevation: 0,

      centerTitle: false,

      toolbarHeight: 76,

    ),

    cardTheme: CardThemeData(

      color: surface,

      elevation: 0,

      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.circular(22),

        side: BorderSide(color: outline.withOpacity(.26)),

      ),

    ),

    inputDecorationTheme: InputDecorationTheme(

      filled: true,

      fillColor: dark ? const Color(0xFF1B2C46) : const Color(0xFFF9FBFE),

      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),

      border: outlineBorder,

      enabledBorder: outlineBorder.copyWith(borderSide: BorderSide(color: outline.withOpacity(.55))),

      focusedBorder: outlineBorder.copyWith(borderSide: BorderSide(color: primary, width: 2)),

      errorBorder: outlineBorder.copyWith(borderSide: BorderSide(color: scheme.error)),

      focusedErrorBorder: outlineBorder.copyWith(borderSide: BorderSide(color: scheme.error, width: 2)),

      labelStyle: TextStyle(color: scheme.onSurfaceVariant),

      hintStyle: TextStyle(color: scheme.onSurfaceVariant),

      prefixIconColor: primary,

      suffixIconColor: primary,

    ),

    filledButtonTheme: FilledButtonThemeData(

      style: FilledButton.styleFrom(

        backgroundColor: primary,

        foregroundColor: scheme.onPrimary,

        iconColor: scheme.onPrimary,

        disabledBackgroundColor: outline.withOpacity(.20),

        disabledForegroundColor: onSurface.withOpacity(.48),

        minimumSize: const Size(48, 54),

        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 14),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),

      ),

    ),

    outlinedButtonTheme: OutlinedButtonThemeData(

      style: OutlinedButton.styleFrom(

        foregroundColor: primary,

        iconColor: primary,

        side: BorderSide(color: outline.withOpacity(.7)),

        minimumSize: const Size(48, 52),

        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        textStyle: const TextStyle(fontWeight: FontWeight.w700),

      ),

    ),

    textButtonTheme: TextButtonThemeData(

      style: TextButton.styleFrom(foregroundColor: primary, iconColor: primary),

    ),

    iconButtonTheme: IconButtonThemeData(

      style: IconButton.styleFrom(foregroundColor: primary),

    ),

    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      surfaceTintColor: surface,
      elevation: 9,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: outline.withOpacity(.38)),
      ),
      textStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(

      backgroundColor: surface,

      indicatorColor: dark ? const Color(0xFF304C77) : const Color(0xFFE3EBFA),

      height: 78,

      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: onSurface, fontWeight: FontWeight.w600, fontSize: 12)),

      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(

        color: states.contains(WidgetState.selected) ? primary : scheme.onSurfaceVariant,

      )),

    ),

    navigationRailTheme: NavigationRailThemeData(

      backgroundColor: surface,

      selectedIconTheme: IconThemeData(color: primary),

      unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),

      indicatorColor: scheme.primaryContainer,

    ),

    bottomSheetTheme: BottomSheetThemeData(

      backgroundColor: surface,

      modalBackgroundColor: surface,

      showDragHandle: true,

      dragHandleColor: outline,

      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),

    ),

    dialogTheme: DialogThemeData(

      backgroundColor: surface,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),

    ),

    snackBarTheme: SnackBarThemeData(

      behavior: SnackBarBehavior.floating,

      backgroundColor: dark ? const Color(0xFF2A3E5A) : brandNavy,

      contentTextStyle: const TextStyle(color: Colors.white),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

    ),

    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8)),

    progressIndicatorTheme: ProgressIndicatorThemeData(

      color: dark ? brandGold : brandNavy,

      linearTrackColor: outline.withOpacity(.20),

    ),

    chipTheme: base.chipTheme.copyWith(

      backgroundColor: surface,

      selectedColor: scheme.primaryContainer,

      labelStyle: TextStyle(color: onSurface, fontWeight: FontWeight.w600),

      side: BorderSide(color: outline.withOpacity(.5)),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

    ),

  );

}

/// Selector de apariencia. Funciona en AppBar oscuro y en superficies normales.
class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = appearance.mode;
    final icon = current == ThemeMode.system
        ? Icons.brightness_auto_rounded
        : current == ThemeMode.dark
            ? Icons.dark_mode_rounded
            : Icons.light_mode_rounded;

    // Este selector se utiliza en los encabezados azules de la aplicación.
    // Se fija el contraste para impedir que el tema global lo oscurezca.
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Cambiar apariencia',
      initialValue: current,
      icon: Icon(icon, color: Theme.of(context).appBarTheme.foregroundColor ?? Colors.white),
      iconSize: 23,
      splashRadius: 24,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 7),
      constraints: const BoxConstraints(minWidth: 240, maxWidth: 300),
      color: scheme.surface,
      surfaceTintColor: scheme.surface,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outline.withOpacity(.40)),
      ),
      onSelected: appearance.setMode,
      itemBuilder: (menuContext) => [
        _themeItem(menuContext, ThemeMode.system,
            Icons.brightness_auto_rounded, 'Automático', 'Seguir el dispositivo'),
        _themeItem(menuContext, ThemeMode.light,
            Icons.light_mode_rounded, 'Tema claro', 'Fondos claros'),
        _themeItem(menuContext, ThemeMode.dark,
            Icons.dark_mode_rounded, 'Tema oscuro', 'Fondos oscuros'),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _themeItem(
    BuildContext context,
    ThemeMode value,
    IconData icon,
    String title,
    String detail,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = appearance.mode == value;
    final ink = colors.onSurface;
    final accent = colors.primary;

    return PopupMenuItem<ThemeMode>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: selected
              ? Border.all(color: accent.withOpacity(.40))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 23,
                color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: TextStyle(
                        color: selected ? colors.onPrimaryContainer : ink,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 3),
                  Text(detail,
                      style: TextStyle(
                        color: selected
                            ? colors.onPrimaryContainer.withOpacity(.83)
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded,
                  size: 20, color: colors.onPrimaryContainer),
            ],
          ],
        ),
      ),
    );
  }
}

class ResponsiveBody extends StatelessWidget {

  const ResponsiveBody({super.key, required this.child, this.maxWidth = 780});

  final Widget child;

  final double maxWidth;

  @override

  Widget build(BuildContext context) => SafeArea(

    child: Center(

      child: ConstrainedBox(

        constraints: BoxConstraints(maxWidth: maxWidth),

        child: child,

      ),

    ),

  );

}

class GroupBanner extends StatelessWidget {

  const GroupBanner({super.key});

  @override

  Widget build(BuildContext context) {

    final compact = MediaQuery.sizeOf(context).width < 360;

    final scaled = MediaQuery.textScalerOf(context).scale(16) > 24;

    return Container(

      margin: const EdgeInsets.only(bottom: 20),

      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [brandNavy, _navyLight, Color(0xFF0E2A5F)],

        ),

        borderRadius: BorderRadius.circular(26),

        border: Border.all(color: brandGold.withOpacity(.55)),

        boxShadow: [BoxShadow(color: brandNavy.withOpacity(.14), blurRadius: 20, offset: const Offset(0, 8))],

      ),

      child: Stack(children: [

        Positioned(right: -38, top: -55,

          child: Container(width: 160, height: 160,

            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: brandGold.withOpacity(.15), width: 20)))),

        Positioned(right: 20, bottom: -74,

          child: Container(width: 150, height: 150,

            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.06), width: 24)))),

        Padding(

          padding: EdgeInsets.all(compact ? 17 : 22),

          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if (compact || scaled)

              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                const GroupLogo(size: 58),

                const SizedBox(height: 14),

                _bannerText(),

              ])

            else

              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

                const GroupLogo(size: 66),

                const SizedBox(width: 17),

                Expanded(child: _bannerText()),

              ]),

            const SizedBox(height: 20),

            Container(height: 1, color: brandGold.withOpacity(.38)),

            const SizedBox(height: 12),

            const Row(children: [

              Icon(Icons.verified_outlined, color: brandGold, size: 16),

              SizedBox(width: 8),

              Expanded(child: Text('Tesorería · Transparencia y servicio',

                style: TextStyle(color: Color(0xFFE4EAF7), fontSize: 12, height: 1.4))),

            ]),

          ]),

        ),

      ]),

    );

  }

  Widget _bannerText() => const Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      Text('NARCÓTICOS ANÓNIMOS', style: TextStyle(color: brandGold, fontSize: 11, letterSpacing: 1.7, fontWeight: FontWeight.w700)),

      SizedBox(height: 7),

      Text('AMIGOS VERDADEROS', style: TextStyle(color: Colors.white, fontSize: 21, height: 1.22, fontWeight: FontWeight.w800)),

      SizedBox(height: 7),

      Text('Unidad · Servicio · Recuperación', style: TextStyle(color: Color(0xFFE4EAF7), fontSize: 13, height: 1.4)),

    ],

  );

}