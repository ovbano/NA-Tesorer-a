import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_tesoreria/treasury.dart';
import 'package:na_tesoreria/report_pdf.dart';
import 'package:na_tesoreria/report_pdf_data.dart';

Json fixture()=>{'month':'2026-10-01','funds':[
  {'fund':'general','opening':10000,'income':1200,'expense':500,'closing':10700},
  {'fund':'rent','opening':2200,'income':1200,'expense':0,'closing':3400}],
  'entries':<Json>[],'dues':<Json>[],'dues_history':{
    'configured':true,'through_month':'2026-10-01','members':<Json>[]}};
Json entry(String id,String kind,{String status='posted',String date='2026-10-01',String? receipt})=>{
  'id':id,'status':status,'entry_date':date,'kind':kind,
  'category':kind=='income'?'rent_contribution':'supplies','fund':kind=='income'?'rent':'general',
  'amount_cents':1200,'description':'Descripción del movimiento','member_name':'Compañero de prueba',
  if(receipt!=null)'receipt_path':receipt,
};
void validPdf(Uint8List data){expect(String.fromCharCodes(data.take(5)),'%PDF-');expect(data.length,greaterThan(1000));}

void main(){
  test('Movement references are chronological and exclude drafts/voids without changing cents',(){
    final report=fixture();report['entries']=[entry('2','expense',date:'2026-10-03'),entry('draft','income',status:'draft'),entry('1','income'),entry('void','expense',status:'void')];
    final before=jsonEncode(report);final rows=pdfPostedEntries(report);
    expect(rows.map((e)=>e['report_ref']),['I01','E01']);expect(rows.map((e)=>e['amount_cents']),[1200,1200]);
    expect(jsonEncode(report),before);
  });
  test('Long text is preserved exactly, including long words and complete Unicode codepoints',(){
    final text='Aporte para el local. '+'PalabraExtensa'*100+'\nCompañero: José 🕊';
    final chunks=pdfTextChunks(text);expect(chunks.length,greaterThan(1));expect(chunks.join(),text);
    expect(chunks.every((c)=>c.runes.length<=210),isTrue);
    expect(()=>pdfTextChunks('texto',limit:0),throwsArgumentError);
    final lines='Una línea\n'*100;final fragments=pdfTextChunks(lines);
    expect(fragments.join(),lines);expect(fragments.every((c)=>'\n'.allMatches(c).length<=5),isTrue);
  });
  test('Concept retains the member and assigned contribution month',(){
    final e=entry('1','income');e['due_month']='2026-09-01';
    final text=pdfConcept(e);expect(text,contains('Compañero de prueba'));expect(text,contains('Septiembre 2026'));
    expect(pdfDate('2026-10-18'),'18/10/2026');
  });
  test('Closed reports generate without mutating their stored snapshot or fresh dues annex',()async{
    final report=fixture();final snapshot=fixture();
    report['closure']={'summary':snapshot,'closed_name':'Servidor de prueba','counted_cents':14100,'difference_cents':0,'note':'Recuento verificado'};
    report['funds']=[{'fund':'general','closing':999999}];
    report['dues_roster']=[{'name':'Por confirmar','tracking':'unconfigured','periods':<Json>[]}];
    final before=jsonEncode(report);validPdf(await reportPdf(report));expect(jsonEncode(report),before);
  });
  test('Long monthly lists, concepts and accumulated dues can paginate',()async{
    final report=fixture();
    report['entries']=List<Json>.generate(160,(i)=>{...entry('$i',i.isEven?'income':'expense'),'description':i==0?'Concepto completo de un movimiento. '*250:'Movimiento del período $i'});
    report['dues_roster']=List<Json>.generate(22,(i)=>{
      'name':'Compañero de prueba $i','previous_pending':1200,'current_pending':600,'total_pending':1800,
      'periods':[{'month':'2026-09-01','expected':1200,'paid':0,'pending':1200},{'month':'2026-10-01','expected':1200,'paid':600,'pending':600}],
    });
    validPdf(await reportPdf(report));
  });
  test('Shared photos, missing photos and corrupt evidence do not block the report',()async{
    final report=fixture();report['entries']=[entry('1','income',receipt:'shared.png'),entry('2','expense',receipt:'shared.png'),entry('3','income',receipt:'missing.png'),entry('4','expense',receipt:'bad.png')];
    final photo=base64Decode('iVBORw0KGgoAAAANSUhEUgAAACAAAAAYCAIAAAAUMWhjAAAALklEQVR4nGP8//8/Ay0BE01NH7Vg1IJRC0aqBbyagSSpZxwt7EYtGLVg1ALCAADCGAawe2Hj9wAAAABJRU5ErkJggg==');
    validPdf(await reportPdf(report,includeEvidence:true,evidence:{'shared.png':photo,'bad.png':Uint8List.fromList([1,2,3])}));
  });
  test('Original PDF attachments remain indexed instead of being decoded as photos',()async{
    final report=fixture();report['entries']=[entry('1','income',receipt:'original.pdf')];
    validPdf(await reportPdf(report,includeEvidence:true,evidence:{'original.pdf':Uint8List.fromList([1,2,3])}));
  });
  test('An empty month without history still produces an explicit report',()async{
    final report=fixture();report.remove('dues_history');validPdf(await reportPdf(report));
  });
}
