import 'package:flutter/material.dart';
import 'brand.dart';
import 'treasury_widgets.dart';
import 'package:uuid/uuid.dart';
import 'treasury.dart';

/// Activity debts are separate from cash until the atomic payment RPC runs.
class ActivityEditor extends StatefulWidget {
  const ActivityEditor({super.key,required this.repo,required this.companions,this.account,this.payment=false});
  final TreasuryRepository repo;
  final List<Json> companions;
  final Json? account;
  final bool payment;
  @override State<ActivityEditor> createState()=>_ActivityEditorState();
}
class _ActivityEditorState extends State<ActivityEditor> {
  final activity=TextEditingController(),original=TextEditingController(),historical=TextEditingController(),amount=TextEditingController(),note=TextEditingController(),reason=TextEditingController();
  late final String operationId;
  String? companionId,error;DateTime? activityDate;DateTime paymentDate=today();bool busy=false,dirty=false;
  @override void initState(){
    super.initState();operationId=const Uuid().v4();final a=widget.account;
    companionId=a?['companion_id'];activity.text=a?['activity']??'';
    original.text=a==null?'':((a['original_cents'] as num)/100).toStringAsFixed(2);
    historical.text=a==null?'0':((a['historical_paid_cents'] as num)/100).toStringAsFixed(2);
    note.text=widget.payment?'':a?['note']??'';
    if(a?['activity_date']!=null)activityDate=DateTime.parse(a!['activity_date']);
    for(final controller in [activity,original,historical,amount,note,reason]){controller.addListener(()=>dirty=true);}
  }
  @override void dispose(){for(final c in [activity,original,historical,amount,note,reason]){c.dispose();}super.dispose();}
  Future<void> chooseCompanion() async {
    final id=await selectOption(context,title:'Elegir compañero',selected:companionId,searchable:true,options:widget.companions.map((companion)=><String,dynamic>{'value':companion['id'],'name':companion['name']}).toList());
    if(id!=null&&mounted)setState((){companionId=id;dirty=true;});
  }
  Future<bool> leave() async {
    if(busy)return false;if(!dirty)return true;
    return await showDialog<bool>(context:context,builder:(context)=>AlertDialog(title:const Text('¿Salir sin guardar?'),content:const Text('Los cambios de esta actividad no se han guardado.'),actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Seguir editando')),FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Salir'))]))??false;
  }
  Future<void> chooseDate() async {
    final current=widget.payment?paymentDate:activityDate??today();
    final first=DateTime(2013),last=today();
    final initial=current.isBefore(first)?first:current.isAfter(last)?last:current;
    final value=await showDatePicker(context:context,initialDate:initial,firstDate:first,lastDate:last);
    if(value!=null&&mounted)setState((){if(widget.payment){paymentDate=value;}else{activityDate=value;}dirty=true;});
  }
  Future<void> save()async{
    if(busy)return;
    try{
      Json data;
      if(widget.payment){
        final value=cents(amount.text)!;if(value<=0||value>(widget.account!['pending_cents'] as num))throw const FormatException('Indica un pago mayor que cero y no superior al saldo pendiente.');
        data={'id':widget.account!['id'],'entry_id':operationId,'entry_date':iso(paymentDate),'amount_cents':value,'note':note.text.trim()};
      }else{
        if(companionId==null&&!(widget.account!=null&&widget.account!['companion_id']==null))throw const FormatException('Selecciona al compañero.');
        if(activity.text.trim().length<3)throw const FormatException('Escribe el nombre de la actividad.');
        if(widget.account!=null&&reason.text.trim().length<5)throw const FormatException('Indica el motivo de la corrección.');
        data={'id':widget.account?['id']??operationId,'version':widget.account?['version']??0,'companion_id':companionId,'activity':activity.text.trim(),'original_cents':cents(original.text),'historical_paid_cents':cents(historical.text),'activity_date':activityDate==null?'':iso(activityDate!),'note':note.text.trim(),'reason':reason.text.trim()};
      }
      setState((){busy=true;error=null;});await widget.repo.profile();
      await widget.repo.client.rpc('treasury_activity_command',params:{'p_action':widget.payment?'pay':'save','p_data':data});
      dirty=false;if(mounted)Navigator.pop(context,true);
    }catch(e){if(mounted)setState(()=>error=message(e));}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context) {
    final selected=widget.companions.where((companion)=>companion['id']==companionId).firstOrNull;
    return PopScope(canPop:!busy&&!dirty,onPopInvokedWithResult:(didPop,result)async{if(!didPop&&await leave()&&mounted){setState(()=>dirty=false);if(context.mounted)Navigator.pop(context);}},child:Scaffold(
      appBar:AppBar(toolbarHeight:MediaQuery.textScalerOf(context).scale(20)*2*1.3+24,title:Text(widget.payment?'Registrar pago':widget.account==null?'Nuevo pendiente':'Corregir pendiente',maxLines:2,style:const TextStyle(fontSize:20)),actions:const [ThemeButton()]),
      body:ResponsiveBody(child:AbsorbPointer(absorbing:busy,child:ListView(padding:const EdgeInsets.fromLTRB(16,20,16,24),children:[
        if(widget.payment)...[
          FormSection(title:widget.account!['name'].toString(),icon:Icons.person_outline,subtitle:widget.account!['activity'].toString(),children:[MoneyCaption('Por cobrar',widget.account!['pending_cents'],emphasis:true)]),
          const InfoNote('El pago se sumará al fondo general. No lo ingreses otra vez en Movimientos.'),
          FormSection(title:'Dinero recibido',icon:Icons.add_card_outlined,children:[TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),style:const TextStyle(fontSize:25,fontWeight:FontWeight.w700),decoration:const InputDecoration(labelText:'Pago · USD',prefixText:'\$ ',hintText:'0,00'))]),
        ]else...[
          const InfoNote('Las deudas son informativas hasta que se recibe un pago. Los abonos históricos no vuelven a sumarse a los fondos.'),
          FormSection(title:'Compañero y actividad',icon:Icons.volunteer_activism_outlined,children:[SelectionField(label:'Compañero',value:selected?['name']?.toString()??widget.account?['name']?.toString()??'Elegir del registro del grupo',icon:Icons.person_search,onTap:chooseCompanion),const SizedBox(height:16),TextField(controller:activity,decoration:const InputDecoration(labelText:'Actividad',hintText:'Bingo, rifa u otra actividad'))]),
          FormSection(title:'Valores del compromiso',icon:Icons.account_balance_wallet_outlined,children:[TextField(controller:original,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Deuda original · USD',prefixText:'\$ ')),const SizedBox(height:16),TextField(controller:historical,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Abonos históricos · USD',prefixText:'\$ '))]),
        ],
        FormSection(title:'Fecha y observaciones',icon:Icons.calendar_month,children:[
          SelectionField(label:widget.payment?'Fecha del pago':'Fecha de la actividad',value:widget.payment?iso(paymentDate):activityDate==null?'Sin fecha · opcional':iso(activityDate!),icon:Icons.calendar_month,onTap:chooseDate),
          if(!widget.payment&&activityDate!=null)TextButton(onPressed:()=>setState((){activityDate=null;dirty=true;}),child:const Text('Dejar sin fecha')),
          const SizedBox(height:16),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Nota opcional')),
        ]),
        if(!widget.payment&&widget.account!=null)FormSection(title:'Motivo de la corrección',icon:Icons.edit_note,children:[TextField(controller:reason,maxLines:3,decoration:const InputDecoration(labelText:'Motivo'))]),
        if(error!=null)InfoNote(error!,icon:Icons.error_outline),
        FilledButton.icon(onPressed:busy?null:save,icon:Icon(busy?Icons.hourglass_top:Icons.check),label:Text(busy?'Guardando…':widget.payment?'Confirmar pago':'Guardar pendiente')),
      ]))),
    ));
  }
}
