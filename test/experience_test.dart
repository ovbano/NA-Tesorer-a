import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_tesoreria/brand.dart';
import 'package:na_tesoreria/experience.dart';
import 'package:na_tesoreria/treasury_widgets.dart';
import 'package:na_tesoreria/treasury_workspace_ui.dart';

Widget host(Widget child,{Brightness brightness=Brightness.light,bool reduce=false,double scale=1})=>MaterialApp(
  theme:groupTheme(brightness),builder:(context,widget)=>MediaQuery(
    data:MediaQuery.of(context).copyWith(disableAnimations:reduce,textScaler:TextScaler.linear(scale)),child:widget!),
  home:Scaffold(body:BrandedBackdrop(child:child)),
);

void main(){
  testWidgets('Loading communicates its state and stops motion on request',(tester)async{
    await tester.pumpWidget(host(const TreasuryLoading(title:'Cargando los saldos',detail:'Consultando el período.',skeleton:true),reduce:true));
    await tester.pumpAndSettle();
    expect(find.text('Cargando los saldos'),findsOneWidget);
    expect(find.byIcon(Icons.hourglass_top_rounded),findsOneWidget);
    expect(find.byType(LinearProgressIndicator),findsNothing);
    expect(tester.takeException(),isNull);
  });

  testWidgets('Decorative card motion does not consume the action callback',(tester)async{
    var taps=0;
    await tester.pumpWidget(host(Center(child:LedgerPanel(child:TextButton(onPressed:()=>taps++,child:const Text('Registrar'))))));
    await tester.tap(find.text('Registrar'));await tester.pumpAndSettle();
    expect(taps,1);expect(tester.takeException(),isNull);
  });

  testWidgets('Metric explanation expands without changing its amount',(tester)async{
    await tester.pumpWidget(host(const SingleChildScrollView(child:WorkspaceMetricCard(
      label:'Dinero disponible',value:r'$142,19',icon:Icons.account_balance_wallet_outlined,featured:true))));
    await tester.tap(find.text('¿Qué incluye?'));await tester.pumpAndSettle();
    expect(find.textContaining('Suma del fondo general'),findsOneWidget);
    expect(find.text(r'$142,19'),findsOneWidget);
    await tester.tap(find.text('Ocultar explicación'));await tester.pumpAndSettle();
    expect(find.textContaining('Suma del fondo general'),findsNothing);
  });

  for(final brightness in Brightness.values){
    for(final width in [320.0,600.0]){
      testWidgets('Period and month selector adapt at $width in $brightness',(tester)async{
        tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,820);
        addTearDown(tester.view.resetDevicePixelRatio);addTearDown(tester.view.resetPhysicalSize);
        DateTime? selected;
        await tester.pumpWidget(host(Builder(builder:(context)=>SingleChildScrollView(child:PeriodPanel(
          label:'Septiembre 2026',onChoose:()async{selected=await showModalBottomSheet<DateTime>(
            context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>MonthSheet(selected:DateTime(2026,9)));},
        ))),brightness:brightness,scale:2));
        await tester.tap(find.text('Septiembre 2026'));await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        await tester.scrollUntilVisible(find.text('Marzo'),120,scrollable:find.byType(Scrollable).last);
        await tester.tap(find.text('Marzo'));await tester.pumpAndSettle();
        expect(selected,DateTime(2026,3));expect(tester.takeException(),isNull);
      });
    }
  }

  testWidgets('Option sheet stays open while searching and returns the selected ID',(tester)async{
    String? selected;
    await tester.pumpWidget(host(Builder(builder:(context)=>Center(child:FilledButton(onPressed:()async{
      selected=await selectOption(context,title:'Elegir compañero',searchable:true,
        options:const [{'value':'a','name':'José B.'},{'value':'b','name':'María S.'}]);
    },child:const Text('Elegir'))))));
    await tester.tap(find.text('Elegir'));await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField),'jose');await tester.pumpAndSettle();
    expect(find.text('José B.'),findsOneWidget);expect(find.text('María S.'),findsNothing);expect(selected,isNull);
    await tester.tap(find.text('José B.'));await tester.pumpAndSettle();expect(selected,'a');
  });

  testWidgets('Animated confirmation keeps its return value and cancel behavior',(tester)async{
    bool? answer;
    await tester.pumpWidget(host(Builder(builder:(context)=>Center(child:TextButton(onPressed:()async{
      answer=await showExperienceDialog<bool>(context:context,barrierDismissible:false,
        builder:(c)=>AlertDialog(title:const Text('Confirmar'),actions:[
          TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
          FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Aceptar'))]));
    },child:const Text('Abrir'))))));
    await tester.tap(find.text('Abrir'));await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));await tester.pumpAndSettle();expect(answer,false);
  });
}
