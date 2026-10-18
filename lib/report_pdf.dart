import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'treasury.dart';
import 'rent_dues.dart';
import 'group_logo.dart';

/// Informe mensual listo para impresión A4 y lectura por terceros.
/// Conserva el contrato usado por Workspace.export().
Future<Uint8List> reportPdf(
  Json report, {
  Map<String, Uint8List> evidence = const {},
  bool includeEvidence = false,
}) async {
  report = rentReportData(report);
  final document = pw.Document(compress: true);
  final logo=pw.MemoryImage(groupLogoBytes);
  final funds = rows(report['funds']);
  final entries = rows(report['entries'])
      .where((entry) => entry['status'] == 'posted')
      .toList();
  final incomeEntries = entries.where((e) => e['kind'] == 'income').toList();
  final expenseEntries = entries.where((e) => e['kind'] == 'expense').toList();
  final history = report['dues_history'] is Map ? Json.from(report['dues_history'] as Map) : <String,dynamic>{};
  final roster = rows(report['dues_roster'] ?? history['members']);
  final totals = rentTotals(roster);
  final hasHistory = history['configured'] == true;
  final dues = rows(report['dues']);

  final navy = PdfColor.fromHex('#10284C');
  final navySoft = PdfColor.fromHex('#EAF0F8');
  final gold = PdfColor.fromHex('#D0AC62');
  final green = PdfColor.fromHex('#116947');
  final greenSoft = PdfColor.fromHex('#EAF5EE');
  final red = PdfColor.fromHex('#A62F39');
  final redSoft = PdfColor.fromHex('#FFF0F1');
  final muted = PdfColor.fromHex('#526178');
  final border = PdfColor.fromHex('#DBE3EC');
  final light = PdfColor.fromHex('#F6F8FB');

  num sumFund(String field) => funds.fold<num>(
        0,
        (total, fund) => total + ((fund[field] as num?) ?? 0),
      );

  final opening = sumFund('opening');
  final income = sumFund('income');
  final expense = sumFund('expense');
  final closing = sumFund('closing');
  String value(Object? input) => money(input);
  String safe(Object? input, {String fallback = '—'}) {
    final text = input?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String fundName(Object? name) => name == 'rent' ? 'Local' : 'General';

  final rawMonth = safe(report['month'], fallback: '');
  String periodText = rawMonth;
  if (rawMonth.length >= 7) {
    final year = int.tryParse(rawMonth.substring(0, 4));
    final month = int.tryParse(rawMonth.substring(5, 7));
    if (year != null && month != null && month >= 1 && month <= 12) {
      periodText = '${monthNames[month - 1]} $year';
    }
  }
  if (periodText.isEmpty) periodText = 'Período no indicado';

  pw.TextStyle style(double size,
          {PdfColor? color, bool bold = false, double? lineSpacing}) =>
      pw.TextStyle(
        fontSize: size,
        color: color ?? navy,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        lineSpacing: lineSpacing,
      );

  pw.Widget sectionTitle(String number, String title,
      {PdfColor? color, String? subtitle}) {
    final ink = color ?? navy;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Container(
            width: 25,
            height: 25,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: ink,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(number, style: style(10, color: PdfColors.white, bold: true)),
          ),
          pw.SizedBox(width: 9),
          pw.Expanded(child: pw.Text(title, style: style(13, color: ink, bold: true))),
        ]),
        if (subtitle != null) ...[
          pw.SizedBox(height: 5),
          pw.Text(subtitle, style: style(8.6, color: muted)),
        ],
        pw.SizedBox(height: 11),
      ],
    );
  }

  pw.Widget statCard(String label, Object? amount,
      {required PdfColor accent, required PdfColor background}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(9),
        border: pw.Border.all(color: border, width: .65),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: style(8.5, color: muted, bold: true)),
          pw.SizedBox(height: 6),
          pw.Text(value(amount), style: style(17, color: accent, bold: true)),
        ],
      ),
    );
  }

  pw.Widget dataTable(
    List<String> headers,
    List<List<String>> data, {
    List<double>? widths,
    PdfColor? headerColor,
  }) {
    if (data.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(13),
        decoration: pw.BoxDecoration(
          color: light,
          borderRadius: pw.BorderRadius.circular(7),
          border: pw.Border.all(color: border, width: .7),
        ),
        child: pw.Text('No existen registros confirmados en esta sección.',
            style: style(9.5, color: muted)),
      );
    }
    final columnWidths = widths == null
        ? null
        : <int, pw.TableColumnWidth>{
            for (var i = 0; i < widths.length; i++)
              i: pw.FlexColumnWidth(widths[i]),
          };
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      columnWidths: columnWidths,
      headerDecoration: pw.BoxDecoration(color: headerColor ?? navy),
      headerStyle: style(8.5, color: PdfColors.white, bold: true),
      cellStyle: style(8.1),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: border, width: .65),
        bottom: pw.BorderSide(color: border, width: .65),
      ),
      oddRowDecoration: pw.BoxDecoration(color: light),
      cellAlignments: {
        for (var i = 1; i < headers.length; i++)
          if (headers[i] == 'USD' || headers[i] == 'Inicio' ||
              headers[i] == 'Ingresos' || headers[i] == 'Egresos' ||
              headers[i] == 'Disponible' || headers[i] == 'Cuota' ||
              headers[i] == 'Recibido' || headers[i] == 'Pendiente' ||
              headers[i] == 'Deuda anterior' || headers[i] == 'Del mes' || headers[i] == 'Deuda total')
            i: pw.Alignment.centerRight,
      },
    );
  }

  String entryDescription(Json e) {
    final category = safe(categories[e['category']] ?? e['category'], fallback: 'Otra categoría');
    final description = safe(e['description'], fallback: 'Sin descripción');
    final member = safe(e['member_name'], fallback: '');
    return '$category\n$description${member.isEmpty ? '' : '\nCompañero: $member'}';
  }

  List<List<String>> entryRows(List<Json> list) => list
      .map((e) => [
            safe(e['entry_date']),
            entryDescription(e),
            fundName(e['fund']),
            value(e['amount_cents']),
          ])
      .toList();

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(37, 37, 37, 42),
      maxPages: 200,
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(width:44,height:44,padding:const pw.EdgeInsets.all(3),
                decoration:pw.BoxDecoration(border:pw.Border.all(color:gold,width:.8),borderRadius:pw.BorderRadius.circular(22)),
                child:pw.Image(logo,fit:pw.BoxFit.contain)),
              pw.SizedBox(width:12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('AMIGOS VERDADEROS',
                        style: style(15, color: navy, bold: true)),
                    pw.SizedBox(height: 3),
                    pw.Text('Narcóticos Anónimos  |  Tesorería del grupo',
                        style: style(8.8, color: muted)),
                  ],
                ),
              ),
              pw.Text('INFORME MENSUAL',
                  style: style(8, color: muted, bold: true)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(children:[pw.Expanded(child:pw.Container(height:1.3,color:navy)),pw.Container(height:1.3,width:68,color:gold)]),
        ],
      ),
      footer: (context) => pw.Column(
        children: [
          pw.Container(height: .6, color: border),
          pw.SizedBox(height: 7),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Amigos Verdaderos  |  Informe de Tesorería',
                  style: style(8, color: muted)),
              pw.Text('Página ${context.pageNumber} de ${context.pagesCount}  ·  USD',
                  style: style(8, color: muted)),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.SizedBox(height: 14),
        pw.Text('Estado financiero del período',
            style: style(20, bold: true)),
        pw.SizedBox(height: 4),
        pw.Text(periodText, style: style(12, color: muted, bold: true)),
        pw.SizedBox(height: 17),
        pw.Row(children: [
          pw.Expanded(
              child: statCard('SALDO INICIAL', opening,
                  accent: navy, background: navySoft)),
          pw.SizedBox(width: 9),
          pw.Expanded(
              child: statCard('INGRESOS', income,
                  accent: green, background: greenSoft)),
          pw.SizedBox(width: 9),
          pw.Expanded(
              child: statCard('EGRESOS', expense,
                  accent: red, background: redSoft)),
        ]),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: pw.BoxDecoration(
            color: navy,
            borderRadius: pw.BorderRadius.circular(9),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('DINERO DISPONIBLE AL CIERRE',
                  style: style(10, color: PdfColors.white, bold: true)),
              pw.Text(value(closing),
                  style: style(20, color: PdfColors.white, bold: true)),
            ],
          ),
        ),
        pw.SizedBox(height: 21),
        sectionTitle('01', 'Resumen por fondo',
            subtitle: 'Saldos y movimientos contabilizados por cada fondo.'),
        dataTable(
          ['Fondo', 'Inicio', 'Ingresos', 'Egresos', 'Disponible'],
          funds.map((f) => [
            fundName(f['fund']) == 'Local' ? 'Fondo para el local' : 'Fondo general',
            value(f['opening']),
            value(f['income']),
            value(f['expense']),
            value(f['closing']),
          ]).toList(),
          widths: [2.4, 1.4, 1.4, 1.4, 1.6],
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(11),
          decoration: pw.BoxDecoration(
            color: light,
            border: pw.Border.all(color: border, width: .6),
            borderRadius: pw.BorderRadius.circular(7),
          ),
          child: pw.Text(
            'Cómo interpretar el balance: el fondo general cubre los gastos del grupo; '
            'el fondo para el local se reserva para aportes y arriendo. '
            'Las cuotas pendientes y los borradores NO forman parte del dinero disponible.',
            style: style(9, color: muted, lineSpacing: 2),
          ),
        ),
        pw.SizedBox(height: 23),
        sectionTitle('02', 'Detalle de ingresos',
            color: green,
            subtitle: '${incomeEntries.length} movimiento(s) confirmado(s). ' 
                'El dinero recibido se presenta separado de los egresos.'),
        dataTable(
          ['Fecha', 'Concepto y detalle', 'Fondo', 'USD'],
          entryRows(incomeEntries),
          widths: [1.35, 4.6, 1.15, 1.35],
          headerColor: green,
        ),
        pw.SizedBox(height: 24),
        sectionTitle('03', 'Detalle de egresos',
            color: red,
            subtitle: '${expenseEntries.length} movimiento(s) confirmado(s). ' 
                'Gastos y pagos realizados durante el período.'),
        dataTable(
          ['Fecha', 'Concepto y detalle', 'Fondo', 'USD'],
          entryRows(expenseEntries),
          widths: [1.35, 4.6, 1.15, 1.35],
          headerColor: red,
        ),
        pw.SizedBox(height: 24),
        sectionTitle('04', 'Anexo privado · Aportes para arriendo',
            subtitle: 'Deuda individual de todos los compañeros registrados. '
                'Los pendientes son informativos y no forman parte del dinero disponible.'),
        if (hasHistory) ...[
          pw.Text('Estado hasta ${safe(history['through_month'])}. Deuda anterior: meses previos. '
              'Del mes: pendiente del período consultado. Total = anterior + del mes. '
              'Por configurar significa que falta confirmar el inicio, no una deuda de cero.',style:style(9,color:muted)),
          pw.SizedBox(height:10),
          dataTable(['Compañero','Deuda anterior','Del mes','Deuda total'],[
            ...roster.map((d)=>d['tracking']=='unconfigured'
              ? [safe(d['name']),'—','—','Por configurar']
              : [safe(d['name']),value(d['previous_pending']),value(d['current_pending']),value(d['total_pending'])]),
            ['TOTAL',value(totals['previous_pending']),value(totals['current_pending']),value(totals['total_pending'])]],
            widths:[3.4,1.6,1.4,1.6]),
          pw.SizedBox(height:18),
          sectionTitle('05','Detalle de meses y abonos',
              subtitle:'Los pagos se aplican al mes asignado y entran en caja en la fecha real de recepción. '
                  'Un excedente de un mes no cancela automáticamente otro.'),
          dataTable(['Compañero','Mes','Cuota','Recibido','Pendiente'],[
            for(final d in roster)
              for(final p in rows(d['periods']))
                [safe(d['name']),monthLabel(DateTime.parse(p['month'] as String)),value(p['expected']),value(p['paid']),value(p['pending'])]],
              widths:[2.6,2,1.1,1.1,1.2]),
        ] else ...[
          pw.Text('Historial acumulado no disponible. Los siguientes importes son solo del mes consultado; no confirman la deuda total.',style:style(9,color:red)),
          pw.SizedBox(height:10),
          dataTable(['Compañero','Cuota','Recibido','Pendiente'],dues.map((d)=>[
            safe(d['name']),value(d['expected']),value(d['paid']),
            value((rentAmount(d,'expected')-rentAmount(d,'paid')).clamp(0,100000000))]).toList(),widths:[3.9,1.3,1.3,1.5]),
        ],
        pw.SizedBox(height: 18),
        pw.Text('Notas de lectura', style: style(10, bold: true)),
        pw.SizedBox(height: 5),
        pw.Text(
          'El informe registra los movimientos confirmados del período seleccionado. '
          'El saldo disponible procede del reporte de los fondos. '
          'Los comprobantes, si se solicitan, aparecen al final como anexos independientes.',
          style: style(9, color: muted, lineSpacing: 2),
        ),
      ],
    ),
  );

  if (includeEvidence) {
    var annexNumber = 0;
    for (final e in entries.where((e) => e['receipt_path'] != null && !e['receipt_path'].toString().toLowerCase().endsWith('.pdf'))) {
      annexNumber++;
      final path = e['receipt_path'].toString();
      final imageBytes = evidence[path];
      pw.ImageProvider? image;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        try {
          image = pw.MemoryImage(imageBytes);
        } catch (_) {
          image = null;
        }
      }
      final isIncome = e['kind'] == 'income';
      final accent = isIncome ? green : red;
      document.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(37),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: navy,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('ANEXO $annexNumber  ·  COMPROBANTE',
                        style: style(13, color: PdfColors.white, bold: true)),
                    pw.SizedBox(height: 5),
                    pw.Text('Amigos Verdaderos  |  ${periodText}',
                        style: style(9, color: PdfColors.white)),
                  ],
                ),
              ),
              pw.SizedBox(height: 17),
              pw.Row(children: [
                pw.Expanded(child: pw.Text(
                    '${isIncome ? 'INGRESO' : 'EGRESO'}  ·  ${safe(e['entry_date'])}',
                    style: style(10, color: accent, bold: true))),
                pw.Text(value(e['amount_cents']),
                    style: style(16, color: accent, bold: true)),
              ]),
              pw.SizedBox(height: 9),
              pw.Text(entryDescription(e), style: style(10, color: navy)),
              pw.SizedBox(height: 13),
              pw.Container(height: 1, color: border),
              pw.SizedBox(height: 13),
              pw.Expanded(
                child: image == null
                    ? pw.Center(child: pw.Text(
                        'El comprobante no se pudo incorporar a este PDF.\n'
                        'Puedes consultar el archivo original desde Tesorería.',
                        textAlign: pw.TextAlign.center,
                        style: style(11, color: muted)))
                    : pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
              ),
              pw.SizedBox(height: 13),
              pw.Text('Anexo informativo  ·  Documento generado por Tesorería',
                  textAlign: pw.TextAlign.center,
                  style: style(8, color: muted)),
            ],
          ),
        ),
      );
    }
  }

  return document.save();
}
