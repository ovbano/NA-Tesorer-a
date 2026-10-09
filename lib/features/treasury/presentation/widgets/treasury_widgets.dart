import 'package:flutter/material.dart';
import 'package:na_tesoreria/core/theme/brand.dart';
import 'package:na_tesoreria/features/treasury/treasury.dart';


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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
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
    );
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
  const ActivityCard({
    super.key,
    required this.account,
    this.onPay,
    this.onEdit,
    required this.onPayment,
  });
  final Json account;
  final VoidCallback? onPay, onEdit;
  final ValueChanged<Json> onPayment;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final pending = (account['pending_cents'] as num).toInt();
    final original = (account['original_cents'] as num).toInt();
    final historical = (account['historical_paid_cents'] as num).toInt();
    final received = (account['paid_cents'] as num).toInt();
    final progress =
        original > 0
            ? ((historical + received) / original).clamp(0.0, 1.0).toDouble()
            : 0.0;
    final payments = rows(account['payments']);
    return LedgerPanel(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        // Must never share a PageStorageKey with scroll-position storage.
        key: PageStorageKey<String>('activity-expanded-${account['id']}'),
        tilePadding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        iconColor: c.primary,
        collapsedIconColor: c.primary,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: c.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                color: c.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                account['name'].toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.ink,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account['activity'].toString(),
                style: TextStyle(color: c.muted, height: 1.45),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.soft,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: c.line),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    MoneyCaption(
                      pending > 0 ? 'Por cobrar' : 'Saldo pendiente',
                      pending,
                      emphasis: true,
                    ),
                    StatusPill(
                      pending > 0 ? 'Pendiente de actividad' : 'Cancelado',
                      complete: pending == 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),


        children: [
          Divider(color: c.line, height: 26),


          _FinanceGrid(
            items: [
              _FinanceCell('Deuda original', original),
              _FinanceCell('Abonos históricos', historical),
              _FinanceCell('Pagos en el sistema', received),
            ],
          ),


          const SizedBox(height: 19),


          _ProgressMeter(value: progress, label: 'Compromiso cubierto'),


          if (account['activity_date'] != null) ...[
            const SizedBox(height: 14),
            _DetailLine(
              Icons.event_outlined,
              'Actividad: ${account['activity_date']}',
            ),
          ],


          if (account['note']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            _DetailLine(Icons.notes_rounded, account['note'].toString()),
          ],


          const SizedBox(height: 18),


          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (pending > 0 && onPay != null)
                FilledButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.add_card_outlined),
                  label: const Text('Registrar pago'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    foregroundColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                ),


              if (onEdit != null)
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Corregir'),
                ),
            ],
          ),


          const SizedBox(height: 22),


          Text(
            'Historial de pagos',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),


          const SizedBox(height: 12),


          if (payments.isEmpty)
            Text(
              'Aún no hay pagos registrados en la app.',
              style: TextStyle(color: c.muted, height: 1.5),
            ),


          for (final payment in payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Material(
                color: c.soft,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => onPayment(payment),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: c.primary,
                          size: 22,
                        ),


                        const SizedBox(width: 12),


                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                money(payment['amount_cents']),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: c.ink,
                                ),
                              ),


                              const SizedBox(height: 4),


                              Text(
                                '${payment['entry_date']} · Ver comprobante',
                                style: TextStyle(color: c.muted, height: 1.45),
                              ),
                            ],
                          ),
                        ),


                        Icon(Icons.chevron_right_rounded, color: c.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
  const FormSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: c.soft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: c.primary, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
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
            ],
          ),
          const SizedBox(height: 18),
          Divider(color: c.line, height: 1),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
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
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 78),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
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
  String query = '';
  String normalized(String value) {
    var text = value.toLowerCase().trim();
    for (final pair
        in const {
          'á': 'a',
          'é': 'e',
          'í': 'i',
          'ó': 'o',
          'ú': 'u',
          'ü': 'u',
        }.entries) {
      text = text.replaceAll(pair.key, pair.value);
    }
    return text;
  }


  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final available =
        MediaQuery.sizeOf(context).height -
        keyboard -
        MediaQuery.paddingOf(context).top;
    final options =
        widget.options
            .where(
              (option) => normalized(
                option['name'].toString(),
              ).contains(normalized(query)),
            )
            .toList();
    final height = (available * .82).clamp(0.0, 700.0);
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.soft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(Icons.list_alt_rounded, color: c.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: c.ink),
                  ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar nombre o apellido',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 3, 20, 20),
                itemCount: options.isEmpty ? 1 : options.length,
                itemBuilder: (context, index) {
                  if (options.isEmpty)
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay resultados. Prueba con otro nombre.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.muted),
                      ),
                    );
                  final option = options[index];
                  final active = widget.selected == option['value'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color:
                          active
                              ? (c.dark
                                  ? const Color(0xFF263B5D)
                                  : const Color(0xFFEAF0FA))
                              : c.soft,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap:
                            () => Navigator.pop(
                              context,
                              option['value'].toString(),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option['name'].toString(),
                                  style: TextStyle(
                                    color: c.ink,
                                    fontWeight:
                                        active
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                active
                                    ? Icons.check_circle_rounded
                                    : Icons.chevron_right_rounded,
                                color: c.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
  void initState() {
    super.initState();
    year = widget.selected.year;
  }


  @override
  Widget build(BuildContext context) {
    final c = _Palette(context);
    final available = MediaQuery.sizeOf(context).height -
        MediaQuery.paddingOf(context).top - MediaQuery.paddingOf(context).bottom;
    final height = (available * .75).clamp(0.0, 680.0);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: c.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.calendar_month_outlined, color: c.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consultar período',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                      Text(
                        'Elige el mes del informe',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: c.ink),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
              decoration: BoxDecoration(
                color: c.soft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Año anterior',
                    onPressed:
                        year > 2013 ? () => setState(() => year--) : null,
                    icon: Icon(Icons.chevron_left_rounded, color: year > 2013 ? c.primary : c.muted),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Año siguiente',
                    onPressed:
                        year < 2100 ? () => setState(() => year++) : null,
                    icon: Icon(Icons.chevron_right_rounded, color: year < 2100 ? c.primary : c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bigText =
                      MediaQuery.textScalerOf(context).scale(16) > 24;
                  final columns = constraints.maxWidth < 215 ? 1 :
                        (constraints.maxWidth < 310 || bigText ? 2 : 3);
                  const spacing = 10.0;
                  final cellWidth =
                      (constraints.maxWidth - (columns - 1) * spacing) /
                      columns;
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(12, (index) {
                        final active =
                            year == widget.selected.year &&
                            index + 1 == widget.selected.month;
                        return SizedBox(
                          width: cellWidth,
                          child: Material(
                            color: active ? _navy : c.soft,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap:
                                  () => Navigator.pop(
                                    context,
                                    DateTime(year, index + 1),
                                  ),
                              child: Container(
                                constraints: const BoxConstraints(
                                  minHeight: 58,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: active ? _gold : c.line,
                                    width: active ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  monthNames[index],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active ? Colors.white : c.ink,
                                    fontWeight:
                                        active
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}