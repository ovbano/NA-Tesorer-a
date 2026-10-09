import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_tesoreria/core/theme/brand.dart';
import 'package:na_tesoreria/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:na_tesoreria/features/treasury/treasury.dart';

final sampleActivity = <String,dynamic>{
  'id':'activity-1','name':'Compañero con un nombre y apellido extenso',
  'activity':'Bingo de apoyo y adecuación del nuevo local del grupo',
  'original_cents':4500.0,'historical_paid_cents':500.0,'paid_cents':1200.0,
  'pending_cents':2800.0,'payments':<Json>[],
};

Widget shell(Widget child, {Brightness brightness = Brightness.light, double scale = 1}) => MaterialApp(
  theme:groupTheme(brightness),
  builder:(context,widget)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(scale)),child:widget!),
  home:Scaffold(body:child),
);

void main() {
  testWidgets('Light and dark themes resolve font sizes without TextStyle.apply assertions',(tester) async {
    for(final brightness in Brightness.values) {
      await tester.pumpWidget(shell(const Text('Tesorería del grupo'),brightness:brightness));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
    }
  });

  testWidgets('Activity expansion keeps bool state separate from a double scroll offset',(tester) async {
    final bucket=PageStorageBucket();
    Widget page()=>shell(PageStorage(bucket:bucket,child:ListView(
      key:const PageStorageKey('treasury-section-2'),
      children:[ActivityCard(key:const ValueKey('account-1'),account:sampleActivity,onPayment:(_){})],
    )));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    // This is the ancestor storage entry an unkeyed ExpansionTile used to read.
    bucket.writeState(tester.element(find.byType(ActivityCard)),120.0);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    await tester.tap(find.text(sampleActivity['name'] as String));
    await tester.pumpAndSettle();
    expect(find.text('Historial de pagos'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Historial de pagos'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });

  for(final width in [320.0,360.0,600.0,1024.0]) {
    for(final scale in [1.0,2.0]) {
      testWidgets('Ledger cards wrap at width $width and text scale $scale',(tester) async {
        tester.view.devicePixelRatio=1;
        tester.view.physicalSize=Size(width,1000);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(shell(ListView(padding:const EdgeInsets.all(16),children:[
          const GroupBanner(),
          const SectionTitle('Aportes para el local',subtitle:'El compromiso de mantener nuestro espacio.'),
          const DueCard(due:{'name':'Un compañero con nombre y apellido largos','expected':1200,'paid':600}),
          ActivityCard(account:sampleActivity,onPay:(){},onEdit:(){},onPayment:(_){}),
          const SelectionField(label:'Fondo que recibe o paga',value:'Local · reservado para el arriendo de nuestro grupo'),
          const InfoNote('Los compromisos pendientes no forman parte del dinero disponible.'),
          ActionCard(icon:Icons.manage_accounts,title:'Administrar usuarios',subtitle:'Abre el panel administrativo del grupo.',onTap:(){}),
        ]),scale:scale,brightness:Brightness.dark));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        await tester.scrollUntilVisible(find.text(sampleActivity['name'] as String),200);
        await tester.tap(find.text(sampleActivity['name'] as String));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
      });
    }
  }

  testWidgets('Companion selector filters accented names',(tester) async {
    await tester.pumpWidget(shell(const OptionSheet(title:'Elegir compañero',searchable:true,options:[{'value':'1','name':'José Fernando'},{'value':'2','name':'Germania S.'}])));
    await tester.enterText(find.byType(TextField),'jose');
    await tester.pumpAndSettle();
    expect(find.text('José Fernando'),findsOneWidget);
    expect(find.text('Germania S.'),findsNothing);
    expect(tester.takeException(),isNull);
  });
  testWidgets('Selector remains within the available screen above the keyboard',(tester) async {
    tester.view.devicePixelRatio=1;
    tester.view.physicalSize=const Size(320,640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(theme:groupTheme(Brightness.light),home:Scaffold(body:MediaQuery(
      data:const MediaQueryData(size:Size(320,640),viewInsets:EdgeInsets.only(bottom:300)),
      child:const OptionSheet(title:'Elegir compañero',searchable:true,options:[{'value':'1','name':'Valentín B.'}]),
    ))));
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
  });

}
