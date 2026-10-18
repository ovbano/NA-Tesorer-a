import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:printing/printing.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'treasury.dart';

import 'entry_editor.dart';

import 'activity_editor.dart';

import 'report_pdf.dart';

import 'brand.dart';

import 'treasury_widgets.dart';

import 'group_logo.dart';

import 'treasury_navigation.dart';

import 'treasury_workspace_ui.dart';

import 'package:flutter/services.dart';

class Workspace extends StatefulWidget {

  const Workspace({super.key,required this.repo,required this.profile});final TreasuryRepository repo;final Json profile;

  @override State<Workspace> createState()=>_WorkspaceState();

}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {

  DateTime month=DateTime(today().year,today().month);int section=0,generation=0;bool loading=true,working=false;String? error,accessError;Json? report,settings;

  List<Json> members=[],companions=[],drafts=[],activities=[];Json? liveProfile;

  Json get profile=>liveProfile??widget.profile;String query='',kind='all';

  String duesSearch='',duesFilter='all',activitySearch='',activityFilter='all';

  final duesSearchController = TextEditingController();

  final activitySearchController = TextEditingController();

  bool get writable=>accessError==null && ['admin','treasurer'].contains(profile['role']);

  bool get closed=>report?['closure']!=null;

  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);appearance.addListener(appearanceChanged);reload();}

  @override void dispose(){generation++;duesSearchController.dispose();activitySearchController.dispose();appearance.removeListener(appearanceChanged);WidgetsBinding.instance.removeObserver(this);super.dispose();}

  void appearanceChanged(){if(mounted)setState((){});}

  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)reload();}

  Future<void> reload()async{

    final ticket=++generation;setState((){loading=true;error=null;});

    try{

      final access=await widget.repo.profile();

      final s=await widget.repo.settings();

      final result=await Future.wait<dynamic>([s==null||period(month).compareTo(s['start_month'])<0?Future<Json>.value({'configured':false}):widget.repo.report(month),widget.repo.all('treasury_members'),widget.repo.companions(),widget.repo.all('treasury_entries',status:'draft'),widget.repo.client.rpc('treasury_activities')]);

      if(!mounted||ticket!=generation)return;

      setState((){liveProfile=access;settings=s;report=result[0];members=result[1];companions=result[2];drafts=result[3];activities=rows(result[4]);accessError=null;});

    }catch(e){if(mounted&&ticket==generation){setState((){error=message(e);if(e is FormatException){accessError=error;report=null;members=[];companions=[];drafts=[];activities=[];}});}}

    finally{if(mounted&&ticket==generation)setState(()=>loading=false);}

  }

  void notify(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}

  Future<void> task(Future<void> Function() action)async{if(working)return;setState(()=>working=true);try{await action();}catch(e){notify(message(e));}finally{if(mounted)setState(()=>working=false);}}

  Future<void> edit([Json? entry])async{

    if(settings==null || !writable)return;

    final result=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>EntryEditor(repo:widget.repo,month:month,settings:settings!,members:members,companions:companions,entry:entry)));

    if(result==true&&mounted){notify('Movimiento guardado.');await reload();}

  }

  Future<void> chooseMonth() async {

    final value=await showModalBottomSheet<DateTime>(context:context,isScrollControlled:true,useSafeArea:true,builder:(_)=>MonthSheet(selected:month));

    if(value!=null&&mounted){setState(()=>month=value);await reload();}

  }

  Future<void> shiftMonth(int delta) async {

    if(working||loading)return;

    setState(()=>month=DateTime(month.year,month.month+delta));

    await reload();

  }

  Future<String?> ask(String title,String label,{bool password=false}) async {

    final controller=TextEditingController();

    final value=await showDialog<String>(context:context,builder:(c)=>AlertDialog(scrollable:true,title:Text(title),content:TextField(controller:controller,obscureText:password,decoration:InputDecoration(labelText:password?'Contraseña':null,hintText:password?null:label,helperText:password?label:null,helperMaxLines:3),maxLines:password?1:3),actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,controller.text),child:const Text('Continuar'))]));

    // Route disposal follows its reverse animation; avoid disposing a focused controller early.

    await Future<void>.delayed(const Duration(milliseconds:300));controller.dispose();return value;

  }

  Future<void> account(String action)async{

    if(action=='logout'){await task(()async{await widget.repo.client.auth.signOut(scope:SignOutScope.local);});}

    if(action=='password'){

      final value=await ask('Cambiar contraseña','Nueva contraseña (mínimo 12 caracteres)',password:true);if(value==null)return;

      if(value.length<12){notify('Utiliza al menos 12 caracteres.');return;}

      final confirmation=await ask('Confirmar contraseña','Repite la nueva contraseña',password:true);if(confirmation!=value){notify('Las contraseñas no coinciden.');return;}

      await task(()async{await widget.repo.client.auth.updateUser(UserAttributes(password:value));notify('Contraseña actualizada.');});

    }

    if(action=='admin'){await launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/admin/'),mode:LaunchMode.externalApplication);}

    if(action=='initial')await initialFunds();

  }

  Future<void> initialFunds() async {

    final general=TextEditingController(text:settings==null?'':((settings!['opening_general'] as num)/100).toStringAsFixed(2));

    final local=TextEditingController(text:settings==null?'':((settings!['opening_rent'] as num)/100).toStringAsFixed(2));

    final note=TextEditingController(text:settings?['note']??''),reason=TextEditingController();DateTime start=settings==null?month:DateTime.parse(settings!['start_month']);String? feedback;bool saving=false;

    await showDialog<void>(context:context,barrierDismissible:false,builder:(c)=>StatefulBuilder(builder:(c,set)=>PopScope(canPop:!saving,child:AlertDialog(scrollable:true,title:Text(settings==null?'Registrar fondos iniciales':'Corregir fondos iniciales'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('Registra dinero físico verificado. General: gastos del grupo. Local: dinero reservado para arriendo. No incluyas deudas pendientes.'),TextButton(onPressed:saving?null:()async{final d=await showDatePicker(context:c,initialDate:start,firstDate:DateTime(2013),lastDate:today());if(d!=null)set(()=>start=DateTime(d.year,d.month));},child:Text('Mes de inicio: ${period(start).substring(0,7)}')),TextField(controller:general,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Gastos del grupo · USD')),const SizedBox(height:12),TextField(controller:local,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Apartado para el local · USD')),const SizedBox(height:12),TextField(controller:note,decoration:const InputDecoration(labelText:'Nota')),if(settings!=null)...[const SizedBox(height:12),const Text('La corrección recalcula los saldos y reabre meses cerrados. Revisa después los informes.'),TextField(controller:reason,decoration:const InputDecoration(labelText:'Motivo de la corrección'))],if(feedback!=null)Text(feedback!,style:const TextStyle(color:Colors.red))])),actions:[TextButton(onPressed:saving?null:()=>Navigator.pop(c),child:const Text('Cancelar')),FilledButton(onPressed:saving?null:()async{try{final a=cents(general.text),b=cents(local.text);if(settings!=null&&reason.text.trim().length<5)throw const FormatException('Explica el motivo de la corrección.');set(()=>saving=true);await widget.repo.command(settings==null?'setup':'initial_update',{'start_month':period(start),'opening_general':a,'opening_rent':b,'note':note.text.trim(),'reason':reason.text.trim()});if(c.mounted)Navigator.pop(c);await reload();}catch(e){if(c.mounted)set((){feedback=message(e);saving=false;});}},child:Text(saving?'Guardando…':'Guardar'))]))));

    await Future<void>.delayed(const Duration(milliseconds:300));for(final controller in [general,local,note,reason]){controller.dispose();}

  }

  
  Future<void> export() async {
    if (report?['configured'] != true || working) return;

    // 1. Seleccionar cómo se generará el informe.
    final includePhotos = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final scheme = theme.colorScheme;
        final dark = theme.brightness == Brightness.dark;

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
          backgroundColor: scheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: BorderSide(
              color: scheme.outlineVariant,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF071D49),
                          Color(0xFF174684),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf_rounded,
                          color: Color(0xFFD9B96D),
                          size: 32,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'INFORME DE TESORERÍA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Exportar informe mensual',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    monthLabel(month),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'El informe presentará los ingresos y egresos '
                    'por separado, junto con el resumen financiero '
                    'y los aportes correspondientes al período.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Opción 1: informe sin fotografías.
                  OutlinedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(
                        color: scheme.outlineVariant,
                      ),
                      backgroundColor: dark
                          ? const Color(0xFF1C2C46)
                          : const Color(0xFFF3F6FB),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: scheme.primary,
                          size: 26,
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sin fotografías',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'PDF más ligero y rápido de compartir.',
                                softWrap: true,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 11),

                  // Opción 2: informe con fotografías.
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF071D49),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          color: Color(0xFFD9B96D),
                          size: 26,
                        ),
                        SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Con fotografías',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Incluye comprobantes fotográficos disponibles.',
                                softWrap: true,
                                style: TextStyle(
                                  color: Color(0xFFDFE8F8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (includePhotos == null || !mounted) return;

    // Se conserva la gestión de carga y errores de task().
    await task(() async {
      // 2. Obtener datos actualizados directamente desde Supabase.
      final fresh = Json.from(
        await widget.repo.client.rpc(
          'treasury_prepare_report',
          params: {
            'p_month': period(month),
            'p_format': 'pdf',
            'p_include_dues': true,
          },
        ) as Map,
      );

      // 3. Preparar los comprobantes fotográficos.
      final evidence = <String, Uint8List>{};
      final processedPaths = <String>{};

      var failed = 0;
      var totalBytes = 0;

      const maxImageBytes = 10 * 1024 * 1024;
      const maxEvidenceBytes = 20 * 1024 * 1024;

      if (includePhotos) {
        final entries = rows(fresh['entries']).where(
          (entry) =>
              entry['status'] == 'posted' &&
              entry['receipt_path'] != null,
        );

        for (final entry in entries) {
          final path = entry['receipt_path'].toString();

          if (path.trim().isEmpty) continue;

          // Evitar descargar varias veces el mismo comprobante.
          if (!processedPaths.add(path)) continue;

          // El informe admite comprobantes de imagen.
          // Los PDF adjuntos se consultan desde el movimiento.
          if (path.toLowerCase().endsWith('.pdf')) {
            failed++;
            continue;
          }

          try {
            final bytes = await widget.repo.client.storage
                .from('treasury-receipts')
                .download(path)
                .timeout(const Duration(seconds: 20));

            if (bytes.isEmpty || bytes.length > maxImageBytes) {
              failed++;
              continue;
            }

            ui.Codec? codec;
            ui.Image? decodedImage;

            try {
              // Reducir imágenes grandes antes de añadirlas al PDF.
              codec = await ui.instantiateImageCodec(
                bytes,
                targetWidth: 1200,
                allowUpscaling: false,
              );

              final frame = await codec.getNextFrame();
              decodedImage = frame.image;

              final optimized = await decodedImage.toByteData(
                format: ui.ImageByteFormat.png,
              );

              if (optimized == null) {
                failed++;
                continue;
              }

              final length = optimized.lengthInBytes;

              if (totalBytes + length > maxEvidenceBytes) {
                failed++;
                continue;
              }

              final imageBytes = Uint8List.fromList(
                optimized.buffer.asUint8List(
                  optimized.offsetInBytes,
                  length,
                ),
              );

              evidence[path] = imageBytes;
              totalBytes += imageBytes.length;
            } finally {
              // Liberar memoria incluso si ocurre un error.
              decodedImage?.dispose();
              codec?.dispose();
            }
          } catch (_) {
            // Un comprobante fallido no detiene el informe completo.
            failed++;
          }
        }
      }

      // 4. Construir el PDF con la función existente.
      final bytes = await reportPdf(
        fresh,
        evidence: evidence,
        includeEvidence: includePhotos,
      );

      // 5. Abrir el sistema de compartir del dispositivo.
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Tesoreria_${period(month).substring(0, 7)}.pdf',
      );

      // 6. Informar si algunas fotografías fueron omitidas.
      if (failed > 0 && mounted) {
        notify(
          '$failed comprobante(s) no pudieron incluirse '
          'en el informe. Puedes consultar sus originales '
          'desde cada movimiento.',
        );
      }
    });
  }


  Future<void> receipt(Json entry)async{

    final path=entry['receipt_path'];if(path==null)return;

    await task(()async{final data=await widget.repo.client.storage.from('treasury-receipts').download(path).timeout(const Duration(seconds:20));if(!mounted)return;if(path.toString().endsWith('.pdf')){await Printing.sharePdf(bytes:data,filename:'Comprobante.pdf');}else{await showDialog<void>(context:context,builder:(c)=>Dialog(child:SizedBox(height:MediaQuery.sizeOf(c).height*.75,child:Column(children:[Expanded(child:InteractiveViewer(child:Image.memory(data,errorBuilder:(_,e,s)=>const Padding(padding:EdgeInsets.all(24),child:Text('No se pudo mostrar esta imagen.'))))),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cerrar'))]))));}});

  }

  Future<void> detail(Json entry) async {
    final income = entry['kind'] == 'income';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        final dark = Theme.of(sheetContext).brightness == Brightness.dark;
        final tone = _movementColor(income, dark);
        final tint = _movementTint(income, dark);
        return FractionallySizedBox(
          heightFactor: MediaQuery.sizeOf(sheetContext).height < 550 ? .94 : .84,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20, 16, 20, 24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: tint,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            income ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: tone, size: 27,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(
                          income ? 'Detalle del ingreso' : 'Detalle del egreso',
                          style: TextStyle(color: scheme.onSurface,
                            fontSize: 20, fontWeight: FontWeight.w800),
                        )),
                        IconButton(
                          tooltip: 'Cerrar detalle',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ]),
                      const SizedBox(height: 19),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(21),
                          border: Border.all(color: tone.withOpacity(.30)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(income ? 'DINERO RECIBIDO' : 'DINERO ENTREGADO',
                              style: TextStyle(color: tone, fontSize: 12,
                                letterSpacing: 1, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${income ? '+' : '−'} ${money(entry['amount_cents'])}',
                                style: TextStyle(color: tone, fontSize: 34,
                                  fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        _movementTag(income ? 'INGRESO' : 'EGRESO', income, dark),
                        StatusPill(
                          entry['status'] == 'posted' ? 'Confirmado'
                          : entry['status'] == 'draft' ? 'Borrador' : 'Anulado',
                          complete: entry['status'] == 'posted',
                        ),
                        Chip(label: Text(entry['entry_date'].toString())),
                      ]),
                      const SizedBox(height: 22),
                      Text(categories[entry['category']] ?? entry['category'].toString(),
                        style: TextStyle(fontSize: 19,
                          fontWeight: FontWeight.w800, color: scheme.onSurface)),
                      const SizedBox(height: 9),
                      Text(entry['description']?.toString() ?? '',
                        style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5)),
                      const SizedBox(height: 18),
                      InfoNote(entry['fund'] == 'rent'
                          ? 'Fondo para el local' : 'Fondo general'),
                      if (entry['no_receipt_reason']?.toString().isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Sin comprobante: ${entry['no_receipt_reason']}',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                        ),
                      if (entry['receipt_path'] != null) ...[
                        OutlinedButton.icon(
                          onPressed: () => receipt(entry),
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Abrir comprobante'),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (writable && entry['status'] != 'void') ...[
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            edit(entry);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(entry['status'] == 'draft'
                              ? 'Completar borrador' : 'Corregir con motivo'),
                          style: FilledButton.styleFrom(
                            backgroundColor: brandNavy,
                            foregroundColor: Colors.white,
                            iconColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                        const SizedBox(height: 9),
                      ],
                      if (writable && entry['status'] == 'draft')
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (d) => AlertDialog(
                                scrollable: true,
                                title: const Text('Descartar borrador'),
                                content: const Text('El borrador se eliminará. No afecta los fondos.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Cancelar')),
                                  FilledButton(onPressed: () => Navigator.pop(d, true),
                                    child: const Text('Descartar')),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await task(() async {
                                await widget.repo.command('discard',
                                  {'id': entry['id'], 'version': entry['version']});
                                await reload();
                              });
                            }
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Descartar borrador'),
                        ),
                      if (writable && entry['status'] == 'posted')
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            final reason = await ask(
                                'Anular movimiento', 'Motivo de la anulación');
                            if (reason == null) return;
                            await task(() async {
                              await widget.repo.command('void', {
                                'id': entry['id'], 'version': entry['version'],
                                'reason': reason,
                              });
                              await reload();
                            });
                          },
                          icon: const Icon(Icons.block_outlined),
                          label: const Text('Anular indicando el motivo'),
                          style: TextButton.styleFrom(foregroundColor: scheme.error),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> activityEditor([Json? account,bool payment=false])async{

    if(!writable)return;

    final saved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>ActivityEditor(repo:widget.repo,companions:companions,account:account,payment:payment)));

    if(saved==true&&mounted){notify(payment?'Pago registrado en el fondo general.':'Pendiente guardado.');await reload();}

  }

  Future<void> closeMonth()async{

    if(!writable||report?['configured']!=true)return;

    if(closed){final reason=await ask('Reabrir mes','Motivo: también se reabrirán los meses posteriores');if(reason==null)return;await task(()async{await widget.repo.command('reopen',{'month':period(month),'reason':reason});await reload();});return;}

    final input=await ask('Cerrar mes','Dinero total contado físicamente · USD');if(input==null)return;

    try{

      final counted=cents(input)!;final fresh=await widget.repo.report(month);final total=rows(fresh['funds']).fold<num>(0,(n,f)=>n+(f['closing'] as num));

      if(!mounted)return;

      final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(scrollable:true,title:const Text('Confirmar cierre'),content:Text('Saldo calculado: ${money(total)}\nDinero contado: ${money(counted)}\nDiferencia: ${money(counted-total)}'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Confirmar'))]));

      if(confirmed!=true)return;final note=await ask('Nota del cierre','Explica diferencias o deja una observación');if(note==null)return;

      await task(()async{await widget.repo.command('close',{'month':period(month),'counted_cents':counted,'note':note.trim()});await reload();});

    }catch(e){notify(message(e));}

  }

  Widget metric(String label, Object? amount, {bool dark=false}) => WorkspaceMetricCard(

    label: label, value: money(amount), featured: dark,

    icon: dark ? Icons.account_balance_wallet_outlined :

      label.contains('local') ? Icons.home_work_outlined : Icons.volunteer_activism_outlined,

  );

    Color _movementColor(bool income, bool dark) => income
      ? (dark ? const Color(0xFF70E5AF) : const Color(0xFF11754A))
      : (dark ? const Color(0xFFFF9B9F) : const Color(0xFFB7273F));

  Color _movementTint(bool income, bool dark) => income
      ? (dark ? const Color(0xFF173A30) : const Color(0xFFE8F7EF))
      : (dark ? const Color(0xFF452833) : const Color(0xFFFFEFF0));

  Widget _movementTag(String label, bool income, bool dark) {
    final foreground = _movementColor(income, dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _movementTint(income, dark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: foreground.withOpacity(.30)),
      ),
      child: Text(label, style: TextStyle(
        color: foreground, fontWeight: FontWeight.w800, fontSize: 11,
      )),
    );
  }

  Widget entryTile(Json e) {
    final p = WorkspacePalette(context);
    final income = e['kind'] == 'income';
    final tone = _movementColor(income, p.dark);
    final tint = _movementTint(income, p.dark);
    final state = e['status'] == 'draft' ? 'Borrador'
        : e['status'] == 'void' ? 'Anulado'
        : e['fund'] == 'rent' ? 'Fondo local' : 'Fondo general';
    final description = e['description']?.toString().trim() ?? '';
    final category = categories[e['category']] ?? 'Otro movimiento';

    return WorkspaceSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => detail(e),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 13, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 49, height: 49,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tone.withOpacity(.26)),
                  ),
                  child: Icon(
                    income ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: tone, size: 26,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _movementTag(income ? 'INGRESO' : 'EGRESO', income, p.dark),
                          Text(state, style: TextStyle(
                            color: p.muted, fontSize: 12, fontWeight: FontWeight.w600,
                          )),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description.isEmpty ? 'Movimiento por completar' : description,
                        style: TextStyle(
                          fontSize: 16, height: 1.35,
                          fontWeight: FontWeight.w800, color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('${e['entry_date']} · $category',
                        style: TextStyle(color: p.muted, height: 1.4, fontSize: 12.5),
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${income ? '+' : '−'} ${money(e['amount_cents'])}',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900,
                            letterSpacing: -.4, color: tone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 19, color: p.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tarjetas del balance: cada importe ocupa el ancho que le corresponde.
  Widget _balanceCaption(String label, num amount, String type) {
    final p = WorkspacePalette(context);
    final opening = type == 'opening';
    final income = type == 'income';
    final color = opening
        ? p.ink
        : _movementColor(income, p.dark);
    final background = opening
        ? p.soft
        : _movementTint(income, p.dark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: opening ? p.line : color.withOpacity(p.dark ? .38 : .24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                opening
                    ? Icons.account_balance_wallet_outlined
                    : income
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                size: 19,
                color: opening ? p.muted : color,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(
                    color: opening ? p.muted : color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              money(amount),
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: opening ? 27 : 25,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyBalance(List<Json> funds) {
    num sum(String field) => funds.fold<num>(
      0, (total, fund) => total + (fund[field] as num));

    return LayoutBuilder(
      builder: (context, constraints) {
        final bigText = MediaQuery.textScalerOf(context).scale(16) > 23;
        final stackMovements = constraints.maxWidth < 260 || bigText;
        const gap = 12.0;
        final incomeCard = _balanceCaption('Ingresos', sum('income'), 'income');
        final expenseCard = _balanceCaption('Egresos', sum('expense'), 'expense');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _balanceCaption('Saldo al inicio', sum('opening'), 'opening'),
            const SizedBox(height: gap),
            if (stackMovements) ...[
              incomeCard,
              const SizedBox(height: gap),
              expenseCard,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: incomeCard),
                  const SizedBox(width: gap),
                  Expanded(child: expenseCard),
                ],
              ),
          ],
        );
      },
    );
  }

  List<Widget> overview() {

    final funds=rows(report?['funds']);

    final total=funds.fold<num>(0,(sum,fund)=>sum+(fund['closing'] as num));

    final recent=rows(report?['entries']).reversed.take(5).toList();

    return [

      const GroupBanner(),

      const WorkspaceHeadline(title:'Nuestro fondo',subtitle:'Un registro claro al servicio del grupo.',icon:Icons.account_balance_wallet_outlined),

      metric('Dinero disponible',total,dark:true),

      LayoutBuilder(builder:(context,constraints) {

        final columns=constraints.maxWidth>=560 && MediaQuery.textScalerOf(context).scale(16)<24;

        return Wrap(spacing:16,children:[for(final fund in funds)SizedBox(width:columns?(constraints.maxWidth-16)/2:constraints.maxWidth,child:metric(fund['fund']=='rent'?'Apartado para el local':'Para gastos del grupo',fund['closing']))]);

      }),

      const InfoNote('Las cuotas pendientes y los borradores no se suman al dinero disponible.'),

      if(writable)WorkspaceActionButton(onPressed:working?null:()=>edit(),icon:Icons.add_circle_outline_rounded,title:'Registrar ingreso o egreso'),

      const SizedBox(height:24),

      WorkspaceSurface(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[

        Wrap(spacing:12,runSpacing:10,alignment:WrapAlignment.spaceBetween,children:[const Text('Balance del mes',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),StatusPill(closed?'Mes cerrado':'Mes abierto',complete:closed)]),

        const SizedBox(height:22),

        _monthlyBalance(funds),

        const SizedBox(height:24),WorkspaceActionButton(onPressed:working?null:export,icon:Icons.picture_as_pdf,title:'Compartir informe PDF',secondary:true),

      ])),

      const WorkspaceHeadline(title:'Movimientos recientes',icon:Icons.history_rounded),

      if(recent.isEmpty)const EmptyLedger('Todavía no hay movimientos','Los ingresos y egresos de este mes aparecerán aquí.'),

      ...recent.map(entryTile),

    ];

  }

  List<Widget> movementView() {

    final filtered=rows(report?['entries']).reversed.where((entry)=>(kind=='all'||entry['kind']==kind)&&'${entry['description']} ${entry['member_name']} ${categories[entry['category']]}'.toLowerCase().contains(query)).toList();

    return [

      const WorkspaceHeadline(title:'Movimientos',subtitle:'Ingresos y egresos del período seleccionado.',icon:Icons.swap_vert_rounded),

      if(writable) ...[WorkspaceActionButton(onPressed:working?null:()=>edit(),icon:Icons.add_circle_outline,title:'Nuevo movimiento'),const SizedBox(height:18)],

      WorkspaceSearchPanel(

        hint:'Buscar detalle o compañero', onChanged:(value)=>setState(()=>query=value.toLowerCase()),

        filters:const {'all':'Todos','income':'Ingresos','expense':'Egresos'},

        selected:kind, onFilter:(value)=>setState(()=>kind=value),

        countLabel:'${filtered.length} movimientos encontrados',

      ),

      if(filtered.isEmpty)const EmptyLedger('Sin movimientos para mostrar','Cambia el filtro o selecciona otro mes.'),

      ...filtered.map(entryTile),

      if(drafts.isNotEmpty)...[const SectionTitle('Borradores',subtitle:'Registros por completar. No afectan el saldo.',icon:Icons.edit_note),...drafts.map(entryTile)],

    ];

  }

  // La búsqueda solo filtra la presentación; nunca modifica los datos ni los totales.

  String _searchKey(Object? value) {

    var text = (value ?? '').toString().toLowerCase().trim();

    const accents = <String, String>{

      'á':'a','à':'a','ä':'a','â':'a','é':'e','è':'e',

      'ë':'e','ê':'e','í':'i','ï':'i','ó':'o','ö':'o',

      'ú':'u','ü':'u','ñ':'n',

    };

    for (final pair in accents.entries) {

      text = text.replaceAll(pair.key, pair.value);

    }

    return text;

  }

  Widget _listFilters({

    required String hint,

    required TextEditingController controller,

    required String search,

    required ValueChanged<String> onSearch,

    required String selected,

    required ValueChanged<String> onFilter,

    required Map<String, String> options,

    required int results,

    required int total,

  }) => WorkspaceSearchPanel(

    hint:hint, controller:controller, onChanged:onSearch,

    onClear:search.isEmpty?null:(){controller.clear();onSearch('');},

    filters:options, selected:selected, onFilter:onFilter,

    countLabel:'$results de $total registros',

  );

  List<Widget> duesView() {

    final dues = rows(report?['dues']);

    final pendingActivities = activities.fold<num>(

      0, (sum, account) => sum + (account['pending_cents'] as num));

    final normalizedDues = _searchKey(duesSearch);

    final filteredDues = dues.where((due) {

      final expected = (due['expected'] as num).toInt();

      final paid = (due['paid'] as num).toInt();

      final pending = (expected - paid).clamp(0, 100000000);

      final matchesName = _searchKey(due['name']).contains(normalizedDues);

      final matchesStatus = duesFilter == 'all' ||

          (duesFilter == 'pending' && pending > 0 && paid == 0) ||

          (duesFilter == 'partial' && pending > 0 && paid > 0) ||

          (duesFilter == 'paid' && pending == 0);

      return matchesName && matchesStatus;

    }).toList();

    final normalizedActivities = _searchKey(activitySearch);

    final filteredActivities = activities.where((account) {

      final pending = (account['pending_cents'] as num).toInt();

      final label = _searchKey('${account['name']} ${account['activity']}');

      return label.contains(normalizedActivities) &&

          (activityFilter == 'all' ||

           (activityFilter == 'pending' && pending > 0) ||

           (activityFilter == 'paid' && pending == 0));

    }).toList();

    return [

      const WorkspaceHeadline(title:'Aportes para el local',

          subtitle: 'El compromiso de mantener nuestro espacio.',

          icon: Icons.home_outlined),

      LedgerPanel(child: Wrap(spacing: 28, runSpacing: 18, children: [

        MoneyCaption('Cuotas del mes',

            dues.fold<num>(0, (sum, due) => sum + (due['expected'] as num))),

        MoneyCaption('Recibido',

            dues.fold<num>(0, (sum, due) => sum + (due['paid'] as num))),

      ])),

      const InfoNote('Los aportes confirmados ya están incluidos en el fondo del local.'),

      _listFilters(

        hint: 'Buscar compañero por nombre o apellido',

        controller: duesSearchController,

        search: duesSearch,

        onSearch: (value) => setState(() => duesSearch = value),

        selected: duesFilter,

        onFilter: (value) => setState(() => duesFilter = value),

        options: const {

          'all': 'Todos',

          'pending': 'Por aportar',

          'partial': 'Abono recibido',

          'paid': 'Cuota cubierta',

        },

        results: filteredDues.length,

        total: dues.length,

      ),

      if (dues.isEmpty)

        const EmptyLedger('Sin cuotas en este mes',

            'Puedes registrar un aporte desde Nuevo movimiento.',

            icon: Icons.people_outline)

      else if (filteredDues.isEmpty)

        const EmptyLedger('Sin coincidencias',

            'Prueba otro nombre o selecciona la etiqueta Todos.',

            icon: Icons.search_off_rounded),

      for (final due in filteredDues)

        DueCard(key: ValueKey('due-${due['id']}'), due: due),

      const SizedBox(height: 14),

      const WorkspaceHeadline(title:'Actividades del grupo',

          subtitle: 'Bingos, rifas y otros compromisos pendientes.',

          icon: Icons.volunteer_activism_outlined),

      WorkspaceSurface(child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          MoneyCaption('Total por cobrar', pendingActivities, emphasis: true),

          const SizedBox(height: 12),

          const Text('Este valor es informativo. Solo los pagos recibidos se incorporan al fondo general.',

              style: TextStyle(height: 1.5)),

        ],

      )),

      if (writable) ...[

        WorkspaceActionButton(onPressed:working?null:()=>activityEditor(),icon:Icons.add_circle_outline,title:'Nuevo pendiente',secondary:true),

        const SizedBox(height: 18),

      ],

      _listFilters(

        hint: 'Buscar compañero o actividad',

        controller: activitySearchController,

        search: activitySearch,

        onSearch: (value) => setState(() => activitySearch = value),

        selected: activityFilter,

        onFilter: (value) => setState(() => activityFilter = value),

        options: const {

          'all': 'Todas',

          'pending': 'Pendiente de actividad',

          'paid': 'Cancelado',

        },

        results: filteredActivities.length,

        total: activities.length,

      ),

      if (activities.isEmpty)

        const EmptyLedger('No hay pendientes de actividades',

            'Registra un compromiso para llevar sus pagos y comprobantes.',

            icon: Icons.check_circle_outline)

      else if (filteredActivities.isEmpty)

        const EmptyLedger('Sin coincidencias',

            'Prueba otra búsqueda o selecciona la etiqueta Todas.',

            icon: Icons.search_off_rounded),

      for (final account in filteredActivities)

        ActivityCard(

          key: ValueKey('activity-card-${account['id']}'),

          account: account,

          onPay: writable && !working ? () => activityEditor(account, true) : null,

          onEdit: writable && !working ? () => activityEditor(account) : null,

          onPayment: detail,

        ),

    ];

  }

  Future<void> audit()async{await task(()async{final data=await widget.repo.client.from('treasury_audit').select('action,actor_name,happened_at').order('id',ascending:false).limit(50);if(!mounted)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>SizedBox(height:MediaQuery.sizeOf(c).height*.8,child:ListView(padding:const EdgeInsets.all(20),children:[const Text('Últimos 50 cambios',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),...data.map((a)=>ListTile(leading:const Icon(Icons.history),title:Text(a['actor_name']??'Usuario'),subtitle:Text('${a['action']} · ${a['happened_at']}')))])));});}

  List<Widget> more()=>[

    const GroupBanner(),

    const WorkspaceHeadline(title:'Tu espacio',subtitle:'Preferencias, herramientas y cuidado del servicio.',icon:Icons.tune_rounded),

    const WorkspaceThemeSelector(),

    const ActionCard(icon:Icons.help_outline,title:'Cómo utilizar Tesorería',subtitle:'General: séptimas y otros ingresos. Local: aportes para arriendo. Borrador: registro por completar, no suma dinero. Confirmar: incorpora el movimiento al saldo. Corregir: conserva el historial.'),

    if(writable&&report?['configured']==true)ActionCard(icon:Icons.lock_clock,title:closed?'Reabrir mes con motivo':'Cerrar mes y verificar dinero',subtitle:closed?'Revisa el motivo antes de modificar un mes cerrado.':'Compara el saldo con el dinero contado en caja.',onTap:working?null:closeMonth),

    ActionCard(icon:Icons.history,title:'Historial de cambios',subtitle:'Consulta quién realizó cada actualización.',onTap:working?null:audit),

    ActionCard(icon:Icons.language,title:'Abrir Tesorería web',subtitle:'Accede a la plataforma del grupo.',onTap:()=>launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/tesoreria/'),mode:LaunchMode.externalApplication)),

    if(writable)ActionCard(icon:Icons.account_balance,title:'Corregir fondos iniciales',subtitle:'Requiere un motivo y recalcula los períodos.',onTap:working?null:initialFunds),

    if(profile['role']=='admin')ActionCard(icon:Icons.manage_accounts,title:'Administrar usuarios',subtitle:'Abre el panel administrativo del grupo.',onTap:()=>account('admin')),

    ActionCard(icon:Icons.password,title:'Cambiar contraseña',onTap:working?null:()=>account('password')),

    ActionCard(icon:Icons.logout,title:'Cerrar sesión',onTap:working?null:()=>account('logout')),

    const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Un día a la vez, juntos.\nAmigos Verdaderos · Narcóticos Anónimos',textAlign:TextAlign.center,style:TextStyle(height:1.6,fontSize:13))),

  ];

  void selectSection(int index) {

    if(index==section)return;

    HapticFeedback.selectionClick();

    setState(()=>section=index);

  }

  List<Widget> content() => error!=null ? [Text(error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),FilledButton(onPressed:reload,child:const Text('Reintentar'))]

    : report?['configured']!=true ? [const GroupBanner(),const SizedBox(height:24),Text(settings==null?'Registra los fondos iniciales para comenzar.':'Este mes es anterior al inicio de Tesorería.'),if(writable&&settings==null)FilledButton(onPressed:initialFunds,child:const Text('Registrar fondos'))]

    : section==0?overview():section==1?movementView():section==2?duesView():more();

  Widget periodControl() {

    final p = WorkspacePalette(context);

    return Padding(padding: const EdgeInsets.fromLTRB(16, 13, 16, 15), child: Row(children: [

      _periodArrow(Icons.chevron_left_rounded, 'Mes anterior', working||loading?null:()=>shiftMonth(-1), p),

      const SizedBox(width: 9),

      Expanded(child: SelectionField(label:'PERÍODO DE CONSULTA',value:monthLabel(month),icon:Icons.calendar_month_rounded,onTap:working||loading?null:chooseMonth)),

      const SizedBox(width: 9),

      _periodArrow(Icons.chevron_right_rounded, 'Mes siguiente', working||loading?null:()=>shiftMonth(1), p),

    ]));

  }

  Widget _periodArrow(IconData icon, String tip, VoidCallback? action, WorkspacePalette p) =>

    Material(color:p.soft, borderRadius:BorderRadius.circular(15), child:IconButton(

      tooltip:tip, onPressed:action, icon:Icon(icon, color:action==null?p.muted:p.accent),

      constraints:const BoxConstraints(minWidth:45,minHeight:51),

    ));

  @override Widget build(BuildContext context) {

    final compactHeight=MediaQuery.sizeOf(context).height<500;

    final largeText=MediaQuery.textScalerOf(context).scale(16)>24;

    final wide=MediaQuery.sizeOf(context).width>=840;

    final name=profile['display_name']??widget.repo.client.auth.currentUser?.email??'Mi cuenta';

    return Scaffold(

    appBar: AppBar(

      automaticallyImplyLeading: false,

      toolbarHeight: MediaQuery.textScalerOf(context).scale(20) * 1.3 + 54,

      backgroundColor: brandNavy,

      foregroundColor: Colors.white,

      surfaceTintColor: Colors.transparent,

      elevation: 0,

      scrolledUnderElevation: 0,

      titleSpacing: 0,

      flexibleSpace: Container(

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [

              Color(0xFF071D49),

              Color(0xFF123875),

              Color(0xFF174684),

            ],

          ),

          border: Border(

            bottom: BorderSide(

              color: brandGold,

              width: 1.2,

            ),

          ),

        ),

      ),

      leadingWidth: MediaQuery.sizeOf(context).width < 360 ? 58 : 70,

      leading: Padding(

        padding: const EdgeInsets.fromLTRB(11, 8, 3, 8),

        child: Container(

          alignment: Alignment.center,

          decoration: BoxDecoration(

            color: Colors.white.withOpacity(0.08),

            borderRadius: BorderRadius.circular(15),

            border: Border.all(

              color: brandGold.withOpacity(0.45),

              width: 1,

            ),

          ),

          child: const GroupLogo(

            size: 44,

            variant: GroupLogoVariant.clean,

          ),

        ),

      ),

      title: Padding(

        padding: const EdgeInsets.only(left: 9),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'TESORERÍA',

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(

                color: Colors.white,

                fontSize: 20,

                fontWeight: FontWeight.w900,

                letterSpacing: 1.1,

                height: 1.2,

              ),

            ),

            const SizedBox(height: 4),

            Text(

              '$name',

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: const TextStyle(

                color: Color(0xFFE0E9FA),

                fontSize: 12,

                fontWeight: FontWeight.w500,

                height: 1.3,

              ),

            ),

          ],

        ),

      ),

      actions: [

        // Selector de tema

        const IconTheme(

          data: IconThemeData(color: Colors.white),

          child: ThemeButton(),

        ),

        // Actualización visible en dispositivos con espacio suficiente

        if (MediaQuery.sizeOf(context).width >= 430)

          IconButton(

            tooltip: 'Actualizar información',

            onPressed: loading || working ? null : reload,

            icon: const Icon(

              Icons.refresh_rounded,

              color: Colors.white,

            ),

          ),

        // Menú de perfil y opciones adicionales

        PopupMenuButton<String>(

          tooltip: 'Mi perfil',

          position: PopupMenuPosition.under,

          offset: const Offset(0, 8),

          color: Theme.of(context).colorScheme.surface,

          surfaceTintColor: Colors.transparent,

          elevation: 6,

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(20),

            side: BorderSide(

              color: Theme.of(context)

                  .colorScheme

                  .outline

                  .withOpacity(0.25),

            ),

          ),

          icon: const Icon(

            Icons.account_circle_outlined,

            color: Colors.white,

            size: 26,

          ),

          onSelected: (action) {

            if (action == 'refresh') {

              if (!loading && !working) reload();

            } else {

              account(action);

            }

          },

          itemBuilder: (menuContext) {

            final scheme = Theme.of(menuContext).colorScheme;

            final role = {

              'admin': 'Administrador',

              'treasurer': 'Tesorería',

              'auditor': 'Consulta',

            }[profile['role']] ?? 'Usuario';

            return [

              PopupMenuItem<String>(

                enabled: false,

                child: Row(

                  children: [

                    CircleAvatar(

                      radius: 21,

                      backgroundColor: scheme.primaryContainer,

                      child: Icon(

                        Icons.person_outline_rounded,

                        color: scheme.onPrimaryContainer,

                      ),

                    ),

                    const SizedBox(width: 11),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            '$name',

                            maxLines: 2,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(

                              color: scheme.onSurface,

                              fontWeight: FontWeight.w800,

                              fontSize: 14,

                            ),

                          ),

                          const SizedBox(height: 3),

                          Text(

                            role,

                            style: TextStyle(

                              color: scheme.onSurfaceVariant,

                              fontSize: 12,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

              const PopupMenuDivider(),

              if (MediaQuery.sizeOf(context).width < 430)

                PopupMenuItem<String>(

                  value: 'refresh',

                  enabled: !loading && !working,

                  child: Row(

                    children: [

                      Icon(

                        Icons.refresh_rounded,

                        color: scheme.primary,

                      ),

                      const SizedBox(width: 13),

                      Text(

                        'Actualizar información',

                        style: TextStyle(color: scheme.onSurface),

                      ),

                    ],

                  ),

                ),

              PopupMenuItem<String>(

                value: 'password',

                child: Row(

                  children: [

                    Icon(

                      Icons.lock_outline_rounded,

                      color: scheme.primary,

                    ),

                    const SizedBox(width: 13),

                    Text(

                      'Cambiar contraseña',

                      style: TextStyle(color: scheme.onSurface),

                    ),

                  ],

                ),

              ),

              PopupMenuItem<String>(

                value: 'logout',

                child: Row(

                  children: [

                    Icon(

                      Icons.logout_rounded,

                      color: scheme.error,

                    ),

                    const SizedBox(width: 13),

                    Text(

                      'Cerrar sesión',

                      style: TextStyle(

                        color: scheme.error,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ],

                ),

              ),

            ];

          },

        ),

        const SizedBox(width: 8),

      ],

    ),

      body:SafeArea(child:Row(children:[if(wide)...[

        TreasuryNavigationRail(selectedIndex: section, onSelect: selectSection),

        const VerticalDivider(width: 1),

      ],Expanded(child:ResponsiveBody(child:Column(children:[

        if(!compactHeight)periodControl(),if(working)const LinearProgressIndicator(),

        Expanded(child:loading?const Center(child:CircularProgressIndicator()):AnimatedSwitcher(duration:MediaQuery.of(context).disableAnimations?Duration.zero:const Duration(milliseconds:180),child:RefreshIndicator(key:ValueKey(section),onRefresh:reload,child:ListView(key:PageStorageKey('treasury-section-$section'),physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width < 360 ? 12 : 20, 0, MediaQuery.sizeOf(context).width < 360 ? 12 : 20, 24),children:[if(compactHeight)periodControl(),...content()])))),

      ]))),])),

      bottomNavigationBar:wide?null:TreasuryNavigationBar(selectedIndex: section, onSelect: selectSection, compactLabels: largeText),

    );

  }

}