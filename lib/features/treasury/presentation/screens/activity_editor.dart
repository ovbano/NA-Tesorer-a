import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:na_tesoreria/core/theme/brand.dart';
import 'package:na_tesoreria/shared/widgets/group_logo.dart';
import 'package:na_tesoreria/features/treasury/treasury.dart';
import 'package:na_tesoreria/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:na_tesoreria/shared/dialogs/treasury_dialogs.dart';
import 'package:na_tesoreria/shared/calendar/treasury_calendar.dart';
import 'package:na_tesoreria/features/treasury/presentation/widgets/treasury_header.dart';

/// Las deudas de actividades no afectan al efectivo hasta registrar un pago.
class ActivityEditor extends StatefulWidget {
  const ActivityEditor({
    super.key,
    required this.repo,
    required this.companions,
    this.account,
    this.payment = false,
  });

  final TreasuryRepository repo;
  final List<Json> companions;
  final Json? account;
  final bool payment;

  @override
  State<ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<ActivityEditor> {
  final activity = TextEditingController();
  final original = TextEditingController();
  final historical = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  final reason = TextEditingController();

  late final String operationId;
  String? companionId, error;
  DateTime? activityDate;
  DateTime paymentDate = today();
  bool busy = false, dirty = false;

  bool get editing => widget.account != null && !widget.payment;

  @override
  void initState() {
    super.initState();
    operationId = const Uuid().v4();
    final a = widget.account;
    companionId = a?['companion_id'];
    activity.text = a?['activity'] ?? '';
    original.text = a == null ? '' : ((a['original_cents'] as num) / 100).toStringAsFixed(2);
    historical.text = a == null ? '0' : ((a['historical_paid_cents'] as num) / 100).toStringAsFixed(2);
    note.text = widget.payment ? '' : a?['note'] ?? '';
    if (a?['activity_date'] != null) activityDate = DateTime.parse(a!['activity_date']);
    for (final controller in [activity, original, historical, amount, note, reason]) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    dirty = true;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [activity, original, historical, amount, note, reason]) {
      controller.removeListener(_onFieldChanged);
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> chooseCompanion() async {
    final id = await selectOption(
      context,
      title: 'Elegir compañero',
      selected: companionId,
      searchable: true,
      options: widget.companions
          .map((c) => <String, dynamic>{'value': c['id'], 'name': c['name']})
          .toList(),
    );
    if (id != null && mounted) setState(() { companionId = id; dirty = true; });
  }

  Future<bool> leave() async {
    if (busy) return false;
    if (!dirty) return true;
    return confirmDiscardChanges(context,
      title: widget.payment ? '¿Salir sin registrar el pago?' : '¿Salir sin guardar?',
      description: widget.payment
          ? 'El pago que estás preparando todavía no se ha registrado.'
          : 'Los cambios de esta actividad aún no se han guardado.',
    );
  }

  Future<void> chooseDate() async {
    final current = widget.payment ? paymentDate : activityDate ?? today();
    final value = await showTreasuryCalendar(
      context,
      selected: current,
      firstDate: DateTime(2013),
      lastDate: today(),
      title: widget.payment ? 'Fecha del pago' : 'Fecha de la actividad',
    );
    if (value != null && mounted) {
      setState(() {
        if (widget.payment) { paymentDate = value; } else { activityDate = value; }
        dirty = true;
      });
    }
  }

  Future<void> save() async {
    if (busy) return;
    try {
      Json data;
      if (widget.payment) {
        final value = cents(amount.text)!;
        if (value <= 0 || value > (widget.account!['pending_cents'] as num)) {
          throw const FormatException('Indica un pago mayor que cero y no superior al saldo pendiente.');
        }
        data = {
          'id': widget.account!['id'],
          'entry_id': operationId,
          'entry_date': iso(paymentDate),
          'amount_cents': value,
          'note': note.text.trim(),
        };
      } else {
        if (companionId == null && !(widget.account != null && widget.account!['companion_id'] == null)) {
          throw const FormatException('Selecciona al compañero.');
        }
        if (activity.text.trim().length < 3) {
          throw const FormatException('Escribe el nombre de la actividad.');
        }
        if (widget.account != null && reason.text.trim().length < 5) {
          throw const FormatException('Indica el motivo de la corrección.');
        }
        data = {
          'id': widget.account?['id'] ?? operationId,
          'version': widget.account?['version'] ?? 0,
          'companion_id': companionId,
          'activity': activity.text.trim(),
          'original_cents': cents(original.text),
          'historical_paid_cents': cents(historical.text),
          'activity_date': activityDate == null ? '' : iso(activityDate!),
          'note': note.text.trim(),
          'reason': reason.text.trim(),
        };
      }
      setState(() { busy = true; error = null; });
      await widget.repo.profile();
      await widget.repo.client.rpc('treasury_activity_command', params: {
        'p_action': widget.payment ? 'pay' : 'save',
        'p_data': data,
      });
      dirty = false;
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = message(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int? _readCents(String input) {
    try { return cents(input, optional: true); } catch (_) { return null; }
  }

  Widget _hero(BuildContext context, {required String heading, required String detail, required IconData icon}) {
    final isPayment = widget.payment;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xff061531), Color(0xff0d2f62), Color(0xff164976)]),
        border: Border.all(color: brandGold.withOpacity(.44)),
        boxShadow: [BoxShadow(color: brandNavy.withOpacity(.18), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: Stack(children: [
        Positioned(right: -56, top: -70, child: Container(width: 190, height: 190,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: brandGold.withOpacity(.14), width: 34)))),
        Positioned(right: -35, bottom: -72, child: Container(width: 145, height: 145,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.045)))),
        Padding(padding: const EdgeInsets.fromLTRB(22, 22, 22, 24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12), borderRadius: BorderRadius.circular(17),
              border: Border.all(color: brandGold.withOpacity(.38))),
              child: const GroupLogo(size: 45)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AMIGOS VERDADEROS', maxLines: 2, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.0, fontSize: 12)),
              SizedBox(height: 3),
              Text('TESORERÍA  •  ACTIVIDADES', style: TextStyle(color: brandGold, fontWeight: FontWeight.w700, letterSpacing: .7, fontSize: 10)),
            ])),
          ]),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: brandGold.withOpacity(.14), border: Border.all(color: brandGold.withOpacity(.38)), borderRadius: BorderRadius.circular(99)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: brandGold, size: 16), const SizedBox(width: 8),
              Text(isPayment ? 'INGRESO POR ACTIVIDAD' : editing ? 'ACTUALIZACIÓN DE COMPROMISO' : 'NUEVO COMPROMISO',
                style: const TextStyle(color: brandGold, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: .65)),
            ])),
          const SizedBox(height: 14),
          Text(heading, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 29, height: 1.12)),
          const SizedBox(height: 10),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 470), child: Text(detail,
            style: const TextStyle(color: Color(0xffe0e9f5), fontSize: 14, height: 1.55))),
          const SizedBox(height: 21),
          Row(children: [
            Container(width: 30, height: 3, decoration: BoxDecoration(color: brandGold, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 8),
            Expanded(child: Text(isPayment ? 'Registro de dinero recibido' : 'Control de compromisos del grupo',
              style: const TextStyle(color: Color(0xffdce8f6), fontSize: 11.5))),
          ]),
        ])),
      ]),
    );
  }

  Widget _section({required String number, required String title, required String subtitle,
      required IconData icon, required List<Widget> children}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.outline.withOpacity(.13)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? .08 : .035), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [brandGold, Color(0xffb19a62), Color(0xff173b70)]))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 21, 20, 16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Text(number, style: TextStyle(color: colors.onPrimaryContainer, fontSize: 17, fontWeight: FontWeight.w900))),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: colors.onSurface, fontSize: 17.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12.5, height: 1.45)),
          ])),
          Icon(icon, size: 21, color: colors.onSurfaceVariant),
        ])),
        Divider(height: 1, color: colors.outline.withOpacity(.11)),
        Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
      ]),
    );
  }

  Widget _stat(String label, int amount, {bool highlight = false}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: highlight ? brandNavy : colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? brandGold.withOpacity(.4) : colors.outline.withOpacity(.17)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: .8,
          color: highlight ? brandGold : colors.onSurfaceVariant)),
        const SizedBox(height: 9),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(money(amount), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 27,
            color: highlight ? Colors.white : colors.onSurface))),
      ]),
    );
  }

  Widget _statsPair(Widget a, Widget b) => LayoutBuilder(builder: (context, size) {
    if (size.maxWidth < 340) return Column(children: [a, const SizedBox(height: 10), b]);
    return Row(children: [Expanded(child: a), const SizedBox(width: 11), Expanded(child: b)]);
  });

  Widget _amountField(TextEditingController controller, String label, {String? helper, bool prominent = false}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: prominent ? 25 : 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0,00',
        prefixText: '\$ ',
        helperText: helper,
        helperMaxLines: 3,
      ),
    );
  }

  Widget _paymentSummary() {
    final pending = (widget.account!['pending_cents'] as num).toInt();
    final entered = _readCents(amount.text);
    final valid = entered != null && entered > 0 && entered <= pending;
    final remaining = valid ? pending - entered : pending;
    final scheme = Theme.of(context).colorScheme;
    return _section(number: '01', title: 'Balance del compromiso',
      subtitle: 'Proyección en tiempo real antes de confirmar el pago.', icon: Icons.pie_chart_outline,
      children: [
        _statsPair(_stat('Por cobrar', pending, highlight: true), _stat('Saldo resultante', remaining)),
        const SizedBox(height: 13),
        if (pending > 0) ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(minHeight: 7,
            value: valid ? (entered / pending).clamp(0.0, 1.0) : 0,
            backgroundColor: scheme.primary.withOpacity(.09), color: brandGold)),
        if (amount.text.trim().isNotEmpty && !valid) Padding(padding: const EdgeInsets.only(top: 13),
          child: Text('Introduce un pago entre 0,01 y ${money(pending)}.',
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700))),
      ]);
  }

  Widget _commitmentPreview() {
    final originalValue = _readCents(original.text);
    final historicalValue = _readCents(historical.text);
    if (originalValue == null || historicalValue == null) return const SizedBox.shrink();
    final remaining = originalValue - historicalValue;
    final scheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _statsPair(_stat('Compromiso', originalValue), _stat('Saldo orientativo', remaining, highlight: true)),
      if (remaining < 0) Padding(padding: const EdgeInsets.only(top: 12), child: Text(
        'Los abonos históricos superan la deuda original. Revisa los valores.',
        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700))),
      if (editing) Padding(padding: const EdgeInsets.only(top: 12), child: Text(
        'El saldo orientativo no incluye los pagos nuevos registrados.',
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.companions.where((c) => c['id'] == companionId).firstOrNull;
    final title = widget.payment ? 'Registrar pago' : editing ? 'Corregir pendiente' : 'Nuevo pendiente';
    return PopScope(
      canPop: !busy && !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await leave() && mounted) {
          setState(() => dirty = false);
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: TreasuryHeader(title: title, overline: 'AMIGOS VERDADEROS', busy: busy),
        body: ResponsiveBody(
          child: AbsorbPointer(
            absorbing: busy,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 36),
              children: [
                _hero(
                  context,
                  heading: widget.payment ? widget.account!['name'].toString() : editing ? 'Editar compromiso' : 'Un nuevo compromiso',
                  detail: widget.payment
                      ? widget.account!['activity'].toString()
                      : editing ? 'Actualiza los datos del compromiso y justifica la corrección.'
                          : 'Registra los compromisos pendientes sin alterar el dinero disponible.',
                  icon: widget.payment ? Icons.payments_outlined : Icons.volunteer_activism_outlined,
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                  child: Row(children: [
                    Icon(Icons.verified_user_outlined, size: 18, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Registro protegido · Tesorería de Amigos Verdaderos',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  ]),
                ),
                if (widget.payment) ...[
                  _paymentSummary(),
                  _section(
                    number: '02', title: 'Dinero recibido',
                    subtitle: 'Registra exactamente el dinero entregado.', icon: Icons.add_card_outlined,
                    children: [
                      _amountField(amount, 'Valor del pago · USD', prominent: true),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () { amount.text = ((widget.account!['pending_cents'] as num) / 100).toStringAsFixed(2); },
                        icon: const Icon(Icons.done_all),
                        label: const Text('Completar saldo pendiente'),
                      ),
                    ],
                  ),
                  const InfoNote('El pago ingresará automáticamente al fondo general. No lo registres otra vez en Movimientos.'),
                ] else ...[
                  _section(
                    number: '01', title: 'Compañero y actividad',
                    subtitle: 'Identifica quién participa y el motivo del compromiso.', icon: Icons.people_outline,
                    children: [
                      SelectionField(
                        label: 'Compañero',
                        value: selected?['name']?.toString() ?? widget.account?['name']?.toString() ?? 'Seleccionar compañero',
                        icon: Icons.person_search,
                        onTap: chooseCompanion,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: activity,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la actividad', hintText: 'Ej.: Bingo, rifa o evento',
                        ),
                      ),
                    ],
                  ),
                  _section(
                    number: '02', title: 'Valores del compromiso',
                    subtitle: 'Los importes pendientes no son dinero disponible.', icon: Icons.account_balance_wallet_outlined,
                    children: [
                      _amountField(original, 'Deuda original · USD'),
                      const SizedBox(height: 16),
                      _amountField(historical, 'Abonos históricos · USD',
                          helper: 'Dinero recibido antes de usar este registro. No se contabiliza otra vez.'),
                      const SizedBox(height: 18),
                      _commitmentPreview(),
                    ],
                  ),
                ],
                _section(
                  number: widget.payment ? '03' : '03', title: 'Fecha y observaciones',
                  subtitle: 'Documenta cuándo ocurrió y añade contexto si hace falta.', icon: Icons.event_note_outlined,
                  children: [
                    SelectionField(
                      label: widget.payment ? 'Fecha del pago' : 'Fecha de la actividad',
                      value: widget.payment ? iso(paymentDate) : activityDate == null ? 'Sin fecha (opcional)' : iso(activityDate!),
                      icon: Icons.calendar_month_outlined,
                      onTap: chooseDate,
                    ),
                    if (!widget.payment && activityDate != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() { activityDate = null; dirty = true; }),
                          icon: const Icon(Icons.event_busy_outlined),
                          label: const Text('Quitar fecha'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: note,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observaciones (opcional)',
                        hintText: 'Añade algún detalle útil para el registro',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                if (editing)
                  _section(
                    number: '04', title: 'Motivo de la corrección',
                    subtitle: 'Deja constancia verificable del cambio.', icon: Icons.history_edu_outlined,
                    children: [
                      TextField(
                        controller: reason,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(labelText: 'Motivo obligatorio', alignLabelWithHint: true),
                      ),
                    ],
                  ),
                if (error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(colors: [Color(0xff0a2a5c), Color(0xff16518b)]),
                    border: Border.all(color: brandGold.withOpacity(.65)),
                    boxShadow: [BoxShadow(color: brandNavy.withOpacity(.23), blurRadius: 19, offset: const Offset(0, 8))],
                  ),
                  child: Material(color: Colors.transparent, child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: busy ? null : save,
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Row(children: [
                        Container(width: 43, height: 43, alignment: Alignment.center,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(14)),
                          child: busy
                            ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : Icon(widget.payment ? Icons.check_circle_outline_rounded : Icons.save_outlined, color: Colors.white, size: 25)),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(busy ? 'Guardando…' : widget.payment ? 'Confirmar pago' : editing ? 'Guardar corrección' : 'Guardar pendiente',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          const Text('REGISTRO SEGURO', style: TextStyle(color: brandGold, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: .9)),
                        ])),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 23),
                      ])),
                  )),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.payment
                      ? 'Verifica el importe antes de confirmar: el pago actualizará los saldos del grupo.'
                      : 'Los importes pendientes son informativos y no representan dinero disponible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, height: 1.45, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}