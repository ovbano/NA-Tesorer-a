import 'package:flutter/material.dart';
import 'brand.dart';
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
  String? companionId,error;DateTime? activityDate;DateTime paymentDate=today();bool busy=false;
  @override void initState(){
    super.initState();operationId=const Uuid().v4();final a=widget.account;
    companionId=a?['companion_id'];activity.text=a?['activity']??'';
    original.text=a==null?'':((a['original_cents'] as num)/100).toStringAsFixed(2);
    historical.text=a==null?'0':((a['historical_paid_cents'] as num)/100).toStringAsFixed(2);
    note.text=widget.payment?'':a?['note']??'';
    if(a?['activity_date']!=null)activityDate=DateTime.parse(a!['activity_date']);
  }
  @override void dispose(){for(final c in [activity,original,historical,amount,note,reason]){c.dispose();}super.dispose();}
  Future<void> chooseCompanion()async{
    var query='';
    final id=await showModalBottomSheet<String>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>StatefulBuilder(builder:(c,set)=>Padding(padding:EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(c).bottom+20),child:SizedBox(height:MediaQuery.sizeOf(c).height*.6,child:Column(children:[TextField(decoration:const InputDecoration(labelText:'Buscar compañero',prefixIcon:Icon(Icons.search)),onChanged:(v)=>set(()=>query=v.toLowerCase())),Expanded(child:ListView(children:widget.companions.where((p)=>p['name'].toString().toLowerCase().contains(query)).map((p)=>ListTile(title:Text(p['name']),onTap:()=>Navigator.pop(c,p['id']))).toList()))])))));
    if(id!=null&&mounted)setState(()=>companionId=id);
  }
  Future<void> chooseDate()async{
    final value=await showDatePicker(context:context,initialDate:widget.payment?paymentDate:activityDate??today(),firstDate:DateTime(2013),lastDate:today());
    if(value!=null&&mounted)setState(()=>widget.payment?paymentDate=value:activityDate=value);
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
      if(mounted)Navigator.pop(context,true);
    }catch(e){if(mounted)setState(()=>error=message(e));}finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final selected=widget.companions.where((p)=>p['id']==companionId).firstOrNull;
    return PopScope(canPop:!busy,child:Scaffold(appBar:AppBar(title:Text(widget.payment?'Recibir pago de actividad':widget.account==null?'Nuevo pendiente':'Corregir pendiente')),body:ResponsiveBody(child:ListView(padding:const EdgeInsets.all(20),children:[
      if(widget.payment)...[Text('${widget.account!['name']} · ${widget.account!['activity']}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text('Por cobrar: ${money(widget.account!['pending_cents'])}'),const SizedBox(height:16),const Text('El pago se sumará al fondo general. No lo ingreses nuevamente en Movimientos.'),const SizedBox(height:16),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Dinero recibido · USD'))]
      else ...[OutlinedButton.icon(onPressed:busy?null:chooseCompanion,icon:const Icon(Icons.person_search),label:Text(selected?['name']??widget.account?['name']??'Elegir compañero')),const SizedBox(height:16),TextField(controller:activity,decoration:const InputDecoration(labelText:'Actividad: bingo, rifa…')),const SizedBox(height:16),TextField(controller:original,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Deuda original · USD')),const SizedBox(height:16),TextField(controller:historical,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Abonos anteriores al sistema · USD')),const SizedBox(height:10),const Text('Los abonos históricos son antecedentes. No se suman otra vez a los fondos actuales.')],
      const SizedBox(height:16),OutlinedButton.icon(onPressed:busy?null:chooseDate,icon:const Icon(Icons.calendar_today),label:Text(widget.payment?'Fecha del pago: ${iso(paymentDate)}':activityDate==null?'Fecha opcional · no disponible':'Fecha: ${iso(activityDate!)}')),
      if(!widget.payment&&activityDate!=null)TextButton(onPressed:()=>setState(()=>activityDate=null),child:const Text('Dejar sin fecha')),
      const SizedBox(height:16),TextField(controller:note,maxLines:3,decoration:const InputDecoration(labelText:'Nota opcional')),
      if(!widget.payment&&widget.account!=null)...[const SizedBox(height:16),TextField(controller:reason,maxLines:2,decoration:const InputDecoration(labelText:'Motivo de la corrección'))],
      if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(error!,style:const TextStyle(color:Colors.red))),const SizedBox(height:24),FilledButton(onPressed:busy?null:save,child:Text(busy?'Guardando…':widget.payment?'Confirmar pago':'Guardar pendiente')),
    ]))));
  }
}
