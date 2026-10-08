import 'package:flutter/material.dart';
import 'treasury.dart';

/// Components deliberately use wrapping content rather than fixed text heights.
class LedgerPanel extends StatelessWidget {
  const LedgerPanel({super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline.withOpacity(.15)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.icon});
  final String title;
  final String? subtitle;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 18),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (icon != null) ...[
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 10),
      ],
      Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700, height: 1.25)),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.55)),
      ],
    ]),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.complete = false});
  final String text;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: complete ? colors.secondaryContainer : colors.primaryContainer, borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: complete ? colors.onSecondaryContainer : colors.onPrimaryContainer)),
    );
  }
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colors.primaryContainer.withOpacity(.45), borderRadius: BorderRadius.circular(18)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 21, color: colors.primary), const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: colors.onSurface, height: 1.5))),
      ]),
    );
  }
}

class EmptyLedger extends StatelessWidget {
  const EmptyLedger(this.title, this.message, {super.key, this.icon = Icons.receipt_long_outlined});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => LedgerPanel(child: Column(children: [
    const SizedBox(height: 12), Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
    const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), Text(message, textAlign: TextAlign.center, style: const TextStyle(height: 1.5)), const SizedBox(height: 12),
  ]));
}

class MoneyCaption extends StatelessWidget {
  const MoneyCaption(this.label, this.value, {super.key, this.emphasis = false});
  final String label;
  final Object? value;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: 12, height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height: 4),
    Text(money(value), style: TextStyle(fontSize: emphasis ? 25 : 19, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary)),
  ]);
}

class DueCard extends StatelessWidget {
  const DueCard({super.key, required this.due});
  final Json due;
  @override
  Widget build(BuildContext context) {
    final expected = (due['expected'] as num).toInt();
    final paid = (due['paid'] as num).toInt();
    final pending = (expected - paid).clamp(0, 100000000);
    final progress = expected > 0 ? (paid / expected).clamp(0.0, 1.0).toDouble() : 0.0;
    return LedgerPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.onPrimaryContainer)),
        const SizedBox(width: 12), Expanded(child: Text(due['name'].toString(), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.35))),
      ]),
      const SizedBox(height: 14), StatusPill(pending == 0 ? 'Cuota cubierta' : paid > 0 ? 'Abono recibido' : 'Por aportar', complete: pending == 0),
      const SizedBox(height: 18),
      Wrap(spacing: 26, runSpacing: 16, children: [MoneyCaption('Cuota del mes', expected), MoneyCaption('Recibido', paid), MoneyCaption('Pendiente', pending)]),
      const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6)),
    ]));
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.account, this.onPay, this.onEdit, required this.onPayment});
  final Json account;
  final VoidCallback? onPay, onEdit;
  final ValueChanged<Json> onPayment;
  @override
  Widget build(BuildContext context) {
    final pending = (account['pending_cents'] as num).toInt();
    final original = (account['original_cents'] as num).toInt();
    final historical = (account['historical_paid_cents'] as num).toInt();
    final received = (account['paid_cents'] as num).toInt();
    final progress = original > 0 ? ((historical + received) / original).clamp(0.0, 1.0).toDouble() : 0.0;
    final payments = rows(account['payments']);
    return LedgerPanel(padding: EdgeInsets.zero, child: ExpansionTile(
      // ExpansionTile stores bool state. Never let it use the ListView's
      // PageStorageKey: that entry stores a double scroll offset instead.
      key: PageStorageKey<String>('activity-expanded-${account['id']}'),
      tilePadding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      shape: const RoundedRectangleBorder(), collapsedShape: const RoundedRectangleBorder(),
      title: Text(account['name'].toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.35)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(account['activity'].toString(), style: const TextStyle(height: 1.5)),
        const SizedBox(height: 12), MoneyCaption(pending > 0 ? 'Por cobrar' : 'Saldo pendiente', pending, emphasis: true),
        const SizedBox(height: 12), StatusPill(pending > 0 ? 'Pendiente de actividad' : 'Cancelado', complete: pending == 0),
      ])),
      children: [
        const Divider(height: 28),
        Wrap(spacing: 26, runSpacing: 16, children: [MoneyCaption('Deuda original', original), MoneyCaption('Abonos históricos', historical), MoneyCaption('Pagos en el sistema', received)]),
        const SizedBox(height: 18), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 6)),
        if (account['activity_date'] != null) ...[const SizedBox(height: 12), Text('Actividad: ${account['activity_date']}')],
        if (account['note']?.toString().isNotEmpty == true) ...[const SizedBox(height: 12), Text(account['note'].toString(), style: const TextStyle(height: 1.5))],
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, children: [
          if (pending > 0 && onPay != null) FilledButton.icon(onPressed: onPay, icon: const Icon(Icons.add_card_outlined), label: const Text('Registrar pago')),
          if (onEdit != null) OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Corregir')),
        ]),
        const SizedBox(height: 22), const Align(alignment: Alignment.centerLeft, child: Text('Historial de pagos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
        const SizedBox(height: 8),
        if (payments.isEmpty) const Align(alignment: Alignment.centerLeft, child: Text('Aún no hay pagos registrados en la app.', style: TextStyle(height: 1.5))),
        for (final payment in payments) InkWell(
          borderRadius: BorderRadius.circular(12), onTap: () => onPayment(payment),
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.receipt_long_outlined, size: 22), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(money(payment['amount_cents']), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${payment['entry_date']} · Ver comprobante', style: const TextStyle(height: 1.5))])),
            const Icon(Icons.chevron_right),
          ])),
        ),
      ],
    ));
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.icon, required this.title, this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => LedgerPanel(padding: EdgeInsets.zero, child: InkWell(
    borderRadius: BorderRadius.circular(24), onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(20), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer)),
      const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.4)), if (subtitle != null) ...[const SizedBox(height: 6), Text(subtitle!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5))]])),
      if (onTap != null) ...[const SizedBox(width: 6), const Icon(Icons.chevron_right, size: 20)],
    ])),
  ));
}

class FormSection extends StatelessWidget {
  const FormSection({super.key, required this.title, required this.icon, required this.children, this.subtitle});
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LedgerPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, height: 1.4)))]),
    if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: const TextStyle(height: 1.5))],
    const SizedBox(height: 20), ...children,
  ]));
}

class SelectionField extends StatelessWidget {
  const SelectionField({super.key, required this.label, required this.value, this.onTap, this.icon = Icons.expand_more});
  final String label, value;
  final VoidCallback? onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(button: true, enabled: onTap != null, child: Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: colors.outline.withOpacity(.4))),
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)), const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w600, color: onTap == null ? colors.onSurfaceVariant : colors.onSurface)),
          ])), const SizedBox(width: 12), Icon(onTap == null ? Icons.lock_outline : icon, size: 22, color: colors.primary),
        ])),
      ),
    ));
  }
}

Future<String?> selectOption(BuildContext context, {required String title, required List<Json> options, String? selected, bool searchable = false}) => showModalBottomSheet<String>(
  context: context, isScrollControlled: true, useSafeArea: true,
  builder: (_) => OptionSheet(title: title, options: options, selected: selected, searchable: searchable),
);

class OptionSheet extends StatefulWidget {
  const OptionSheet({super.key, required this.title, required this.options, this.selected, this.searchable = false});
  final String title;
  final List<Json> options;
  final String? selected;
  final bool searchable;
  @override State<OptionSheet> createState() => _OptionSheetState();
}
class _OptionSheetState extends State<OptionSheet> {
  String query = '';
  String normalized(String value) {
    var text = value.toLowerCase().trim();
    for (final pair in const {'á':'a','é':'e','í':'i','ó':'o','ú':'u','ü':'u'}.entries) { text = text.replaceAll(pair.key, pair.value); }
    return text;
  }
  @override Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final available = MediaQuery.sizeOf(context).height - keyboard - MediaQuery.paddingOf(context).top;
    final options = widget.options.where((option) => normalized(option['name'].toString()).contains(normalized(query))).toList();
    return Padding(padding: EdgeInsets.only(bottom: keyboard), child: SizedBox(height: available * .72, child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(widget.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        if (widget.searchable) ...[const SizedBox(height: 12), TextField(decoration: const InputDecoration(hintText: 'Nombre o apellido', prefixIcon: Icon(Icons.search)), onChanged: (value) => setState(() => query = value)), const SizedBox(height: 12)],
        if (options.isEmpty) const Padding(padding:EdgeInsets.all(20),child:Text('No hay resultados. Prueba con otro nombre.',textAlign:TextAlign.center)),
        for (final option in options) Padding(padding: const EdgeInsets.only(bottom: 8), child: Material(
          color: widget.selected == option['value'] ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: Text(option['name'].toString(), style: const TextStyle(height: 1.4)), trailing: Icon(widget.selected == option['value'] ? Icons.check_circle : Icons.chevron_right), onTap: () => Navigator.pop(context, option['value'].toString())),
        )),
      ],
    )));
  }

}

class MonthSheet extends StatefulWidget {
  const MonthSheet({super.key, required this.selected});
  final DateTime selected;
  @override State<MonthSheet> createState() => _MonthSheetState();
}
class _MonthSheetState extends State<MonthSheet> {
  late int year;
  @override void initState() { super.initState(); year = widget.selected.year; }
  @override Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .72,
    child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [const Expanded(child: Text('Consultar período', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))), IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(tooltip: 'Año anterior', onPressed: year > 2013 ? () => setState(() => year--) : null, icon: const Icon(Icons.chevron_left)), Flexible(child: Text('$year', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700))), IconButton(tooltip: 'Año siguiente', onPressed: year < 2100 ? () => setState(() => year++) : null, icon: const Icon(Icons.chevron_right))]),
      const SizedBox(height: 16),
      Expanded(child: SingleChildScrollView(child: LayoutBuilder(builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(16) > 24;
        final columns = constraints.maxWidth < 280 || largeText ? 2 : 3;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(spacing: 10, runSpacing: 10, children: List.generate(12, (index) {
          final selected = year == widget.selected.year && index + 1 == widget.selected.month;
          return SizedBox(width: width, child: selected ? FilledButton(onPressed: () => Navigator.pop(context, DateTime(year, index + 1)), child: Text(monthNames[index], textAlign: TextAlign.center)) : OutlinedButton(onPressed: () => Navigator.pop(context, DateTime(year, index + 1)), child: Text(monthNames[index], textAlign: TextAlign.center)));
        }));
      }))),
    ])),
  );
}
