import 'package:flutter/material.dart';
import 'treasury.dart';
import 'treasury_widgets.dart';
import 'ux_components.dart';

Future<T?> showServiceForm<T>(BuildContext context,Widget child)=>showModalBottomSheet<T>(
  context:context,isScrollControlled:true,useSafeArea:true,isDismissible:false,enableDrag:false,
  builder:(_)=>child,
);

class ServiceFormFrame extends StatelessWidget {
  const ServiceFormFrame({super.key,required this.title,required this.description,required this.icon,
    required this.child,required this.onSubmit,this.submitLabel='Guardar',this.busy=false,this.error});
  final String title,description,submitLabel;
  final IconData icon;
  final Widget child;
  final VoidCallback onSubmit;
  final bool busy;
  final String? error;
  @override
  Widget build(BuildContext context){
    final screen=MediaQuery.sizeOf(context);
    final keyboard=MediaQuery.viewInsetsOf(context).bottom;
    final available=(screen.height-keyboard-MediaQuery.paddingOf(context).vertical).clamp(0.0,screen.height);
    return PopScope(canPop:!busy,child:Padding(padding:EdgeInsets.only(bottom:keyboard),child:SizedBox(height:available*.94,
      child:SingleChildScrollView(keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.manual,
        padding:const EdgeInsets.fromLTRB(18,4,18,24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          AdaptiveIntro(title:title,subtitle:description,icon:icon,eyebrow:'TU SERVICIO · TESORERÍA'),
          const SizedBox(height:18),AbsorbPointer(absorbing:busy,child:child),
          if(error!=null) Semantics(liveRegion:true,child:FieldNote(error!,warning:true)),
          const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:onSubmit,
            icon:Icon(busy?Icons.hourglass_top_rounded:Icons.check_circle_outline_rounded),
            label:Text(busy?'Guardando…':submitLabel,textAlign:TextAlign.center)),
          const SizedBox(height:8),TextButton(onPressed:busy?null:()=>Navigator.pop(context),child:const Text('Cancelar')),
        ])),
    )));
  }
}

abstract class ServiceFormState<T extends StatefulWidget> extends State<T> {
  final form=GlobalKey<FormState>();
  bool saving=false;
  String? error;
  Future<void> commit(Future<void> Function() action) async {
    if(saving||!(form.currentState?.validate()??false))return;
    FocusScope.of(context).unfocus();setState((){saving=true;error=null;});
    try{await action();if(mounted)Navigator.pop(context,true);}
    catch(e){if(mounted)setState((){saving=false;error=message(e);});}
  }
  String? validMoney(String? input){try{cents(input??'');return null;}catch(e){return message(e);}}
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key,required this.onSave});
  final Future<void> Function(String) onSave;
  @override State<PasswordForm> createState()=>_PasswordFormState();
}
class _PasswordFormState extends ServiceFormState<PasswordForm> {
  final password=TextEditingController(),confirmation=TextEditingController();
  bool visible=false,confirmVisible=false;
  @override void dispose(){password.dispose();confirmation.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ServiceFormFrame(
    title:'Cuida tu acceso',description:'Actualiza tu contraseña. Tu cuenta y tus movimientos se conservan.',icon:Icons.lock_reset_rounded,
    submitLabel:'Actualizar contraseña',busy:saving,error:error,
    onSubmit:()=>commit(()=>widget.onSave(password.text)),
    child:Form(key:form,autovalidateMode:AutovalidateMode.onUserInteraction,child:UxSection(
      title:'Una contraseña que solo tú conozcas',icon:Icons.password_rounded,child:Column(children:[
        TextFormField(controller:password,obscureText:!visible,enableSuggestions:false,autocorrect:false,
          autofillHints:const [AutofillHints.newPassword],textInputAction:TextInputAction.next,
          validator:(v)=>(v??'').length<12?'Utiliza al menos 12 caracteres.':null,
          decoration:InputDecoration(labelText:'Nueva contraseña',helperText:'Mínimo 12 caracteres.',
            suffixIcon:IconButton(tooltip:visible?'Ocultar contraseña':'Mostrar contraseña',onPressed:()=>setState(()=>visible=!visible),icon:Icon(visible?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
        const SizedBox(height:16),TextFormField(controller:confirmation,obscureText:!confirmVisible,enableSuggestions:false,autocorrect:false,
          autofillHints:const [AutofillHints.newPassword],validator:(v)=>v!=password.text?'Las contraseñas no coinciden.':null,
          decoration:InputDecoration(labelText:'Repite la contraseña',suffixIcon:IconButton(tooltip:confirmVisible?'Ocultar confirmación':'Mostrar confirmación',
            onPressed:()=>setState(()=>confirmVisible=!confirmVisible),icon:Icon(confirmVisible?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
        const FieldNote('Puedes volver a cambiarla cuando lo necesites. Guarda tu credencial de forma privada.'),
      ]))),
  );
}

class InitialFundsForm extends StatefulWidget {
  const InitialFundsForm({super.key,required this.settings,required this.month,required this.onSave});
  final Json? settings;
  final DateTime month;
  final Future<void> Function(Json) onSave;
  @override State<InitialFundsForm> createState()=>_InitialFundsFormState();
}
class _InitialFundsFormState extends ServiceFormState<InitialFundsForm> {
  late final TextEditingController general,local,note,reason;
  late DateTime start;
  bool get correcting=>widget.settings!=null;
  @override void initState(){super.initState();
    general=TextEditingController(text:correcting?((widget.settings!['opening_general'] as num)/100).toStringAsFixed(2):'');
    local=TextEditingController(text:correcting?((widget.settings!['opening_rent'] as num)/100).toStringAsFixed(2):'');
    note=TextEditingController(text:widget.settings?['note']??'');reason=TextEditingController();
    start=correcting?DateTime.parse(widget.settings!['start_month'] as String):widget.month;
  }
  @override void dispose(){for(final c in [general,local,note,reason]){c.dispose();}super.dispose();}
  Future<void> chooseStart()async{
    final selected=await showModalBottomSheet<DateTime>(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>MonthSheet(selected:start));
    if(selected!=null&&mounted)setState(()=>start=selected);
  }
  Future<void> save()async{
    if(period(start).compareTo(period(today()))>0){setState(()=>error='El mes de inicio no puede ser futuro.');return;}
    await commit(()=>widget.onSave({'start_month':period(start),'opening_general':cents(general.text),
      'opening_rent':cents(local.text),'note':note.text.trim(),'reason':reason.text.trim()}));
  }
  @override Widget build(BuildContext context)=>ServiceFormFrame(
    title:correcting?'Corregir el punto de partida':'Registrar fondos iniciales',
    description:'Separa el dinero físico disponible del grupo y el que está reservado para arriendo.',
    icon:Icons.account_balance_wallet_outlined,submitLabel:correcting?'Aplicar corrección':'Registrar fondos',busy:saving,error:error,onSubmit:save,
    child:Form(key:form,child:Column(children:[
      UxSection(title:'Desde qué mes',step:'01',child:SelectionField(label:'Inicio de Tesorería',value:monthLabel(start),icon:Icons.calendar_month_outlined,onTap:chooseStart)),
      UxSection(title:'Dinero para gastos del grupo',step:'02',description:'Séptimas y otros fondos disponibles para los gastos del grupo.',child:TextFormField(
        controller:general,validator:validMoney,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Fondo general · USD',prefixIcon:Icon(Icons.volunteer_activism_outlined),hintText:'0,00'))),
      UxSection(title:'Dinero apartado para arriendo',step:'03',description:'Efectivo reservado para pagar el local. No incluyas cuotas que todavía se deben.',child:TextFormField(
        controller:local,validator:validMoney,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Reserva del local · USD',prefixIcon:Icon(Icons.home_work_outlined),hintText:'0,00'))),
      UxSection(title:'Deja contexto',icon:Icons.notes_rounded,child:Column(children:[
        TextFormField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Observación del saldo',alignLabelWithHint:true)),
        if(correcting)...[
          const FieldNote('Esta corrección recalcula los saldos y reabre los meses cerrados. Después deberás revisar los informes.',warning:true),
          TextFormField(controller:reason,maxLines:3,validator:(v)=>(v??'').trim().length<5?'Explica el motivo con al menos 5 caracteres.':null,
            decoration:const InputDecoration(labelText:'Motivo de la corrección',alignLabelWithHint:true)),
        ],
      ])),
    ])),
  );
}

class RentSetupForm extends StatefulWidget {
  const RentSetupForm({super.key,required this.person,required this.settings,required this.month,required this.onSave});
  final Json person,settings;
  final DateTime month;
  final Future<void> Function(Json) onSave;
  @override State<RentSetupForm> createState()=>_RentSetupFormState();
}
class _RentSetupFormState extends ServiceFormState<RentSetupForm> {
  final amount=TextEditingController(text:'12.00');
  DateTime? start;
  @override void dispose(){amount.dispose();super.dispose();}
  Future<void> chooseStart()async{
    final selected=await showModalBottomSheet<DateTime>(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>MonthSheet(selected:start??widget.month));
    if(selected!=null&&mounted)setState(()=>start=selected);
  }
  Future<void> save()async{
    if(start==null){setState(()=>error='Elige desde qué mes corresponde la cuota.');return;}
    if(period(start!).compareTo(widget.settings['start_month'] as String)<0){setState(()=>error='El inicio no puede ser anterior al inicio de Tesorería.');return;}
    await commit(()=>widget.onSave({'source_anniversary_id':widget.person['source_id'],'name':widget.person['name'],
      'start_month':period(start!),'end_month':null,'monthly_cents':cents(amount.text)}));
  }
  @override Widget build(BuildContext context)=>ServiceFormFrame(title:'Configurar su participación',
    description:'${widget.person['name']} · Confirma el compromiso antes de calcular sus cuotas.',icon:Icons.person_add_alt_1_outlined,
    submitLabel:'Guardar inicio y cuota',busy:saving,error:error,onSubmit:save,
    child:Form(key:form,child:Column(children:[
      UxSection(title:'Mes en que empieza a aportar',step:'01',description:'No asumimos fechas ni creamos una deuda sin este dato.',child:SelectionField(
        label:'Inicio de la cuota',value:start==null?'Seleccionar mes':monthLabel(start!),icon:Icons.calendar_month_outlined,onTap:chooseStart)),
      UxSection(title:'Compromiso mensual',step:'02',child:TextFormField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),
        validator:(v){final invalid=validMoney(v);if(invalid!=null)return invalid;return (cents(v??'')??0)<=0?'La cuota debe ser mayor que cero.':null;},
        decoration:const InputDecoration(labelText:'Cuota mensual · USD',prefixIcon:Icon(Icons.payments_outlined)))),
      const FieldNote('Esto configura cuotas informativas. El dinero solo entra al fondo cuando registras un aporte recibido. Los meses cerrados mantienen sus protecciones.'),
    ])),
  );
}

class CloseMonthForm extends StatefulWidget {
  const CloseMonthForm({super.key,required this.month,required this.report,required this.onSave});
  final DateTime month;
  final Json report;
  final Future<void> Function(Json) onSave;
  @override State<CloseMonthForm> createState()=>_CloseMonthFormState();
}
class _CloseMonthFormState extends ServiceFormState<CloseMonthForm> {
  final counted=TextEditingController(),note=TextEditingController();
  int get total=>rows(widget.report['funds']).fold<int>(0,(sum,f)=>sum+((f['closing'] as num?)?.toInt()??0));
  int? get actual{try{return cents(counted.text,optional:true);}catch(_){return null;}}
  @override void dispose(){counted.dispose();note.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final difference=actual==null?null:actual!-total;
    return ServiceFormFrame(title:'Cerrar ${monthLabel(widget.month)}',description:'Compara el registro con el dinero contado físicamente antes de cerrar el período.',
      icon:Icons.lock_clock_outlined,submitLabel:'Confirmar cierre del mes',busy:saving,error:error,
      onSubmit:()=>commit(()=>widget.onSave({'month':period(widget.month),'counted_cents':cents(counted.text),'note':note.text.trim()})),
      child:Form(key:form,child:Column(children:[
        UxSection(title:'Lo que indica el registro',step:'01',child:FactsGrid(facts:[
          for(final f in rows(widget.report['funds'])) UxFact(f['fund']=='rent'?'Reservado para el local':'Fondo general',money(f['closing'])),
          UxFact('Total calculado',money(total)),
        ])),
        UxSection(title:'Cuenta el dinero',step:'02',description:'Suma el efectivo y el dinero del grupo disponible en cuentas.',child:Column(children:[
          TextFormField(controller:counted,validator:validMoney,onChanged:(_)=>setState((){}),keyboardType:const TextInputType.numberWithOptions(decimal:true),
            decoration:const InputDecoration(labelText:'Dinero contado · USD',prefixIcon:Icon(Icons.payments_outlined))),
          const SizedBox(height:12),FactsGrid(facts:[UxFact('Diferencia con el registro',difference==null?'Por verificar':money(difference),
            color:difference!=null&&difference!=0?Theme.of(context).colorScheme.error:null)]),
        ])),
        UxSection(title:'Observación del cierre',step:'03',description:'Si hay una diferencia, explica su motivo antes de confirmar.',child:TextFormField(
          controller:note,maxLines:3,validator:(v)=>difference!=null&&difference!=0&&(v??'').trim().length<5?'Explica la diferencia (mínimo 5 caracteres).':null,
          decoration:const InputDecoration(labelText:'Nota del cierre',alignLabelWithHint:true))),
        const FieldNote('El cierre conserva el informe del período. Para corregir movimientos cerrados tendrás que reabrir el mes indicando un motivo.'),
      ])),
    );
  }
}

class TextRequestForm extends StatefulWidget {
  const TextRequestForm({super.key,required this.title,required this.description,this.password=false});
  final String title,description;
  final bool password;
  @override State<TextRequestForm> createState()=>_TextRequestFormState();
}
class _TextRequestFormState extends State<TextRequestForm> {
  final value=TextEditingController();
  @override void dispose(){value.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ServiceFormFrame(title:widget.title,description:widget.description,
    icon:widget.password?Icons.lock_outline:Icons.edit_note_rounded,
    onSubmit:()=>Navigator.pop(context,value.text),submitLabel:'Continuar',child:UxSection(title:widget.password?'Contraseña':'Escribe el motivo o la observación',child:TextField(
      controller:value,obscureText:widget.password,maxLines:widget.password?1:4,
      decoration:InputDecoration(labelText:widget.password?'Contraseña':'Detalle',alignLabelWithHint:!widget.password))),
  );
}

class ReasonActionForm extends StatefulWidget {
  const ReasonActionForm({super.key,required this.title,required this.description,required this.onSave});
  final String title,description;
  final Future<void> Function(String) onSave;
  @override State<ReasonActionForm> createState()=>_ReasonActionFormState();
}
class _ReasonActionFormState extends ServiceFormState<ReasonActionForm> {
  final reason=TextEditingController();
  @override void dispose(){reason.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ServiceFormFrame(title:widget.title,description:widget.description,
    icon:Icons.lock_open_rounded,submitLabel:'Reabrir con este motivo',busy:saving,error:error,
    onSubmit:()=>commit(()=>widget.onSave(reason.text.trim())),child:Form(key:form,child:UxSection(
      title:'Motivo de la reapertura',description:'Quedará guardado en el historial del servicio.',child:TextFormField(
        controller:reason,maxLines:4,validator:(v)=>(v??'').trim().length<5?'Explica el motivo con al menos 5 caracteres.':null,
        decoration:const InputDecoration(labelText:'Por qué necesitas reabrir',alignLabelWithHint:true)))),
  );
}

class ReportOptionsForm extends StatefulWidget {
  const ReportOptionsForm({super.key,required this.month});
  final DateTime month;
  @override State<ReportOptionsForm> createState()=>_ReportOptionsFormState();
}
class _ReportOptionsFormState extends State<ReportOptionsForm> {
  bool photos=false;
  @override Widget build(BuildContext context)=>ServiceFormFrame(title:'Prepara el informe',
    description:'${monthLabel(widget.month)} · Reúne la información del período para compartirla.',icon:Icons.picture_as_pdf_outlined,
    submitLabel:'Generar y compartir PDF',onSubmit:()=>Navigator.pop(context,photos),child:Column(children:[
      const UxSection(title:'Qué incluye el documento',icon:Icons.description_outlined,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('• Resumen por fondo\n• Ingresos y egresos separados\n• Anexo privado de aportes y deuda acumulada',style:TextStyle(height:1.8)),
      ])),
      UxSection(title:'Comprobantes',icon:Icons.receipt_long_outlined,child:Column(children:[
        SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,value:photos,onChanged:(v)=>setState(()=>photos=v),
          title:const Text('Incluir fotografías',style:TextStyle(fontWeight:FontWeight.w700)),
          subtitle:const Text('El PDF ocupará más espacio y puede tardar más en prepararse.')),
        const FieldNote('Los comprobantes adjuntos como PDF se consultan desde sus movimientos. Las fotos solo se añaden si activas esta opción.'),
      ])),
    ]),
  );
}
