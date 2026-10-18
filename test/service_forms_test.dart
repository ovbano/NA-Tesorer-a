import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:na_tesoreria/brand.dart';
import 'package:na_tesoreria/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:na_tesoreria/service_forms.dart';
import 'package:na_tesoreria/treasury.dart';
import 'package:na_tesoreria/ux_components.dart';
import 'package:na_tesoreria/movement_card.dart';
import 'package:na_tesoreria/rent_dues_card.dart';

Widget host(Widget child,{Brightness brightness=Brightness.light,double scale=1})=>MaterialApp(
  theme:groupTheme(brightness),builder:(c,w)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:TextScaler.linear(scale)),child:w!),
  home:Scaffold(body:Builder(builder:(context)=>FilledButton(onPressed:()=>showServiceForm<bool>(context,child),child:const Text('Abrir')))),
);
Future<void> open(WidgetTester tester,Widget form)async{
  await tester.pumpWidget(host(form));await tester.tap(find.text('Abrir'));await tester.pumpAndSettle();
}
Future<void> submit(WidgetTester tester,String label)async{
  await tester.ensureVisible(find.text(label));await tester.tap(find.text(label));await tester.pumpAndSettle();
}

void main(){
  testWidgets('Password confirmation is local and never submits mismatched values',(tester)async{
    var calls=0;
    await open(tester,PasswordForm(onSave:(value)async{calls++;}));
    await tester.enterText(find.byType(TextFormField).at(0),'NuevaClave1234');
    await tester.enterText(find.byType(TextFormField).at(1),'OtraClave1234');
    await submit(tester,'Actualizar contraseña');
    expect(calls,0);expect(find.text('Las contraseñas no coinciden.'),findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1),'NuevaClave1234');
    await submit(tester,'Actualizar contraseña');expect(calls,1);
  });
  testWidgets('Save errors keep the password form and entered values available',(tester)async{
    await open(tester,PasswordForm(onSave:(_)async{throw const FormatException('No se pudo guardar.');}));
    await tester.enterText(find.byType(TextFormField).at(0),'NuevaClave1234');
    await tester.enterText(find.byType(TextFormField).at(1),'NuevaClave1234');
    await submit(tester,'Actualizar contraseña');
    expect(find.text('No se pudo guardar.'),findsOneWidget);expect(find.byType(PasswordForm),findsOneWidget);
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text,'NuevaClave1234');
  });
  testWidgets('Initial correction preserves separate funds and requires its reason',(tester)async{
    Json? saved;
    await open(tester,InitialFundsForm(settings:{'opening_general':24790,'opening_rent':2200,'start_month':'2026-08-01','note':''},
      month:DateTime(2026,10),onSave:(value)async{saved=value;}));
    await tester.enterText(find.byType(TextFormField).at(0),'248,90');
    await tester.enterText(find.byType(TextFormField).at(1),'22');
    await submit(tester,'Aplicar corrección');expect(saved,isNull);
    await tester.enterText(find.byType(TextFormField).at(3),'Corrección de registro');
    await submit(tester,'Aplicar corrección');
    expect(saved?['opening_general'],24890);expect(saved?['opening_rent'],2200);
    expect(saved?['start_month'],'2026-08-01');expect(saved?['reason'],'Corrección de registro');
  });
  testWidgets('Rent participation cannot silently assume its starting month',(tester)async{
    var calls=0;
    await open(tester,RentSetupForm(person:{'source_id':'c1','name':'Compañero de prueba'},settings:{'start_month':'2026-08-01'},month:DateTime(2026,10),onSave:(_)async{calls++;}));
    await submit(tester,'Guardar inicio y cuota');
    expect(calls,0);expect(find.text('Elige desde qué mes corresponde la cuota.'),findsOneWidget);
    await submit(tester,'Cancelar');expect(calls,0);
  });
  testWidgets('Rent setup sends the confirmed month and public directory ID',(tester)async{
    Json? saved;
    await open(tester,RentSetupForm(person:{'source_id':'c1','name':'Compañero de prueba'},settings:{'start_month':'2026-08-01'},month:DateTime(2026,10),onSave:(v)async{saved=v;}));
    await tester.ensureVisible(find.text('Seleccionar mes'));await tester.tap(find.text('Seleccionar mes'));await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Septiembre'),100,scrollable:find.byType(Scrollable).last);
    await tester.tap(find.text('Septiembre'));await tester.pumpAndSettle();
    await submit(tester,'Guardar inicio y cuota');
    expect(saved?['source_anniversary_id'],'c1');expect(saved?['start_month'],'2026-09-01');expect(saved?['monthly_cents'],1200);
  });
  testWidgets('Closing with a difference requires an explanation and exact cents',(tester)async{
    Json? saved;
    await open(tester,CloseMonthForm(month:DateTime(2026,10),report:{'funds':[{'fund':'general','closing':12300},{'fund':'rent','closing':0}]},onSave:(value)async{saved=value;}));
    await tester.enterText(find.byType(TextFormField).at(0),'124,00');
    await submit(tester,'Confirmar cierre del mes');expect(saved,isNull);
    await tester.enterText(find.byType(TextFormField).at(1),'Recuento revisado');
    await submit(tester,'Confirmar cierre del mes');
    expect(saved?['month'],'2026-10-01');expect(saved?['counted_cents'],12400);expect(saved?['note'],'Recuento revisado');
  });
  for(final brightness in Brightness.values){
    for(final width in [320.0,600.0]){
      testWidgets('Views wrap at $width with enlarged text in $brightness',(tester)async{
        tester.view.devicePixelRatio=1;tester.view.physicalSize=Size(width,900);
        addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(theme:groupTheme(brightness),builder:(c,w)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:const TextScaler.linear(2)),child:w!),
          home:Scaffold(body:ListView(padding:const EdgeInsets.all(16),children:[
            const AdaptiveIntro(title:'Un nuevo compromiso',subtitle:'Información del servicio para el grupo.',icon:Icons.volunteer_activism_outlined,showLogo:true),
            MovementCard(entry:{'status':'posted','kind':'income','fund':'rent','entry_date':'2026-10-18','amount_cents':1200,'description':'Aporte parcial para el local del grupo','member_name':'Nombre extenso del compañero'},onTap:(){}),
            RentDuesCard(member:{'id':'c1','name':'Compañero con nombre extenso','tracking':'unconfigured','periods':<Json>[]},onConfigure:(){}),
            ServiceOptions(title:'Cuenta y seguridad',options:[ServiceOption('Cambiar contraseña','Cuida tu credencial de acceso.',Icons.lock_reset_rounded,(){})]),
          ]))));
        await tester.pumpAndSettle();expect(tester.takeException(),isNull);
        await tester.scrollUntilVisible(find.text('Configurar inicio y cuota'),160);
        expect(tester.takeException(),isNull);
        await tester.scrollUntilVisible(find.text('Cambiar contraseña'),160);
        expect(tester.takeException(),isNull);
      });
    }
  }
  for(final brightness in Brightness.values){
    testWidgets('Login validates locally and adapts its header in $brightness',(tester)async{
      final client=SupabaseClient('https://example.supabase.co','test-public-key');
      addTearDown(()=>client.dispose());
      await tester.pumpWidget(MaterialApp(theme:groupTheme(brightness),home:LoginScreen(repo:TreasuryRepository(client))));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Iniciar sesión'));await tester.tap(find.text('Iniciar sesión'));await tester.pumpAndSettle();
      expect(find.text('Escribe un correo válido'),findsOneWidget);expect(find.text('Escribe tu contraseña'),findsOneWidget);
      expect(tester.takeException(),isNull);
    });
  }

  for(final brightness in Brightness.values){
    testWidgets('Service forms scroll above the keyboard in $brightness',(tester)async{
      tester.view.devicePixelRatio=1;tester.view.physicalSize=const Size(320,640);
      addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(theme:groupTheme(brightness),home:Scaffold(body:MediaQuery(
        data:const MediaQueryData(size:Size(320,640),viewInsets:EdgeInsets.only(bottom:300),textScaler:TextScaler.linear(2)),
        child:PasswordForm(onSave:(_)async{})))));
      await tester.pumpAndSettle();expect(tester.takeException(),isNull);
      await tester.scrollUntilVisible(find.text('Cancelar'),100);expect(tester.takeException(),isNull);
    });
  }

}
