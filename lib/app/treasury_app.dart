import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:na_tesoreria/core/theme/brand.dart';
import 'package:na_tesoreria/features/auth/presentation/auth_gate.dart';

class TreasuryApp extends StatelessWidget {
  const TreasuryApp({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appearance,
        builder: (context, _) => MaterialApp(
          title: 'Amigos Verdaderos · Tesorería',
          debugShowCheckedModeBanner: false,
          locale: const Locale('es', 'EC'),
          supportedLocales: const [Locale('es', 'EC')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: groupTheme(Brightness.light),
          darkTheme: groupTheme(Brightness.dark),
          themeMode: appearance.mode,
          themeAnimationDuration: const Duration(milliseconds: 280),
          home: const AuthGate(),
        ),
      );
}
