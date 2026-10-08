import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'treasury.dart';
import 'entry_editor.dart';
import 'activity_editor.dart';
import 'report_pdf.dart';
import 'brand.dart';
import 'treasury_widgets.dart';
import 'group_logo.dart';
import 'package:flutter/services.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key,required this.repo,required this.profile});final TreasuryRepository repo;final Json profile;
  @override State<Workspace> createState()=>_WorkspaceState();
}
class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  DateTime month=DateTime(today().year,today().month);int section=0,generation=0;bool loading=true,working=false;String? error,accessError;Json? report,settings;
  List<Json> members=[],companions=[],drafts=[],activities=[];Json? liveProfile;
  Json get profile=>liveProfile??widget.profile;String query='',kind='all';
  bool get writable=>accessError==null && ['admin','treasurer'].contains(profile['role']);
  bool get closed=>report?['closure']!=null;
  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);appearance.addListener(appearanceChanged);reload();}
  @override void dispose(){generation++;appearance.removeListener(appearanceChanged);WidgetsBinding.instance.removeObserver(this);super.dispose();}
  void appearanceChanged(){if(mounted)setState((){});}
  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)reload();}
  Future<void> reload()async{
    final ticket=++generation;setState((){loading=true;error=null;});
    try{
      final access=await widget.repo.profile();
      final s=await widget.repo.settings();
      final result=await Future.wait<dynamic>([s==null||period(month).compareTo(s['start_month'])<0?Future<Json>.value({'configured':false}):widget.repo.report(month),widget.repo.all('treasury_members'),widget.repo.companions(),widget.repo.all('treasury_entries',status:'draft'),widget.repo.client.rpc('treasury_activities')]);
      if(!mounted||ticket!=generation)return;
      setState((){liveProfile=access;settings=s;report=result[0];members=result[1];companions=result[2];drafts=result[3];activities=rows(result[4]);accessError=null;});
    }catch(e){if(mounted&&ticket==generation){setState((){error=message(e);if(e is FormatException){accessError=error;report=null;members=[];companions=[];drafts=[];activities=[];}});}}
    finally{if(mounted&&ticket==generation)setState(()=>loading=false);}
  }
  void notify(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
  Future<void> task(Future<void> Function() action)async{if(working)return;setState(()=>working=true);try{await action();}catch(e){notify(message(e));}finally{if(mounted)setState(()=>working=false);}}
  Future<void> edit([Json? entry])async{
    if(settings==null || !writable)return;
    final result=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>EntryEditor(repo:widget.repo,month:month,settings:settings!,members:members,companions:companions,entry:entry)));
    if(result==true&&mounted){notify('Movimiento guardado.');await reload();}
  }
  Future<void> chooseMonth() async {
    final value=await showModalBottomSheet<DateTime>(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>MonthSheet(selected:month));
    if(value!=null&&mounted){setState(()=>month=value);await reload();}
  }
  Future<void> shiftMonth(int delta) async {
    if(working||loading)return;
    setState(()=>month=DateTime(month.year,month.month+delta));
    await reload();
  }
  Future<String?> ask(String title,String label,{bool password=false}) async {
    final controller=TextEditingController();
    final value=await showDialog<String>(context:context,builder:(c)=>AlertDialog(scrollable:true,title:Text(title),content:TextField(controller:controller,obscureText:password,decoration:InputDecoration(labelText:password?'Contraseña':null,hintText:password?null:label,helperText:password?label:null,helperMaxLines:3),maxLines:password?1:3),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,controller.text),child:const Text('Continuar'))]));
    // Route disposal follows its reverse animation; avoid disposing a focused controller early.
    await Future<void>.delayed(const Duration(milliseconds:300));controller.dispose();return value;
  }
  Future<void> account(String action)async{
    if(action=='logout'){await task(()async{await widget.repo.client.auth.signOut(scope:SignOutScope.local);});}
    if(action=='password'){
      final value=await ask('Cambiar contraseña','Nueva contraseña (mínimo 12 caracteres)',password:true);if(value==null)return;
      if(value.length<12){notify('Utiliza al menos 12 caracteres.');return;}
      final confirmation=await ask('Confirmar contraseña','Repite la nueva contraseña',password:true);if(confirmation!=value){notify('Las contraseñas no coinciden.');return;}
      await task(()async{await widget.repo.client.auth.updateUser(UserAttributes(password:value));notify('Contraseña actualizada.');});
    }
    if(action=='admin'){await launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/admin/'),mode:LaunchMode.externalApplication);}
    if(action=='initial')await initialFunds();
  }
  Future<void> initialFunds() async {
    final general=TextEditingController(text:settings==null?'':((settings!['opening_general'] as num)/100).toStringAsFixed(2));
    final local=TextEditingController(text:settings==null?'':((settings!['opening_rent'] as num)/100).toStringAsFixed(2));
    final note=TextEditingController(text:settings?['note']??''),reason=TextEditingController();DateTime start=settings==null?month:DateTime.parse(settings!['start_month']);String? feedback;bool saving=false;
    await showDialog<void>(context:context,barrierDismissible:false,builder:(c)=>StatefulBuilder(builder:(c,set)=>PopScope(canPop:!saving,child:AlertDialog(scrollable:true,title:Text(settings==null?'Registrar fondos iniciales':'Corregir fondos iniciales'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Registra dinero físico verificado. General: gastos del grupo. Local: dinero reservado para arriendo. No incluyas deudas pendientes.'),TextButton(onPressed:saving?null:()async{final d=await showDatePicker(context:c,initialDate:start,firstDate:DateTime(2013),lastDate:today());if(d!=null)set(()=>start=DateTime(d.year,d.month));},child:Text('Mes de inicio: ${period(start).substring(0,7)}')),TextField(controller:general,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Gastos del grupo · USD')),const SizedBox(height:12),TextField(controller:local,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Apartado para el local · USD')),const SizedBox(height:12),TextField(controller:note,decoration:const InputDecoration(labelText:'Nota')),if(settings!=null)...[const SizedBox(height:12),const Text('La corrección recalcula los saldos y reabre meses cerrados. Revisa después los informes.'),TextField(controller:reason,decoration:const InputDecoration(labelText:'Motivo de la corrección'))],if(feedback!=null)Text(feedback!,style:const TextStyle(color:Colors.red))])),actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:saving?null:()async{try{final a=cents(general.text),b=cents(local.text);if(settings!=null&&reason.text.trim().length<5)throw const FormatException('Explica el motivo de la corrección.');set(()=>saving=true);await widget.repo.command(settings==null?'setup':'initial_update',{'start_month':period(start),'opening_general':a,'opening_rent':b,'note':note.text.trim(),'reason':reason.text.trim()});if(c.mounted)Navigator.pop(c);await reload();}catch(e){if(c.mounted)set((){feedback=message(e);saving=false;});}},child:Text(saving?'Guardando…':'Guardar'))]))));
    await Future<void>.delayed(const Duration(milliseconds:300));for(final controller in [general,local,note,reason]){controller.dispose();}
  }
  Future<void> export()async{
    if(report?['configured']!=true)return;
    final photos=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(scrollable:true,title:const Text('Informe mensual'),content:const Text('Ingresos y egresos se presentan separados. ¿Deseas incluir también las fotografías?'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Sin fotos')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Con fotos'))]));if(photos==null)return;
    await task(()async{
      final fresh=Json.from(await widget.repo.client.rpc('treasury_prepare_report',params:{'p_month':period(month),'p_format':'pdf','p_include_dues':true}) as Map);
      final evidence=<String,Uint8List>{};var failed=0,totalBytes=0;
      if(photos){for(final e in rows(fresh['entries']).where((e)=>e['status']=='posted'&&e['receipt_path']!=null)){
        final path=e['receipt_path'].toString();if(path.toLowerCase().endsWith('.pdf')){failed++;continue;}
        try{final bytes=await widget.repo.client.storage.from('treasury-receipts').download(path).timeout(const Duration(seconds:20));if(bytes.length>10485760){failed++;continue;}final codec=await ui.instantiateImageCodec(bytes,targetWidth:1200,allowUpscaling:false);final frame=await codec.getNextFrame();final optimized=await frame.image.toByteData(format:ui.ImageByteFormat.png);frame.image.dispose();codec.dispose();if(optimized==null||totalBytes+optimized.lengthInBytes>20971520){failed++;continue;}final image=optimized.buffer.asUint8List(optimized.offsetInBytes,optimized.lengthInBytes);totalBytes+=image.length;evidence[path]=image;}catch(_){failed++;}
      }}
      final bytes=await reportPdf(fresh,evidence:evidence,includeEvidence:photos);await Printing.sharePdf(bytes:bytes,filename:'Tesoreria_${period(month).substring(0,7)}.pdf');if(failed>0)notify('$failed comprobante(s) no pudieron incluirse. Consulta sus originales desde el movimiento.');
    });
  }
  Future<void> receipt(Json entry)async{
    final path=entry['receipt_path'];if(path==null)return;
    await task(()async{final data=await widget.repo.client.storage.from('treasury-receipts').download(path).timeout(const Duration(seconds:20));if(!mounted)return;if(path.toString().endsWith('.pdf')){await Printing.sharePdf(bytes:data,filename:'Comprobante.pdf');}else{await showDialog<void>(context:context,builder:(c)=>Dialog(child:SizedBox(height:MediaQuery.sizeOf(c).height*.75,child:Column(children:[Expanded(child:InteractiveViewer(child:Image.memory(data,errorBuilder:(_,e,s)=>const Padding(padding:EdgeInsets.all(24),child:Text('No se pudo mostrar esta imagen.'))))),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cerrar'))]))));}});
  }
  Future<void> detail(Json entry)async{
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>Padding(padding:const EdgeInsets.all(24),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(money(entry['amount_cents']),style:const TextStyle(fontSize:36,fontWeight:FontWeight.bold)),Wrap(spacing:10,runSpacing:10,children:[Text(entry['entry_date'].toString()),StatusPill(entry['status']=='posted'?'Confirmado':entry['status']=='draft'?'Borrador':'Anulado',complete:entry['status']=='posted')]),const SizedBox(height:16),Text(categories[entry['category']]??entry['category'],style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:12),Text(entry['description']??'',style:const TextStyle(height:1.5)),const SizedBox(height:16),InfoNote(entry['fund']=='rent'?'Fondo para el local':'Fondo general'),if(entry['no_receipt_reason']?.toString().isNotEmpty==true)Text('Sin comprobante: ${entry['no_receipt_reason']}'),if(entry['receipt_path']!=null)TextButton.icon(onPressed:()=>receipt(entry),icon:const Icon(Icons.receipt_long),label:const Text('Abrir comprobante')),if(writable&&entry['status']!='void')FilledButton(onPressed:(){Navigator.pop(c);edit(entry);},child:Text(entry['status']=='draft'?'Completar borrador':'Corregir con motivo')),if(writable&&entry['status']=='draft')TextButton(onPressed:()async{Navigator.pop(c);final confirmed=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(scrollable:true,title:const Text('Descartar borrador'),content:const Text('El borrador se eliminará. No afecta los fondos.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Descartar'))]));if(confirmed==true)await task(()async{await widget.repo.command('discard',{'id':entry['id'],'version':entry['version']});await reload();});},child:const Text('Descartar borrador')),if(writable&&entry['status']=='posted')TextButton(onPressed:()async{Navigator.pop(c);final reason=await ask('Anular movimiento','Motivo de la anulación');if(reason==null)return;await task(()async{await widget.repo.command('void',{'id':entry['id'],'version':entry['version'],'reason':reason});await reload();});},child:const Text('Anular indicando el motivo'))]))));
  }
  Future<void> activityEditor([Json? account,bool payment=false])async{
    if(!writable)return;
    final saved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>ActivityEditor(repo:widget.repo,companions:companions,account:account,payment:payment)));
    if(saved==true&&mounted){notify(payment?'Pago registrado en el fondo general.':'Pendiente guardado.');await reload();}
  }
  Future<void> closeMonth()async{
    if(!writable||report?['configured']!=true)return;
    if(closed){final reason=await ask('Reabrir mes','Motivo: también se reabrirán los meses posteriores');if(reason==null)return;await task(()async{await widget.repo.command('reopen',{'month':period(month),'reason':reason});await reload();});return;}
    final input=await ask('Cerrar mes','Dinero total contado físicamente · USD');if(input==null)return;
    try{
      final counted=cents(input)!;final fresh=await widget.repo.report(month);final total=rows(fresh['funds']).fold<num>(0,(n,f)=>n+(f['closing'] as num));
      if(!mounted)return;
      final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(scrollable:true,title:const Text('Confirmar cierre'),content:Text('Saldo calculado: ${money(total)}\nDinero contado: ${money(counted)}\nDiferencia: ${money(counted-total)}'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Confirmar'))]));
      if(confirmed!=true)return;final note=await ask('Nota del cierre','Explica diferencias o deja una observación');if(note==null)return;
      await task(()async{await widget.repo.command('close',{'month':period(month),'counted_cents':counted,'note':note.trim()});await reload();});
    }catch(e){notify(message(e));}
  }
  Widget metric(String label,Object? amount,{bool dark=false}) {
    final scheme=Theme.of(context).colorScheme;
    return Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(24),
      decoration:BoxDecoration(color:dark?brandNavy:scheme.surface,borderRadius:BorderRadius.circular(24),border:Border.all(color:dark?brandGold.withOpacity(.55):scheme.outline.withOpacity(.16))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(dark?Icons.account_balance_wallet_outlined:label.contains('local')?Icons.home_outlined:Icons.volunteer_activism_outlined,color:dark?brandGold:scheme.primary),const SizedBox(height:16),
        Text(label,style:TextStyle(color:dark?Colors.white70:scheme.onSurfaceVariant,fontSize:14,fontWeight:FontWeight.w600)),const SizedBox(height:8),
        Text(money(amount),style:TextStyle(fontSize:34,fontWeight:FontWeight.w800,color:dark?Colors.white:scheme.onSurface)),
      ]));
  }
  Widget entryTile(Json e) {
    final income=e['kind']=='income';final scheme=Theme.of(context).colorScheme;
    return Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide(color:scheme.outline.withOpacity(.15))),
      child:InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>detail(e),child:Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        CircleAvatar(backgroundColor:scheme.primaryContainer,child:Icon(income?Icons.south_west:Icons.north_east,color:scheme.onPrimaryContainer)),const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(e['description']?.toString().isNotEmpty==true?e['description']:'Comprobante por completar',style:const TextStyle(fontWeight:FontWeight.w600,height:1.4)),const SizedBox(height:6),
          Text('${e['entry_date']} · ${categories[e['category']]}',style:TextStyle(color:scheme.onSurfaceVariant,height:1.4)),const SizedBox(height:10),
          Wrap(spacing:12,runSpacing:8,children:[Text('${income?'+':'−'} ${money(e['amount_cents'])}',style:TextStyle(fontSize:21,fontWeight:FontWeight.w700,color:scheme.primary)),
            Text(e['status']=='draft'?'Borrador':e['status']=='void'?'Anulado':e['fund']=='rent'?'Local':'General',style:TextStyle(color:scheme.onSurfaceVariant))]),
        ])),const Icon(Icons.chevron_right,size:20),
      ]))));
  }
  List<Widget> overview() {
    final funds=rows(report?['funds']);
    final total=funds.fold<num>(0,(sum,fund)=>sum+(fund['closing'] as num));
    final recent=rows(report?['entries']).reversed.take(5).toList();
    return [
      const GroupBanner(),
      const SectionTitle('Nuestro fondo',subtitle:'Un registro claro al servicio del grupo.'),
      metric('Dinero disponible',total,dark:true),
      LayoutBuilder(builder:(context,constraints) {
        final columns=constraints.maxWidth>=560 && MediaQuery.textScalerOf(context).scale(16)<24;
        return Wrap(spacing:16,children:[for(final fund in funds)SizedBox(width:columns?(constraints.maxWidth-16)/2:constraints.maxWidth,child:metric(fund['fund']=='rent'?'Apartado para el local':'Para gastos del grupo',fund['closing']))]);
      }),
      const InfoNote('Las cuotas pendientes y los borradores no se suman al dinero disponible.'),
      if(writable)FilledButton.icon(onPressed:working?null:()=>edit(),icon:const Icon(Icons.add),label:const Text('Registrar ingreso o egreso')),
      const SizedBox(height:24),
      LedgerPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Wrap(spacing:12,runSpacing:10,alignment:WrapAlignment.spaceBetween,children:[const Text('Balance del mes',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),StatusPill(closed?'Mes cerrado':'Mes abierto',complete:closed)]),
        const SizedBox(height:22),
        Wrap(spacing:28,runSpacing:20,children:[for(final field in const {'opening':'Saldo al inicio','income':'Ingresos','expense':'Egresos'}.entries)MoneyCaption(field.value,funds.fold<num>(0,(sum,fund)=>sum+(fund[field.key] as num)))]),
        const SizedBox(height:24),OutlinedButton.icon(onPressed:working?null:export,icon:const Icon(Icons.picture_as_pdf_outlined),label:const Text('Compartir informe PDF')),
      ])),
      const SectionTitle('Movimientos recientes',icon:Icons.history),
      if(recent.isEmpty)const EmptyLedger('Todavía no hay movimientos','Los ingresos y egresos de este mes aparecerán aquí.'),
      ...recent.map(entryTile),
    ];
  }
  List<Widget> movementView() {
    final filtered=rows(report?['entries']).reversed.where((entry)=>(kind=='all'||entry['kind']==kind)&&'${entry['description']} ${entry['member_name']} ${categories[entry['category']]}'.toLowerCase().contains(query)).toList();
    return [
      const SectionTitle('Movimientos',subtitle:'Ingresos y egresos del período seleccionado.',icon:Icons.swap_vert),
      if(writable) ...[FilledButton.icon(onPressed:working?null:()=>edit(),icon:const Icon(Icons.add),label:const Text('Nuevo movimiento')),const SizedBox(height:18)],
      TextField(decoration:const InputDecoration(hintText:'Buscar detalle o compañero',prefixIcon:Icon(Icons.search)),onChanged:(value)=>setState(()=>query=value.toLowerCase())),
      const SizedBox(height:14),Wrap(spacing:8,runSpacing:8,children:[for(final filter in const {'all':'Todos','income':'Ingresos','expense':'Egresos'}.entries)ChoiceChip(label:Text(filter.value),selected:kind==filter.key,onSelected:(_)=>setState(()=>kind=filter.key))]),
      const SizedBox(height:16),
      if(filtered.isEmpty)const EmptyLedger('Sin movimientos para mostrar','Cambia el filtro o selecciona otro mes.'),
      ...filtered.map(entryTile),
      if(drafts.isNotEmpty)...[const SectionTitle('Borradores',subtitle:'Registros por completar. No afectan el saldo.',icon:Icons.edit_note),...drafts.map(entryTile)],
    ];
  }
  List<Widget> duesView() {
    final dues=rows(report?['dues']);
    final pendingActivities=activities.fold<num>(0,(sum,account)=>sum+(account['pending_cents'] as num));
    return [
      const SectionTitle('Aportes para el local',subtitle:'El compromiso de mantener nuestro espacio.',icon:Icons.home_outlined),
      LedgerPanel(child:Wrap(spacing:28,runSpacing:18,children:[MoneyCaption('Cuotas del mes',dues.fold<num>(0,(sum,due)=>sum+(due['expected'] as num))),MoneyCaption('Recibido',dues.fold<num>(0,(sum,due)=>sum+(due['paid'] as num)))])),
      const InfoNote('Los aportes confirmados ya están incluidos en el fondo del local.'),
      if(dues.isEmpty)const EmptyLedger('Sin cuotas en este mes','Puedes registrar un aporte desde Nuevo movimiento.',icon:Icons.people_outline),
      for(final due in dues)DueCard(key:ValueKey('due-${due['id']}'),due:due),
      const SizedBox(height:14),
      const SectionTitle('Actividades del grupo',subtitle:'Bingos, rifas y otros compromisos pendientes.',icon:Icons.volunteer_activism_outlined),
      LedgerPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[MoneyCaption('Total por cobrar',pendingActivities,emphasis:true),const SizedBox(height:12),const Text('Este valor es informativo. Solo los pagos recibidos se incorporan al fondo general.',style:TextStyle(height:1.5))])),
      if(writable)...[OutlinedButton.icon(onPressed:working?null:()=>activityEditor(),icon:const Icon(Icons.add),label:const Text('Nuevo pendiente')),const SizedBox(height:18)],
      if(activities.isEmpty)const EmptyLedger('No hay pendientes de actividades','Registra un compromiso para llevar sus pagos y comprobantes.',icon:Icons.check_circle_outline),
      for(final account in activities)ActivityCard(
        key:ValueKey('activity-card-${account['id']}'),account:account,
        onPay:writable&&!working?()=>activityEditor(account,true):null,
        onEdit:writable&&!working?()=>activityEditor(account):null,
        onPayment:detail,
      ),
    ];
  }
  Future<void> audit()async{await task(()async{final data=await widget.repo.client.from('treasury_audit').select('action,actor_name,happened_at').order('id',ascending:false).limit(50);if(!mounted)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>SizedBox(height:MediaQuery.sizeOf(c).height*.8,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('Últimos 50 cambios',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),...data.map((a)=>ListTile(leading:const Icon(Icons.history),title:Text(a['actor_name']??'Usuario'),subtitle:Text('${a['action']} · ${a['happened_at']}')))])));});}
  List<Widget> more()=>[
    const GroupBanner(),
    const SectionTitle('Tu espacio',subtitle:'Preferencias, herramientas y cuidado del servicio.'),
    LedgerPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      const Text('Apariencia',style:TextStyle(fontSize:19,fontWeight:FontWeight.w700)),const SizedBox(height:8),const Text('Elige cómo se presenta la app en este dispositivo.'),const SizedBox(height:16),
      Wrap(spacing:8,runSpacing:10,children:[for(final option in const {ThemeMode.system:'Automático',ThemeMode.light:'Claro',ThemeMode.dark:'Oscuro'}.entries)ChoiceChip(label:Text(option.value),selected:appearance.mode==option.key,onSelected:(_){appearance.setMode(option.key);})]),
    ])),
    const ActionCard(icon:Icons.help_outline,title:'Cómo utilizar Tesorería',subtitle:'General: séptimas y otros ingresos. Local: aportes para arriendo. Borrador: registro por completar, no suma dinero. Confirmar: incorpora el movimiento al saldo. Corregir: conserva el historial.'),
    if(writable&&report?['configured']==true)ActionCard(icon:Icons.lock_clock,title:closed?'Reabrir mes con motivo':'Cerrar mes y verificar dinero',subtitle:closed?'Revisa el motivo antes de modificar un mes cerrado.':'Compara el saldo con el dinero contado en caja.',onTap:working?null:closeMonth),
    ActionCard(icon:Icons.history,title:'Historial de cambios',subtitle:'Consulta quién realizó cada actualización.',onTap:working?null:audit),
    ActionCard(icon:Icons.language,title:'Abrir Tesorería web',subtitle:'Accede a la plataforma del grupo.',onTap:()=>launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/tesoreria/'),mode:LaunchMode.externalApplication)),
    if(writable)ActionCard(icon:Icons.account_balance,title:'Corregir fondos iniciales',subtitle:'Requiere un motivo y recalcula los períodos.',onTap:working?null:initialFunds),
    if(profile['role']=='admin')ActionCard(icon:Icons.manage_accounts,title:'Administrar usuarios',subtitle:'Abre el panel administrativo del grupo.',onTap:()=>account('admin')),
    ActionCard(icon:Icons.password,title:'Cambiar contraseña',onTap:working?null:()=>account('password')),
    ActionCard(icon:Icons.logout,title:'Cerrar sesión',onTap:working?null:()=>account('logout')),
    const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Un día a la vez, juntos.\nAmigos Verdaderos · Narcóticos Anónimos',textAlign:TextAlign.center,style:TextStyle(height:1.6,fontSize:13))),
  ];
  void selectSection(int index) {
    if(index==section)return;
    HapticFeedback.selectionClick();
    setState(()=>section=index);
  }
  List<Widget> content() => error!=null ? [Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),FilledButton(onPressed:reload,child:const Text('Reintentar'))]
    : report?['configured']!=true ? [const GroupBanner(),const SizedBox(height:24),Text(settings==null?'Registra los fondos iniciales para comenzar.':'Este mes es anterior al inicio de Tesorería.'),if(writable&&settings==null)FilledButton(onPressed:initialFunds,child:const Text('Registrar fondos'))]
    : section==0?overview():section==1?movementView():section==2?duesView():more();
  Widget periodControl()=>Padding(padding:const EdgeInsets.fromLTRB(16,12,16,16),child:Row(children:[
    IconButton(tooltip:'Mes anterior',onPressed:working||loading?null:()=>shiftMonth(-1),icon:const Icon(Icons.chevron_left)),
    Expanded(child:SelectionField(label:'Período de consulta',value:monthLabel(month),icon:Icons.calendar_month,onTap:working||loading?null:chooseMonth)),
    IconButton(tooltip:'Mes siguiente',onPressed:working||loading?null:()=>shiftMonth(1),icon:const Icon(Icons.chevron_right)),
  ]));
  @override Widget build(BuildContext context) {
    final compactHeight=MediaQuery.sizeOf(context).height<500;
    final largeText=MediaQuery.textScalerOf(context).scale(16)>24;
    final wide=MediaQuery.sizeOf(context).width>=840;
    final name=profile['display_name']??widget.repo.client.auth.currentUser?.email??'Mi cuenta';
    return Scaffold(
      appBar:AppBar(toolbarHeight:MediaQuery.textScalerOf(context).scale(23)*1.3+MediaQuery.textScalerOf(context).scale(12)*1.5+20,leading:const Padding(padding:EdgeInsets.all(10),child:GroupLogo(size:48)),title:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Tesorería',maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:23,fontWeight:FontWeight.w700)),Text('$name',maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:Colors.white70))]),actions:[
        const ThemeButton(),IconButton(tooltip:'Actualizar',onPressed:loading||working?null:reload,icon:const Icon(Icons.refresh)),
        PopupMenuButton<String>(icon:const Icon(Icons.account_circle_outlined),tooltip:'Mi perfil',onSelected:account,itemBuilder:(_)=>[PopupMenuItem<String>(enabled:false,child:Text('$name\n${{'admin':'Administrador','treasurer':'Tesorería','auditor':'Consulta'}[profile['role']]}')),const PopupMenuItem(value:'password',child:Text('Cambiar contraseña')),const PopupMenuItem(value:'logout',child:Text('Cerrar sesión'))]),
      ]),
      body:SafeArea(child:Row(children:[if(wide)...[
        NavigationRail(selectedIndex:section,onDestinationSelected:selectSection,labelType:NavigationRailLabelType.all,destinations:const [NavigationRailDestination(icon:Icon(Icons.dashboard_outlined),label:Text('Resumen')),NavigationRailDestination(icon:Icon(Icons.swap_vert),label:Text('Movimientos')),NavigationRailDestination(icon:Icon(Icons.people_outline),label:Text('Aportes')),NavigationRailDestination(icon:Icon(Icons.more_horiz),label:Text('Más'))]),const VerticalDivider(width:1),
      ],Expanded(child:ResponsiveBody(child:Column(children:[
        if(!compactHeight)periodControl(),if(working)const LinearProgressIndicator(),
        Expanded(child:loading?const Center(child:CircularProgressIndicator()):AnimatedSwitcher(duration:MediaQuery.of(context).disableAnimations?Duration.zero:const Duration(milliseconds:180),child:RefreshIndicator(key:ValueKey(section),onRefresh:reload,child:ListView(key:PageStorageKey('treasury-section-$section'),physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(20,0,20,24),children:[if(compactHeight)periodControl(),...content()])))),
      ]))),])),
      bottomNavigationBar:wide?null:NavigationBar(labelBehavior:largeText?NavigationDestinationLabelBehavior.alwaysHide:NavigationDestinationLabelBehavior.alwaysShow,selectedIndex:section,onDestinationSelected:selectSection,destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Resumen'),NavigationDestination(icon:Icon(Icons.swap_vert),label:'Movimientos'),NavigationDestination(icon:Icon(Icons.people_outline),selectedIcon:Icon(Icons.people),label:'Aportes'),NavigationDestination(icon:Icon(Icons.more_horiz),label:'Más')]),
    );
  }
}
