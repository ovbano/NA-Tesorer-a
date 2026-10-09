/// Formato monetario de la aplicación: $142,19 / -$7,00.
/// No realiza operaciones con doubles, para evitar errores de redondeo.
String money(Object? value) {
  final centsValue = value is num ? value.toInt() : 0;
  final absolute = centsValue.abs();
  final whole = absolute ~/ 100;
  final decimal = (absolute % 100).toString().padLeft(2, '0');
  return '${centsValue < 0 ? '-' : ''}\$$whole,$decimal';
}

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
