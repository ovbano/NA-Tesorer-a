import 'package:flutter/material.dart';
import 'brand.dart';
import 'experience.dart';
import 'group_logo.dart';

/// Encabezados adaptativos: el tema claro usa tinta azul sobre marfil;
/// el tema oscuro usa tinta clara sobre azul. No cambia la identidad del logo.
class AdaptiveIntro extends StatelessWidget {
  const AdaptiveIntro({super.key,required this.title,required this.subtitle,
    required this.icon,this.eyebrow='AMIGOS VERDADEROS',this.showLogo=false,this.trailing});
  final String title,subtitle,eyebrow;
  final IconData icon;
  final bool showLogo;
  final Widget? trailing;
  @override
  Widget build(BuildContext context){
    final theme=Theme.of(context),c=theme.colorScheme;
    final dark=theme.brightness==Brightness.dark;
    return Container(width:double.infinity,padding:const EdgeInsets.all(22),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),
        gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,
          colors:dark?const [Color(0xFF102744),Color(0xFF193957)]:const [Color(0xFFFAF7EF),Color(0xFFEBF1FA)]),
        border:Border.all(color:dark?brandGold.withOpacity(.35):const Color(0xFFD6DEEA))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          if(showLogo) const GroupLogo(size:52,variant:GroupLogoVariant.clean)
          else Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:c.primary.withOpacity(.09),borderRadius:BorderRadius.circular(16)),child:Icon(icon,color:c.primary,size:25)),
          const SizedBox(width:12),Expanded(child:Padding(padding:const EdgeInsets.only(top:4),child:Text(eyebrow,
            style:TextStyle(color:dark?brandGold:const Color(0xFF72551F),fontWeight:FontWeight.w800,fontSize:11,letterSpacing:1,height:1.5)))),
          if(trailing!=null) trailing!,
        ]),
        const SizedBox(height:20),Text(title,style:theme.textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800,height:1.2,color:c.onSurface)),
        const SizedBox(height:10),Text(subtitle,style:TextStyle(color:c.onSurfaceVariant,height:1.55)),
      ]),
    );
  }
}

class UxSection extends StatelessWidget {
  const UxSection({super.key,required this.title,required this.child,this.description,this.icon=Icons.folder_outlined,this.step});
  final String title;
  final String? description,step;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme;
    return PanelMotion(child:Container(width:double.infinity,margin:const EdgeInsets.only(bottom:16),
      decoration:BoxDecoration(color:c.surface,borderRadius:BorderRadius.circular(24),border:Border.all(color:c.outlineVariant)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Padding(padding:const EdgeInsets.all(18),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:38,height:38,alignment:Alignment.center,decoration:BoxDecoration(color:c.primaryContainer,borderRadius:BorderRadius.circular(12)),
            child:step==null?Icon(icon,color:c.onPrimaryContainer,size:21):Text(step!,style:TextStyle(color:c.onPrimaryContainer,fontWeight:FontWeight.w800))),
          const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(title,style:TextStyle(color:c.onSurface,fontSize:18,fontWeight:FontWeight.w800,height:1.3)),
            if(description!=null)...[const SizedBox(height:5),Text(description!,style:TextStyle(color:c.onSurfaceVariant,fontSize:13,height:1.45))],
          ])),
        ])),
        Divider(height:1,color:c.outlineVariant.withOpacity(.6)),
        Padding(padding:const EdgeInsets.all(18),child:child),
      ]),
    ));
  }
}

class UxFact {
  const UxFact(this.label,this.value,{this.color});
  final String label,value;
  final Color? color;
}
class FactsGrid extends StatelessWidget {
  const FactsGrid({super.key,required this.facts});
  final List<UxFact> facts;
  @override
  Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){
    final c=Theme.of(context).colorScheme;
    final columns=constraints.maxWidth>=460&&MediaQuery.textScalerOf(context).scale(16)<24?2:1;
    final width=(constraints.maxWidth-(columns-1)*10)/columns;
    return Wrap(spacing:10,runSpacing:10,children:[for(final fact in facts) SizedBox(width:width,
      child:Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:c.surfaceContainerHighest.withOpacity(.45),borderRadius:BorderRadius.circular(16)),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(fact.label,style:TextStyle(color:c.onSurfaceVariant,fontSize:12,height:1.4)),
          const SizedBox(height:6),Text(fact.value,style:TextStyle(color:fact.color??c.onSurface,fontWeight:FontWeight.w800,fontSize:19,height:1.25))]))),
    ]);
  });
}

class ServiceOption {
  const ServiceOption(this.title,this.description,this.icon,this.onTap,{this.danger=false});
  final String title,description;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
}
class ServiceOptions extends StatelessWidget {
  const ServiceOptions({super.key,required this.title,required this.options,this.description});
  final String title;
  final String? description;
  final List<ServiceOption> options;
  @override
  Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme;
    return UxSection(title:title,description:description,icon:Icons.dashboard_customize_outlined,
      child:Column(children:[for(var i=0;i<options.length;i++)...[
        if(i>0) Divider(height:22,color:c.outlineVariant.withOpacity(.6)),
        Material(color:Colors.transparent,child:InkWell(borderRadius:BorderRadius.circular(14),onTap:options[i].onTap,
          child:Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:(options[i].danger?c.error:c.primary).withOpacity(.08),borderRadius:BorderRadius.circular(13)),
              child:Icon(options[i].icon,color:options[i].danger?c.error:c.primary,size:21)),
            const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(options[i].title,style:TextStyle(color:options[i].danger?c.error:c.onSurface,fontWeight:FontWeight.w700,fontSize:16,height:1.3)),
              const SizedBox(height:4),Text(options[i].description,style:TextStyle(color:c.onSurfaceVariant,fontSize:12,height:1.5)),
            ])),
            if(options[i].onTap!=null) Padding(padding:const EdgeInsets.only(left:6,top:6),child:Icon(Icons.chevron_right_rounded,color:c.onSurfaceVariant,size:20)),
          ]))),
        ),
      ]]),
    );
  }
}

class FieldNote extends StatelessWidget {
  const FieldNote(this.text,{super.key,this.warning=false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context){
    final c=Theme.of(context).colorScheme;
    final ink=warning?c.error:c.primary;
    return Container(width:double.infinity,margin:const EdgeInsets.symmetric(vertical:10),padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:ink.withOpacity(.07),borderRadius:BorderRadius.circular(16),border:Border.all(color:ink.withOpacity(.18))),
      child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(warning?Icons.info_outline_rounded:Icons.lightbulb_outline_rounded,color:ink,size:20),
        const SizedBox(width:10),Expanded(child:Text(text,style:TextStyle(color:c.onSurface,height:1.5,fontSize:13)))]));
  }
}
