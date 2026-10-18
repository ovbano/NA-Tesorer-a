import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'treasury.dart';
import 'rent_dues.dart';
import 'group_logo.dart';
import 'report_pdf_data.dart';

/// Documento A4 con secciones independientes y navegación visual constante.
/// Los importes del balance proceden del reporte, incluida su foto de cierre.
Future<Uint8List> reportPdf(Json report,{
  Map<String,Uint8List> evidence=const {},bool includeEvidence=false,
})async{
  report=rentReportData(report);
  final document=pw.Document(compress:true);
  final logo=pw.MemoryImage(groupLogoBytes);
  final funds=rows(report['funds']);
  final entries=pdfPostedEntries(report);
  final incomes=entries.where((e)=>e['kind']=='income').toList();
  final expenses=entries.where((e)=>e['kind']=='expense').toList();
  final history=report['dues_history'] is Map?Json.from(report['dues_history'] as Map):<String,dynamic>{};
  final roster=rows(report['dues_roster']??history['members']);
  final dues=rows(report['dues']);
  final debtTotals=rentTotals(roster);
  final closed=report['closure'] is Map;
  final closure=closed?Json.from(report['closure'] as Map):<String,dynamic>{};
  final periodLabel=pdfMonth(report['month']);
  final navy=PdfColor.fromHex('#10284C'),gold=PdfColor.fromHex('#B5944D');
  final pale=PdfColor.fromHex('#EDF2F8'),paper=PdfColor.fromHex('#FAF8F2');
  final green=PdfColor.fromHex('#146344'),red=PdfColor.fromHex('#A73348');
  final muted=PdfColor.fromHex('#566478'),line=PdfColor.fromHex('#DCE3EC');
  num sum(String key)=>funds.fold<num>(0,(total,f)=>total+((f[key] as num?)??0));
  String safe(Object? input,{String fallback='-'}) {
    final text=input?.toString().trim()??'';return text.isEmpty?fallback:text;
  }
  String fundName(Object? fund)=>fund=='rent'?'Local':'General';
  pw.TextStyle style(double size,{bool bold=false,PdfColor? color})=>pw.TextStyle(
    fontSize:size,color:color??navy,fontWeight:bold?pw.FontWeight.bold:pw.FontWeight.normal,
  );
  pw.Widget note(String text,{bool warning=false})=>pw.Container(
    width:double.infinity,padding:const pw.EdgeInsets.all(12),
    decoration:pw.BoxDecoration(color:warning?paper:pale,borderRadius:pw.BorderRadius.circular(7),
      border:pw.Border.all(color:line,width:.6)),
    child:pw.Text(text,style:style(9.4,color:muted)),
  );
  pw.Widget header(String section,{bool private=false})=>pw.Column(children:[
    pw.Row(crossAxisAlignment:pw.CrossAxisAlignment.center,children:[
      pw.Image(logo,width:40,height:40),pw.SizedBox(width:11),
      pw.Expanded(child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
        pw.Text('AMIGOS VERDADEROS',style:style(13,bold:true)),pw.SizedBox(height:4),
        pw.Text('Narcóticos Anónimos | Tesorería',style:style(8.5,color:muted)),
      ])),
      pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[
        pw.Text(periodLabel,style:style(9,bold:true)),pw.SizedBox(height:4),
        pw.Text(private?'ANEXO PRIVADO':'INFORME MENSUAL',style:style(7.5,color:muted)),
      ]),
    ]),
    pw.SizedBox(height:11),pw.Row(children:[pw.Expanded(child:pw.Container(height:1,color:navy)),pw.Container(width:68,height:1,color:gold)]),
    pw.SizedBox(height:7),pw.Align(alignment:pw.Alignment.centerLeft,child:pw.Text(section.toUpperCase(),style:style(8,color:muted))),
    pw.SizedBox(height:12),
  ]);
  pw.Widget footer(pw.Context context)=>pw.Column(children:[
    pw.SizedBox(height:10),pw.Container(height:.6,color:line),pw.SizedBox(height:7),
    pw.Row(children:[pw.Expanded(child:pw.Text('Amigos Verdaderos | $periodLabel',style:style(8,color:muted))),
      pw.Text('${context.pageNumber} / ${context.pagesCount}  -  USD',style:style(8,color:muted))]),
  ]);
  void section(String name,List<pw.Widget> content,{bool private=false}){
    document.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,
      margin:const pw.EdgeInsets.fromLTRB(38,28,38,28),maxPages:200,
      header:(context)=>header(name,private:private),footer:footer,build:(context)=>content));
  }
  pw.Widget heading(String number,String title,String subtitle,{PdfColor? accent})=>pw.Padding(
    padding:const pw.EdgeInsets.only(bottom:16),child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text('$number  /  TESORERÍA',style:style(8,bold:true,color:accent??gold)),pw.SizedBox(height:7),
      pw.Text(title,style:style(21,bold:true)),pw.SizedBox(height:7),pw.Text(subtitle,style:style(9.5,color:muted)),
    ]));
  pw.Widget table(List<String> headers,List<List<String>> data,List<double> widths,{
    List<int> numeric=const [],bool totalLast=false,PdfColor? accent,
  }){
    if(data.isEmpty)return note('No hay registros confirmados en esta sección.');
    pw.Widget cell(String value,int column,{bool head=false,bool total=false})=>pw.Container(
      padding:const pw.EdgeInsets.symmetric(horizontal:6,vertical:8),
      alignment:numeric.contains(column)?pw.Alignment.topRight:pw.Alignment.topLeft,
      child:pw.Text(value,style:style(head?9:9.4,bold:head||total,color:head?PdfColors.white:navy),
        textAlign:numeric.contains(column)?pw.TextAlign.right:pw.TextAlign.left),
    );
    return pw.Table(columnWidths:{for(var i=0;i<widths.length;i++)i:pw.FlexColumnWidth(widths[i])},
      border:pw.TableBorder(horizontalInside:pw.BorderSide(color:line,width:.45),bottom:pw.BorderSide(color:line,width:.6)),
      children:[
        pw.TableRow(repeat:true,decoration:pw.BoxDecoration(color:accent??navy),
          children:[for(var i=0;i<headers.length;i++)cell(headers[i],i,head:true)]),
        for(var row=0;row<data.length;row++)pw.TableRow(
          decoration:pw.BoxDecoration(color:totalLast&&row==data.length-1?pale:row.isEven?PdfColor.fromHex('#F6F8FB'):PdfColors.white),
          children:[for(var col=0;col<data[row].length;col++)cell(data[row][col],col,total:totalLast&&row==data.length-1)]),
      ]);
  }
  pw.Widget totalBand(String label,Object? value,{PdfColor? accent})=>pw.Container(
    padding:const pw.EdgeInsets.all(15),decoration:pw.BoxDecoration(color:accent??navy,borderRadius:pw.BorderRadius.circular(8)),
    child:pw.Row(children:[pw.Expanded(child:pw.Text(label,style:style(10,bold:true,color:PdfColors.white))),pw.SizedBox(width:12),
      pw.Text(money(value),style:style(22,bold:true,color:PdfColors.white))]),
  );
  pw.Widget metric(String label,num value,PdfColor accent)=>pw.Container(
    padding:const pw.EdgeInsets.all(13),decoration:pw.BoxDecoration(color:pale,borderRadius:pw.BorderRadius.circular(7)),
    child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Text(label,style:style(9,color:muted)),
      pw.SizedBox(height:8),pw.Text(money(value),style:style(17,bold:true,color:accent))]),
  );

  final balanceRows=<List<String>>[
    for(final f in funds)[f['fund']=='rent'?'Reserva para el local':'Fondo general',money(f['opening']),money(f['income']),money(f['expense']),money(f['closing'])],
    ['TOTAL',money(sum('opening')),money(sum('income')),money(sum('expense')),money(sum('closing'))],
  ];
  section('Resumen financiero',[
    heading('01','Informe de tesorería',periodLabel),
    pw.Text(closed?'MES CERRADO':'PROVISIONAL - MES ABIERTO',style:style(9,bold:true,color:closed?green:muted)),
    pw.SizedBox(height:5),pw.Text('Emitido el ${pdfDate(iso(today()))}',style:style(8.5,color:muted)),pw.SizedBox(height:17),
    pw.Row(children:[pw.Expanded(child:metric('Al iniciar',sum('opening'),navy)),pw.SizedBox(width:9),
      pw.Expanded(child:metric('Ingresos',sum('income'),green)),pw.SizedBox(width:9),pw.Expanded(child:metric('Egresos',sum('expense'),red))]),
    pw.SizedBox(height:13),totalBand('DINERO DEL GRUPO AL FINALIZAR',sum('closing')),pw.SizedBox(height:20),
    pw.Text('Así se distribuye el dinero',style:style(13,bold:true)),pw.SizedBox(height:10),
    table(['Fondo','Al iniciar','Ingresos','Egresos','Al finalizar'],balanceRows,[2.5,1.4,1.4,1.4,1.6],numeric:[1,2,3,4],totalLast:true),
    pw.SizedBox(height:14),note('El fondo general cubre los gastos del grupo. La reserva del local se aparta para el arriendo. Ambos forman el total; la reserva no es dinero libre para otros gastos.'),
    pw.SizedBox(height:9),note('Al finalizar = saldo inicial + ingresos - egresos. Las deudas pendientes, los borradores y los movimientos anulados no se suman al dinero disponible.'),
    if(incomes.isEmpty||expenses.isEmpty)...[pw.SizedBox(height:12),pw.Text([
      if(incomes.isEmpty)'No hubo ingresos confirmados en este período.',if(expenses.isEmpty)'No hubo egresos confirmados en este período.',
    ].join(' '),style:style(9,color:muted))],
    if(closed)...[
      pw.SizedBox(height:16),pw.Text('Revisión del cierre',style:style(12,bold:true)),pw.SizedBox(height:8),
      table(['Dato','Registro'],[
        if(closure['closed_name']!=null)['Revisado por',safe(closure['closed_name'])],
        if(closure['counted_cents'] is num)['Dinero contado',money(closure['counted_cents'])],
        if(closure['difference_cents'] is num)['Diferencia con el registro',money(closure['difference_cents'])],
      ],[2.6,5.4]),
      if(safe(closure['note'],fallback:'').isNotEmpty)...[
        pw.SizedBox(height:8),for(final chunk in pdfTextChunks('Observación: ${closure['note']}'))pw.Padding(padding:const pw.EdgeInsets.only(bottom:5),child:pw.Text(chunk,style:style(9,color:muted))),
      ],
    ],
  ]);

  void movements(List<Json> list,{required bool income}){
    if(list.isEmpty)return;
    final detailRows=<List<String>>[];
    for(final e in list){
      final chunks=pdfTextChunks(pdfConcept(e));
      for(var i=0;i<chunks.length;i++)detailRows.add([
        safe(e['report_ref']),i==0?pdfDate(e['entry_date']):'',chunks[i],
        i==0?fundName(e['fund']):'',i==0?money(e['amount_cents']):'',
      ]);
    }
    final accent=income?green:red;
    final amount=list.fold<num>(0,(sum,e)=>sum+((e['amount_cents'] as num?)??0));
    section(income?'Ingresos':'Egresos',[
      heading(income?'02':'03',income?'Ingresos del período':'Egresos del período',
        '${list.length} movimientos confirmados. Ordenados por fecha y separados por fondo.',accent:accent),
      table(['Ref.','Fecha','Concepto y compañero','Fondo','USD'],detailRows,[.7,1.2,4.65,1.1,1.35],numeric:[4],accent:accent),
      pw.SizedBox(height:14),table(['Totales de esta sección','General','Local','TOTAL'],[
        [income?'Ingresos confirmados':'Egresos confirmados',
          for(final fund in ['general','rent'])money(list.where((e)=>e['fund']==fund).fold<num>(0,(sum,e)=>sum+((e['amount_cents'] as num?)??0))),money(amount)],
      ],[3.4,1.5,1.5,1.6],numeric:[1,2,3],totalLast:true),
    ]);
  }
  movements(incomes,income:true);movements(expenses,income:false);

  section('Aportes para arriendo',[
    heading('04','Anexo privado de arriendo','Deuda individual de todos los compañeros registrados. Estos pendientes son informativos y no son dinero en caja.'),
    if(history['configured']==true)...[
      note('Estado hasta ${pdfMonth(history['through_month'])}. Deuda anterior: meses previos. Del mes: pendiente del período consultado. Deuda total = anterior + del mes.'),
      pw.SizedBox(height:12),table(['Compañero','Deuda anterior','Del mes','Deuda total'],[
        for(final d in roster)d['tracking']=='unconfigured'?[safe(d['name']),'-','-','Por configurar']:
          [safe(d['name']),money(d['previous_pending']),money(d['current_pending']),money(d['total_pending'])],
        ['TOTAL CALCULADO',money(debtTotals['previous_pending']),money(debtTotals['current_pending']),money(debtTotals['total_pending'])],
      ],[3.7,1.5,1.4,1.6],numeric:[1,2,3],totalLast:true),
      pw.SizedBox(height:12),note('Por configurar significa que falta confirmar el inicio de su cuota; no equivale a una deuda de cero. El total calculado solo reúne las participaciones configuradas.'),
    ]else ...[
      note('No se pudo obtener el historial acumulado. La tabla siguiente muestra solo el mes consultado y no confirma la deuda total.',warning:true),pw.SizedBox(height:12),
      table(['Compañero','Cuota','Recibido','Pendiente'],[
        for(final d in dues)[safe(d['name']),money(d['expected']),money(d['paid']),money((rentAmount(d,'expected')-rentAmount(d,'paid')).clamp(0,100000000))],
      ],[3.7,1.5,1.4,1.6],numeric:[1,2,3]),
    ],
  ],private:true);
  final periodRows=<List<String>>[
    for(final d in roster)for(final p in rows(d['periods']))[
      safe(d['name']),pdfMonth(p['month']),money(p['expected']),money(p['paid']),money(p['pending'])],
  ];
  if(history['configured']==true&&periodRows.isNotEmpty)section('Cuotas y abonos por mes',[
    heading('05','Detalle de cuotas y abonos','Consulta qué mes corresponde a cada obligación y cuánto se ha recibido.'),
    table(['Compañero','Mes','Cuota','Recibido','Pendiente'],periodRows,[3,2,1.2,1.2,1.3],numeric:[2,3,4]),
    pw.SizedBox(height:12),note('El pago se descuenta del mes asignado y entra a caja en su fecha real de recepción. Un excedente de una cuota no cancela automáticamente otros meses.'),
  ],private:true);

  final receipts=entries.where((e)=>safe(e['receipt_path'],fallback:'').isNotEmpty).toList();
  if(receipts.isNotEmpty)section('Índice de comprobantes',[
    heading('06','Comprobantes del período','La referencia coincide con las tablas de ingresos y egresos.'),
    table(['Ref.','Fecha','Fondo','USD','Documento'],[
      for(final e in receipts)[safe(e['report_ref']),pdfDate(e['entry_date']),fundName(e['fund']),money(e['amount_cents']),
        e['receipt_path'].toString().toLowerCase().endsWith('.pdf')?'PDF original':'Fotografía'],
    ],[.8,1.8,1.4,1.5,2.5],numeric:[3]),
    pw.SizedBox(height:12),note(includeEvidence?'Las fotografías disponibles se incluyen a continuación. Los PDF originales se consultan desde el movimiento en Tesorería.':'Las fotografías no se incluyeron en esta exportación. Los originales se conservan en los movimientos de Tesorería.'),
  ]);
  if(includeEvidence){
    final groups=<String,List<Json>>{};
    for(final e in receipts){final path=e['receipt_path'].toString();if(!path.toLowerCase().endsWith('.pdf'))(groups[path]??=<Json>[]).add(e);}
    for(final group in groups.entries){
      final refs=group.value.map((e)=>safe(e['report_ref'])).toList();
      final references=refs.take(3).join(', ')+(refs.length>3?' (${refs.length} movimientos)':'');
      pw.ImageProvider? image;
      final bytes=evidence[group.key];
      if(bytes!=null&&bytes.isNotEmpty){try{image=pw.MemoryImage(bytes);}catch(_){image=null;}}
      section('Comprobante $references',[
        heading('ANEXO','Comprobante $references','Fotografía asociada a los movimientos indicados.'),
        table(['Ref.','Fecha','Fondo','USD'],[
          for(final e in group.value)[safe(e['report_ref']),pdfDate(e['entry_date']),fundName(e['fund']),money(e['amount_cents'])],
        ],[1,2.5,2.5,2],numeric:[3]),
        pw.SizedBox(height:14),
        if(image==null)note('No se pudo incorporar esta fotografía. Consulta el original desde el movimiento en Tesorería.',warning:true)
        else pw.Container(height:430,padding:const pw.EdgeInsets.all(6),decoration:pw.BoxDecoration(border:pw.Border.all(color:line,width:.8)),
          child:pw.Center(child:pw.Image(image,width:507,height:416,fit:pw.BoxFit.contain))),
      ]);
    }
  }
  return document.save();
}
