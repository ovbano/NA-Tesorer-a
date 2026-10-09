import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:na_tesoreria/core/models/json.dart';
import 'package:na_tesoreria/core/utils/dates.dart';

/// Acceso a datos del grupo. Las reglas de autorización deben seguir
/// aplicándose también en Supabase (RLS y funciones RPC).
class TreasuryRepository {
  TreasuryRepository(this.client);

  final SupabaseClient client;

  /// Confirma sesión y rol activo antes de habilitar áreas protegidas.
  Future<Json> profile() async {
    final response = await client.auth.getUser();
    final id = response.user?.id;
    if (id == null) {
      throw const FormatException('Inicia sesión para continuar.');
    }

    final profile = await client
        .from('profiles')
        .select('id,display_name,role,active')
        .eq('id', id)
        .maybeSingle();

    if (profile == null ||
        profile['active'] != true ||
        !const <String>['admin', 'treasurer', 'auditor']
            .contains(profile['role'])) {
      throw const FormatException(
        'Tu cuenta no tiene acceso activo a Tesorería. '
        'Contacta al administrador.',
      );
    }
    return Json.from(profile);
  }

  Future<Json?> settings() async {
    final result = await client.from('treasury_settings').select().maybeSingle();
    return result == null ? null : Json.from(result);
  }

  Future<Json> report(DateTime month) async {
    final result = await client.rpc(
      'treasury_report',
      params: {'p_month': period(month)},
    );
    return _jsonResult(result, 'informe mensual');
  }

  /// Paginación estable en lotes de 500, sin recortar registros del grupo.
  Future<List<Json>> all(String table, {String? status}) async {
    final data = <Json>[];
    const pageSize = 500;

    for (var offset = 0; ; offset += pageSize) {
      var query = client.from(table).select();
      if (status != null) query = query.eq('status', status);

      final page = await query
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);
      data.addAll(rows(page));

      if (page.length < pageSize) return data;
    }
  }

  Future<List<Json>> companions() async {
    final result = await client.rpc('treasury_companions');
    return rows(result);
  }

  /// No modifica acciones, nombres de parámetros ni payloads del backend.
  Future<Json> command(String action, Json data) async {
    final result = await client.rpc(
      'treasury_command',
      params: {'p_action': action, 'p_data': data},
    );
    return _jsonResult(result, 'operación de Tesorería');
  }

  Json _jsonResult(dynamic result, String operation) {
    if (result is! Map) {
      throw FormatException(
        'El servidor no devolvió un resultado válido para $operation.',
      );
    }
    return Json.from(result);
  }
}
