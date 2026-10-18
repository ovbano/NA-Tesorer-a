import 'experience.dart';
import 'ux_components.dart';
import 'service_forms.dart';
import 'movement_card.dart';
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:printing/printing.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'treasury.dart';
import 'rent_dues.dart';
import 'rent_dues_card.dart';

import 'entry_editor.dart';

import 'activity_editor.dart';

import 'report_pdf.dart';

import 'brand.dart';

import 'treasury_widgets.dart';


import 'treasury_navigation.dart';

import 'treasury_workspace_ui.dart';

import 'package:flutter/services.dart';

class Workspace extends StatefulWidget {

  const Workspace({super.key,required this.repo,required this.profile});final TreasuryRepository repo;final Json profile;

  @override State<Workspace> createState()=>_WorkspaceState();

}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {

  DateTime month=DateTime(today().year,today().month);int section=0,generation=0;bool loading=true,working=false;String? error,accessError;Json? report,settings;

  List<Json> members=[],companions=[],drafts=[],activities=[];Json? liveProfile;Json? duesHistory;List<Json> duesRoster=[];

  Json get profile=>liveProfile??widget.profile;String query='',kind='all';

  String duesSearch='',duesFilter='all',activitySearch='',activityFilter='all';

  final duesSearchController = TextEditingController();
  final movementSearchController = TextEditingController();

  final activitySearchController = TextEditingController();

  bool get writable=>accessError==null && ['admin','treasurer'].contains(profile['role']);

  bool get closed=>report?['closure']!=null;

  @override void initState(){super.initState();WidgetsBinding.instance.addObserver(this);appearance.addListener(appearanceChanged);reload();}

  @override void dispose(){generation++;movementSearchController.dispose();duesSearchController.dispose();activitySearchController.dispose();appearance.removeListener(appearanceChanged);WidgetsBinding.instance.removeObserver(this);super.dispose();}

  void appearanceChanged(){if(mounted)setState((){});}

  @override void didChangeAppLifecycleState(AppLifecycleState state){if(state==AppLifecycleState.resumed)reload();}

  Future<void> reload()async{

    final ticket=++generation;setState((){loading=true;error=null;});

    try{

      final access=await widget.repo.profile();

      final s=await widget.repo.settings();

      final result=await Future.wait<dynamic>([s==null||period(month).compareTo(s['start_month'])<0?Future<Json>.value({'configured':false}):widget.repo.report(month),widget.repo.all('treasury_members'),widget.repo.companions(),widget.repo.all('treasury_entries',status:'draft'),widget.repo.client.rpc('treasury_activities'),s==null||period(month).compareTo(s['start_month'])<0?Future<Json>.value({'configured':false}):widget.repo.duesHistory(month)]);

      if(!mounted||ticket!=generation)return;

      setState((){liveProfile=access;settings=s;report=result[0];members=result[1];companions=result[2];drafts=result[3];activities=rows(result[4]);duesHistory=Json.from(result[5] as Map);duesRoster=duesHistory?['configured']==true?rentRoster(duesHistory!,members,companions):[];accessError=null;});

    }catch(e){if(mounted&&ticket==generation){setState((){error=message(e);if(e is FormatException){accessError=error;report=null;members=[];companions=[];drafts=[];activities=[];duesHistory=null;duesRoster=[];}});}}

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

  Future<String?> ask(String title,String label,{bool password=false})=>
    showServiceForm<String>(context,TextRequestForm(title:title,description:label,password:password));

  Future<void> account(String action)async{

    if(action=='logout'){await task(()async{await widget.repo.client.auth.signOut(scope:SignOutScope.local);});}

    if(action=='password'){
      final saved=await showServiceForm<bool>(context,PasswordForm(onSave:(value)async{
        await widget.repo.client.auth.updateUser(UserAttributes(password:value));
      }));
      if(saved==true)notify('Contraseña actualizada.');
    }

    if(action=='admin'){await launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/admin/'),mode:LaunchMode.externalApplication);}

    if(action=='initial')await initialFunds();

  }

  Future<void> initialFunds() async {
    if(!writable||working)return;
    final saved=await showServiceForm<bool>(context,InitialFundsForm(settings:settings,month:month,onSave:(payload)async{
      await widget.repo.command(settings==null?'setup':'initial_update',payload);
    }));
    if(saved==true&&mounted){notify('Fondos iniciales guardados.');await reload();}
  }

  Future<void> export() async {
    if (report?['configured'] != true || working) return;

    // 1. Seleccionar cómo se generará el informe.
    final includePhotos=await showServiceForm<bool>(context,ReportOptionsForm(month:month));

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

      final exportHistory = await widget.repo.duesHistory(month);
      if (exportHistory['configured'] != true) {
        throw const FormatException('No se pudo obtener el historial de aportes. Vuelve a intentar.');
      }
      final exportMembers = await widget.repo.all('treasury_members');
      final exportCompanions = await widget.repo.companions();
      fresh['dues_history'] = exportHistory;
      fresh['dues_roster'] = rentRoster(exportHistory,exportMembers,exportCompanions);

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
          if (path.toLowerCase().endsWith('.pdf')) continue;

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

    await task(()async{final data=await widget.repo.client.storage.from('treasury-receipts').download(path).timeout(const Duration(seconds:20));if(!mounted)return;if(path.toString().endsWith('.pdf')){await Printing.sharePdf(bytes:data,filename:'Comprobante.pdf');}else{await showExperienceDialog<void>(context:context,builder:(c)=>Dialog(child:SizedBox(height:MediaQuery.sizeOf(c).height*.75,child:Column(children:[Expanded(child:InteractiveViewer(child:Image.memory(data,errorBuilder:(_,e,s)=>const Padding(padding:EdgeInsets.all(24),child:Text('No se pudo mostrar esta imagen.'))))),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Cerrar'))]))));}});

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
                      SheetHeading(title:income?'Detalle del ingreso':'Detalle del egreso',
                        icon:income?Icons.south_west_rounded:Icons.north_east_rounded,
                        subtitle:'Movimiento del fondo ${entry['fund']=='rent'?'del local':'general'}',
                        onClose:()=>Navigator.pop(sheetContext)),
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
                            final confirmed = await showExperienceDialog<bool>(
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
    if(!writable||working||report?['configured']!=true)return;
    if(closed){
      final saved=await showServiceForm<bool>(context,ReasonActionForm(
        title:'Reabrir ${monthLabel(month)}',description:'También se reabrirán los meses posteriores. Conserva un motivo claro para la auditoría.',
        onSave:(reason)async{await widget.repo.command('reopen',{'month':period(month),'reason':reason});}));
      if(saved==true&&mounted){notify('Período reabierto.');await reload();}
      return;
    }
    await task(()async{
      final fresh=await widget.repo.report(month);
      if(!mounted)return;
      final saved=await showServiceForm<bool>(context,CloseMonthForm(month:month,report:fresh,onSave:(payload)async{
        await widget.repo.command('close',payload);
      }));
      if(saved==true&&mounted){notify('Mes cerrado. El informe quedó conservado.');await reload();}
    });
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

  Widget entryTile(Json entry)=>MovementCard(entry:entry,onTap:()=>detail(entry));

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

      AdaptiveIntro(title:'Nuestro fondo, con claridad',subtitle:'${monthLabel(month)} · Revisa el dinero disponible y los movimientos del grupo.',icon:Icons.account_balance_wallet_outlined,showLogo:true),
      const SizedBox(height:18),

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
    bool matches(Json entry)=>(kind=='all'||entry['kind']==kind)&&
      _searchKey('${entry['description']} ${entry['member_name']} ${categories[entry['category']]} ${entry['entry_date']}').contains(_searchKey(query));
    final filtered=rows(report?['entries']).reversed.where((entry)=>entry['status']!='draft'&&matches(entry)).toList();
    final filteredDrafts=drafts.where(matches).toList();

    return [

      const WorkspaceHeadline(title:'Movimientos',subtitle:'Ingresos y egresos del período seleccionado.',icon:Icons.swap_vert_rounded),

      if(writable) ...[WorkspaceActionButton(onPressed:working?null:()=>edit(),icon:Icons.add_circle_outline,title:'Nuevo movimiento'),const SizedBox(height:18)],

      WorkspaceSearchPanel(

        controller:movementSearchController,onClear:(){movementSearchController.clear();setState(()=>query='');},
        hint:'Detalle, compañero o fecha', onChanged:(value)=>setState(()=>query=value.toLowerCase()),

        filters:const {'all':'Todos','income':'Ingresos','expense':'Egresos'},

        selected:kind, onFilter:(value)=>setState(()=>kind=value),

        countLabel:'${filtered.length} movimientos · ${filteredDrafts.length} borradores',

      ),

      UxSection(title:'En esta búsqueda',icon:Icons.analytics_outlined,description:'Solo movimientos confirmados. Los borradores y anulados no se suman.',child:FactsGrid(facts:[
        UxFact('Ingresos',money(filtered.where((e)=>e['status']=='posted'&&e['kind']=='income').fold<int>(0,(sum,e)=>sum+((e['amount_cents'] as num?)?.toInt()??0)))),
        UxFact('Egresos',money(filtered.where((e)=>e['status']=='posted'&&e['kind']=='expense').fold<int>(0,(sum,e)=>sum+((e['amount_cents'] as num?)?.toInt()??0)))),
      ])),

      if(filtered.isEmpty&&filteredDrafts.isEmpty)const EmptyLedger('Sin movimientos para mostrar','Cambia el filtro o selecciona otro mes.'),
      if(filtered.isEmpty&&filteredDrafts.isNotEmpty)const FieldNote('La búsqueda encontró borradores por completar. Todavía no afectan los saldos.'),

      ...filtered.map(entryTile),

      if(filteredDrafts.isNotEmpty)...[const SectionTitle('Borradores guardados',subtitle:'Por completar; pueden corresponder a otro período. No afectan el saldo.',icon:Icons.edit_note),...filteredDrafts.map(entryTile)],

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

  Future<void> receiveRent(Json member,Json duePeriod) async {
    if(!writable||working||closed||settings==null||period(month)!=period(today()))return;
    final saved=await Navigator.push<bool>(context,MaterialPageRoute(builder:(_)=>EntryEditor(
      repo:widget.repo,month:month,settings:settings!,members:members,companions:companions,
      initialPayment:{'kind':'income','category':'rent_contribution','fund':'rent',
        'entry_date':iso(today()),'member_id':member['id'],'due_month':duePeriod['month'],
        'amount_cents':duePeriod['pending'],
        'description':'Aporte para arriendo · ${member['name']} · ${monthLabel(DateTime.parse(duePeriod['month'] as String))}'},
    )));
    if(saved==true&&mounted){notify('Aporte guardado. El saldo se actualiza según el mes asignado.');await reload();}
  }

  Future<void> configureRent(Json person)async{
    if(!writable||working||settings==null)return;
    final saved=await showServiceForm<bool>(context,RentSetupForm(person:person,settings:settings!,month:month,onSave:(payload)async{
      await widget.repo.profile();
      await widget.repo.command('member',payload);
    }));
    if(saved==true&&mounted){notify('Inicio y cuota guardados.');await reload();}
  }

  List<Widget> duesView() {

    final dues = duesRoster;
    final total = rentTotals(dues);

    final pendingActivities = activities.fold<num>(

      0, (sum, account) => sum + (account['pending_cents'] as num));

    final filteredDues = filterRent(dues,duesSearch,duesFilter);

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

      UxSection(title:'Panorama del compromiso',description:'Deuda calculada de los compañeros con inicio confirmado.',icon:Icons.home_work_outlined,
        child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          FactsGrid(facts:[UxFact('Total por cobrar',money(total['total_pending'])),UxFact('Meses anteriores',money(total['previous_pending'])),UxFact('Mes consultado',money(total['current_pending']))]),
          const SizedBox(height:10),ExpansionTile(key:const PageStorageKey<String>('rent-month-summary'),tilePadding:EdgeInsets.zero,
            title:const Text('Ver cuotas y recaudación del mes',style:TextStyle(fontSize:14,fontWeight:FontWeight.w700)),children:[
              FactsGrid(facts:[
                UxFact('Cuotas del mes',money(rows(report?['dues']).fold<int>(0,(sum,d)=>sum+rentAmount(d,'expected')))),
                UxFact('Recibido para este mes',money(rows(report?['dues']).fold<int>(0,(sum,d)=>sum+rentAmount(d,'paid')))),
              ]),
            ]),
        ])),

      const InfoNote('La deuda es informativa y no suma dinero en caja. Los abonos se descuentan del mes asignado; el dinero ingresa en su fecha real de recepción.'),
      if (dues.any((d)=>d['tracking']=='unconfigured'))
        const InfoNote('Hay compañeros con inicio por configurar. Confirma desde qué mes les corresponde la cuota; su deuda todavía no se ha calculado.'),
      if (period(month)!=period(today()))
        WorkspaceActionButton(onPressed:working?null:()async{setState(()=>month=DateTime(today().year,today().month));await reload();},icon:Icons.today,title:'Ir al mes actual para recibir abonos',secondary:true),

      _listFilters(

        hint: 'Buscar compañero por nombre o apellido',

        controller: duesSearchController,

        search: duesSearch,

        onSearch: (value) => setState(() => duesSearch = value),

        selected: duesFilter,

        onFilter: (value) => setState(() => duesFilter = value),

        options: const {

          'all': 'Todos',

          'pending': 'Con deuda',
          'partial': 'Con abonos y deuda',
          'paid': 'Sin deuda calculada',
          'unconfigured': 'Por configurar',

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

        RentDuesCard(key:ValueKey('due-${due['id']}'),member:due,
          onConfigure:writable&&!working&&due['tracking']=='unconfigured'?()=>configureRent(due):null,
          onPay:writable&&!working&&!closed&&period(month)==period(today())?(p)=>receiveRent(due,p):null),

      const SizedBox(height: 14),

      const WorkspaceHeadline(title:'Actividades del grupo',

          subtitle: 'Bingos, rifas y otros compromisos pendientes.',

          icon: Icons.volunteer_activism_outlined),

      UxSection(title:'Compromisos de actividades',description:'Solo los pagos recibidos se incorporan al fondo general.',icon:Icons.volunteer_activism_outlined,
        child:FactsGrid(facts:[UxFact('Total por cobrar',money(pendingActivities)),UxFact('Compromisos registrados','${activities.length}') ])),

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

  Future<void> audit()async{await task(()async{final data=await widget.repo.client.from('treasury_audit').select('action,actor_name,happened_at').order('id',ascending:false).limit(50);if(!mounted)return;await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>SizedBox(height:MediaQuery.sizeOf(c).height*.8,child:ListView(padding:const EdgeInsets.all(20),children:[SheetHeading(title:'Historial de cambios',subtitle:'Últimos 50 registros de auditoría',icon:Icons.history_rounded,onClose:()=>Navigator.pop(c)),const SizedBox(height:16),...data.map((a)=>ListTile(leading:const Icon(Icons.history),title:Text(a['actor_name']??'Usuario'),subtitle:Text('${a['action']} · ${a['happened_at']}')))])));});}

  List<Widget> more(){
    final name=profile['display_name']??widget.repo.client.auth.currentUser?.email??'Mi cuenta';
    final role=profile['role']=='admin'?'Administrador':profile['role']=='auditor'?'Auditor':'Tesorería';
    return [
      AdaptiveIntro(title:'Tu espacio',subtitle:'$name · $role',icon:Icons.person_outline_rounded,showLogo:true,
        eyebrow:'TU CUENTA · AMIGOS VERDADEROS'),
      const SizedBox(height:18),
      const WorkspaceThemeSelector(),
      ServiceOptions(title:'Cuidado del período',description:monthLabel(month),options:[
        if(writable&&report?['configured']==true) ServiceOption(closed?'Reabrir mes con motivo':'Revisar y cerrar el mes',
          closed?'Reabre este período y los posteriores para corregir registros.':'Compara el saldo con el dinero contado y guarda el cierre.',
          Icons.lock_clock_outlined,working?null:closeMonth),
        if(writable) ServiceOption('Fondos iniciales','Consulta o corrige el punto de partida de ambos fondos.',Icons.account_balance_wallet_outlined,working?null:initialFunds),
        ServiceOption('Historial de cambios','Identifica quién realizó cada actualización.',Icons.history_rounded,working?null:audit),
      ]),
      ServiceOptions(title:'Cuenta y seguridad',options:[
        ServiceOption('Cambiar contraseña','Actualízala con confirmación en una sola ventana.',Icons.lock_reset_rounded,working?null:()=>account('password')),
        if(profile['role']=='admin') ServiceOption('Administrar usuarios','Abre el panel de accesos del grupo en la web.',Icons.manage_accounts_outlined,working?null:()=>account('admin')),
        ServiceOption('Cerrar sesión','Salir de esta cuenta en este dispositivo.',Icons.logout_rounded,working?null:()=>account('logout'),danger:true),
      ]),
      ServiceOptions(title:'Herramientas del servicio',options:[
        ServiceOption('Abrir Tesorería web','Continúa en la plataforma web del grupo.',Icons.open_in_browser_rounded,
          ()=>launchUrl(Uri.parse('https://narcoticos-anonimos-azure.vercel.app/tesoreria/'),mode:LaunchMode.externalApplication)),
      ]),
      UxSection(title:'Guía rápida',icon:Icons.help_outline_rounded,child:ExpansionTile(
        key:const PageStorageKey<String>('service-guide-expanded'),tilePadding:EdgeInsets.zero,
        title:const Text('Cómo llevar el registro'),children:const [
          FieldNote('General: séptimas y otros ingresos para gastos del grupo. Local: dinero reservado para arriendo.'),
          FieldNote('Un borrador permite completar un registro después; no aumenta ni disminuye el saldo.'),
          FieldNote('Confirmar incorpora el movimiento. Corregir conserva el historial. Los pendientes no son dinero en caja.'),
        ])),
      const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('Un día a la vez, juntos.\nAmigos Verdaderos · Narcóticos Anónimos',textAlign:TextAlign.center,style:TextStyle(height:1.6,fontSize:12))),
    ];
  }

  Future<void> openAccount()async{
    if(working)return;
    final name=profile['display_name']??widget.repo.client.auth.currentUser?.email??'Mi cuenta';
    final email=widget.repo.client.auth.currentUser?.email??'';
    final role=profile['role']=='admin'?'Administrador':profile['role']=='auditor'?'Auditor':'Tesorería';
    final selected=await showModalBottomSheet<String>(context:context,isScrollControlled:true,useSafeArea:true,builder:(c)=>
      SizedBox(height:MediaQuery.sizeOf(c).height*.85,child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,4,18,24),child:Column(children:[
        AdaptiveIntro(title:'$name',subtitle:'$email · $role',icon:Icons.person_outline_rounded,showLogo:true,eyebrow:'TU CUENTA'),
        const SizedBox(height:16),ServiceOptions(title:'Accesos rápidos',options:[
          ServiceOption('Tu espacio','Preferencias y herramientas de tu servicio.',Icons.dashboard_customize_outlined,()=>Navigator.pop(c,'space')),
          ServiceOption('Actualizar información','Vuelve a consultar los datos del período.',Icons.refresh_rounded,loading?null:()=>Navigator.pop(c,'refresh')),
          if(writable) ServiceOption('Fondos iniciales','Revisa el punto de partida del grupo.',Icons.account_balance_wallet_outlined,()=>Navigator.pop(c,'initial')),
          ServiceOption('Cambiar contraseña','Cuida la credencial de tu cuenta.',Icons.lock_reset_rounded,()=>Navigator.pop(c,'password')),
          ServiceOption('Cerrar sesión','Salir de este dispositivo.',Icons.logout_rounded,()=>Navigator.pop(c,'logout'),danger:true),
        ]),
        TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Volver')),
      ]))));
    if(selected==null||!mounted)return;
    if(selected=='space'){selectSection(3);}else if(selected=='refresh'){await reload();}else{await account(selected);}
  }

  void selectSection(int index) {

    if(index==section)return;

    HapticFeedback.selectionClick();

    setState(()=>section=index);

  }

  List<Widget> content() => section==3?more():error!=null ? [const WorkspaceHeadline(title:'No pudimos cargar este período',icon:Icons.cloud_off_rounded),InfoNote(error!),WorkspaceActionButton(onPressed:reload,icon:Icons.refresh_rounded,title:'Volver a intentar')]

    : report?['configured']!=true ? [const GroupBanner(),const SizedBox(height:24),Text(settings==null?'Registra los fondos iniciales para comenzar.':'Este mes es anterior al inicio de Tesorería.'),if(writable&&settings==null)FilledButton(onPressed:initialFunds,child:const Text('Registrar fondos'))]

    : section==0?overview():section==1?movementView():section==2?duesView():more();

  Widget periodControl()=>PeriodPanel(label:monthLabel(month),loading:loading,
    current:period(month)==period(today()),
    onChoose:working||loading?null:chooseMonth,
    onPrevious:working||loading?null:()=>shiftMonth(-1),
    onNext:working||loading?null:()=>shiftMonth(1));

  @override Widget build(BuildContext context) {

    final compactHeight=MediaQuery.sizeOf(context).height<500;

    final largeText=MediaQuery.textScalerOf(context).scale(16)>24;

    final wide=MediaQuery.sizeOf(context).width>=840;

    final name=profile['display_name']??widget.repo.client.auth.currentUser?.email??'Mi cuenta';

    return Scaffold(

    appBar: AppBar(automaticallyImplyLeading:false,
      toolbarHeight:MediaQuery.textScalerOf(context).scale(20)*1.3+50,
      backgroundColor:Theme.of(context).colorScheme.surface,
      foregroundColor:Theme.of(context).colorScheme.onSurface,
      surfaceTintColor:Colors.transparent,titleSpacing:16,
      title:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('TESORERÍA',style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800,fontSize:18,letterSpacing:.7)),
        const SizedBox(height:4),Text('$name',maxLines:1,overflow:TextOverflow.ellipsis,
          style:TextStyle(color:Theme.of(context).colorScheme.onSurfaceVariant,fontSize:12)),
      ]),
      actions:[ThemeButton(foregroundColor:Theme.of(context).colorScheme.primary),
        IconButton(tooltip:'Mi perfil y opciones',onPressed:working?null:openAccount,
          icon:Icon(Icons.account_circle_outlined,color:Theme.of(context).colorScheme.primary,size:28)),const SizedBox(width:8)],
      bottom:PreferredSize(preferredSize:const Size.fromHeight(1),child:Container(height:1,color:Theme.of(context).colorScheme.outlineVariant)),
    ),

      body:SafeArea(child:BrandedBackdrop(child:Row(children:[if(wide)...[

        TreasuryNavigationRail(selectedIndex: section, onSelect: selectSection),

        const VerticalDivider(width: 1),

      ],Expanded(child:ResponsiveBody(child:Column(children:[

        if(!compactHeight)periodControl(),if(working)const BusyStrip(message:'Procesando tu solicitud…'),

        Expanded(child:loading?TreasuryLoading(title:'Consultando ${monthLabel(month)}',detail:'Cargando saldos, movimientos y aportes del grupo.',skeleton:true):AnimatedSwitcher(duration:MediaQuery.of(context).disableAnimations?Duration.zero:const Duration(milliseconds:180),child:RefreshIndicator(key:ValueKey(section),onRefresh:reload,child:ListView(key:PageStorageKey('treasury-section-$section'),physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(MediaQuery.sizeOf(context).width < 360 ? 12 : 20, 0, MediaQuery.sizeOf(context).width < 360 ? 12 : 20, 24),children:[if(compactHeight)periodControl(),...content()])))),

      ]))),]))),

      bottomNavigationBar:wide?null:TreasuryNavigationBar(selectedIndex: section, onSelect: selectSection, compactLabels: largeText),

    );

  }

}
