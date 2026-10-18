import 'treasury.dart';

/// Adaptadores exclusivos del informe: no alteran registros ni saldos.
List<Json> pdfPostedEntries(Json report) {
  final entries=rows(report['entries']).where((e)=>e['status']=='posted').toList();
  entries.sort((a,b){
    final date=(a['entry_date']??'').toString().compareTo((b['entry_date']??'').toString());
    return date!=0?date:(a['created_at']??a['id']??'').toString().compareTo((b['created_at']??b['id']??'').toString());
  });
  var income=0,expense=0;
  return entries.map((e)=>{...e,'report_ref':e['kind']=='income'?'I${(++income).toString().padLeft(2,'0')}':'E${(++expense).toString().padLeft(2,'0')}'}).toList();
}

/// Limita la altura de cada fila conservando todo el texto, incluso palabras
/// largas. Las filas de continuación no vuelven a incluir importes.
List<String> pdfTextChunks(String text,{int limit=210}) {
  if(limit<1)throw ArgumentError.value(limit,'limit');
  final runes=text.runes.toList();
  if(runes.isEmpty)return [''];
  final result=<String>[];
  for(var start=0;start<runes.length;){
    var end=(start+limit).clamp(0,runes.length).toInt();
    var breaks=0;
    for(var i=start;i<end;i++){if(runes[i]==10&&++breaks>=5){end=i+1;break;}}
    if(end<runes.length){
      for(var i=end-1;i>start+limit~/2;i--){if(runes[i]==32||runes[i]==10){end=i+1;break;}}
    }
    result.add(String.fromCharCodes(runes.sublist(start,end)));
    start=end;
  }
  return result;
}

String pdfDate(Object? input) {
  final text=input?.toString()??'';
  final date=DateTime.tryParse(text);
  return date==null?'Sin fecha':'${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';
}
String pdfMonth(Object? input) {
  final date=DateTime.tryParse(input?.toString()??'');
  return date==null?'Período no indicado':monthLabel(date);
}
String pdfConcept(Json entry) {
  final description=(entry['description']??'').toString().trim();
  final category=categories[entry['category']]??'Otro movimiento';
  final member=(entry['member_name']??'').toString().trim();
  return [description.isEmpty?category:description,
    if(description.isNotEmpty&&description!=category)category,
    if(member.isNotEmpty)'Compañero: $member',
    if(entry['due_month']!=null)'Cuota asignada a ${pdfMonth(entry['due_month'])}',
  ].join('\n');
}
