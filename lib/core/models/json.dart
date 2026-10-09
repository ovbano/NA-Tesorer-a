/// Estructuras y contratos compartidos por todas las pantallas de Tesorería.
/// Los importes se expresan siempre en centavos enteros.
typedef Json = Map<String, dynamic>;

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
