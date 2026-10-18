import 'experience.dart';
import 'ux_components.dart';
import 'package:flutter/material.dart';
import 'package:na_tesoreria/brand.dart';
import 'treasury.dart';


// Shared presentation tokens. No financial or backend operations live here.
const _navy = Color(0xFF071D49);
const _gold = Color(0xFFD9B96D);


class _Palette {
  _Palette(BuildContext context)
    : scheme = Theme.of(context).colorScheme,
      dark = Theme.of(context).brightness == Brightness.dark;
  final ColorScheme scheme;
  final bool dark;
  Color get surface => scheme.surface;
  Color get soft => dark ? const Color(0xFF192B47) : const Color(0xFFF4F7FC);
  Color get line => dark ? const Color(0xFF344661) : const Color(0xFFE0E7F0);
  Color get accent => dark ? const Color(0xFFF1D18B) : const Color(0xFF86641F);
  Color get ink => scheme.onSurface;
  Color get muted => scheme.onSurfaceVariant;
  Color get primary => dark ? const Color(0xFFBFD1FF) : _navy;
  Color get positive => dark ? const Color(0xFF9DE4C2) : const Color(0xFF176448);
  Color get positiveSoft => dark ? const Color(0xFF1C483A) : const Color(0xFFE5F5ED);
  Color get warning => dark ? const Color(0xFFFFD69A) : const Color(0xFF805615);
  Color get warningSoft => dark ? const Color(0xFF45351F) : const Color(0xFFFFF1D8);
}


class LedgerPanel extends StatelessWidget {
  const LedgerPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return PanelMotion(child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        gradient: LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[c.surface,Color.alphaBlend(c.primary.withOpacity(.025),c.surface)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(c.dark ? .12 : .035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    ));
  }
}


class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.icon});
  final String title;
  final String? subtitle;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.soft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.line),
              ),
              child: Icon(icon, color: c.primary, size: 24),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: c.ink,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    subtitle!,
                    style: TextStyle(color: c.muted, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.complete = false});
  final String text;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final foreground =
        complete
            ? (c.dark ? const Color(0xFFA7E8C7) : const Color(0xFF156443))
            : (c.dark ? const Color(0xFFFFD99C) : const Color(0xFF815515));
    final background =
        complete
            ? (c.dark ? const Color(0xFF174635) : const Color(0xFFE5F6EC))
            : (c.dark ? const Color(0xFF4B3821) : const Color(0xFFFFF2DA));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.soft,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: c.primary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: c.ink, height: 1.55)),
          ),
        ],
      ),
    );
  }
}


class EmptyLedger extends StatelessWidget {
  const EmptyLedger(
    this.title,
    this.message, {
    super.key,
    this.icon = Icons.receipt_long_outlined,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return LedgerPanel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: c.soft,
                shape: BoxShape.circle,
                border: Border.all(color: c.line),
              ),
              child: Icon(icon, size: 34, color: c.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.55, color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}


class MoneyCaption extends StatelessWidget {
  const MoneyCaption(
    this.label,
    this.value, {
    super.key,
    this.emphasis = false,
  });
  final String label;
  final Object? value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: c.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
          money(value),
          maxLines: 1,
          style: TextStyle(
            fontSize: emphasis ? 27 : 19,
            height: 1.22,
            fontWeight: FontWeight.w800,
            color: c.primary,
          ),
        ),
        ),
      ],
    );
  }
}


class _FinanceGrid extends StatelessWidget {
  const _FinanceGrid({required this.items});
  final List<Widget> items;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bigText = MediaQuery.textScalerOf(context).scale(16) > 23;
      final columns =
          constraints.maxWidth >= 570 && !bigText
              ? 3
              : constraints.maxWidth >= 380 && !bigText
              ? 2
              : 1;
      const gap = 10.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final child in items) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}


class _FinanceCell extends StatelessWidget {
  const _FinanceCell(this.label, this.amount, {this.highlight = false});
  final String label;
  final Object? amount;
  final bool highlight;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            highlight
                ? (c.dark ? const Color(0xFF263B5D) : const Color(0xFFEAF0FA))
                : c.soft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: c.line),
      ),
      child: MoneyCaption(label, amount, emphasis: highlight),
    );
  }
}


class DueCard extends StatelessWidget {
  const DueCard({super.key, required this.due});
  final Json due;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final expected = (due['expected'] as num).toInt();
    final paid = (due['paid'] as num).toInt();
    final pending = (expected - paid).clamp(0, 100000000);
    final progress =
        expected > 0 ? (paid / expected).clamp(0.0, 1.0).toDouble() : 0.0;
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: c.soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.person_outline_rounded, color: c.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      due['name'].toString(),
                      style: TextStyle(
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 9),
                    StatusPill(
                      pending == 0
                          ? 'Cuota cubierta'
                          : paid > 0
                          ? 'Abono recibido'
                          : 'Por aportar',
                      complete: pending == 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FinanceGrid(
            items: [
              _FinanceCell('Cuota del mes', expected),
              _FinanceCell('Recibido', paid),
              _FinanceCell('Pendiente', pending, highlight: pending > 0),
            ],
          ),
          const SizedBox(height: 17),
          _ProgressMeter(value: progress, label: 'Progreso de aporte'),
        ],
      ),
    );
  }
}


class _ProgressMeter extends StatelessWidget {
  const _ProgressMeter({required this.value, required this.label});
  final double value;
  final String label;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: c.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: c.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: c.line,
            valueColor: AlwaysStoppedAnimation<Color>(c.dark ? _gold : _navy),
          ),
        ),
      ],
    );
  }
}


class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key,required this.account,this.onPay,this.onEdit,required this.onPayment});
  final Json account;
  final VoidCallback? onPay,onEdit;
  final ValueChanged<Json> onPayment;
  @override Widget build(BuildContext context){
    final c=_Palette(context);
    final pending=(account['pending_cents'] as num).toInt();
    final original=(account['original_cents'] as num).toInt();
    final historical=(account['historical_paid_cents'] as num).toInt();
    final received=(account['paid_cents'] as num).toInt();
    final progress=original>0?((historical+received)/original).clamp(0.0,1.0).toDouble():0.0;
    final payments=rows(account['payments']);
    return LedgerPanel(padding:EdgeInsets.zero,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Padding(padding:const EdgeInsets.fromLTRB(18,18,18,0),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        StatusPill(pending>0?'Pendiente de actividad':'Cancelado',complete:pending==0),
        const SizedBox(height:12),Text(account['activity']??'Actividad del grupo',style:TextStyle(color:c.muted,fontSize:13,height:1.4)),
        const SizedBox(height:14),Text('Por cobrar',style:TextStyle(color:c.muted,fontSize:12)),
        const SizedBox(height:4),Text(money(pending),style:TextStyle(color:pending>0?c.ink:c.positive,fontSize:28,fontWeight:FontWeight.w900)),
      ])),
      ExpansionTile(key:PageStorageKey<String>('activity-expanded-${account['id']}'),
        tilePadding:const EdgeInsets.symmetric(horizontal:18,vertical:4),childrenPadding:const EdgeInsets.fromLTRB(18,0,18,18),
        shape:const RoundedRectangleBorder(),collapsedShape:const RoundedRectangleBorder(),
        title:Text(account['name'].toString(),style:TextStyle(color:c.ink,fontSize:19,fontWeight:FontWeight.w800,height:1.3)),
        subtitle:Text('Ver compromiso, abonos y comprobantes',style:TextStyle(color:c.muted,fontSize:12,height:1.4)),
        children:[
          const SizedBox(height:12),FactsGrid(facts:[UxFact('Compromiso original',money(original)),UxFact('Abonos históricos',money(historical)),UxFact('Pagos en el sistema',money(received))]),
          const SizedBox(height:18),_ProgressMeter(value:progress,label:'Compromiso cubierto'),
          if(account['activity_date']!=null)Padding(padding:const EdgeInsets.only(top:12),child:_DetailLine(Icons.event_outlined,'Actividad: ${account['activity_date']}')),
          if(account['note']?.toString().isNotEmpty==true)Padding(padding:const EdgeInsets.only(top:12),child:_DetailLine(Icons.notes_rounded,account['note'].toString())),
          const SizedBox(height:18),Wrap(spacing:10,runSpacing:10,children:[
            if(pending>0&&onPay!=null)FilledButton.icon(onPressed:onPay,icon:const Icon(Icons.add_card_outlined),label:const Text('Registrar pago')),
            if(onEdit!=null)OutlinedButton.icon(onPressed:onEdit,icon:const Icon(Icons.edit_outlined),label:const Text('Corregir')),
          ]),
          const SizedBox(height:20),Text('Historial de pagos',style:TextStyle(color:c.ink,fontSize:17,fontWeight:FontWeight.w800)),
          const SizedBox(height:12),
          if(payments.isEmpty)Text('Aún no hay pagos registrados en la app.',style:TextStyle(color:c.muted,height:1.5)),
          for(final payment in payments)Padding(padding:const EdgeInsets.only(bottom:10),child:Material(color:c.soft,borderRadius:BorderRadius.circular(16),child:InkWell(
            borderRadius:BorderRadius.circular(16),onTap:()=>onPayment(payment),child:Padding(padding:const EdgeInsets.all(14),child:Row(children:[
              Icon(Icons.receipt_long_outlined,color:c.primary),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(money(payment['amount_cents']),style:TextStyle(color:c.ink,fontSize:18,fontWeight:FontWeight.w800)),
                const SizedBox(height:4),Text('${payment['entry_date']} · Abrir movimiento',style:TextStyle(color:c.muted,fontSize:12,height:1.4)),
              ])),Icon(Icons.chevron_right_rounded,color:c.primary),
            ]))),
          )),
        ]),
    ]));
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: c.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(height: 1.5, color: c.muted)),
        ),
      ],
    );
  }
}


class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.soft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.line),
                  ),
                  child: Icon(icon, color: c.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                          color: c.ink,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: TextStyle(color: c.muted, height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 7),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 17,
                    color: c.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class FormSection extends StatelessWidget {
  const FormSection({super.key,required this.title,required this.icon,required this.children,this.subtitle});
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  @override Widget build(BuildContext context)=>UxSection(title:title,description:subtitle,icon:icon,
    child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:children));
}

class SelectionField extends StatelessWidget {
    const SelectionField({
      super.key,
      required this.label,
      required this.value,
      this.onTap,
      this.icon = Icons.expand_more,
    });

    final String label;
    final String value;
    final VoidCallback? onTap;
    final IconData icon;

    @override
    Widget build(BuildContext context) {
      final theme = Theme.of(context);
      final c = _Palette(context);
      final enabled = onTap != null;
      final dark = theme.brightness == Brightness.dark;

      final background = dark
          ? const Color(0xFF1A2B44)
          : const Color(0xFFF7F9FD);

      final borderColor = enabled
          ? (dark
              ? const Color(0xFF48648A)
              : const Color(0xFFD5E0EF))
          : c.line;

      final accentColor = dark
          ? brandGold
          : const Color(0xFF173F83);

      return Semantics(
        button: enabled,
        enabled: enabled,
        label: '$label: $value',
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(19),
            splashColor: accentColor.withOpacity(0.10),
            highlightColor: accentColor.withOpacity(0.05),
            child: AnimatedContainer(
              duration: experienceDuration(context,180),
              constraints: const BoxConstraints(minHeight: 82),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                  width: enabled ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Icono representativo del campo.
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: dark
                          ? const Color(0xFF293F61)
                          : const Color(0xFFE8EEFA),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      size: 23,
                      color: enabled ? accentColor : c.muted,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Etiqueta y valor.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: c.muted,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          value,
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: c.ink,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Indicador de interacción.
                  if (enabled)
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(
                          dark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Este campo no se puede modificar',
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: c.muted,
                        size: 19,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

Future<String?> selectOption(
  BuildContext context, {
  required String title,
  required List<Json> options,
  String? selected,
  bool searchable = false,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder:
      (_) => OptionSheet(
        title: title,
        options: options,
        selected: selected,
        searchable: searchable,
      ),
);


class OptionSheet extends StatefulWidget {
  const OptionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selected,
    this.searchable = false,
  });
  final String title;
  final List<Json> options;
  final String? selected;
  final bool searchable;
  @override
  State<OptionSheet> createState() => _OptionSheetState();
}


class _OptionSheetState extends State<OptionSheet> {
  final search=TextEditingController();
  String query='';
  @override
  void dispose(){search.dispose();super.dispose();}
  String normalized(String value){
    var text=value.toLowerCase().trim();
    for(final pair in const {'á':'a','é':'e','í':'i','ó':'o','ú':'u','ü':'u','ñ':'n'}.entries){text=text.replaceAll(pair.key,pair.value);}
    return text;
  }
  @override
  Widget build(BuildContext context){
    final c=_Palette(context);
    final keyboard=MediaQuery.viewInsetsOf(context).bottom;
    final available=(MediaQuery.sizeOf(context).height-keyboard-MediaQuery.paddingOf(context).top).clamp(0.0,760.0);
    final options=widget.options.where((o)=>normalized(o['name'].toString()).contains(normalized(query))).toList();
    return Padding(padding:EdgeInsets.only(bottom:keyboard),child:SizedBox(height:available*.9,
      child:CustomScrollView(keyboardDismissBehavior:ScrollViewKeyboardDismissBehavior.manual,slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(18,4,18,12),sliver:SliverToBoxAdapter(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          SheetHeading(title:widget.title,icon:widget.searchable?Icons.person_search_outlined:Icons.tune_rounded,
            subtitle:'Selecciona una opción para continuar',onClose:()=>Navigator.pop(context)),
          if(widget.searchable) ...[
            const SizedBox(height:16),TextField(controller:search,textInputAction:TextInputAction.search,
              decoration:InputDecoration(hintText:'Buscar nombre o apellido',prefixIcon:const Icon(Icons.search_rounded),
                suffixIcon:query.isEmpty?null:IconButton(tooltip:'Limpiar búsqueda',onPressed:(){search.clear();setState(()=>query='');},icon:const Icon(Icons.close_rounded))),
              onChanged:(v)=>setState(()=>query=v)),
          ],
          const SizedBox(height:12),Text('${options.length} opciones disponibles',style:TextStyle(color:c.muted,fontSize:12)),
        ]))),
        if(options.isEmpty) SliverToBoxAdapter(child:Padding(padding:const EdgeInsets.all(24),child:Column(children:[
          Icon(Icons.search_off_rounded,size:38,color:c.muted),const SizedBox(height:12),const Text('No hay resultados. Prueba con otro nombre.',textAlign:TextAlign.center)]))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(18,0,18,22),sliver:SliverList(delegate:SliverChildBuilderDelegate((context,index){
          final option=options[index],active=widget.selected==option['value'];
          return Padding(padding:const EdgeInsets.only(bottom:10),child:PanelMotion(child:Material(
            color:active?Theme.of(context).colorScheme.primaryContainer:c.soft,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(19),side:BorderSide(color:active?c.primary.withOpacity(.45):c.line)),
            clipBehavior:Clip.antiAlias,
            child:InkWell(onTap:()=>Navigator.pop(context,option['value'].toString()),child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[
              Container(width:34,height:34,alignment:Alignment.center,decoration:BoxDecoration(color:c.primary.withOpacity(.08),borderRadius:BorderRadius.circular(11)),
                child:Icon(active?Icons.check_rounded:widget.searchable?Icons.person_outline_rounded:Icons.circle_outlined,color:c.primary,size:19)),
              const SizedBox(width:12),Expanded(child:Text(option['name'].toString(),style:TextStyle(color:c.ink,fontWeight:active?FontWeight.w800:FontWeight.w600,height:1.4))),
              const SizedBox(width:8),Icon(active?Icons.check_circle_rounded:Icons.chevron_right_rounded,color:c.primary,size:21),
            ]))),
          )));
        },childCount:options.length))),
      ]),
    ));
  }
}

class MonthSheet extends StatefulWidget {
  const MonthSheet({super.key, required this.selected});
  final DateTime selected;
  @override
  State<MonthSheet> createState() => _MonthSheetState();
}


class _MonthSheetState extends State<MonthSheet> {
  late int year;
  @override
  void initState(){super.initState();year=widget.selected.year;}
  @override
  Widget build(BuildContext context){
    final c=_Palette(context);
    final height=(MediaQuery.sizeOf(context).height-MediaQuery.paddingOf(context).vertical)*.86;
    return SizedBox(height:height,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,4,18,24),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      SheetHeading(title:'Tu período de consulta',icon:Icons.date_range_rounded,
        subtitle:'Elige el año y toca el mes que deseas consultar.',onClose:()=>Navigator.pop(context)),
      const SizedBox(height:18),
      Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:c.soft,borderRadius:BorderRadius.circular(19),border:Border.all(color:c.line)),child:Row(children:[
        IconButton(tooltip:'Año anterior',onPressed:year>2013?()=>setState(()=>year--):null,icon:const Icon(Icons.chevron_left_rounded)),
        Expanded(child:AnimatedSwitcher(duration:experienceDuration(context),child:Text('$year',key:ValueKey(year),textAlign:TextAlign.center,style:TextStyle(color:c.ink,fontSize:28,fontWeight:FontWeight.w800)))),
        IconButton(tooltip:'Año siguiente',onPressed:year<2100?()=>setState(()=>year++):null,icon:const Icon(Icons.chevron_right_rounded)),
      ])),
      const SizedBox(height:10),Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:()=>Navigator.pop(context,DateTime(today().year,today().month)),
        icon:const Icon(Icons.today_rounded),label:const Text('Consultar mes actual'))),
      const SizedBox(height:6),
      LayoutBuilder(builder:(context,constraints){
        final big=MediaQuery.textScalerOf(context).scale(16)>24;
        final columns=constraints.maxWidth<240?1:big||constraints.maxWidth<340?2:3;
        final width=(constraints.maxWidth-(columns-1)*10)/columns;
        return Wrap(spacing:10,runSpacing:10,children:List.generate(12,(index){
          final active=year==widget.selected.year&&index+1==widget.selected.month;
          final now=year==today().year&&index+1==today().month;
          return SizedBox(width:width,child:PanelMotion(child:Material(
            color:active?brandNavy:c.soft,clipBehavior:Clip.antiAlias,
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(19),side:BorderSide(color:active?brandGold:now?c.primary:c.line,width:active?1.8:1)),
            child:InkWell(onTap:()=>Navigator.pop(context,DateTime(year,index+1)),child:Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:16),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Text('${index+1}'.padLeft(2,'0'),style:TextStyle(color:active?brandGold:c.muted,fontSize:11,fontWeight:FontWeight.w700)),
                const SizedBox(height:6),Text(monthNames[index],textAlign:TextAlign.center,style:TextStyle(color:active?Colors.white:c.ink,fontWeight:FontWeight.w700)),
                if(active||now) ...[const SizedBox(height:6),Icon(active?Icons.check_circle_rounded:Icons.circle,size:active?15:5,color:active?brandGold:c.primary)],
              ])),
            ),
          )));
        }));
      }),
      const SizedBox(height:16),Text('El mes marcado es tu consulta actual. Los saldos cambian al seleccionar otro período.',textAlign:TextAlign.center,style:TextStyle(color:c.muted,fontSize:12,height:1.4)),
    ])));
  }
}
