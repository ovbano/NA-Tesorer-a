import 'package:flutter/material.dart';
import 'treasury.dart';
import 'rent_dues.dart';
import 'ux_components.dart';
import 'treasury_workspace_ui.dart';

class RentDuesCard extends StatelessWidget {
  const RentDuesCard({super.key,required this.member,this.onConfigure,this.onPay});
  final Json member;
  final VoidCallback? onConfigure;
  final ValueChanged<Json>? onPay;
  @override Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme;
    final unknown=member['tracking']=='unconfigured';
    final periods=rows(member['periods']);
    final pending=periods.where((p)=>rentAmount(p,'pending')>0).toList();
    final debt=rentAmount(member,'total_pending');
    final accent=unknown?c.tertiary:debt>0?c.error:c.primary;
    return WorkspaceSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        CircleAvatar(backgroundColor:accent.withOpacity(.09),child:Icon(Icons.person_outline_rounded,color:accent)),
        const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${member['name']}',style:TextStyle(color:c.onSurface,fontSize:20,fontWeight:FontWeight.w800,height:1.3)),
          const SizedBox(height:6),Text(rentStatus(member),style:TextStyle(color:accent,fontSize:12,fontWeight:FontWeight.w700)),
        ])),
      ]),
      const SizedBox(height:18),
      if(unknown)...[
        const FieldNote('Falta confirmar desde qué mes le corresponde aportar. Su deuda todavía no se puede calcular.'),
        if(onConfigure!=null) FilledButton.tonalIcon(onPressed:onConfigure,icon:const Icon(Icons.edit_calendar_outlined),label:const Text('Configurar inicio y cuota')),
      ]else ...[
        Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:accent.withOpacity(.06),borderRadius:BorderRadius.circular(18)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Deuda total acumulada',style:TextStyle(color:c.onSurfaceVariant,fontSize:12)),
            const SizedBox(height:7),Text(money(member['total_pending']),style:TextStyle(color:accent,fontSize:28,fontWeight:FontWeight.w900))])),
        const SizedBox(height:12),FactsGrid(facts:[UxFact('Meses anteriores',money(member['previous_pending'])),UxFact('Mes consultado',money(member['current_pending']))]),
        if(member['end_month']!=null) FieldNote('Participación finalizada: ${member['end_month']}. Sus pendientes anteriores se conservan.'),
        if(onPay!=null&&pending.isNotEmpty)...[const SizedBox(height:14),FilledButton.icon(onPressed:()=>onPay!(pending.first),icon:const Icon(Icons.add_card_outlined),label:const Text('Abonar al pendiente más antiguo'))],
        if(periods.isEmpty)const FieldNote('Sin cuotas generadas en este período. Revisa el inicio de su participación.')
        else ExpansionTile(key:PageStorageKey<String>('rent-expanded-${member['id']}'),tilePadding:EdgeInsets.zero,childrenPadding:EdgeInsets.zero,
          leading:Icon(Icons.history_rounded,color:c.primary),title:const Text('Ver meses y abonos',style:TextStyle(fontWeight:FontWeight.w700)),children:[
            for(final p in periods) UxSection(title:monthLabel(DateTime.parse(p['month'] as String)),icon:Icons.calendar_month_outlined,
              child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
                FactsGrid(facts:[UxFact('Cuota',money(p['expected'])),UxFact('Recibido',money(p['paid'])),UxFact('Pendiente',money(p['pending']))]),
                if(rentAmount(p,'credit')>0)FieldNote('Excedente: ${money(p['credit'])}. No cancela automáticamente otros meses.'),
                if(onPay!=null&&rentAmount(p,'pending')>0)...[const SizedBox(height:12),OutlinedButton.icon(onPressed:()=>onPay!(p),icon:const Icon(Icons.add_card_outlined),label:const Text('Registrar abono a este mes'))],
              ])),
          ]),
      ],
    ]));
  }
}
