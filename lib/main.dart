import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:na_tesoreria/app/treasury_app.dart';
import 'package:na_tesoreria/core/config/public_key.dart';
import 'package:na_tesoreria/core/config/supabase_config.dart';
import 'package:na_tesoreria/core/theme/brand.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: publicSupabaseUrl);
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: publicSupabaseKey);
  if (url.isEmpty || !isPublicKey(key)) {
    runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Configura la URL y una clave pública de Supabase (anon o publishable). '
                'Nunca uses una clave administrativa. Sigue la guía del proyecto y '
                'ejecuta con --dart-define-from-file=config.local.json.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ));
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  await appearance.load();
  runApp(const TreasuryApp());
}
