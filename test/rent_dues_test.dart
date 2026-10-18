import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_tesoreria/treasury.dart';
import 'package:na_tesoreria/rent_dues.dart';
import 'package:na_tesoreria/rent_dues_card.dart';
import 'package:na_tesoreria/report_pdf.dart';

final account = <String,dynamic>{
  'id':'m1','name':'José B.','previous_pending':1200,'current_pending':600,
  'total_pending':1800,'periods':<Json>[
    {'month':'2026-09-01','expected':1200,'paid':0,'pending':1200,'credit':0},
    {'month':'2026-10-01','expected':1200,'paid':600,'pending':600,'credit':0},
  ],
};
Json fixture() => {'month':'2026-10-01','funds':<Json>[], 'entries':<Json>[],
  'dues':<Json>[], 'dues_history':{'configured':true,'through_month':'2026-10-01','members':[account]}};

void main() {
  test('All 22 registered companions appear, including six unconfigured',(){
    final companions=List<Json>.generate(22,(i)=>{'id':'c$i','name':'Compañero $i'});
    final members=List<Json>.generate(16,(i)=>{'id':'m$i','source_anniversary_id':'c$i','name':'Compañero $i'});
    final history={'members':[for(final m in members) {...account,...m}]};
    final roster=rentRoster(history,members,companions);
    expect(roster.length,22);
    expect(roster.where((m)=>m['tracking']=='unconfigured').length,6);
    expect(roster.firstWhere((m)=>m['source_id']=='c20')['total_pending'],isNull);
    expect(filterRent(roster,'','paid'),isEmpty);
    expect(rentTotals(roster)['total_pending'],16*1800);
  });
  test('Names do not link different people; unmatched members and old debt remain',(){
    final roster=rentRoster({'members':[account]},[
      {'id':'m1','name':'José B.','end_month':'2026-09-01'}
    ],[{'id':'other','name':'José B.'}]);
    expect(roster.length,2);
    expect(filterRent(roster,'jose','pending').single['id'],'m1');
    expect(filterRent(roster,'jose','partial').single['id'],'m1');
    expect(filterRent(roster,'jose','unconfigured').length,1);
  });
  test('Future participation is distinct from unconfigured debt',(){
    final roster=rentRoster({'members':<Json>[]},[
      {'id':'m2','source_anniversary_id':'c2','name':'Future','start_month':'2027-01-01'}
    ],[{'id':'c2','name':'Future'}]);
    expect(roster.single['tracking'],'not_due');
    expect(rentAmount(roster.single,'total_pending'),0);
  });
  test('Closed cash balances remain unchanged while fresh arrears survive',(){
    final input=fixture();
    input['closure']={'summary':{'month':'2026-10-01','funds':[{'closing':12345}],'entries':<Json>[],'dues':<Json>[]}};
    final output=rentReportData(input);
    expect(rows(output['funds']).single['closing'],12345);
    expect((output['dues_history'] as Map)['members'],[account]);
  });
  test('PDF accepts accumulated debt, unknown companions and closed balances',()async{
    final report=fixture();
    report['dues_roster']=[account,{'name':'Sin inicio','tracking':'unconfigured','periods':<Json>[]}];
    final bytes=await reportPdf(report);
    expect(String.fromCharCodes(bytes.take(5)),'%PDF-');
    expect(bytes.length,greaterThan(1000));
  });
  for(final width in [320.0,600.0]) {
    testWidgets('Rent card supports large text and independent expansion at $width',(tester)async{
      tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,1200);
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      Json? selected;
      final bucket=PageStorageBucket();
      await tester.pumpWidget(MaterialApp(builder:(c,w)=>MediaQuery(
        data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(2)),child:w!),
        home:Scaffold(body:PageStorage(bucket:bucket,child:ListView(key:const PageStorageKey('ledger-scroll'),
          children:[RentDuesCard(member:account,onPay:(p)=>selected=p)])))));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await tester.ensureVisible(find.text('Ver meses y abonos'));
      await tester.tap(find.text('Ver meses y abonos'));await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await tester.ensureVisible(find.text('Registrar abono a este mes').first);
      await tester.tap(find.text('Registrar abono a este mes').first);
      expect(selected?['month'],'2026-09-01');
    });
  }
}
