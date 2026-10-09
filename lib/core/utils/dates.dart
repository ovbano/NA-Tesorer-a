const monthNames = <String>[
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

String monthLabel(DateTime month) =>
    '${monthNames[month.month - 1]} ${month.year}';

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
