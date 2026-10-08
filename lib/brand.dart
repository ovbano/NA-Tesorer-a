import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_logo.dart';

const brandNavy = Color(0xff071d49);
const brandGold = Color(0xffd9b96d);
final appearance = Appearance();
class Appearance extends ChangeNotifier {
  ThemeMode mode = ThemeMode.system;
  SharedPreferences? preferences;
  Future<void> load() async {
    try {
      preferences = await SharedPreferences.getInstance();
      final saved = preferences!.getString('appearance');
      mode = saved == 'dark' ? ThemeMode.dark : saved == 'light' ? ThemeMode.light : ThemeMode.system;
    } catch (_) { mode = ThemeMode.system; }
  }
  Future<void> setMode(ThemeMode next) async {
    mode = next;
    notifyListeners();
    try { await preferences?.setString('appearance', next.name); } catch (_) { /* Keep the selected theme for this session. */ }
  }
}
ThemeData groupTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: brandNavy, brightness: brightness).copyWith(
    primary: dark ? const Color(0xffb6caff) : brandNavy,
    secondary: dark ? brandGold : const Color(0xff77591f),
    surface: dark ? const Color(0xff14223b) : Colors.white,
  );
  final base = ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xff0b1426) : const Color(0xfff3f5fa),
    textTheme: base.textTheme.apply(fontSizeFactor: 1.04),
    appBarTheme: const AppBarTheme(backgroundColor: brandNavy, foregroundColor: Colors.white, elevation: 0, toolbarHeight: 76),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: scheme.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.outline.withOpacity(.35))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: scheme.primary, width: 2))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(48, 56), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surface, indicatorColor: dark ? const Color(0xff34496b) : const Color(0xffe5eafa), height: 80),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, showDragHandle: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28)))),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8)),
  );
}
class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});
  @override Widget build(BuildContext context) => PopupMenuButton<ThemeMode>(
    tooltip: 'Cambiar apariencia', initialValue: appearance.mode,
    icon: Icon(Theme.of(context).brightness == Brightness.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
    onSelected: (mode) { appearance.setMode(mode); },
    itemBuilder: (_) => const [PopupMenuItem(value: ThemeMode.system, child: Text('Usar tema del dispositivo')), PopupMenuItem(value: ThemeMode.light, child: Text('Tema claro')), PopupMenuItem(value: ThemeMode.dark, child: Text('Tema oscuro'))],
  );
}
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 780});
  final Widget child;
  final double maxWidth;
  @override Widget build(BuildContext context) => SafeArea(child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child)));
}
class GroupBanner extends StatelessWidget {
  const GroupBanner({super.key});
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18), padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [brandNavy, Color(0xff173f83)]), borderRadius: BorderRadius.circular(26)),
    child: Row(children: [const GroupLogo(size: 62), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('AMIGOS VERDADEROS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)), SizedBox(height: 6), Text('Unidad · Servicio · Recuperación', style: TextStyle(color: brandGold, height: 1.5))]))]),
  );
}
