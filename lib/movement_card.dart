import 'package:flutter/material.dart';
import 'treasury.dart';
import 'treasury_workspace_ui.dart';

class MovementCard extends StatelessWidget {
  const MovementCard({super.key,required this.entry,required this.onTap});
  final Json entry;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme,dark=Theme.of(context).brightness==Brightness.dark;
    final income=entry['kind']=='income';
    final tone=income?(dark?const Color(0xFF8EE7BC):const Color(0xFF146443)):(dark?const Color(0xFFFFA8AF):const Color(0xFFAC3047));
    final status=entry['status']=='draft'?'Borrador':entry['status']=='void'?'Anulado':'Confirmado';
    final description=(entry['description']??'').toString().trim();
    Widget tag(String text)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),
      decoration:BoxDecoration(color:tone.withOpacity(.08),borderRadius:BorderRadius.circular(9)),
      child:Text(text,style:TextStyle(color:tone,fontWeight:FontWeight.w700,fontSize:11,height:1.3)));
    return WorkspaceSurface(padding:EdgeInsets.zero,child:Material(color:Colors.transparent,child:InkWell(onTap:onTap,child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(width:42,height:42,decoration:BoxDecoration(color:tone.withOpacity(.10),borderRadius:BorderRadius.circular(14)),
              child:Icon(income?Icons.south_west_rounded:Icons.north_east_rounded,color:tone,size:23)),
            const SizedBox(width:12),Expanded(child:Wrap(spacing:7,runSpacing:7,children:[tag(income?'INGRESO':'EGRESO'),tag(status)])),
          ]),
          const SizedBox(height:16),
          Text(entry['amount_cents']==null?'Importe por completar':'${income?'+':'−'} ${money(entry['amount_cents'])}',
            style:TextStyle(color:tone,fontSize:27,fontWeight:FontWeight.w900,height:1.2)),
          const SizedBox(height:11),Text(description.isEmpty?'Movimiento por completar':description,
            style:TextStyle(color:c.onSurface,fontSize:17,fontWeight:FontWeight.w700,height:1.4)),
          const SizedBox(height:8),Text(categories[entry['category']]??'Otro movimiento',style:TextStyle(color:c.onSurfaceVariant,fontSize:12)),
          const SizedBox(height:16),Wrap(spacing:14,runSpacing:10,children:[
            _meta(context,Icons.calendar_today_outlined,entry['entry_date']?.toString()??'Fecha por definir'),
            _meta(context,entry['fund']=='rent'?Icons.home_work_outlined:Icons.volunteer_activism_outlined,entry['fund']=='rent'?'Fondo del local':'Fondo general'),
            if(entry['member_name']!=null)_meta(context,Icons.person_outline_rounded,'${entry['member_name']}'),
            if(entry['receipt_path']!=null)_meta(context,Icons.receipt_long_outlined,'Con comprobante'),
          ]),
        ])),
        Container(padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),decoration:BoxDecoration(color:c.primary.withOpacity(.035),border:Border(top:BorderSide(color:c.outlineVariant.withOpacity(.65)))),
          child:Row(children:[Expanded(child:Text(entry['status']=='draft'?'Abrir y completar':'Ver detalle y opciones',style:TextStyle(color:c.primary,fontWeight:FontWeight.w700,fontSize:12))),
            Icon(Icons.arrow_forward_rounded,color:c.primary,size:18)])),
      ],
    ))));
  }
  Widget _meta(BuildContext context,IconData icon,String text)=>Row(mainAxisSize:MainAxisSize.min,children:[
    Icon(icon,size:15,color:Theme.of(context).colorScheme.onSurfaceVariant),const SizedBox(width:5),
    Flexible(child:Text(text,style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:12,height:1.4))),
  ]);
}
