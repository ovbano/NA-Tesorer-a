import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'brand.dart';

import 'treasury_widgets.dart';

import 'package:image_picker/image_picker.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uuid/uuid.dart';

import 'treasury.dart';
import 'treasury_calendar.dart';
import 'treasury_dialogs.dart';

class EntryEditor extends StatefulWidget {

  const EntryEditor({super.key,required this.repo,required this.month,required this.settings,required this.members,required this.companions,this.entry});

  final TreasuryRepository repo;final DateTime month;final Json settings;final List<Json> members,companions;final Json? entry;

  @override State<EntryEditor> createState()=>_EntryEditorState();

}

class _EntryEditorState extends State<EntryEditor> {

  final amount=TextEditingController(),description=TextEditingController(),noReceipt=TextEditingController(),reason=TextEditingController();

  late String id,kind,category,fund;late int version;late DateTime date,due;String? memberId,receiptPath,error;XFile? photo;bool busy=false,dirty=false;

  bool get income => kind == 'income';
  Color get movementColor => income ? const Color(0xFF177A4E) : const Color(0xFFC2383A);
  bool get correcting=>widget.entry?['status']=='posted';bool get rent=>category=='rent_contribution';

  @override void initState(){super.initState();final e=widget.entry??{};id=e['id']??const Uuid().v4();version=e['version']??0;kind=e['kind']??'income';category=e['category']??'seventh';fund=e['fund']??'general';date=DateTime.parse(e['entry_date']??iso(today()));due=DateTime.parse(e['due_month']??period(widget.month));memberId=e['member_id'];receiptPath=e['receipt_path'];amount.text=e['amount_cents']==null?'':((e['amount_cents'] as num)/100).toStringAsFixed(2);description.text=e['description']??'';noReceipt.text=e['no_receipt_reason']??'';for(final c in [amount,description,noReceipt,reason]){c.addListener(()=>dirty=true);}}

  @override void dispose(){for(final c in [amount,description,noReceipt,reason]){c.dispose();}super.dispose();}

  void changed(VoidCallback update){setState((){update();dirty=true;});}

  Future<void> pick(ImageSource source) async {try{final result=await ImagePicker().pickImage(source:source,maxWidth:1600,maxHeight:1600,imageQuality:78);if(result!=null&&mounted)changed(()=>photo=result);}catch(e){if(mounted)setState(()=>error='No se pudo abrir la cámara o galería. Revisa los permisos.');}}

  Future<bool> leave() async {
    if (busy) return false;
    if (!dirty) return true;
    return confirmLeaveEditor(context);
  }

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
    final initial = month ? due : date;
    final start = DateTime.parse(widget.settings['start_month']);
    final first = month ? DateTime(start.year, start.month) : start;
    final last = month ? DateTime(today().year + 2, 12, 31) : today();
    if (first.isAfter(last)) {
      setState(() => error = 'El inicio de Tesorería es posterior a hoy. Revisa los fondos iniciales.');
      return;
    }
    final picked = await showTreasuryCalendaredit(
      context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      title: month ? 'Mes del aporte' : 'Fecha del movimiento',
    );
    if (picked != null && mounted) {
      changed(() {
        if (month) {
          due = DateTime(picked.year, picked.month);
        } else {
          date = picked;
        }
      });
    }
  }


  Widget _kindSelector() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget choice(String value, String label, IconData icon, Color color) {
      final selected = kind == value;
      final background = selected
          ? (dark ? color.withOpacity(.22) : color.withOpacity(.10))
          : Theme.of(context).colorScheme.surface;
      return Expanded(
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: busy ? null : () => changed(() {
              kind = value;
              category = kind == 'income' ? 'seventh' : 'supplies';
              fund = 'general';
            }),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 70),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? color : Theme.of(context).colorScheme.outline.withOpacity(.35),
                  width: selected ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: selected ? color : Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 7),
                  Text(label, style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? color : Theme.of(context).colorScheme.onSurface,
                  )),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Row(children: [
      choice('income', 'Ingreso', Icons.south_west_rounded, const Color(0xFF168555)),
      const SizedBox(width: 12),
      choice('expense', 'Egreso', Icons.north_east_rounded, const Color(0xFFC54142)),
    ]);
  }

  Widget _summaryBanner() {
    final positive = income;
    final tint = positive ? const Color(0xFF126B49) : const Color(0xFF9F3038);
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavy, Color.lerp(brandNavy, tint, .42)!, brandNavy],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandGold.withOpacity(.45)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: positive ? const Color(0xFFA7F0CA) : const Color(0xFFFFB7B9), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(positive ? 'ENTRADA DE DINERO' : 'SALIDA DE DINERO',
              style: TextStyle(color: positive ? const Color(0xFFA7F0CA) : const Color(0xFFFFB7B9),
                fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const SizedBox(height: 5),
            Text(positive ? 'Registrar un ingreso' : 'Registrar un egreso',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            const Text('Control de fondos · Amigos Verdaderos',
              style: TextStyle(color: Color(0xFFE0E8F6), fontSize: 12)),
          ],
        )),
      ]),
    );
  }

  Widget _actions() {
    final color = income ? const Color(0xFF147A4E) : const Color(0xFFBD393B);
    final small = MediaQuery.sizeOf(context).width < 350 ||
        MediaQuery.textScalerOf(context).scale(16) > 23;
    final buttons = <Widget>[
      if (!correcting)
        OutlinedButton.icon(
          onPressed: busy ? null : () => save(false),
          icon: const Icon(Icons.edit_note_rounded),
          label: const Text('Guardar borrador'),
        ),
      FilledButton.icon(
        onPressed: busy ? null : () => save(true),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          iconColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(.45),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(0, 54),
        ),
        icon: busy
            ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(busy ? 'Guardando…' : correcting ? 'Guardar corrección' : 'Confirmar movimiento'),
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: small
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final b in buttons) Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
              ])
            : Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 10,
                children: buttons),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 520 ||
        MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = Theme.of(context).colorScheme;
    final selected = [
      ...widget.members.map((member) => {'value': member['id'], 'name': member['name']}),
      ...widget.companions.map((companion) => {
        'value': 'source:${companion['id']}',
        'name': companion['name'],
      }),
    ].where((companion) => companion['value'] == memberId).firstOrNull;

    return PopScope(
      canPop: !dirty && !busy,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await leave() && mounted) {
          setState(() => dirty = false);
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          toolbarHeight: 74,
          backgroundColor: brandNavy,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Regresar',
            onPressed: () async {
              if (await leave() && mounted) {
                setState(() => dirty = false);
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(correcting ? 'CORREGIR MOVIMIENTO'
                  : widget.entry == null ? 'NUEVO MOVIMIENTO' : 'COMPLETAR BORRADOR',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: .5)),
              Text(income ? 'Ingreso' : 'Egreso',
                style: TextStyle(
                  color: income ? const Color(0xFFA7F0CA) : const Color(0xFFFFB7B9),
                  fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          actions: const [ThemeButton()],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: Container(height: 3,
                color: income ? const Color(0xFF22AC73) : const Color(0xFFE65A60)),
          ),
        ),
        body: ResponsiveBody(
          child: AbsorbPointer(
            absorbing: busy,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: const EdgeInsets.fromLTRB(16, 17, 16, 24),
              children: [
                _summaryBanner(),
                const InfoNote('General: gastos del grupo. Local: dinero reservado para el arriendo. Puedes guardar un borrador y completarlo después.'),
                FormSection(
                  title: 'Datos del movimiento',
                  icon: Icons.account_balance_wallet_outlined,
                  subtitle: 'Selecciona el tipo de operación y completa sus datos.',
                  children: [
                    _kindSelector(),
                    const SizedBox(height: 18),
                    SelectionField(label: 'Categoría', value: categories[category] ?? category,
                      icon: Icons.category_outlined, onTap: chooseCategory),
                    const SizedBox(height: 14),
                    SelectionField(label: 'Fondo que recibe o paga',
                      value: fund == 'rent' ? 'Local · reservado para arriendo' : 'General · gastos del grupo',
                      icon: Icons.account_balance_outlined,
                      onTap: ['rent', 'rent_contribution', 'seventh'].contains(category) ? null : chooseFund),
                    const SizedBox(height: 14),
                    SelectionField(label: 'Fecha del movimiento', value: iso(date),
                      icon: Icons.calendar_month_outlined, onTap: () => pickDate(false)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: movementColor),
                      decoration: InputDecoration(
                        labelText: income ? 'Importe del ingreso · USD' : 'Importe del egreso · USD',
                        hintText: '0,00', prefixText: r'$ ',
                        prefixIcon: Icon(Icons.payments_outlined, color: movementColor),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: movementColor, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Detalle del movimiento',
                        hintText: income ? 'Ejemplo: séptima de la reunión'
                            : 'Ejemplo: compra de materiales para el grupo',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                if (rent)
                  FormSection(
                    title: 'Aporte para el local',
                    icon: Icons.home_work_outlined,
                    children: [
                      SelectionField(
                        label: 'Compañero',
                        value: selected?['name']?.toString() ?? 'Elegir del registro del grupo',
                        icon: Icons.person_search_outlined,
                        onTap: chooseMember,
                      ),
                      const SizedBox(height: 14),
                      SelectionField(label: 'Mes del aporte', value: monthLabel(due),
                        icon: Icons.calendar_today_outlined, onTap: () => pickDate(true)),
                    ],
                  ),
                FormSection(
                  title: 'Comprobante',
                  icon: Icons.receipt_long_outlined,
                  subtitle: 'Adjunta una fotografía o selecciona una imagen de tu galería.',
                  children: [
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      OutlinedButton.icon(onPressed: busy ? null : () => pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined), label: const Text('Tomar foto')),
                      OutlinedButton.icon(onPressed: busy ? null : () => pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined), label: const Text('Galería')),
                    ]),
                    if (photo != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: FutureBuilder<Uint8List>(
                          future: photo!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const InfoNote('No se pudo abrir esta fotografía. Selecciona otra.');
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox(height: 160,
                                child: Center(child: CircularProgressIndicator()));
                            }
                            return Image.memory(snapshot.data!, height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (_, error, stack) =>
                                const InfoNote('Esta imagen no se puede mostrar. Selecciona otra.'));
                          },
                        ),
                      ),
                    ],
                    if (receiptPath != null) ...[
                      const SizedBox(height: 16),
                      const StatusPill('Comprobante adjunto', complete: true),
                    ],
                    if (kind == 'expense') ...[
                      const SizedBox(height: 16),
                      TextField(controller: noReceipt, maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Si no hay comprobante',
                          hintText: 'Explica el motivo',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        )),
                    ],
                  ],
                ),
                if (correcting)
                  FormSection(
                    title: 'Motivo de la corrección',
                    icon: Icons.edit_note_rounded,
                    subtitle: 'La modificación quedará registrada en el historial.',
                    children: [TextField(controller: reason, maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Motivo de la corrección'))],
                  ),
                if (error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(child: Text(error!, style: TextStyle(color: colors.onErrorContainer))),
                    ]),
                  ),
                if (compact) _actions(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: compact ? null : SafeArea(top: false, child: _actions()),
      ),
    );
  }
}