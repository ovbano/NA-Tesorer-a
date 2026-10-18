import 'treasury.dart';

/// No recalcula obligaciones: el servidor determina los meses y sus saldos.
/// Se enlaza por ID, nunca por coincidencias de nombres.
List<Json> rentRoster(Json history, List<Json> members, List<Json> companions) {
  final byId = {for (final row in rows(history['members'])) row['id']: row};
  final used = <Object?>{};
  Json configured(Json member, [Json? companion]) {
    used.add(member['id']);
    final row = byId[member['id']];
    return {
      ...?row,
      if (row == null) ...{
        ...member, 'previous_pending': 0, 'current_pending': 0,
        'total_pending': 0, 'periods': <Json>[],
      },
      'name': companion?['name'] ?? member['name'],
      'source_id': companion?['id'] ?? member['source_anniversary_id'],
      'tracking': row == null ? 'not_due' : 'configured',
    };
  }
  final result = <Json>[];
  for (final companion in companions) {
    final linked = members.where((m) => m['source_anniversary_id'] == companion['id']);
    result.add(linked.isNotEmpty ? configured(linked.first, companion) : {
      'id': 'source:${companion['id']}', 'source_id': companion['id'],
      'name': companion['name'], 'tracking': 'unconfigured',
      'previous_pending': null, 'current_pending': null,
      'total_pending': null, 'periods': <Json>[],
    });
  }
  for (final member in members) {
    if (!used.contains(member['id'])) result.add(configured(member));
  }
  for (final row in byId.values) {
    if (used.add(row['id'])) result.add({...row, 'tracking': 'configured'});
  }
  result.sort((a, b) => rentSearchKey(a['name']).compareTo(rentSearchKey(b['name'])));
  return result;
}

String rentSearchKey(Object? input) {
  var text = (input ?? '').toString().trim().toLowerCase();
  const accents = 'áéíóúüñ';
  const plain = 'aeiouun';
  for (var i = 0; i < accents.length; i++) {
    text = text.replaceAll(accents[i], plain[i]);
  }
  return text;
}

int rentAmount(Json row, String field) => (row[field] as num?)?.toInt() ?? 0;
String rentStatus(Json row) => row['tracking'] == 'unconfigured'
    ? 'Inicio por configurar'
    : row['tracking'] == 'not_due' ? 'Sin cuotas en este período'
    : rentAmount(row, 'total_pending') > 0 ? 'Con deuda pendiente' : 'Al día';

List<Json> filterRent(List<Json> roster, String query, String status) =>
    roster.where((row) {
      final unknown = row['tracking'] == 'unconfigured';
      final pending = rentAmount(row, 'total_pending');
      return rentSearchKey(row['name']).contains(rentSearchKey(query)) &&
          (status == 'all' || (status == 'unconfigured' ? unknown :
            !unknown && (status == 'pending' ? pending > 0 : status == 'partial'
              ? pending > 0 && rows(row['periods']).any((p) => rentAmount(p,'paid') > 0)
              : pending == 0)));
    }).toList();

Json rentTotals(List<Json> roster) => {
  for (final key in ['previous_pending', 'current_pending', 'total_pending'])
    key: roster.where((row) => row['tracking'] != 'unconfigured')
        .fold<int>(0, (sum, row) => sum + rentAmount(row, key)),
};

/// El cierre mantiene su foto financiera; el anexo usa el historial solicitado.
Json rentReportData(Json input) {
  final closure = input['closure'];
  final summary = closure is Map ? closure['summary'] : null;
  return summary is Map ? {
    ...Json.from(summary), 'closure': closure,
    'dues_history': input['dues_history'], 'dues_roster': input['dues_roster'],
  } : input;
}
