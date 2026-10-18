import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Estructuras y contratos compartidos por todas las pantallas de Tesorería.
/// Los importes se expresan siempre en centavos enteros.
typedef Json = Map<String, dynamic>;

/// Claves persistidas en la base de datos: no cambiar sin migración.
const categories = <String, String>{
  'seventh': 'Séptima tradición',
  'rent_contribution': 'Aporte para el local',
  'other_income': 'Otro ingreso',
  'rent': 'Arriendo',
  'supplies': 'Café, azúcar e insumos',
  'literature': 'Literatura',
  'service': 'Servicio / área',
  'event': 'Actividad del grupo',
  'other_expense': 'Otro gasto',
};

const incomeCategories = <String>[
  'seventh',
  'rent_contribution',
  'other_income',
];

const monthNames = <String>[
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String monthLabel(DateTime month) =>
    '${monthNames[month.month - 1]} ${month.year}';

/// Formato monetario de la aplicación: $142,19 / -$7,00.
/// No realiza operaciones con doubles, para evitar errores de redondeo.
String money(Object? value) {
  final centsValue = value is num ? value.toInt() : 0;
  final absolute = centsValue.abs();
  final whole = absolute ~/ 100;
  final decimal = (absolute % 100).toString().padLeft(2, '0');
  return '${centsValue < 0 ? '-' : ''}\$$whole,$decimal';
}

/// Fecha civil de Ecuador continental (UTC-05:00), independiente de la
/// zona horaria configurada en el teléfono. No es una conversión para
/// operaciones con marcas de tiempo de Supabase.
DateTime today() {
  final ecuador = DateTime.now().toUtc().subtract(const Duration(hours: 5));
  return DateTime(ecuador.year, ecuador.month, ecuador.day);
}

String iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String period(DateTime date) => iso(DateTime(date.year, date.month));

/// Convierte USD introducidos por el usuario a centavos sin usar double.
/// Se admite punto o coma decimal, hasta dos decimales y máximo $1.000.000.
/// Un campo vacío puede ser null exclusivamente para borradores.
int? cents(String text, {bool optional = false}) {
  final input = text.trim().replaceAll(',', '.');
  if (input.isEmpty && optional) return null;

  final valid = RegExp(r'^\d{1,7}(\.\d{1,2})?$');
  if (!valid.hasMatch(input)) {
    throw const FormatException(
      'Escribe un monto válido con hasta dos decimales.',
    );
  }

  final parts = input.split('.');
  final whole = int.parse(parts[0]);
  final fraction = parts.length == 1
      ? 0
      : int.parse(parts[1].padRight(2, '0'));
  final result = whole * 100 + fraction;

  if (result > 100000000) {
    throw const FormatException('El monto supera el límite permitido.');
  }
  return result;
}

/// Convierte listas provenientes de RPC en mapas independientes.
/// Mantiene la interfaz utilizada en workspace y editores.
List<Json> rows(dynamic value) {
  if (value == null) return <Json>[];
  if (value is! List) {
    throw const FormatException('El servidor devolvió una lista no válida.');
  }
  return value.map<Json>((item) {
    if (item is! Map) {
      throw const FormatException('El servidor devolvió un registro no válido.');
    }
    return Json.from(item);
  }).toList();
}

/// Mensajes aptos para mostrar al usuario, sin exponer detalles internos.
String message(Object error) {
  if (error is FormatException) return error.message;
  if (error is AuthException) {
    return 'No se pudo iniciar o actualizar la sesión. '
        'Revisa tus credenciales y conexión.';
  }
  if (error is PostgrestException) {
    // Se conserva el mensaje de la RPC, que puede contener validaciones
    // financieras relevantes para el usuario.
    return error.message;
  }
  if (error is StorageException) {
    return 'No se pudo guardar o abrir el comprobante. '
        'Revisa tu conexión y vuelve a intentar.';
  }
  return 'No se pudo completar la operación. '
      'Comprueba tu conexión e intenta nuevamente.';
}

/// Verifica exclusivamente la forma de una clave pública de Supabase.
/// NO certifica la autenticidad ni la validez criptográfica del token.
bool isPublicKey(String key) {
  final trimmed = key.trim();
  if (trimmed.startsWith('sb_publishable_')) return true;

  try {
    final pieces = trimmed.split('.');
    if (pieces.length != 3) return false;
    final decoded = utf8.decode(
      base64Url.decode(base64Url.normalize(pieces[1])),
    );
    final payload = jsonDecode(decoded);
    return payload is Map && payload['role'] == 'anon';
  } catch (_) {
    return false;
  }
}

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