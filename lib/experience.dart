import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'brand.dart';
import 'group_logo.dart';

Duration experienceDuration(BuildContext context, [int ms = 200]) =>
    MediaQuery.of(context).disableAnimations ? Duration.zero : Duration(milliseconds:ms);

/// Decoración vectorial local. No recibe gestos ni altera el logotipo.
class BrandPattern extends CustomPainter {
  const BrandPattern({required this.color});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final pen=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=1;
    final center=Offset(size.width*.91,size.height*.14);
    final radius=math.min(size.width,size.height)*.56;
    for(final factor in [.65,.86,1.08]) {canvas.drawCircle(center,radius*factor,pen);}
    final diamond=Path()..moveTo(center.dx,center.dy-radius*.55)
      ..lineTo(center.dx+radius*.55,center.dy)..lineTo(center.dx,center.dy+radius*.55)
      ..lineTo(center.dx-radius*.55,center.dy)..close();
    canvas.drawPath(diamond,pen);
    canvas.drawLine(Offset(0,size.height*.85),Offset(size.width,size.height*.68),pen);
  }
  @override
  bool shouldRepaint(covariant BrandPattern oldDelegate)=>oldDelegate.color!=color;
}

class BrandedBackdrop extends StatelessWidget {
  const BrandedBackdrop({super.key,required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final dark=Theme.of(context).brightness==Brightness.dark;
    return Stack(fit:StackFit.expand,children:[
      DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
        begin:Alignment.topLeft,end:Alignment.bottomRight,
        colors:dark?const [Color(0xFF081629),Color(0xFF142640)]:const [Color(0xFFF8F7F2),Color(0xFFEBF0F8)],
      ))),
      Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:BrandPattern(color:(dark?brandGold:brandNavy).withOpacity(dark ? .055 : .035))))),
      child,
    ]);
  }
}

/// Respuesta táctil y de puntero, conservando los gestos de sus hijos.
class PanelMotion extends StatefulWidget {
  const PanelMotion({super.key,required this.child});
  final Widget child;
  @override
  State<PanelMotion> createState()=>_PanelMotionState();
}
class _PanelMotionState extends State<PanelMotion> {
  bool hover=false,pressed=false;
  @override
  Widget build(BuildContext context)=>MouseRegion(
    onEnter:(_)=>setState(()=>hover=true),onExit:(_)=>setState((){hover=false;pressed=false;}),
    child:Listener(onPointerDown:(_)=>setState(()=>pressed=true),
      onPointerUp:(_)=>setState(()=>pressed=false),onPointerCancel:(_)=>setState(()=>pressed=false),
      child:AnimatedScale(scale:pressed ? .995 : 1,duration:experienceDuration(context,130),
        child:AnimatedSlide(offset:hover&&!pressed?const Offset(0,-.008):Offset.zero,
          duration:experienceDuration(context),child:widget.child))),
  );
}

class TreasuryLoading extends StatefulWidget {
  const TreasuryLoading({super.key,this.title='Cargando Tesorería',
    this.detail='Preparando tu espacio de servicio.',this.skeleton=false});
  final String title,detail;
  final bool skeleton;
  @override
  State<TreasuryLoading> createState()=>_TreasuryLoadingState();
}
class _TreasuryLoadingState extends State<TreasuryLoading> with SingleTickerProviderStateMixin {
  late final AnimationController pulse=AnimationController(vsync:this,duration:const Duration(milliseconds:1600));
  @override
  void didChangeDependencies(){super.didChangeDependencies();
    if(MediaQuery.of(context).disableAnimations||!TickerMode.of(context)){pulse.stop();}
    else if(!pulse.isAnimating){pulse.repeat(reverse:true);}
  }
  @override
  void dispose(){pulse.dispose();super.dispose();}
  @override
  Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Semantics(liveRegion:true,label:'${widget.title}. ${widget.detail}',
      child:ExcludeSemantics(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),
        child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Column(mainAxisSize:MainAxisSize.min,children:[
          AnimatedBuilder(animation:pulse,builder:(c,child)=>Container(
            padding:EdgeInsets.all(12+pulse.value*3),
            decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:brandGold.withOpacity(.35+pulse.value*.25)),
              boxShadow:[BoxShadow(color:brandNavy.withOpacity(.08),blurRadius:30,spreadRadius:pulse.value*4)]),
            child:child),child:const GroupLogo(size:88,variant:GroupLogoVariant.featured)),
          const SizedBox(height:24),Text(widget.title,textAlign:TextAlign.center,
            style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),
          const SizedBox(height:10),Text(widget.detail,textAlign:TextAlign.center,style:TextStyle(color:colors.onSurfaceVariant,height:1.5)),
          const SizedBox(height:22),
          if(MediaQuery.of(context).disableAnimations) Icon(Icons.hourglass_top_rounded,color:colors.primary)
          else SizedBox(width:180,child:LinearProgressIndicator(minHeight:3,borderRadius:BorderRadius.circular(5))),
          if(widget.skeleton) ...[
            const SizedBox(height:28),
            for(final width in [double.infinity,260.0,200.0]) Container(
              height:14,width:width,margin:const EdgeInsets.only(bottom:12),
              decoration:BoxDecoration(color:colors.onSurface.withOpacity(.055),borderRadius:BorderRadius.circular(8))),
          ],
        ]))),
      )));
  }
}

class BusyStrip extends StatelessWidget {
  const BusyStrip({super.key,this.message='Guardando los cambios…'});
  final String message;
  @override
  Widget build(BuildContext context)=>Semantics(liveRegion:true,child:Container(
    padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),
    color:Theme.of(context).colorScheme.primaryContainer,
    child:Row(children:[if(MediaQuery.of(context).disableAnimations) const Icon(Icons.hourglass_top_rounded,size:17) else const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)),
      const SizedBox(width:12),Expanded(child:Text(message,style:const TextStyle(fontWeight:FontWeight.w600,fontSize:13)))]),
  ));
}

class SheetHeading extends StatelessWidget {
  const SheetHeading({super.key,required this.title,required this.icon,this.subtitle,this.onClose});
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.all(18),
    decoration:BoxDecoration(gradient:const LinearGradient(colors:[brandNavy,Color(0xFF234C7C)]),borderRadius:BorderRadius.circular(22)),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white.withOpacity(.10),borderRadius:BorderRadius.circular(13)),child:Icon(icon,color:brandGold)),
      const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:19,height:1.25)),
        if(subtitle!=null) ...[const SizedBox(height:6),Text(subtitle!,style:const TextStyle(color:Color(0xFFDDE6F4),fontSize:12,height:1.4))],
      ])),
      if(onClose!=null) IconButton(tooltip:'Cerrar',onPressed:onClose,icon:const Icon(Icons.close_rounded,color:Colors.white)),
    ]),
  );
}

/// Mismas respuestas y cancelación que showDialog, con entrada suave.
Future<T?> showExperienceDialog<T>({required BuildContext context,
  required WidgetBuilder builder,bool barrierDismissible=true}) {
  final captured=InheritedTheme.capture(from:context,to:Navigator.of(context,rootNavigator:true).context);
  return showGeneralDialog<T>(context:context,barrierDismissible:barrierDismissible,
    barrierLabel:MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor:const Color(0xFF041127).withOpacity(.64),
    transitionDuration:experienceDuration(context,240),
    pageBuilder:(c,a,b)=>SafeArea(child:captured.wrap(Builder(builder:builder))),
    transitionBuilder:(c,a,b,child)=>FadeTransition(opacity:CurvedAnimation(parent:a,curve:Curves.easeOut),
      child:SlideTransition(position:Tween<Offset>(begin:const Offset(0,.035),end:Offset.zero)
        .animate(CurvedAnimation(parent:a,curve:Curves.easeOutCubic)),child:child)),
  );
}

class PeriodPanel extends StatelessWidget {
  const PeriodPanel({super.key,required this.label,this.onChoose,this.onPrevious,this.onNext,this.loading=false,this.current=false});
  final String label;
  final VoidCallback? onChoose,onPrevious,onNext;
  final bool loading,current;
  @override
  Widget build(BuildContext context)=>PanelMotion(child:Container(
    margin:const EdgeInsets.fromLTRB(16,14,16,14),
    clipBehavior:Clip.antiAlias,
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),
      gradient:const LinearGradient(colors:[brandNavy,Color(0xFF234B7A)]),
      border:Border.all(color:brandGold.withOpacity(.48)),
      boxShadow:[BoxShadow(color:brandNavy.withOpacity(.13),blurRadius:18,offset:const Offset(0,7))]),
    child:Material(color:Colors.transparent,child:Column(children:[
      InkWell(onTap:onChoose,child:Padding(padding:const EdgeInsets.fromLTRB(18,16,16,14),
        child:Row(children:[
          const Icon(Icons.calendar_month_rounded,color:brandGold,size:27),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('PERÍODO DE CONSULTA',style:TextStyle(color:brandGold,fontWeight:FontWeight.w700,fontSize:10,letterSpacing:1.2)),
            const SizedBox(height:4),AnimatedSwitcher(duration:experienceDuration(context),
              child:Align(key:ValueKey(label),alignment:Alignment.centerLeft,
                child:Text(label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:21,height:1.2)))),
          ])),
          const SizedBox(width:8),Icon(onChoose==null?Icons.lock_clock_outlined:Icons.expand_more_rounded,color:Colors.white70),
        ]))),
      Container(color:Colors.white.withOpacity(.055),padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),
        child:Row(children:[
          IconButton(tooltip:'Mes anterior',onPressed:onPrevious,icon:Icon(Icons.chevron_left_rounded,color:onPrevious==null?Colors.white30:Colors.white)),
          Expanded(child:Text(loading?'Consultando los movimientos…':current?'Mes actual · toca para cambiar':'Consulta histórica · toca para cambiar',textAlign:TextAlign.center,
            style:const TextStyle(color:Color(0xFFDCE6F5),fontSize:12,height:1.35))),
          IconButton(tooltip:'Mes siguiente',onPressed:onNext,icon:Icon(Icons.chevron_right_rounded,color:onNext==null?Colors.white30:Colors.white)),
        ])),
      if(loading&&!MediaQuery.of(context).disableAnimations) const LinearProgressIndicator(minHeight:2,color:brandGold,backgroundColor:Colors.transparent),
    ])),
  ));
}

class MetricExplanation extends StatefulWidget {
  const MetricExplanation({super.key,required this.text,this.onDark=false});
  final String text;
  final bool onDark;
  @override
  State<MetricExplanation> createState()=>_MetricExplanationState();
}
class _MetricExplanationState extends State<MetricExplanation> {
  bool expanded=false;
  @override
  Widget build(BuildContext context){
    final ink=widget.onDark?const Color(0xFFE6EDF8):Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const SizedBox(height:8),
      TextButton.icon(onPressed:()=>setState(()=>expanded=!expanded),
        style:TextButton.styleFrom(foregroundColor:widget.onDark?brandGold:null,padding:EdgeInsets.zero),
        icon:Icon(expanded?Icons.keyboard_arrow_up_rounded:Icons.info_outline_rounded,size:18),
        label:Text(expanded?'Ocultar explicación':'¿Qué incluye?',style:const TextStyle(fontSize:12))),
      AnimatedSize(duration:experienceDuration(context),alignment:Alignment.topLeft,
        child:expanded?Padding(padding:const EdgeInsets.only(bottom:8),child:Text(widget.text,style:TextStyle(color:ink,fontSize:13,height:1.5))):const SizedBox(width:double.infinity)),
    ]);
  }
}
