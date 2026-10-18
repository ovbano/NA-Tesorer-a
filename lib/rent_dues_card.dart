import 'package:flutter/material.dart';
import 'treasury.dart';
import 'rent_dues.dart';
import 'treasury_workspace_ui.dart';

class RentDuesCard extends StatelessWidget {
  const RentDuesCard({super.key, required this.member, this.onConfigure, this.onPay});
  final Json member;
  final VoidCallback? onConfigure;
  final ValueChanged<Json>? onPay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unknown = member['tracking'] == 'unconfigured';
    final periods = rows(member['periods']);
    final debt = rentAmount(member, 'total_pending');
    final accent = unknown ? colors.tertiary : debt > 0 ? colors.error : colors.primary;
    Widget amount(String title, String key) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title, style: TextStyle(color:colors.onSurfaceVariant)),
        const SizedBox(height:4),Text(unknown ? 'Por calcular' : money(member[key]),
          style: const TextStyle(fontSize:19,fontWeight:FontWeight.w800))],
    );
    return WorkspaceSurface(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          CircleAvatar(backgroundColor:accent.withOpacity(.12),
            child:Icon(Icons.person_outline,color:accent)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('${member['name']}',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
            Container(margin:const EdgeInsets.only(top:6),padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
              decoration:BoxDecoration(color:accent.withOpacity(.09),borderRadius:BorderRadius.circular(10)),
              child:Text(rentStatus(member),style:TextStyle(color:accent,fontWeight:FontWeight.w700,fontSize:12))),
          ])),
        ]),
        const SizedBox(height:20),
        amount('Deuda total acumulada','total_pending'),
        const Divider(height:28),
        Wrap(spacing:28,runSpacing:16,children:[
          amount('Meses anteriores','previous_pending'),
          amount('Mes consultado','current_pending'),
        ]),
        if (member['end_month'] != null) Padding(
          padding:const EdgeInsets.only(top:12),
          child:Text('Participación finalizada: ${member['end_month']}. Los pendientes se conservan.'),
        ),
        if (unknown) ...[
          const SizedBox(height:14),
          const Text('Confirma el inicio de su cuota mensual. No se asume una deuda de cero.'),
          if(onConfigure!=null) Padding(padding:const EdgeInsets.only(top:12),
            child:OutlinedButton.icon(onPressed:onConfigure,icon:const Icon(Icons.edit_calendar_outlined),label:const Text('Configurar inicio'))),
        ] else if(periods.isEmpty) ...[
          const SizedBox(height:14),const Text('Sin cuotas generadas en este período. Revisa su fecha de inicio.'),
        ] else ...[
          const SizedBox(height:12),
          ExpansionTile(key:PageStorageKey<String>('rent-expanded-${member['id']}'),tilePadding:EdgeInsets.zero,childrenPadding:EdgeInsets.zero,
            title:const Text('Ver meses y abonos',style:TextStyle(fontWeight:FontWeight.w700)),
            leading:Icon(Icons.history_rounded,color:colors.primary),children:[
              for(final p in periods) Container(
                width:double.infinity,
                margin:const EdgeInsets.only(bottom:12),padding:const EdgeInsets.all(14),
                decoration:BoxDecoration(color:colors.surfaceContainerHighest.withOpacity(.45),borderRadius:BorderRadius.circular(16)),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(monthLabel(DateTime.parse(p['month'] as String)),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:16)),
                  const SizedBox(height:10),
                  Wrap(spacing:18,runSpacing:10,children:[
                    Text('Cuota: ${money(p['expected'])}'),Text('Recibido: ${money(p['paid'])}'),
                    Text('Pendiente: ${money(p['pending'])}',style:const TextStyle(fontWeight:FontWeight.w700)),
                  ]),
                  if(rentAmount(p,'credit')>0) Padding(padding:const EdgeInsets.only(top:10),
                    child:Text('Excedente: ${money(p['credit'])}. No cancela automáticamente otros meses.')),
                  if(onPay!=null&&rentAmount(p,'pending')>0) Padding(
                    padding:const EdgeInsets.only(top:12),child:FilledButton.icon(
                      onPressed:()=>onPay!(p),icon:const Icon(Icons.add_card),label:const Text('Registrar abono a este mes'))),
                ]),
              ),
            ]),
        ],
      ],
    ));
  }
}
