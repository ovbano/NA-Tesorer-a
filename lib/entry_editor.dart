import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'brand.dart';
import 'treasury_widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'treasury.dart';

class EntryEditor extends StatefulWidget {
  const EntryEditor({super.key,required this.repo,required this.month,required this.settings,required this.members,required this.companions,this.entry});
  final TreasuryRepository repo;final DateTime month;final Json settings;final List<Json> members,companions;final Json? entry;
  @override State<EntryEditor> createState()=>_EntryEditorState();
}
class _EntryEditorState extends State<EntryEditor> {
  final amount=TextEditingController(),description=TextEditingController(),noReceipt=TextEditingController(),reason=TextEditingController();
  late String id,kind,category,fund;late int version;late DateTime date,due;String? memberId,receiptPath,error;XFile? photo;bool busy=false,dirty=false;
  bool get correcting=>widget.entry?['status']=='posted';bool get rent=>category=='rent_contribution';
  @override void initState(){super.initState();final e=widget.entry??{};id=e['id']??const Uuid().v4();version=e['version']??0;kind=e['kind']??'income';category=e['category']??'seventh';fund=e['fund']??'general';date=DateTime.parse(e['entry_date']??iso(today()));due=DateTime.parse(e['due_month']??period(widget.month));memberId=e['member_id'];receiptPath=e['receipt_path'];amount.text=e['amount_cents']==null?'':((e['amount_cents'] as num)/100).toStringAsFixed(2);description.text=e['description']??'';noReceipt.text=e['no_receipt_reason']??'';for(final c in [amount,description,noReceipt,reason]){c.addListener(()=>dirty=true);}}
  @override void dispose(){for(final c in [amount,description,noReceipt,reason]){c.dispose();}super.dispose();}
  void changed(VoidCallback update){setState((){update();dirty=true;});}
  Future<void> pick(ImageSource source) async {try{final result=await ImagePicker().pickImage(source:source,maxWidth:1600,maxHeight:1600,imageQuality:78);if(result!=null&&mounted)changed(()=>photo=result);}catch(e){if(mounted)setState(()=>error='No se pudo abrir la cámara o galería. Revisa los permisos.');}}
  Future<bool> leave()async {if(busy)return false;if(!dirty)return true;return await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('¿Salir sin guardar?'),content:const Text('Los datos que has escrito se perderán. Puedes volver y guardarlos como borrador.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Seguir editando')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Salir'))]))??false;}
  Future<void> chooseMember() async {
    final choices=<Json>[...widget.members.map((m)=>{'value':m['id'],'name':m['name']}),...widget.companions.where((c)=>!widget.members.any((m)=>m['source_anniversary_id']==c['id'])).map((c)=>{'value':'source:${c['id']}','name':c['name']})];
    final selected=await selectOption(context,title:'Elegir compañero',options:choices,selected:memberId,searchable:true);
    if(selected!=null&&mounted)changed(()=>memberId=selected);
  }
  Future<void> chooseCategory() async {
    final value=await selectOption(context,title:'Categoría del movimiento',selected:category,options:categories.entries.where((entry)=>incomeCategories.contains(entry.key)==(kind=='income')).map((entry)=><String,dynamic>{'value':entry.key,'name':entry.value}).toList());
    if(value!=null&&mounted)changed((){category=value;if(category=='rent'||rent)fund='rent';if(category=='seventh')fund='general';});
  }
  Future<void> chooseFund() async {
    final value=await selectOption(context,title:'Fondo que recibe o paga',selected:fund,options:const [{'value':'general','name':'General · gastos del grupo'},{'value':'rent','name':'Local · reservado para arriendo'}]);
    if(value!=null&&mounted)changed(()=>fund=value);
  }

  Future<void> save(bool posted) async {
    if(busy)return;
    try {
      final value=cents(amount.text,optional:!posted);if(value!=null&&value<=0)throw const FormatException('Indica un monto mayor que cero.');
      if(posted&&description.text.trim().length<3)throw const FormatException('Describe el movimiento.');
      if(posted&&rent&&memberId==null)throw const FormatException('Selecciona al compañero del aporte.');
      if(posted&&kind=='expense'&&receiptPath==null&&photo==null&&noReceipt.text.trim().length<5)throw const FormatException('Adjunta un comprobante o explica por qué no existe.');
      if(correcting&&reason.text.trim().length<5)throw const FormatException('Indica el motivo de la corrección.');
      setState((){busy=true;error=null;});
      // Confirm active role immediately before every write; the RPC validates it again.
      await widget.repo.profile();
      if(photo!=null){final bytes=await photo!.readAsBytes();if(bytes.length>10485760)throw const FormatException('La fotografía supera 10 MB. Selecciona otra.');final png=bytes.length>8&&bytes[0]==137&&bytes[1]==80&&bytes[2]==78&&bytes[3]==71;final jpeg=bytes.length>3&&bytes[0]==255&&bytes[1]==216;final webp=bytes.length>12&&String.fromCharCodes(bytes.take(4))=='RIFF'&&String.fromCharCodes(bytes.sublist(8,12))=='WEBP';if(!png&&!jpeg&&!webp)throw const FormatException('Selecciona una fotografía JPG, PNG o WEBP.');final ext=png?'png':webp?'webp':'jpg';final path='$id/${const Uuid().v4()}.$ext';await widget.repo.client.storage.from('treasury-receipts').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:'image/${png?'png':webp?'webp':'jpeg'}'));receiptPath=path;photo=null;}
      final payload=<String,dynamic>{'id':id,'version':version,'status':posted?'posted':'draft','entry_date':iso(date),'kind':kind,'category':category,'fund':fund,'amount_cents':value,'description':description.text.trim(),'member_id':rent&&memberId?.startsWith('source:')!=true?memberId:null,'due_month':rent?period(due):null,'receipt_path':receiptPath,'no_receipt_reason':noReceipt.text.trim(),if(rent&&memberId?.startsWith('source:')==true)'source_anniversary_id':memberId!.substring(7),if(correcting)'reason':reason.text.trim()};
      await widget.repo.command(correcting?'correct':'save',payload);
      dirty=false;if(mounted)Navigator.pop(context,true);
    }catch(e){if(mounted)setState(()=>error=message(e));}finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> pickDate(bool month) async {
    final initial=month?due:date;
    final start=DateTime.parse(widget.settings['start_month']);
    final first=month?DateTime(start.year,start.month):start;
    final last=month?DateTime(today().year+2,12,31):today();
    if(first.isAfter(last)){setState(()=>error='El inicio de Tesorería es posterior a hoy. Revisa los fondos iniciales.');return;}
    final safeInitial=initial.isBefore(first)?first:initial.isAfter(last)?last:initial;
    final picked=await showDatePicker(context:context,initialDate:safeInitial,firstDate:first,lastDate:last,helpText:month?'Mes del aporte':'Fecha del movimiento');
    if(picked!=null&&mounted)changed((){if(month){due=DateTime(picked.year,picked.month);}else{date=picked;}});
  }
  Widget saveActions()=>Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:12,runSpacing:12,alignment:WrapAlignment.center,children:[
    if(!correcting)OutlinedButton.icon(onPressed:busy?null:()=>save(false),icon:const Icon(Icons.edit_note),label:const Text('Guardar borrador')),
    FilledButton.icon(onPressed:busy?null:()=>save(true),icon:Icon(busy?Icons.hourglass_top:Icons.check),label:Text(busy?'Guardando…':correcting?'Guardar corrección':'Confirmar movimiento')),
  ]));
  @override Widget build(BuildContext context) {
    final compact=MediaQuery.sizeOf(context).height<500||MediaQuery.viewInsetsOf(context).bottom>0;
    final selected=[...widget.members.map((member)=>{'value':member['id'],'name':member['name']}),...widget.companions.map((companion)=>{'value':'source:${companion['id']}','name':companion['name']})].where((companion)=>companion['value']==memberId).firstOrNull;
    return PopScope(canPop:!dirty&&!busy,onPopInvokedWithResult:(didPop,result)async{
      if(!didPop&&await leave()&&mounted){setState(()=>dirty=false);if(context.mounted)Navigator.pop(context);}
    },child:Scaffold(
      appBar:AppBar(toolbarHeight:MediaQuery.textScalerOf(context).scale(20)*2*1.3+24,title:Text(correcting?'Corregir movimiento':widget.entry==null?'Nuevo movimiento':'Completar borrador',maxLines:2,style:const TextStyle(fontSize:20)),actions:const [ThemeButton()]),
      body:ResponsiveBody(child:AbsorbPointer(absorbing:busy,child:ListView(padding:const EdgeInsets.fromLTRB(16,20,16,24),children:[
        const InfoNote('General: gastos del grupo. Local: dinero reservado para el arriendo. Puedes guardar un borrador y completarlo después.'),
        FormSection(title:'Datos del movimiento',icon:Icons.swap_vert,children:[
          Wrap(spacing:10,runSpacing:10,children:[for(final option in const {'income':'Ingreso','expense':'Egreso'}.entries)ChoiceChip(label:Text(option.value),avatar:Icon(option.key=='income'?Icons.south_west:Icons.north_east,size:18),selected:kind==option.key,onSelected:(_)=>changed((){kind=option.key;category=kind=='income'?'seventh':'supplies';fund='general';}))]),
          const SizedBox(height:18),SelectionField(label:'Categoría',value:categories[category]??category,onTap:chooseCategory),
          const SizedBox(height:16),SelectionField(label:'Fondo que recibe o paga',value:fund=='rent'?'Local · reservado para arriendo':'General · gastos del grupo',onTap:['rent','rent_contribution','seventh'].contains(category)?null:chooseFund),
          const SizedBox(height:16),SelectionField(label:'Fecha del movimiento',value:iso(date),icon:Icons.calendar_month,onTap:()=>pickDate(false)),
          const SizedBox(height:16),TextField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),style:const TextStyle(fontSize:25,fontWeight:FontWeight.w700),decoration:const InputDecoration(labelText:'Monto · USD',hintText:'0,00',prefixText:'\$ ')),
          const SizedBox(height:16),TextField(controller:description,maxLines:3,decoration:const InputDecoration(labelText:'Detalle',hintText:'Ejemplo: séptima de la reunión')),
        ]),
        if(rent)FormSection(title:'Aporte para el local',icon:Icons.home_outlined,children:[
          SelectionField(label:'Compañero',value:selected?['name']?.toString()??'Elegir del registro del grupo',icon:Icons.person_search,onTap:chooseMember),
          const SizedBox(height:16),SelectionField(label:'Mes del aporte',value:monthLabel(due),icon:Icons.date_range,onTap:()=>pickDate(true)),
        ]),
        FormSection(title:'Comprobante',icon:Icons.receipt_long_outlined,subtitle:'Toma una fotografía o selecciona una imagen de tu galería.',children:[
          Wrap(spacing:10,runSpacing:10,children:[OutlinedButton.icon(onPressed:()=>pick(ImageSource.camera),icon:const Icon(Icons.camera_alt_outlined),label:const Text('Tomar foto')),OutlinedButton.icon(onPressed:()=>pick(ImageSource.gallery),icon:const Icon(Icons.photo_library_outlined),label:const Text('Galería'))]),
          if(photo!=null)...[const SizedBox(height:16),ClipRRect(borderRadius:BorderRadius.circular(16),child:FutureBuilder<Uint8List>(future:photo!.readAsBytes(),builder:(context,snapshot){
            if(snapshot.hasError)return const InfoNote('No se pudo abrir esta fotografía. Selecciona otra.');
            if(!snapshot.hasData)return const SizedBox(height:160,child:Center(child:CircularProgressIndicator()));
            return Image.memory(snapshot.data!,height:220,fit:BoxFit.contain,errorBuilder:(_,error,stack)=>const InfoNote('Esta imagen no se puede mostrar. Selecciona otra.'));
          }))],
          if(receiptPath!=null)...[const SizedBox(height:16),const StatusPill('Comprobante adjunto',complete:true)],
          if(kind=='expense')...[const SizedBox(height:16),TextField(controller:noReceipt,maxLines:3,decoration:const InputDecoration(labelText:'Si no hay comprobante',hintText:'Explica el motivo'))],
        ]),
        if(correcting)FormSection(title:'Motivo de la corrección',icon:Icons.edit_note,subtitle:'La modificación quedará registrada en el historial.',children:[TextField(controller:reason,maxLines:3,decoration:const InputDecoration(labelText:'Motivo'))]),
        if(error!=null)InfoNote(error!,icon:Icons.error_outline),
        if(compact)saveActions(),
      ]))),
      bottomNavigationBar:compact?null:SafeArea(child:saveActions()),
    ));
  }
}
